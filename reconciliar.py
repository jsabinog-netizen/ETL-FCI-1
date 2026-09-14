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

Si se automatiza en GitHub Actions, usar el MISMO grupo de concurrencia
que el workflow incremental del proyecto: ambos escriben las mismas
tablas y no pueden solaparse.
"""
import logging
import sys
import subprocess

from config import PROJECTS, PROJECT_ID
from extractor import run_extraction
from loader import get_client, reconciliar_module
from metadata import ensure_metadata_table

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(name)s - %(message)s')
logger = logging.getLogger(__name__)


def main():
    proyecto = sys.argv[1] if len(sys.argv) == 2 else None

    # Sin default: este script BORRA. Un `python reconciliar.py` sin
    # argumento no puede terminar disparando borrados sobre varios
    # proyectos de producción a la vez.
    if not proyecto:
        logger.error(
            "Debe especificar un proyecto. Uso: python reconciliar.py <proyecto>\n"
            f"Proyectos disponibles: {list(PROJECTS)}"
        )
        sys.exit(1)

    if proyecto not in PROJECTS:
        logger.error(f"Proyecto desconocido: {proyecto}. Opciones: {list(PROJECTS)}")
        sys.exit(1)

    proyectos_a_correr = [proyecto]
    logger.info(f"=== INICIO RECONCILIACIÓN: {proyecto} ===")

    # 1. Extracción FULL REFRESH — trae el universo completo, ignora watermarks.
    # Es la precondición del borrado: sin el universo completo, el MERGE
    # con DELETE borraría todo lo que no cambió recientemente.
    logger.info("Extrayendo en modo FULL REFRESH...")
    run_extraction(projects=proyectos_a_correr, full_refresh=True)

    # 2. Reconciliar módulo por módulo (con guardrail de borrado)
    client = get_client()

    exitosos = 0
    fallidos = []
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
                    umbral_pct=0.8
                )
                if status != "reconciled":
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

    logger.info(f"=== RECONCILIACIÓN TERMINADA: {exitosos} OK | {len(fallidos)} fallidos ===")

    # Corta antes de dbt a propósito: si algún módulo no se reconcilió,
    # los marts quedarían mezclando datos reconciliados con datos viejos.
    # Es preferible no propagar esa mezcla al dashboard.
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
