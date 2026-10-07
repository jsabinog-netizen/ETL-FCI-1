-- Grano: una empresa deduplicada por NIT.
-- Mart dimensional de empresas para Ruta Mujer.
-- Incluye matriz ejecutiva: vacantes aportadas/activas/cerradas,
-- mujeres remitidas/contratadas, y motivo de cierre inferido.

with empresas as (
    select *
    from {{ ref('stg_pre_registro_empresarial') }}
    where nit is not null
    qualify row_number() over (
        partition by nit
        order by modified_time desc nulls last, created_time desc nulls last, id desc
    ) = 1
),
-- ── Vacantes: métricas por NIT ──
vacantes_detalle as (
    select
        nit_empresa as nit,
        count(*) as vacantes_aportadas,
        coalesce(sum(n_mero_de_puestos_de_trabajo), 0) as puestos_de_trabajo_aportados,
        countif(estado_de_la_vacante = 'activa') as vacantes_activas,
        countif(estado_de_la_vacante = 'cerrada') as vacantes_cerradas
    from {{ ref('dim_vacantes_rm') }}
    where nit_empresa is not null
    group by nit_empresa
),
-- ── Intermediación: contratadas por vacante para inferir motivo de cierre ──
-- Una vacante cerrada con al menos 1 "contratado" ⟹ cerrada por intermediación.
-- Una vacante cerrada sin contratados ⟹ cerrada por gestión directa o cancelada.
contratadas_por_vacante as (
    select
        v.nit_empresa as nit,
        v.id as vacante_id,
        v.estado_de_la_vacante,
        countif(i.etapa_embudo = '6. Contratada' or i.estado = 'contratado' or lower(i.estado) like '%contratad%') as num_contratadas_vacante
    from {{ ref('dim_vacantes_rm') }} v
    left join {{ ref('fct_intermediacion_rm') }} i
        on v.id = i.buscar_vacante_id
    where v.nit_empresa is not null
    group by v.nit_empresa, v.id, v.estado_de_la_vacante
),
cierre_por_nit as (
    select
        nit,
        countif(estado_de_la_vacante = 'cerrada' and num_contratadas_vacante > 0) as vacantes_cerradas_intermediacion,
        countif(estado_de_la_vacante = 'cerrada' and num_contratadas_vacante = 0) as vacantes_cerradas_gestion_directa
    from contratadas_por_vacante
    group by nit
),
-- ── Participantes por empresa (todas las intermediaciones, no solo las cerradas) ──
participantes as (
    select
        nit_de_la_empresa as nit,
        count(distinct documento) as mujeres_remitidas,
        count(distinct case when etapa_embudo = '6. Contratada' or estado = 'contratado' or lower(estado) like '%contratad%' then documento end) as mujeres_contratadas
    from {{ ref('fct_intermediacion_rm') }}
    where nit_de_la_empresa is not null
    group by nit_de_la_empresa
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
        -- ── Indicadores booleanos ──
        coalesce(v.vacantes_aportadas > 0, false) as tiene_vacantes,
        coalesce(i.num_intermediaciones > 0, false) as fue_intermediada,
        coalesce(a.num_agendamientos > 0, false) as fue_agendada,

        -- ── Métricas de volumen ──
        coalesce(v.vacantes_aportadas, 0) as vacantes_aportadas,
        coalesce(v.puestos_de_trabajo_aportados, 0) as puestos_de_trabajo_aportados,
        coalesce(v.vacantes_activas, 0) as vacantes_activas,
        coalesce(v.vacantes_cerradas, 0) as vacantes_cerradas,
        coalesce(c.vacantes_cerradas_intermediacion, 0) as vacantes_cerradas_intermediacion,
        coalesce(c.vacantes_cerradas_gestion_directa, 0) as vacantes_cerradas_gestion_directa,
        coalesce(p.mujeres_remitidas, 0) as mujeres_remitidas,
        coalesce(p.mujeres_contratadas, 0) as mujeres_contratadas,
        coalesce(i.num_intermediaciones, 0) as num_intermediaciones,
        coalesce(a.num_agendamientos, 0) as num_agendamientos,

        -- ── Ratios de efectividad ──
        coalesce(round(safe_divide(c.vacantes_cerradas_intermediacion, nullif(v.vacantes_cerradas, 0)), 4), 0) as pct_vacantes_cerradas_intermediacion,
        coalesce(round(safe_divide(p.mujeres_contratadas, nullif(p.mujeres_remitidas, 0)), 4), 0) as tasa_colocacion_mujeres,

        -- Compatibilidad: num_vacantes sigue existiendo para no romper reportes previos
        coalesce(v.vacantes_aportadas, 0) as num_vacantes
    from empresas e
    left join vacantes_detalle v on e.nit = v.nit
    left join cierre_por_nit c on e.nit = c.nit
    left join participantes p on e.nit = p.nit
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
