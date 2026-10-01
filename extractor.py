import time
import random
import logging
import requests
import json 
import os

from datetime import datetime

# Importar la clase ZohoAuth de mi archivo auth
from auth import ZohoAuth

#Importat modulos
from config import PROJECTS


from metadata import get_watermark, ensure_metadata_table, write_run
from loader import get_client

#Configurar el logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(name)s - %(message)s',)

#Obtener el nombre de mi archivo
logger = logging.getLogger(__name__)  

#Funcion que aumenta el tiempo de espera que cada falla una llamada a la API
def request_with_backoff(fn, max_retries=5):
    """
    Ejecuta fn() con reintentos usando backoff exponencial y jitter.

    Args:
        fn: Callable sin argumentos. Ejemplo:
            request_with_backoff(lambda: requests.get(url, headers=h))
        max_retries: Número máximo de intentos (default: 5).
            Con 5 intentos la espera máxima es ~17 segundos.

    Returns:
        El resultado de fn() cuando tiene éxito.

    Raises:
        La excepción original de fn() si se agotan todos los reintentos.
    """

    #Intentar varias veces
    for intento in range(max_retries):
        #Si funciona retornar el resultado
        try:
            result = fn()
            return result
        #Si hay algun error aumentar tiempo de espera, si es el intento 5 lanzar un error 
        except Exception as e: 
            if intento == max_retries-1:
                raise 
            wait_time = (2 ** intento)+random.uniform(0,1)
            logger.warning(f"Intento {intento+1}/{max_retries} falló: {e}. Reintentando en {wait_time:.2f}s...")
            time.sleep(wait_time)

def fetch_page(auth, module_name, fields, page, per_page=200, since=None, _retried= False):
    """
    Hace UN request a la API de Zoho para una página específica.
    Maneja errores de forma diferenciada según el código HTTP.

    Args:
        auth: instancia de ZohoAuth
        module_name: nombre del módulo en Zoho (ej: "Registro_empresas")
        fields: lista de campos a solicitar
        page: número de página a extraer
        per_page: registros por página (Zoho max: 200)
        since: datetime string ISO para extracción incremental (o None)
        _retried: uso interno — evita loop infinito en renovación de token 401.No pasar desde afuera.

    Returns:
        tuple: (lista_de_registros, hay_mas_paginas, next_page_token)
    """
    if len(fields) > 50:
        raise ValueError(
            f"{module_name} tiene {len(fields)} campos — Zoho permite máximo 50"
        )

    fields_con_sistema = list(fields)
    if "Modified_Time" not in fields_con_sistema:
        fields_con_sistema.append("Modified_Time")

    # URL base de Zoho CRM API v8:
    base_url = f"https://www.zohoapis.com/crm/v8/{module_name}"

    parametros = {
    "fields":",".join(f.strip() for f in fields_con_sistema),
    "page": page,
    "per_page": per_page
    }

    headers = auth.get_header()

    if since is not None:
        parametros["sort_by"] = "Modified_Time"
        parametros["sort_order"] = "asc"
        headers["If-Modified-Since"] = since

    #Hacer el request con mis parametros y header 
    response = requests.get(base_url, headers=headers, params=parametros)

    #Si la respuesta es correcta obtener los registros
    if response.status_code == 200:
        res_json = response.json()
        registros = res_json.get("data", [])
        info = res_json.get("info", {})
        mas_registros = info.get("more_records", False)
        next_page_token = info.get("next_page_token")
        return registros, mas_registros, next_page_token

    #Si no hay registros
    elif response.status_code == 204:
        return [], False, None

    #Si no hay registros desde la fecha escogida
    elif response.status_code == 304:
        return [], False, None

    # 400/403 — errores no recuperables, no reintenta. 
    # 400: bug en el request (campos, módulo inválido)
    # 403: sin permisos en Zoho — contactar administrador
    elif response.status_code in (400,403,404):
        res_json = response.json()
        codigo_error = res_json.get("code", "UNKNOWN")
        mensaje_error = res_json.get("message", "Sin mensaje")
        logger.error(
            f"{response.status_code} en {module_name} |"
            f"código: {codigo_error} | mensaje: {mensaje_error}"
        )
        raise Exception(f"{response.status_code} {codigo_error} en {module_name} - {mensaje_error}")

    # Token vencido o inválido — renueva una vez y reintenta
    elif response.status_code == 401:
        if _retried:
            raise Exception(f"401 persistente en {module_name} — verificá credenciales en .env")
        auth.get_access_token()
        return fetch_page(auth, module_name, fields, page, per_page, since, _retried=True)

    # Rate limit excedido — espera Retry-After (o 60s por defecto) y deja que request_with_backoff reintente
    elif response.status_code == 429:
        retry_time = response.headers.get("Retry-After")
        if retry_time:
            time.sleep(int(retry_time))
        else: 
            time.sleep(60)
        raise Exception(f"429 Rate limit en {module_name}. Esperó {retry_time or 60}s")

    # 5xx y otros errores del servidor — raise para que request_with_backoff reintente con backoff
    else:
        logger.warning(f"{response.status_code} en {module_name} — reintentando con backoff")
        raise Exception(f"HTTP {response.status_code} en {module_name}")

def _extract_single_chunk(auth, module_name, fields, since=None, checkpoint_suffix=""):
    """Extrae registros para un único lote de campos respetando paginación y checkpoints."""
    os.makedirs("checkpoints", exist_ok=True)
    checkpoint_file = f"checkpoints/{module_name}{checkpoint_suffix}.json"

    # Validar si existe un checkpoint previo para este lote
    if os.path.exists(checkpoint_file):
        with open(checkpoint_file, "r") as f:
            estado = json.load(f)
        page = estado["page"]
        all_records = estado["records"]
        logger.info(f"{module_name}{checkpoint_suffix}: reanudando desde página {page} con {len(all_records)} registros previos")
    else:
        all_records = []
        page = 1
        logger.info(f"Iniciando extracción de {module_name}{checkpoint_suffix}...")
        if since is not None:
            logger.info(f"Modo Incremental desde {since}")
        else:
            logger.info("Modo Full refresh")

    has_more = True
    start_time = datetime.now()
    paginas_procesadas = 0
    while has_more:
        registros, mas_paginas, _token = request_with_backoff(
            lambda: fetch_page(auth, module_name=module_name, fields=fields,
                               page=page, since=since)
        )
        all_records.extend(registros)

        estado = {"page": page, "records": all_records}
        with open(checkpoint_file, "w") as f:
            json.dump(estado, f)
        
        logger.info(f"{module_name}{checkpoint_suffix} página {page} | {len(registros)} registros | {len(all_records)} acumulados")

        paginas_procesadas += 1
        page += 1
        has_more = mas_paginas

    duracion = (datetime.now() - start_time).total_seconds()
    logger.info(f"{module_name}{checkpoint_suffix} completado | {len(all_records)} registros | {paginas_procesadas} páginas | {duracion:.1f}s")

    if os.path.exists(checkpoint_file):
        os.remove(checkpoint_file)
    return all_records


def extract_module(auth, module_name, fields, since=None):
    """
    Extrae TODOS los registros de un módulo de Zoho con paginación.
    Si la lista de campos supera 45, divide automáticamente en lotes (chunks)
    de máximo 40 campos y fusiona los resultados por 'id' para respetar el límite de 50 de Zoho CRM.

    Args:
        auth: instancia de ZohoAuth
        module_name: nombre del módulo
        fields: lista de campos
        since: si se pasa, solo extrae registros modificados después de esta fecha

    Returns:
        list: todos los registros del módulo consolidados
    """
    os.makedirs("checkpoints", exist_ok=True)
    if len(fields) <= 45:
        return _extract_single_chunk(auth, module_name, fields, since=since, checkpoint_suffix="")

    max_chunk_size = 40
    chunks = [fields[i:i + max_chunk_size] for i in range(0, len(fields), max_chunk_size)]
    logger.info(f"{module_name}: {len(fields)} campos divididos en {len(chunks)} lotes (límite Zoho <= 50)")

    records_by_id = {}
    for idx, chunk in enumerate(chunks, 1):
        logger.info(f"{module_name}: Extrayendo lote {idx}/{len(chunks)} ({len(chunk)} campos)...")
        chunk_records = _extract_single_chunk(auth, module_name, chunk, since=since, checkpoint_suffix=f"_chunk_{idx}")
        for r in chunk_records:
            rid = str(r.get("id"))
            if rid not in records_by_id:
                records_by_id[rid] = r
            else:
                records_by_id[rid].update(r)

    merged_records = list(records_by_id.values())
    logger.info(f"{module_name}: Fusión de {len(chunks)} lotes completada con {len(merged_records)} registros consolidados")
    return merged_records

def run_extraction(projects=None, since=None, full_refresh=False):
    """
    Ejecuta la extracción de los proyectos seleccionados.

    Args:
        projects: lista de proyectos a extraer (ej: ["colsubsidio"]), o None para todos
        since: datetime ISO string para modo incremental, o None para full refresh
    """
    #Listar todos los proyectos de config
    todos_los_proyectos = PROJECTS
    #Si se escogio el proyecto validar si existe y extraerlo, si no extraer todos los proyectps
    if projects is None:
        projects = todos_los_proyectos
    else:
        for nombre in projects:
            if nombre not in todos_los_proyectos:
                disponibles = list(todos_los_proyectos.keys())
                raise ValueError(
                    f"Proyecto '{nombre}' no existe. Proyectos disponibles: {disponibles}"
                )
        projects = {nombre: todos_los_proyectos[nombre] for nombre in projects}
    
    os.makedirs("output", exist_ok=True) #Crer carpeta de salidas

    client = get_client()

    fallidos = []
    #Recorre cada proyecto y cada módulo
    for project_name, project_cfg in projects.items():
        auth = ZohoAuth(env_prefix=project_cfg["env_prefix"])  # ← por proyecto
        modules = project_cfg["modules"]
        ensure_metadata_table(client, project_cfg["dataset_id"])
        os.makedirs(f"output/{project_name}", exist_ok=True)

        ensure_metadata_table(client, project_cfg["dataset_id"]) #Crear la tabla si no existe

        logger.info(f"Extrayendo proyecto {project_name}...")                       
        for module_name, fields in modules.items():
            try:
                if full_refresh:
                    #Ignora la marca de agua, si elegi traer todos los datos
                    # Un checkpoint previo puede ser parcial o de otro modo de extracción.
                    # Para borrar se exige comenzar una extracción completa nueva.
                    checkpoint_existe = os.path.exists(f"checkpoints/{module_name}.json") or any(
                        os.path.exists(f"checkpoints/{module_name}_chunk_{i}.json") for i in range(1, 10)
                    )
                    if checkpoint_existe:
                        raise RuntimeError(f"{module_name}: checkpoint previo; no es seguro reconciliar")
                    module_since = None
                else:
                    module_since = since or get_watermark(client, project_name, module_name, project_cfg["dataset_id"])
                registros = extract_module(auth, module_name, fields, since=module_since)
                ruta_registros = f"output/{project_name}/{module_name}.json"
                with open(ruta_registros, "w") as f:
                    json.dump(registros, f)
                logger.info(f"{module_name}: {len(registros)} registros extraídos")
            except Exception as e:
                logger.error(f"{module_name} FALLÓ — no se extrajo: {e}")
                fallidos.append(f"{project_name}.{module_name}")
                try:
                    status = "reconcile_error" if full_refresh else "error"
                    write_run(client, project_name, module_name, status, 0, None,
                              dataset_id=project_cfg["dataset_id"])
                except Exception:
                    logger.exception(f"{module_name}: tampoco se pudo registrar el fallo")
    if fallidos:
        raise RuntimeError(f"Extracción incompleta; no cargar ni reconciliar: {fallidos}")

#Probar el modulo
if __name__ == "__main__":
    from pipeline_cli import select_projects
    run_extraction(projects=select_projects(PROJECTS))
