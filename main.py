import sys
import subprocess
import logging
from extractor import run_extraction
from loader import run_load, get_client
from config import PROJECTS
from pipeline_cli import select_projects
from auth import ZohoAuth
from borrados import propagar_borrados

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

    # 3. Borrados: solo proyectos con propagar_borrados=True en config.
    # Un fallo acá NO bloquea dbt (los datos cargados son válidos y el tablero
    # no debe quedar desactualizado), pero la corrida termina en error.
    errores_borrado = []
    con_borrados = [p for p in proyectos if PROJECTS[p].get("propagar_borrados")]
    if con_borrados:
        logger.info("=== BORRADOS ===")
        client = get_client()
        for p in con_borrados:
            cfg = PROJECTS[p]
            try:
                propagar_borrados(client, ZohoAuth(env_prefix=cfg["env_prefix"]), p,
                                  cfg["dataset_id"], list(cfg["modules"]))
            except Exception as e:
                logger.error(f"Borrados de {p} incompletos: {e}")
                errores_borrado.append(p)

    # 4. dbt
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

    if errores_borrado:
        logger.error(f"=== PIPELINE CON ERRORES: borrados incompletos en {errores_borrado} ===")
        sys.exit(1)

    logger.info("=== PIPELINE COMPLETO ===")

if __name__ == "__main__":
    main()
