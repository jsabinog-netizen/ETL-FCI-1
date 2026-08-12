"""
Proceso de BORRADO — sincroniza borrados de Zoho hacia BigQuery.

Corre SEPARADO del pipeline incremental (loader.py). Una vez al día.
Flujo:
  1. Extrae en FULL REFRESH.
  2. Por cada módulo, hace MERGE con borrado (WHEN NOT MATCHED BY SOURCE DELETE),
     protegido por el guardrail es_seguro_borrar.

PELIGRO: este proceso BORRA datos. Solo debe correr con full refresh.
Nunca mezclar con el pipeline incremental.
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
    # sys.argv[0] es el nombre del script, [1] es el argumento opcional
    proyecto = sys.argv[1] if len(sys.argv) > 1 else None
    proyectos_a_correr = [proyecto] if proyecto else ["colsubsidio", "giz"]

    logger.info(f"=== INICIO RECONCILIACIÓN: {proyectos_a_correr} ===")

    # 1. Extracción FULL REFRESH — trae el universo completo, ignora watermarks.
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
                reconciliar_module(
                    client,
                    module_name,
                    fields,
                    dataset=config["dataset_id"],
                    project_name=p
                )
                exitosos += 1
            except Exception as e:
                logger.error(f"{module_name} FALLÓ en reconciliación — continúo: {e}")
                fallidos.append(module_name)

    logger.info(f"=== RECONCILIACIÓN TERMINADA: {exitosos} OK | {len(fallidos)} fallidos ===")
    if fallidos:
        logger.warning(f"Módulos fallidos: {fallidos}")

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


if __name__ == "__main__":
    main()