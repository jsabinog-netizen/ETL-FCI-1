"""Validar reglas SQL reales con fixtures en BigQuery, sin crear tablas."""
from pathlib import Path
import re
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from loader import get_client
c=get_client(); root=Path('fci_dbt/models/ruta_mujer/marts')
# Exercise the actual age CASE at every boundary and NULL.
s=(root/'fct_ruta_mujer.sql').read_text(encoding='utf-8')
case=re.search(r'case\s+when edad is null.*?end as rango_etario',s,re.S).group()
rows=list(c.query('select edad, '+case+' from unnest([null,17,18,25,26,35,36,45,46,55,56]) edad').result())
expected={None:'7.',17:'1.',18:'2.',25:'2.',26:'3.',35:'3.',36:'4.',45:'4.',46:'5.',55:'5.',56:'6.'}
assert all(r['rango_etario'].startswith(expected[r['edad']]) for r in rows)
print('Rango etario: 11 fronteras correctas')
# Use the complete post mart with synthetic inputs, without creating tables.
s=(root/'fct_postvinculacion_rm.sql').read_text(encoding='utf-8')
fixture='''(select *, timestamp '2026-01-01' created_time, timestamp '2026-01-01' modified_time,
 timestamp '2026-01-01' _loaded_at, date_sub(current_date('America/Bogota'), interval dias day) fecha_inicio_contrato,
 if(llamada, current_date('America/Bogota'), cast(null as date)) fecha_llamada_seguimiento
 from unnest([struct(19 as dias, false as llamada), (20,false),(24,false),(25,false),(30,true),(cast(null as int64),false)]))'''
s=s.replace("{{ ref('stg_postvinculaci_n_colsub') }}",fixture)
rows=list(c.query(s).result())
for r in rows:
    d=r['dias']; called=r['llamada']
    assert r['alerta_vencida']==(d is not None and d>=20 and not called)
    assert r['alerta_escalada']==(d is not None and d>=25 and not called)
    assert r['dias_desviacion_hito']==(d-20 if called else None)
    assert r['estado_post_calculado']==(None if d is None else 'Post realizada' if called else 'Pendiente por post' if d>=20 else 'En plazo')
print('Postvinculacion: 6 escenarios correctos')
# Mitigation NULL flags, priority of placement, other-barrier consolidation and payment delay.
s=(root/'fct_mitigacion_rm.sql').read_text(encoding='utf-8')
fixture='''(select *, timestamp '2026-01-01' created_time, timestamp '2026-01-01' modified_time,
 timestamp '2026-01-01' _loaded_at, date '2026-01-01' fecha_registro,
 'otro' tipo_barrera, 'Transporte' otro_tipo_barrera, 'otro' servicio_recibido, 'Apoyo' otro_servicio
 from unnest([struct('si' as mitigacion_completada_txt, 'true' as es_micromitigacion_txt,
 'si' as dispersion_colocacion, 'si' as dispersion_formacion, cast(null as date) as fecha_pago),
 (null,null,null,null,date '2026-01-05')]))'''
s=s.replace("{{ ref('stg_mitigaci_n_colsubsidios') }}",fixture)
rows=list(c.query(s).result())
for r in rows:
    completed=r['mitigacion_completada_txt']=='si'
    assert r['mitigacion_completada']==completed and r['es_micromitigacion']==completed
    assert r['pago_pendiente']==completed
    assert r['barrera_consolidada']=='Transporte' and r['servicio_consolidado']=='Apoyo'
    assert r['etapa_mitigacion']==('Colocaci\u00f3n' if completed else 'Sin clasificar')
    assert r['dias_registro_a_pago']==(None if completed else 4)
print('Mitigacion: 2 escenarios correctos')

# Verify actual stage CASE for every combination of the seven completion flags.
s=(root/'fct_ruta_mujer.sql').read_text(encoding='utf-8')
case=re.search(r"case when postvinculada.*?end as etapa_actual",s,re.S).group()
flags=['inscrita','orientada','psicosocial','formada','intermediada','colocada','postvinculada']
columns=', '.join(f'(mask & {1 << i}) != 0 as {name}' for i,name in enumerate(flags))
rows=list(c.query('select mask, '+case+' from (select mask, '+columns+
                  ' from unnest(generate_array(0,127)) mask)').result())
for r in rows:
    assert int(r['etapa_actual'].split('.')[0]) == r['mask'].bit_length()
print('Etapas: 128 combinaciones correctas, incluidas Formacion y Postvinculacion')
