import sys
import subprocess
import logging
from extractor import run_extraction
from loader import run_load
from config import PROJECTS
from pipeline_cli import select_projects

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(name)s - %(message)s'
)
logger = logging.getLogger(__name__)

def main():
    # Ninguna llamada sin argumentos puede tocar proyectos de producción.
    proyectos = select_projects(PROJECTS, allow_all=True)

    logger.info(f"Proyectos a procesar: {proyectos or 'todos'}")

    # 1. Extracción
    logger.info("=== EXTRACCIÓN ===")
    run_extraction(projects=proyectos, full_refresh=False)

    # 2. Carga
    logger.info("=== CARGA ===")
    run_load(projects=proyectos)

    # 3. dbt
    logger.info("=== DBT BUILD ===")

    for proyecto in proyectos:
        logger.info(f"dbt build — {proyecto}")
        result = subprocess.run([
            "dbt", "build",
            "--project-dir", "fci_dbt",
            "--select", f"path:models/{proyecto}"
        ])
        if result.returncode != 0:
            logger.error(f"dbt build falló en {proyecto}")
            sys.exit(1)

    logger.info("=== PIPELINE COMPLETO ===")

if __name__ == "__main__":
    main()
