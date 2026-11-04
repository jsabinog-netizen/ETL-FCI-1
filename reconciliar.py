"""
Proceso de BORRADO — sincroniza borrados de Zoho hacia BigQuery.

Corre SEPARADO del pipeline incremental (loader.py). Una vez al día.
Flujo:
  1. Extrae en FULL REFRESH.
  2. Por cada módulo, hace MERGE con borrado (WHEN NOT MATCHED BY SOURCE DELETE),
     protegido por el guardrail es_seguro_borrar.
  3. dbt build del proyecto.

PELIGRO: este proceso BORRA datos. Solo debe correr con full refresh.
Nunca mezclar con el pipeline incremental.

Uso:
  python reconciliar.py <proyecto> --dry-run   # lista lo que borraría; no escribe en BigQuery
  python reconciliar.py <proyecto>             # borra de verdad

Antes del primer borrado real de un proyecto, correr el --dry-run y revisar
los ids en Zoho.

Si se automatiza en GitHub Actions, usar el MISMO grupo de concurrencia
que el workflow incremental del proyecto: ambos escriben las mismas
tablas y no pueden solaparse.
"""
import logging
import sys
import subprocess

from config import PROJECTS, PROJECT_ID
from extractor import run_extraction
from loader import get_client, reconciliar_module, contar_huerfanos, decidir_borrado
from metadata import ensure_metadata_table

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(name)s - %(message)s')
logger = logging.getLogger(__name__)

UMBRAL_PCT = 0.8


def dry_run(proyecto):
    """
    Informa, módulo por módulo, qué registros de raw ya no están en Zoho y
    si el guardrail dejaría borrarlos. No escribe nada en BigQuery ni corre dbt.
    """
    config = PROJECTS[proyecto]
    client = get_client()
    total, fallidos = 0, []
    for module_name in config["modules"]:
        try:
            n_zoho, n_raw, huerfanos = contar_huerfanos(
                client, module_name, config["dataset_id"], proyecto)
        except Exception as e:
            logger.error(f"{module_name}: dry-run FALLÓ — {e}")
            fallidos.append(module_name)
            continue
        if n_zoho == 0:
            veredicto = "se omitiría (Zoho vacío)"
        elif decidir_borrado(n_zoho, n_raw, UMBRAL_PCT):
            veredicto = f"borraría {len(huerfanos)}"
        else:
            veredicto = f"BLOQUEADO por guardrail ({len(huerfanos)} huérfanos, no borraría)"
        logger.info(f"{module_name}: zoho={n_zoho} raw={n_raw} → {veredicto}")
        for h in huerfanos:
            logger.info(f"    id={h['id']}  Name={h['Name']}  Modified_Time={h['Modified_Time']}")
        total += len(huerfanos)

    logger.info(f"=== DRY-RUN {proyecto}: {total} huérfanos en total | {len(fallidos)} módulos fallidos ===")
    if fallidos:
        raise RuntimeError(f"Dry-run incompleto en '{proyecto}': {fallidos}")


def main():
    args = sys.argv[1:]
    es_dry_run = "--dry-run" in args
    posicionales = [a for a in args if a != "--dry-run"]
    proyecto = posicionales[0] if len(posicionales) == 1 else None

    # Sin default: este script BORRA. Un `python reconciliar.py` sin
    # argumento no puede terminar disparando borrados sobre varios
    # proyectos de producción a la vez.
    if not proyecto:
        logger.error(
            "Debe especificar un proyecto. Uso: python reconciliar.py <proyecto> [--dry-run]\n"
            f"Proyectos disponibles: {list(PROJECTS)}"
        )
        sys.exit(1)

    if proyecto not in PROJECTS:
        logger.error(f"Proyecto desconocido: {proyecto}. Opciones: {list(PROJECTS)}")
        sys.exit(1)

    proyectos_a_correr = [proyecto]
    modo = "DRY-RUN" if es_dry_run else "RECONCILIACIÓN"
    logger.info(f"=== INICIO {modo}: {proyecto} ===")

    # 1. Extracción FULL REFRESH — trae el universo completo, ignora watermarks.
    # Es la precondición del borrado: sin el universo completo, el MERGE
    # con DELETE borraría todo lo que no cambió recientemente.
    logger.info("Extrayendo en modo FULL REFRESH...")
    run_extraction(projects=proyectos_a_correr, full_refresh=True)

    if es_dry_run:
        dry_run(proyecto)
        return

    # 2. Reconciliar módulo por módulo (con guardrail de borrado)
    client = get_client()

    exitosos = 0
    fallidos = []
    omitidos = []
    for p in proyectos_a_correr:
        config = PROJECTS[p]
        ensure_metadata_table(client, config["dataset_id"])

        for module_name, fields in config["modules"].items():
            try:
                status = reconciliar_module(
                    client,
                    module_name,
                    fields,
                    dataset=config["dataset_id"],
                    project_name=p,
                    umbral_pct=UMBRAL_PCT
                )
                if status == "reconcile_skipped":
                    omitidos.append(module_name)
                elif status != "reconciled":
                    fallidos.append(f"{module_name} ({status})")
                    logger.warning(f"{module_name}: reconciliación incompleta ({status})")
                else:
                    exitosos += 1
            except Exception as e:
                # Se continúa para no dejar los demás módulos sin reconciliar
                # por un fallo puntual, pero al final se levanta el error:
                # un proceso que falla en silencio es cómo el pipeline de
                # Colsubsidio estuvo 19 días roto terminando en verde.
                logger.error(f"{module_name} FALLÓ en reconciliación — continúo: {e}")
                fallidos.append(module_name)

    logger.info(
        f"=== RECONCILIACIÓN TERMINADA: {exitosos} OK | "
        f"{len(omitidos)} omitidos | {len(fallidos)} fallidos ==="
    )

    # Un origen vacío puede ser legítimo (Participantes_Bootcamps nunca
    # se usó); se informa sin bloquear dbt. Los errores y los bloqueos
    # por caída sospechosa de volumen sí impiden continuar.
    if omitidos:
        logger.warning(
            f"Módulos sin datos en origen ({len(omitidos)}): {omitidos}. "
            "No es un fallo, pero revisá si alguno debería tener registros."
        )
    if fallidos:
        raise RuntimeError(
            f"Reconciliación incompleta en '{proyecto}': "
            f"{len(fallidos)} módulos fallaron: {fallidos}"
        )

    # 3. dbt build por proyecto
    for p in proyectos_a_correr:
        logger.info(f"dbt build — {p}")
        result = subprocess.run([
            "dbt", "build",
            "--project-dir", "fci_dbt",
            "--select", f"path:models/{p}"
        ])
        if result.returncode != 0:
            logger.error(f"dbt build falló en {p}")
            sys.exit(1)

    logger.info(f"=== RECONCILIACIÓN COMPLETA: {proyecto} ===")


if __name__ == "__main__":
    main()
