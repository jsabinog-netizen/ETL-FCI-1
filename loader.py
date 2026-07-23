import os
import json
import logging

from google.cloud import bigquery
from dotenv import load_dotenv
from metadata import ensure_metadata_table, write_run
from config import PROJECTS

# Cargar variables de entorno
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(BASE_DIR, ".env"))

# Misma config de logging que extractor.py
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(name)s - %(message)s')
logger = logging.getLogger(__name__)

PROJECT_ID = "zoho-bq-pipeline-492116"

# Campos que Zoho devuelve como OBJETO ({"name":..,"id":..,"email":..}) o LISTA.
# Estos aterrizan como columna JSON nativa en raw. .
NESTED_FIELDS = {
    # estándar de Zoho (siempre objetos)
    "Owner", "Created_By", "Modified_By",
    # listas
    "Tag", "Connected_To__s",
    # lookups a otros módulos (vienen como objeto {name, id})
    "Empresa", "Profesional_asignado", "Profesional_asignado1",
    "Agenda", "Agenda_origen", "Agendamiento_grupal_origen",
    "Colocaci_n", "Intermediaci_n", "Orientaci_n", "Registro",
    "Registro_Giz"
}


def get_client():
    cred_path = os.path.join(BASE_DIR, "gcp-credentials.json")
    return bigquery.Client.from_service_account_json(cred_path, project=PROJECT_ID)

# SCHEMAS — explícitos, no autodetect

def build_raw_schema(fields):
    """
    Schema de la tabla RAW.
    - id           → STRING (llave del MERGE, viene de Zoho)
    - anidados     → JSON   (objetos/listas; dbt los lee con JSON_VALUE)
    - resto        → STRING (aterrizaje fiel; el casteo de fechas/números es dbt)
    - Modified_Time→ TIMESTAMP (plumbing: fuente del since incremental)
    - _loaded_at   → TIMESTAMP (plumbing: auditoría, cuándo se cargó)
    """
    cols = [bigquery.SchemaField("id", "STRING")]
    for f in fields:
        if f == "Modified_Time": 
            continue
        tipo = "JSON" if f in NESTED_FIELDS else "STRING"
        cols.append(bigquery.SchemaField(f, tipo))
    cols.append(bigquery.SchemaField("Modified_Time", "TIMESTAMP"))
    cols.append(bigquery.SchemaField("_loaded_at", "TIMESTAMP"))
    return cols


def build_staging_schema(fields):
    """
    Schema de STAGING: TODO STRING. La carga nunca falla por un tipo.
    Los tipos reales se materializan en el MERGE hacia raw.
    """
    cols = [bigquery.SchemaField("id", "STRING")]
    for f in fields:
        if f == "Modified_Time":     
            continue
        cols.append(bigquery.SchemaField(f, "STRING"))
    cols.append(bigquery.SchemaField("Modified_Time", "STRING"))
    return cols

# PREPARACIÓN DE FILAS

def _to_cell(value):
    """
    Convierte cualquier valor de Zoho a algo que entra en una columna STRING:
    - None         → None  (queda NULL en BigQuery)
    - dict / list  → json.dumps (objeto/lista anidada → texto JSON)
    - str          → tal cual
    - número/bool  → str(value)
    """
    if value is None:
        return None
    if isinstance(value, (dict, list)):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, str):
        return value
    return str(value)


def prepare_rows(records, fields):
    """Convierte los registros crudos de Zoho en filas listas para staging (todo STRING)."""
    rows = []
    for r in records:
        row = {"id": _to_cell(r.get("id"))}
        for f in fields:
            row[f] = _to_cell(r.get(f))
        row["Modified_Time"] = _to_cell(r.get("Modified_Time"))
        rows.append(row)
    return rows

# OPERACIONES BIGQUERY

def ensure_table(client, table_fqn, schema):
    """Crea la tabla con schema explícito si no existe. Si ya existe, no la toca."""
    table = bigquery.Table(table_fqn, schema=schema)
    client.create_table(table, exists_ok=True)


def load_to_staging(client, rows, staging_schema, staging_fqn):
    """Carga las filas a staging reemplazando el contenido anterior (WRITE_TRUNCATE)."""
    job_config = bigquery.LoadJobConfig(
        schema=staging_schema,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
    )
    job = client.load_table_from_json(rows, staging_fqn, job_config=job_config)
    job.result()  # espera a que termine; lanza excepción si falla
    return job.output_rows


def count_insert_update(client, staging_fqn, raw_fqn):
    """
    Cuenta ANTES del MERGE cuántos ids de staging ya existen en raw (updates)
    y cuántos son nuevos (inserts). DISTINCT por si hubiera ids repetidos.
    """
    q = f"""
    SELECT
      (SELECT COUNT(DISTINCT id) FROM `{staging_fqn}`) AS total,
      (SELECT COUNT(DISTINCT s.id) FROM `{staging_fqn}` s
       WHERE EXISTS (SELECT 1 FROM `{raw_fqn}` t WHERE t.id = s.id)) AS updates
    """
    row = list(client.query(q).result())[0]
    total = row["total"]
    updates = row["updates"]
    inserts = total - updates
    return inserts, updates


def _src_expr(name, field_type):
    """Cómo se lee cada columna desde staging (S) al materializar el tipo en raw."""
    if name == "_loaded_at":
        return "CURRENT_TIMESTAMP()"            # generado en la carga, no viene de Zoho
    if field_type == "JSON":
        return f"SAFE.PARSE_JSON(S.`{name}`)"   # texto JSON → JSON nativo (SAFE = no rompe si viene mal)
    if field_type == "TIMESTAMP":               # Modified_Time
        return f"SAFE_CAST(S.`{name}` AS TIMESTAMP)"
    return f"S.`{name}`"                         # STRING: tal cual


def build_merge_sql(raw_fqn, staging_fqn, raw_schema):
    """
    Construye el MERGE idempotente dinámicamente desde el schema raw.
    - Dedup defensivo: se queda con la fila más reciente por id (por si Zoho
      repite un id entre páginas). Evita que el MERGE explote.
    - WHEN MATCHED   → actualiza todas las columnas menos id.
    - WHEN NOT MATCHED → inserta la fila nueva.
    """
    update_set = ",\n    ".join(
        f"T.`{f.name}` = {_src_expr(f.name, f.field_type)}"
        for f in raw_schema if f.name != "id"
    )
    insert_cols = ", ".join(f"`{f.name}`" for f in raw_schema)
    insert_vals = ", ".join(_src_expr(f.name, f.field_type) for f in raw_schema)

    return f"""
MERGE `{raw_fqn}` T
USING (
  SELECT * EXCEPT(_rn) FROM (
    SELECT s.*, ROW_NUMBER() OVER (PARTITION BY id ORDER BY Modified_Time DESC) AS _rn
    FROM `{staging_fqn}` s
  )
  WHERE _rn = 1
) S
ON T.id = S.id
WHEN MATCHED THEN UPDATE SET
    {update_set}
WHEN NOT MATCHED THEN INSERT ({insert_cols})
VALUES ({insert_vals})
"""
def build_merge_sql_with_delete(raw_fqn, staging_fqn, raw_schema):
    """
    Igual que build_merge_sql pero agrega WHEN NOT MATCHED BY SOURCE THEN DELETE:
    borra de raw los registros que YA NO vienen de Zoho (borrados en el CRM).

    PELIGRO: usar SOLO en modo reconciliación con FULL REFRESH. En una carga
    incremental borraría todo lo que no cambió recientemente.
    """
    update_set = ",\n    ".join(
        f"T.`{f.name}` = {_src_expr(f.name, f.field_type)}"
        for f in raw_schema if f.name != "id"
    )
    insert_cols = ", ".join(f"`{f.name}`" for f in raw_schema)
    insert_vals = ", ".join(_src_expr(f.name, f.field_type) for f in raw_schema)

    return f"""
MERGE `{raw_fqn}` T
USING (
  SELECT * EXCEPT(_rn) FROM (
    SELECT s.*, ROW_NUMBER() OVER (PARTITION BY id ORDER BY Modified_Time DESC) AS _rn
    FROM `{staging_fqn}` s
  )
  WHERE _rn = 1
) S
ON T.id = S.id
WHEN MATCHED THEN UPDATE SET
    {update_set}
WHEN NOT MATCHED BY TARGET THEN INSERT ({insert_cols})
VALUES ({insert_vals})
WHEN NOT MATCHED BY SOURCE THEN DELETE
"""


def es_seguro_borrar(client, staging_fqn, raw_fqn, umbral_pct=0.8, tolerancia_abs=5):
    """
    Decide si es seguro borrar comparando staging (fuente) vs raw (destino).
    Combina % y cantidad absoluta para no bloquear borrados legítimos en tablas chicas.

    Seguro si: la fuente trae >= umbral_pct de raw, O la caída es <= tolerancia_abs.
    Aborta SOLO si caen muchos registros (> tolerancia) Y en gran proporción (< umbral_pct)
    — señal de extracción incompleta/fallida.

    Devuelve (es_seguro, n_staging, n_raw).
    """
    q = f"""
    SELECT
      (SELECT COUNT(DISTINCT id) FROM `{staging_fqn}`) AS n_staging,
      (SELECT COUNT(DISTINCT id) FROM `{raw_fqn}`)     AS n_raw
    """
    row = list(client.query(q).result())[0]
    n_staging = row["n_staging"] or 0
    n_raw = row["n_raw"] or 0

    if n_raw == 0:
        return True, n_staging, n_raw

    caida_abs = n_raw - n_staging
    ratio = n_staging / n_raw

    if ratio >= umbral_pct or caida_abs <= tolerancia_abs:
        return True, n_staging, n_raw

    return False, n_staging, n_raw


def reconciliar_module(client, module_name, fields,dataset, project_name="colsubsidio", umbral_pct=0.8, tolerancia_abs=5):
    """
    Modo RECONCILIACIÓN: carga full refresh + MERGE con borrado de los que
    ya no están en Zoho. Protegido por guardrail de conteo.

    Requiere que output/{project}/{module}.json sea un FULL REFRESH.
    Corre por separado del pipeline incremental normal.
    """
    table_name = module_name.lower()
    raw_fqn = f"{PROJECT_ID}.{dataset}.{table_name}"
    staging_fqn = f"{PROJECT_ID}.{dataset}._stg_{table_name}"

    path = f"output/{project_name}/{module_name}.json"
    if not os.path.exists(path):
        logger.error(f"{module_name}: no existe {path} — corré el extractor en full refresh primero")
        return
    with open(path, "r", encoding="utf-8") as f:
        records = json.load(f)

    if not records:
        # CLAVE: vacío → NO borrar (podría ser extracción fallida, no un módulo realmente vacío).
        logger.warning(f"{module_name}: 0 registros — NO se reconcilia (posible extracción incompleta)")
        return

    if "id" not in records[0]:
        logger.error(f"{module_name}: registros sin 'id' — abortado")
        return

    rows = prepare_rows(records, fields)
    raw_schema = build_raw_schema(fields)
    staging_schema = build_staging_schema(fields)

    ensure_table(client, raw_fqn, raw_schema)
    cargados = load_to_staging(client, rows, staging_schema, staging_fqn)
    logger.info(f"{module_name}: {cargados} filas en staging (reconciliación)")

    seguro, n_staging, n_raw = es_seguro_borrar(client, staging_fqn, raw_fqn, umbral_pct, tolerancia_abs)
    if not seguro:
        logger.error(
            f"{module_name}: ABORTADO borrado — staging={n_staging} vs raw={n_raw} "
            f"(caída sospechosa). Se hace MERGE normal SIN borrar."
        )
        client.query(build_merge_sql(raw_fqn, staging_fqn, raw_schema)).result()
        return

    # Contar cuántos se van a borrar (para el log)
    q_borrados = f"""
    SELECT COUNT(*) AS n FROM `{raw_fqn}` T
    WHERE NOT EXISTS (SELECT 1 FROM `{staging_fqn}` S WHERE S.id = T.id)
    """
    n_borrados = list(client.query(q_borrados).result())[0]["n"]

    client.query(build_merge_sql_with_delete(raw_fqn, staging_fqn, raw_schema)).result()

    logger.info(f"{module_name}: reconciliación OK | staging={n_staging} raw_antes={n_raw} | BORRADOS={n_borrados}")
    if n_borrados > 0:
        logger.warning(f"{module_name}: se borraron {n_borrados} registros que ya no están en Zoho")


# ORQUESTACIÓN POR MÓDULO

def load_module(client, module_name, fields,dataset, project_name="colsubsidio"):
    """
    Carga un módulo desde output/{project_name}/{module_name}.json a su tabla raw,
    con upsert idempotente. Loggea insertados vs actualizados.
    """
    table_name = module_name.lower()
    raw_fqn = f"{PROJECT_ID}.{dataset}.{table_name}"
    staging_fqn = f"{PROJECT_ID}.{dataset}._stg_{table_name}"

    # 1. Leer el JSON que dejó el extractor
    path = f"output/{project_name}/{module_name}.json"
    if not os.path.exists(path):
        logger.error(f"{module_name}: no existe {path} — corré el extractor primero")
        return
    with open(path, "r", encoding="utf-8") as f:
        records = json.load(f)

    if not records:
        logger.warning(f"{module_name}: 0 registros en {path} — nada que cargar")
        write_run(client, project_name, module_name, "empty", 0, None)
        return

    # 2. Guardrail: sin 'id' no hay MERGE seguro
    if "id" not in records[0]:
        logger.error(
            f"{module_name}: los registros no traen 'id' de Zoho — "
            f"no puedo hacer MERGE seguro. Revisá la extracción."
        )
        return

    # 3. Preparar filas y schemas
    rows = prepare_rows(records, fields)
    raw_schema = build_raw_schema(fields)
    staging_schema = build_staging_schema(fields)

    # 4. Asegurar que raw exista (la necesita el conteo y el MERGE)
    ensure_table(client, raw_fqn, raw_schema)

    # 5. Cargar a staging (reemplaza cada corrida)
    cargados = load_to_staging(client, rows, staging_schema, staging_fqn)
    logger.info(f"{module_name}: {cargados} filas en staging")

    # 6. Contar antes del MERGE
    inserts, updates = count_insert_update(client, staging_fqn, raw_fqn)

    # 7. MERGE idempotente
    merge_sql = build_merge_sql(raw_fqn, staging_fqn, raw_schema)
    client.query(merge_sql).result()

    # 8. Log de salida 
    logger.info(f"{module_name}: {inserts} insertados | {updates} actualizados | tabla {table_name}")

    # 9. Watermark = MAX(Modified_Time) de lo cargado → fuente del since incremental
    fechas = [r.get("Modified_Time") for r in records if r.get("Modified_Time")]
    watermark = max(fechas) if fechas else None
    write_run(client, project_name, module_name, "success", len(records), watermark)

def run_load(projects=None):
    """
    Carga los módulos de los proyectos seleccionados a BigQuery.
    projects: lista de nombres ["colsubsidio", "giz"] o None para todos.
    """
    todos = PROJECTS
    if projects is None:
        projects = todos
    else:
        projects = {nombre: todos[nombre] for nombre in projects}

    client = get_client()
    ensure_metadata_table(client)

    for project_name, project_cfg in projects.items():
        dataset  = project_cfg["dataset_id"]
        modules  = project_cfg["modules"]
        logger.info(f"Cargando proyecto {project_name}...")
        exitosos, fallidos = 0, []
        for module_name, fields in modules.items():
            try:
                load_module(client, module_name, fields, dataset, project_name=project_name)
                exitosos += 1
            except Exception as e:
                logger.error(f"{module_name} FALLÓ — continúo: {e}")
                fallidos.append(module_name)
        logger.info(f"{project_name}: {exitosos} OK | {len(fallidos)} fallidos")
        if fallidos:
            logger.warning(f"Fallidos: {fallidos}")

# PUNTO DE ENTRADA

if __name__ == "__main__":
    run_load(["giz"])