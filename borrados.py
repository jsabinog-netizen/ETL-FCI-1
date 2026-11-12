"""
Propagación INCREMENTAL de borrados Zoho → BigQuery.

El MERGE incremental de loader.py inserta y actualiza, pero nunca borra.
Zoho expone GET /{modulo}/deleted con los ids que ESTÁN en la papelera o
fueron borrados permanentemente. Cada corrida del pipeline pide esa lista y
hace DELETE de esos ids en raw.

Diferencia con reconciliar.py: acá se borra solo lo que Zoho CONFIRMA como
borrado (evidencia positiva), no lo que falta en un full refresh (evidencia
por ausencia). Por eso no necesita el guardrail de volumen.

Se pide la lista completa en cada corrida, sin watermark: es idempotente
(si una corrida falla, la siguiente borra lo pendiente) y el volumen es chico.

Límite conocido: si alguien RESTAURA un registro desde la papelera, sale de
esta lista pero no vuelve a raw por el incremental si su Modified_Time no
cambia. reconciliar.py lo reinserta (el full refresh lo trae de vuelta).

Caso real que lo motivó: en Psicosocial_RutaM_v2, al diligenciar el
diagnóstico la integración borra el registro "enlace enviado" y crea uno
nuevo; el viejo quedaba en raw y duplicaba la cédula.
"""
import logging

import requests
from google.cloud import bigquery

from config import PROJECT_ID
from extractor import request_with_backoff
from metadata import write_run

logger = logging.getLogger(__name__)

BASE_URL = "https://www.zohoapis.com/crm/v8"
PAGINAS_SIN_TOKEN = 2000 // 200


def fetch_deleted_ids(auth, module_name, per_page=200):
    """
    Devuelve los ids borrados del módulo (papelera + permanentes).
    204 = nada borrado. Cualquier otro error se propaga.
    """
    ids, page, token = [], 1, None
    while True:
        params = {"type": "all", "per_page": per_page}
        if page > PAGINAS_SIN_TOKEN:
            if not token:
                raise RuntimeError(f"{module_name}: más de 2000 borrados y Zoho no devolvió next_page_token")
            params["page_token"] = token
        else:
            params["page"] = page

        def _get():
            r = requests.get(f"{BASE_URL}/{module_name}/deleted",
                             headers=auth.get_header(), params=params)
            if r.status_code == 401:
                auth.get_access_token()
                raise Exception(f"401 en /deleted de {module_name}, token renovado")
            if r.status_code not in (200, 204):
                raise Exception(f"HTTP {r.status_code} en /deleted de {module_name}: {r.text[:200]}")
            return r

        resp = request_with_backoff(_get)
        if resp.status_code == 204:
            break
        body = resp.json()
        ids.extend(str(d["id"]) for d in body.get("data", []) if d.get("id"))
        info = body.get("info", {})
        if not info.get("more_records"):
            break
        token = info.get("next_page_token")
        page += 1
    return ids


def delete_from_raw(client, dataset, module_name, ids):
    """DELETE de los ids en la tabla raw del módulo. Devuelve cuántas filas borró."""
    if not ids:
        return 0
    raw_fqn = f"{PROJECT_ID}.{dataset}.{module_name.lower()}"
    job = client.query(
        f"DELETE FROM `{raw_fqn}` WHERE id IN UNNEST(@ids)",
        job_config=bigquery.QueryJobConfig(query_parameters=[
            bigquery.ArrayQueryParameter("ids", "STRING", ids),
        ]),
    )
    job.result()
    return job.num_dml_affected_rows or 0


def propagar_borrados(client, auth, project_name, dataset, modules):
    """
    Corre después de la carga y antes de dbt. Intenta todos los módulos;
    al final levanta error si alguno falló (no debe fallar en silencio).

    Auditoría en pipeline_metadata con watermark NULL: get_watermark usa
    MAX(watermark), así que estas filas no mueven el incremental, y
    verificar_frescura.py solo mira success/empty/error.
    """
    fallidos, total = [], 0
    for module_name in modules:
        try:
            ids = fetch_deleted_ids(auth, module_name)
            borrados = delete_from_raw(client, dataset, module_name, ids)
            total += borrados
            if borrados:
                logger.warning(f"{module_name}: {borrados} registros borrados en Zoho eliminados de raw")
            else:
                logger.info(f"{module_name}: {len(ids)} borrados en Zoho, ninguno pendiente en raw")
            write_run(client, project_name, module_name, "deleted", borrados, None, dataset_id=dataset)
        except Exception as e:
            logger.error(f"{module_name}: propagación de borrados FALLÓ — continúo: {e}")
            fallidos.append(module_name)
            try:
                write_run(client, project_name, module_name, "delete_error", 0, None, dataset_id=dataset)
            except Exception:
                logger.exception(f"{module_name}: tampoco se pudo registrar el fallo")

    logger.info(f"{project_name}: borrados propagados = {total} | módulos fallidos = {len(fallidos)}")
    if fallidos:
        raise RuntimeError(f"Propagación de borrados incompleta en '{project_name}': {fallidos}")
    return total
