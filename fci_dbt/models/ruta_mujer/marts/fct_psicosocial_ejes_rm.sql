-- Grano: un eje de un diagnostico psicosocial de Corte 2 (diagnostico_id + eje).
-- Solo diagnosticos diligenciados (los demas no tienen puntajes).
-- Alimenta el grafico "Resultados por ejes": eje en el eje X y
-- % de mujeres con alerta = mujeres en alerta / mujeres diagnosticadas.
--
-- Umbral: var umbral_eje_psicosocial en dbt_project.yml (hoy > 0).

with diagnosticos as (
    select * from {{ ref('fct_psicosocial_rm') }}
    where diagnostico_diligenciado
)
select
    concat(d.id, '-', e.eje_orden) as eje_diagnostico_id,
    d.id as diagnostico_id,
    d.documento,
    d.corte,
    d.profesional_que_remite,
    d.nivel_riesgo,
    e.eje_orden,
    e.eje,
    e.eje_pct,
    e.eje_puntaje,
    e.eje_puntaje_maximo,
    coalesce(e.eje_pct > {{ var('umbral_eje_psicosocial') }}, false) as en_alerta,
    case when coalesce(e.eje_pct > {{ var('umbral_eje_psicosocial') }}, false) then 'Sí' else 'No' end as tiene_alerta
from diagnosticos d,
unnest([
    struct(1 as eje_orden, 'Violencias' as eje, d.eje_1_violencias_pct as eje_pct,
           d.puntaje_eje_1_violencias as eje_puntaje, 30 as eje_puntaje_maximo),
    struct(2, 'Redes de apoyo', d.eje_2_redes_de_apoyo_pct, d.puntaje_eje_2_redes_de_apoyo, 20),
    struct(3, 'Bienestar emocional', d.eje_3_bienestar_emocional_pct, d.puntaje_eje_3_bienestar_emocional, 20),
    struct(4, 'Autonomía económica', d.eje_4_autonomia_pct, d.puntaje_eje_4_autonomia, 15),
    struct(5, 'Barreras', d.eje_5_barreras_pct, d.puntaje_eje_5_barreras, 15)
]) e
