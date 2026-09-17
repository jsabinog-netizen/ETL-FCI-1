-- Grano: una empresa deduplicada por NIT.
-- Mart dimensional de empresas para Ruta Mujer.

with empresas as (
    select *
    from {{ ref('stg_pre_registro_empresarial') }}
    where nit is not null
    qualify row_number() over (
        partition by nit
        order by modified_time desc nulls last, created_time desc nulls last, id desc
    ) = 1
),
vacantes as (
    select
        nit_empresa as nit,
        count(*) as num_vacantes
    from {{ ref('dim_vacantes_rm') }}
    where nit_empresa is not null
    group by nit_empresa
),
intermediacion as (
    select
        nit_de_la_empresa as nit,
        count(*) as num_intermediaciones
    from {{ ref('fct_intermediacion_rm') }}
    where nit_de_la_empresa is not null
    group by nit_de_la_empresa
),
agendamiento as (
    select
        coalesce(empresa_lookup, '') as nit_lookup,
        empresa_id,
        count(*) as num_agendamientos
    from {{ ref('fct_agenda_comercial_rm') }}
    group by 1, 2
),
agenda_por_empresa as (
    select
        e.nit,
        sum(a.num_agendamientos) as num_agendamientos
    from agendamiento a
    join empresas e on a.nit_lookup = e.nit or a.empresa_id = e.id
    group by e.nit
),
base as (
    select
        e.* replace (
            date(e.created_time) as created_time,
            date(e._loaded_at) as _loaded_at,
            date(e.modified_time) as modified_time,
            date(e.last_activity_time) as last_activity_time
        ),
        coalesce(v.num_vacantes > 0, false) as tiene_vacantes,
        coalesce(i.num_intermediaciones > 0, false) as fue_intermediada,
        coalesce(a.num_agendamientos > 0, false) as fue_agendada,
        coalesce(v.num_vacantes, 0) as num_vacantes,
        coalesce(i.num_intermediaciones, 0) as num_intermediaciones,
        coalesce(a.num_agendamientos, 0) as num_agendamientos
    from empresas e
    left join vacantes v on e.nit = v.nit
    left join intermediacion i on e.nit = i.nit
    left join agenda_por_empresa a on e.nit = a.nit
)
select
    *,
    case
        when fue_intermediada then '4. Intermediada'
        when tiene_vacantes   then '3. Con vacantes'
        when fue_agendada     then '2. Agendada'
        else '1. Solo registrada'
    end as etapa_empresa
from base
