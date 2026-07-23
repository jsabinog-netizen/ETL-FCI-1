import sys
import subprocess
import logging
from extractor import run_extraction
from loader import run_load

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(name)s - %(message)s'
)
logger = logging.getLogger(__name__)

def main():
    # sys.argv[0] es el nombre del script, [1:] son los argumentos
    proyectos = sys.argv[1:] if len(sys.argv) > 1 else None
    # None significa "todos" en run_extraction y run_load

    logger.info(f"Proyectos a procesar: {proyectos or 'todos'}")

    # 1. Extracción
    logger.info("=== EXTRACCIÓN ===")
    run_extraction(projects=proyectos, full_refresh=False)

    # 2. Carga
    logger.info("=== CARGA ===")
    run_load(projects=proyectos)

    # 3. dbt
    logger.info("=== DBT BUILD ===")

    # Si no se especificaron proyectos, correr todos
    proyectos_dbt = proyectos if proyectos else ["colsubsidio", "giz"]

    for proyecto in proyectos_dbt:
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