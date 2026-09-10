"""Verificaciones de cierre de Ruta Mujer; solo consultas agregadas y de esquema."""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from loader import get_client

DATASET = "zoho-bq-pipeline-492116.proyecto_ruta_mujer"


def main():
    client = get_client()
    queries = {
        "raw_con_corte": f"""select table_name from `{DATASET}.INFORMATION_SCHEMA.COLUMNS`
            where column_name = 'Corte' and not starts_with(table_name, '_stg_')
            order by table_name""",
        "cortes": f"select corte, count(*) n from `{DATASET}.fct_ruta_mujer` group by 1 order by 2 desc",
        "etapas": f"select etapa_actual, count(*) n from `{DATASET}.fct_ruta_mujer` group by 1 order by 1",
        "nuevas_etapas": f"""select countif(formada) formadas,
            countif(postvinculada) postvinculadas,
            countif(formacion_id is not null) con_registro_formacion,
            countif(postvinculacion_id is not null) con_registro_postvinculacion
            from `{DATASET}.fct_ruta_mujer`""",
        "inventario": f"""select table_id as table_name, row_count from `{DATASET}.__TABLES__`
            where starts_with(table_id, 'fct_') or starts_with(table_id, 'dim_') order by 1""",
        "columnas_persona": f"""select column_name from `{DATASET}.INFORMATION_SCHEMA.COLUMNS`
            where table_name = 'fct_ruta_mujer' and column_name in (
                'corte', 'rango_etario', 'concepto_intermediacion', 'nivel_educativo_normalizado',
                'ocupacion_actual', 'evoluci_n', 'tiene_inscripcion', 'tiene_orientacion',
                'tiene_psicosocial', 'tiene_intermediacion', 'tiene_colocacion',
                'formada', 'postvinculada', 'tiene_formacion', 'tiene_postvinculacion',
                'fecha_formacion', 'fecha_postvinculacion', 'formacion_id', 'postvinculacion_id') order by 1""",
        "grano": f"""select count(*) filas, count(distinct documento) documentos_unicos
            from `{DATASET}.fct_ruta_mujer`""",
        "postvinculacion": f"""select count(*) filas, countif(alerta_vencida) alertas_vencidas,
            countif(estado_post_calculado != estado_post_zoho) discrepancias_zoho_vs_calculado,
            countif(empresa is not null) empresas_conservadas
            from `{DATASET}.fct_postvinculacion_rm`""",
        "mitigacion_esquema": f"""select column_name, data_type from `{DATASET}.INFORMATION_SCHEMA.COLUMNS`
            where table_name = 'fct_mitigacion_rm' order by ordinal_position""",
        "mitigacion_filas": f"select count(*) filas from `{DATASET}.fct_mitigacion_rm`",
        "marts_con_timestamp": f"""select table_name, column_name from `{DATASET}.INFORMATION_SCHEMA.COLUMNS`
            where (starts_with(table_name, 'fct_') or starts_with(table_name, 'dim_'))
            and data_type = 'TIMESTAMP' order by 1, 2""",
    }
    report = {name: [dict(row) for row in client.query(sql).result()]
              for name, sql in queries.items()}
    print(json.dumps(report, ensure_ascii=False, indent=2))
    assert len(report["raw_con_corte"]) == 14
    assert len(report["columnas_persona"]) == 19
    grain = report["grano"][0]
    assert grain["filas"] == grain["documentos_unicos"], "CRITICO: se multiplicaron mujeres"
    schema = {r["column_name"]: r["data_type"] for r in report["mitigacion_esquema"]}
    assert schema["valor_mitigacion"] == "NUMERIC"
    for field in ["fecha_registro", "fecha_pago", "created_time", "modified_time", "_loaded_at"]:
        assert schema[field] == "DATE", field
    assert not report["marts_con_timestamp"], "TIMESTAMP expuesto a Power BI"


if __name__ == "__main__":
    main()
