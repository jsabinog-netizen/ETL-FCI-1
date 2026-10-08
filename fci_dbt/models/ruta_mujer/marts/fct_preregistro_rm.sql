-- Grano: un preregistro por id de Zoho.
-- Alimenta la página PREREGISTRO del dashboard y permite priorizar
-- a las participantes según las fases del programa que tienen pendientes.

with inscripcion as (
    select documento,
        max(fecha_de_registro) as fecha_inscripcion,
        max(coalesce(inscripci_n_completada in ('si', 'sí', 'true'), false)) as inscripcion_completada
    from {{ ref('stg_inscripci_n_colsubsidios') }}
    where documento is not null
    group by documento
),
orientacion as (
    select documento,
        max(fecha_de_orientaci_n) as fecha_orientacion,
        max(coalesce(orientaci_n_sociocupacion_completada in ('si', 'sí', 'true'), false)) as orientacion_completada
    from {{ ref('stg_orientaci_n_colsubsidios') }}
    where documento is not null
    group by documento
),
psicosocial as (
    select documento,
        max(coalesce(fecha_inicio_acompanamiento_sc_1, date(created_time))) as fecha_psicosocial,
        max(coalesce(acompa_amiento_psicosocial_completado in ('si', 'sí', 'true'), false)) as psicosocial_completada
    from {{ ref('stg_psicosocial_rutam') }}
    where documento is not null
    group by documento
),
formacion as (
    select documento,
        count(*) as num_registros_formacion,
        max(coalesce(fecha_formaci_n, fecha_curso)) as fecha_formacion,
        max(coalesce(formaci_n_completada in ('si', 'sí', 'true'), false)) as formacion_completada
    from {{ ref('stg_formaci_n_colsubsidios') }}
    where documento is not null
    group by documento
),
intermediacion as (
    select documento,
        count(*) as num_intermediaciones,
        max(fecha_intermediaci_n) as fecha_intermediacion,
        max(coalesce(intermediaci_n_completada in ('si', 'sí', 'true'), false)) as intermediacion_completada
    from {{ ref('stg_intermediaci_n_ruta_m') }}
    where documento is not null
    group by documento
),
colocacion as (
    select documento,
        max(fecha_de_vinculaci_n_laboral) as fecha_colocacion
    from {{ ref('stg_colocaci_n_colsubsidios') }}
    where documento is not null
    group by documento
),
postvinculacion as (
    select documento,
        max(coalesce(fecha_inicio_contrato, fecha_llamada_seguimiento)) as fecha_postvinculacion
    from {{ ref('stg_postvinculaci_n_colsub') }}
    where documento is not null
    group by documento
),
base as (
    select
        p.* replace (
            date(p.created_time) as created_time,
            date(p._loaded_at) as _loaded_at,
            date(p.modified_time) as modified_time,
            coalesce(nullif(trim(p.tipo_de_poblaci_n), ''), 'Pendiente de tipificación en inscripción') as tipo_de_poblaci_n
        ),
        -- ── Indicadores por fase de la ruta (booleanos internos) ──
        ins.documento is not null as se_inscribio,
        ins.documento is not null as tiene_inscripcion_bool,
        coalesce(ins.inscripcion_completada, false) as inscripcion_completada_bool,

        ori.documento is not null as tiene_orientacion_bool,
        coalesce(ori.orientacion_completada, false) as orientacion_completada_bool,

        psi.documento is not null as tiene_psicosocial_bool,
        coalesce(psi.psicosocial_completada, false) as psicosocial_completada_bool,

        coalesce(frm.num_registros_formacion, 0) > 0 as tiene_formacion_bool,
        coalesce(frm.formacion_completada, false) as formacion_completada_bool,

        coalesce(itm.num_intermediaciones, 0) > 0 as tiene_intermediacion_bool,
        coalesce(itm.intermediacion_completada, false) as intermediacion_completada_bool,

        col.fecha_colocacion is not null as tiene_colocacion_bool,
        col.fecha_colocacion is not null as colocada_bool,

        post.documento is not null as tiene_postvinculacion_bool,
        post.documento is not null as postvinculada_bool,

        -- ── Fechas de cada fase ──
        ins.fecha_inscripcion,
        ori.fecha_orientacion,
        psi.fecha_psicosocial,
        frm.fecha_formacion,
        itm.fecha_intermediacion,
        col.fecha_colocacion,
        post.fecha_postvinculacion

    from {{ ref('stg_pre_registro_rutam') }} p
    left join inscripcion ins on p.documento = ins.documento
    left join orientacion ori on p.documento = ori.documento
    left join psicosocial psi on p.documento = psi.documento
    left join formacion frm on p.documento = frm.documento
    left join intermediacion itm on p.documento = itm.documento
    left join colocacion col on p.documento = col.documento
    left join postvinculacion post on p.documento = post.documento
)
select
    * except (
        tiene_inscripcion_bool, inscripcion_completada_bool,
        tiene_orientacion_bool, orientacion_completada_bool,
        tiene_psicosocial_bool, psicosocial_completada_bool,
        tiene_formacion_bool, formacion_completada_bool,
        tiene_intermediacion_bool, intermediacion_completada_bool,
        tiene_colocacion_bool, colocada_bool,
        tiene_postvinculacion_bool, postvinculada_bool
    ),
    -- ── Flags Sí/No en texto para segmentadores de Power BI ──
    case when tiene_inscripcion_bool then 'Sí' else 'No' end as tiene_inscripcion,
    case when inscripcion_completada_bool then 'Sí' else 'No' end as inscripcion_completada,
    case when tiene_orientacion_bool then 'Sí' else 'No' end as tiene_orientacion,
    case when orientacion_completada_bool then 'Sí' else 'No' end as orientacion_completada,
    case when tiene_psicosocial_bool then 'Sí' else 'No' end as tiene_psicosocial,
    case when psicosocial_completada_bool then 'Sí' else 'No' end as psicosocial_completada,
    case when tiene_formacion_bool then 'Sí' else 'No' end as tiene_formacion,
    case when formacion_completada_bool then 'Sí' else 'No' end as formacion_completada,
    case when tiene_intermediacion_bool then 'Sí' else 'No' end as tiene_intermediacion,
    case when intermediacion_completada_bool then 'Sí' else 'No' end as intermediacion_completada,
    case when tiene_colocacion_bool then 'Sí' else 'No' end as tiene_colocacion,
    case when colocada_bool then 'Sí' else 'No' end as colocada,
    case when tiene_postvinculacion_bool then 'Sí' else 'No' end as tiene_postvinculacion,
    case when postvinculada_bool then 'Sí' else 'No' end as postvinculada,

    -- Estado final del preregistro (replica la columna original del dashboard)
    case
        when se_inscribio then 'Inscritos'
        when lower(trim(coalesce(preinscripci_n_completad, ''))) like '%no aplica%'
            then 'No aplica'
        else 'Pendiente'
    end as estado_inscripcion_final,

    case
        when created_time >= '2026-09-01' then 'corte 2'
        else 'corte 1'
    end as corte_evento,

    -- ── Etapa máxima alcanzada en la ruta ──
    case
        when tiene_postvinculacion_bool then '6. Postvinculación'
        when tiene_colocacion_bool      then '5. Colocación'
        when tiene_intermediacion_bool  then '4. Intermediación'
        when tiene_psicosocial_bool     then '3. Atención Psicosocial'
        when tiene_orientacion_bool     then '2. Orientación'
        when tiene_inscripcion_bool     then '1. Inscripción'
        else                                 '0. Solo preregistro'
    end as etapa_actual,

    -- ── Próxima fase pendiente para priorización ──
    case
        when not tiene_inscripcion_bool then '1. Pendiente Inscripción'
        when not tiene_orientacion_bool then '2. Pendiente Orientación'
        when not tiene_intermediacion_bool and not tiene_colocacion_bool then '3. Pendiente Intermediación'
        when not tiene_colocacion_bool then '4. Pendiente Colocación'
        when not tiene_postvinculacion_bool then '5. Pendiente Postvinculación'
        else '6. Ruta completa'
    end as siguiente_fase_pendiente

from base