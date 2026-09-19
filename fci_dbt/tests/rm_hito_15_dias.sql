-- depends_on: {{ ref('fct_postvinculacion_rm') }}
{{ config(severity='warn') }}
with casos as (
    select 14 as dias, cast(null as date) as llamada, false as esperado union all
    select 15, null, true union all select 20, null, true union all
    select 15, date '2026-09-01', false union all select cast(null as int64), null, false union all
    select -1, null, false
)
select * from casos
where {{ rm_post_vencida('dias','llamada') }} != esperado
