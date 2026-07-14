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

from config import MODULES_COLSUBSIDIO
from extractor import run_extraction
from loader import get_client, reconciliar_module
from metadata import ensure_metadata_table

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(name)s - %(message)s')
logger = logging.getLogger(__name__)


def main():
    logger.info("=== INICIO RECONCILIACIÓN (con borrado de registros eliminados en Zoho) ===")

    # 1. Extracción FULL REFRESH — trae el universo completo, ignora watermarks.
    logger.info("Extrayendo en modo FULL REFRESH...")
    run_extraction(projects=["colsubsidio"], full_refresh=True)

    # 2. Reconciliar módulo por módulo (con guardrail de borrado)
    client = get_client()
    ensure_metadata_table(client)

    exitosos = 0
    fallidos = []
    for module_name, fields in MODULES_COLSUBSIDIO.items():
        try:
            reconciliar_module(client, module_name, fields)
            exitosos += 1
        except Exception as e:
            logger.error(f"{module_name} FALLÓ en reconciliación — continúo: {e}")
            fallidos.append(module_name)

    logger.info(f"=== RECONCILIACIÓN TERMINADA: {exitosos} OK | {len(fallidos)} fallidos ===")
    if fallidos:
        logger.warning(f"Módulos fallidos: {fallidos}")


if __name__ == "__main__":
    main()