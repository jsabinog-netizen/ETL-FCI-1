"""Verificaciones de tanda 2: consultas agregadas y fixtures SQL sin escrituras.

Ejecutar después del build. Guarda resultados sin datos personales en output/.
Los conteos históricos se reportan como referencia, no como restricciones.
"""
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from loader import get_client

DATASET = 'zoho-bq-pipeline-492116.proyecto_ruta_mujer'
ROOT = Path(__file__).resolve().parents[1]


def probar_reglas(client):
    """Ejercita el SQL de producción: seis slots y completada histórica."""
    mart = (ROOT / 'fci_dbt/models/ruta_mujer/marts/fct_formacion_rm.sql').read_text(encoding='utf-8')
    # Un registro con seis cursos y otro sin cursos: no generar filas vacías.
    fields = ["id", "documento", "corte", "primer_nombre", "segundo_nombre",
              "primer_apellido", "segundo_apellido", "n_mero_de_celular", "municipio",
              "localidad", "profesional_de_orientaci_n", "formaci_n_completada"]
    columns = ["cast(n as string) as id"] + [f"'sí' as {f}" for f in fields if f != 'id']
    for slot, course, suffix in [
        (1, 'fortalecimiento_de_habilidades_t_cnica', ''),
        (2, 'fortalecimiento_de_habilidades_t_cnicas_2', '_2'),
        (3, 'fortalecimiento_de_habilidades_t_cnicas_3', '_3'),
        (4, 'fortalecimiento_de_habilidades_t_cnicas_4', '_4'),
        (5, 'fortalecimiento_de_habilidades_blandas', '_blandas'),
        (6, 'fortalecimiento_de_habilidades_blandas_2', '_blandas_2'),
    ]:
        columns += [f"if(n=1, 'Curso {slot}', null) as {course}",
                    f"date '2026-05-{20+slot}' as fecha_curso{suffix}",
                    f"'virtual' as modalidad{suffix}", f"'mañana' as jornada{suffix}"]
    columns += [f"date '2026-01-01' as {f}" for f in ['fecha_formaci_n', 'created_time', 'modified_time', '_loaded_at']]
    fixture = '(select ' + ', '.join(columns) + ' from unnest([1,2]) n)'
    rows = list(client.query(mart.replace("{{ ref('stg_formaci_n_colsubsidios') }}", fixture)).result())
    assert len(rows) == 6 and {r['id_curso'] for r in rows} == {f'1:{s}' for s in range(1,7)}
    for r in rows:
        assert r['curso'] == f"Curso {r['slot']}"
        assert r['tipo_curso'] == ('técnica' if r['slot'] <= 4 else 'blandas')
        assert r['fecha_curso'].day == 20 + r['slot']
        assert r['estado_formacion'] == 'Completada'

    mart = (ROOT / 'fci_dbt/models/ruta_mujer/marts/fct_ruta_mujer.sql').read_text(encoding='utf-8')
    agg = re.search(r'formacion_agg as \((.*?)\n\), postvinculacion', mart, re.S).group(1)
    fixture = """(select * from unnest([
        struct('a' as documento, 'sí' as formaci_n_completada, date '2026-01-01' as fecha),
        ('a', 'no', date '2026-02-01'), ('b', null, date '2026-01-01'),
        (null, 'sí', date '2026-01-01')]))"""
    agg = agg.replace("{{ ref('stg_formaci_n_colsubsidios') }}", fixture)
    state = re.search(r"case\s+when num_registros_formacion = 0.*?end as estado_formacion_mujer", mart, re.S).group()
    via = re.search(r"case when preregistro_id is not null.*?end as via_de_ingreso", mart, re.S).group()
    formed = re.search(r'coalesce\(fa.alguna_completada, false\) as formada', mart).group()
    sql = f"""with formacion_agg as ({agg}), base as (
        select documento, coalesce(fa.num_registros_formacion,0) num_registros_formacion,
        coalesce(fa.alguna_completada,false) alguna_formacion_completada, {formed},
        if(documento='a','pr1',null) preregistro_id
        from unnest(['a','b','c']) documento left join formacion_agg fa using(documento)
    ) select *, {state}, {via} from base"""
    rows = {r['documento']: dict(r) for r in client.query(sql).result()}
    assert rows['a']['estado_formacion_mujer'] == 'Completada' and rows['a']['formada']
    assert rows['a']['num_registros_formacion'] == 2
    assert rows['b']['estado_formacion_mujer'] == 'Pendiente' and not rows['b']['formada']
    assert rows['c']['estado_formacion_mujer'] == 'Sin iniciar' and not rows['c']['formada']
    assert rows['a']['via_de_ingreso'] == 'Con preregistro'
    assert rows['c']['via_de_ingreso'] == 'Registro directo'


def main():
    client = get_client()
    probar_reglas(client)
    queries = {
        '1_grano_mujer': "select count(*) filas, count(distinct documento) documentos from `{d}.fct_ruta_mujer`",
        '2_columnas_nuevas': """select column_name from `{d}.INFORMATION_SCHEMA.COLUMNS`
            where table_name='fct_ruta_mujer' and column_name in
            ('estado_formacion_mujer','num_registros_formacion','via_de_ingreso',
             'tuvo_preregistro','alguna_formacion_completada') order by 1""",
        '3_grano_curso': "select count(*) filas, count(distinct id_curso) ids, count(distinct documento) personas from `{d}.fct_formacion_rm`",
        '4_estados_formacion': "select estado_formacion_mujer, count(*) mujeres from `{d}.fct_ruta_mujer` group by 1 order by 1",
        '5_via_ingreso': "select via_de_ingreso, count(*) mujeres from `{d}.fct_ruta_mujer` group by 1 order by 1",
        '6_etapas': "select etapa_actual, count(*) mujeres from `{d}.fct_ruta_mujer` group by 1 order by 1",
        '7_fechas': "select column_name,data_type from `{d}.INFORMATION_SCHEMA.COLUMNS` where table_name='fct_ruta_mujer' and column_name like 'fecha%' order by 1",
        'slots': "select slot,tipo_curso,count(*) n from `{d}.fct_formacion_rm` group by 1,2 order by 1",
        'cursos': "select curso,count(*) inscripciones,count(distinct documento) personas from `{d}.fct_formacion_rm` group by 1 order by 2 desc",
        'columnas_raw_formacion': """select column_name from `{d}.INFORMATION_SCHEMA.COLUMNS`
            where table_name='formaci_n_colsubsidios' and
            (column_name like 'Fecha_curso%' or column_name like 'Fortalecimiento%'
             or column_name like 'Modalidad%' or column_name like 'Jornada%') order by 1""",
        'observaciones': """select 'comercial' agenda,count(*) filas,countif(observaciones_agendamiento is not null) con_observaciones
            from `{d}.fct_agenda_comercial_rm` union all
            select 'orientacion',count(*),countif(observaciones_agendamiento is not null) from `{d}.fct_agenda_orientacion_rm`""",
    }
    report = {name: [dict(r) for r in client.query(sql.format(d=DATASET)).result()]
              for name, sql in queries.items()}
    report['reglas_sinteticas'] = 'PASS: seis slots, ausencia de cursos, completada histórica, tres estados y vía de ingreso'
    report['delta_vs_516'] = report['3_grano_curso'][0]['filas'] - 516
    before = ROOT / 'output/tanda2_antes.json'
    if before.exists():
        report['antes'] = json.loads(before.read_text(encoding='utf-8'))
        report['delta_vs_antes'] = report['3_grano_curso'][0]['filas'] - report['antes']['formacion'][0]['filas']
    result = json.dumps(report, ensure_ascii=False, indent=2)
    (ROOT / 'output/tanda2_resultados.json').write_text(result, encoding='utf-8')
    print(result)
    grain = report['1_grano_mujer'][0]
    assert grain['filas'] == grain['documentos'], 'CRÍTICO: join multiplica mujeres'
    assert len(report['2_columnas_nuevas']) == 5
    grain_c = report['3_grano_curso'][0]
    assert grain_c['filas'] == grain_c['ids'], 'id_curso duplicado o nulo'
    assert all(r['data_type'] == 'DATE' for r in report['7_fechas'])
    for name in ['4_estados_formacion', '5_via_ingreso', '6_etapas']:
        assert sum(r['mujeres'] for r in report[name]) == grain['filas']
    assert len(report['columnas_raw_formacion']) == 24


if __name__ == '__main__':
    main()
