"""Auditoría incremental por módulo, separada de reconciliación.

Actions define PIPELINE_STARTED_AT antes de main.py para exigir auditoría de
esa ejecución. Sin esa variable se toma el último estado de cada módulo en
las dos horas anteriores a la última actividad del proyecto (máximo 24h).
Sin un id de corrida, el historial no permite atribución exacta; en Actions
la ventana explícita evita reutilizar éxitos de ejecuciones anteriores.
"""
import logging
import os
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from google.cloud import bigquery
from config import PROJECTS, PROJECT_ID
from loader import get_client

logger = logging.getLogger(__name__)
MAX_HORAS = 24


def verificar(client, proyecto, desde=None, ahora=None):
    ahora = ahora or datetime.now(timezone.utc)
    dataset = PROJECTS[proyecto]["dataset_id"]
    esperados = set(PROJECTS[proyecto]["modules"])
    if not esperados:
        raise RuntimeError(f"{proyecto}: no hay módulos configurados")
    parametros = [bigquery.ScalarQueryParameter("proyecto", "STRING", proyecto),
                  bigquery.ArrayQueryParameter("modulos", "STRING", sorted(esperados))]
    q_ultima = f"""
        select max(run_at) as ultima_corrida
        from `{PROJECT_ID}.{dataset}.pipeline_metadata`
        where project_name = @proyecto
          and module_name in unnest(@modulos)
          and status in ('success', 'empty', 'error')
    """
    row = next(iter(client.query(q_ultima, job_config=bigquery.QueryJobConfig(
        query_parameters=parametros)).result()), None)
    ultima = row["ultima_corrida"] if row else None
    if ultima is None:
        raise RuntimeError(f"{proyecto}: sin auditoría incremental registrada")
    horas = (ahora - ultima).total_seconds() / 3600
    if horas < 0 or horas > MAX_HORAS:
        raise RuntimeError(f"{proyecto}: última actividad fuera de tolerancia ({horas:.1f}h)")
    if desde is not None and (desde.tzinfo is None or desde > ahora):
        raise ValueError("PIPELINE_STARTED_AT debe tener zona horaria y no estar en el futuro")
    inicio = desde if desde is not None else ultima - timedelta(hours=2)
    q_estado = f"""
        select module_name, status, run_at
        from `{PROJECT_ID}.{dataset}.pipeline_metadata`
        where project_name = @proyecto
          and module_name in unnest(@modulos)
          and status in ('success', 'empty', 'error')
          and run_at >= @inicio and run_at <= @ultima
        qualify row_number() over (
            partition by module_name order by run_at desc, (status = 'error') desc
        ) = 1
    """
    cfg = bigquery.QueryJobConfig(query_parameters=parametros + [
        bigquery.ScalarQueryParameter("inicio", "TIMESTAMP", inicio),
        bigquery.ScalarQueryParameter("ultima", "TIMESTAMP", ultima)])
    estados = {r["module_name"]: r["status"] for r in client.query(q_estado, job_config=cfg).result()}
    faltantes = sorted(esperados - estados.keys())
    fallidos = sorted(m for m, status in estados.items() if status not in ('success', 'empty'))
    if faltantes or fallidos:
        raise RuntimeError(f"{proyecto}: módulos sin auditoría reciente={faltantes}; fallidos={fallidos}")
    logger.info(f"{proyecto}: frescura OK; {len(estados)}/{len(esperados)} módulos; última actividad {ultima}")


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in PROJECTS:
        logger.error(f"Uso: python scripts/verificar_frescura.py <proyecto>; opciones: {list(PROJECTS)}")
        return 1
    try:
        valor = os.environ.get('PIPELINE_STARTED_AT')
        desde = datetime.fromisoformat(valor.replace('Z', '+00:00')) if valor else None
        verificar(get_client(), sys.argv[1], desde=desde)
    except Exception as exc:
        logger.error(f"Verificación de frescura fallida: {exc}")
        return 1
    return 0


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
    sys.exit(main())
