-- Una fila por colocación, incluyendo aquellas sin seguimiento.
-- No atribuir a un contrato el seguimiento de otro contrato de la misma mujer.
with colocaciones as (
    select *, count(*) over (partition by documento, fecha_de_vinculaci_n_laboral) as colocaciones_misma_fecha
    from {{ ref('stg_colocaci_n_colsubsidios') }}
), seguimiento as (
    select documento, fecha_inicio_contrato, count(*) as num_seguimientos,
        min(fecha_llamada_seguimiento) as primera_llamada
    from {{ ref('fct_postvinculacion_rm') }}
    group by documento, fecha_inicio_contrato
), persona as (
    select documento, count(*) as seguimientos_persona
    from {{ ref('fct_postvinculacion_rm') }} group by documento
), base as (
    select c.id as colocacion_id, c.documento, c.nombre_de_empresa_contratante_empleador as empresa,
        c.nit_de_empresa_contratante_empleador as nit_empresa,
        c.sector_econ_mico_empresa_contratante_empleador as sector,
        c.fecha_de_vinculaci_n_laboral as fecha_inicio_contrato, c.corte,
        case when c.fecha_de_vinculaci_n_laboral >= '2026-09-01' then 'corte 2'
             when c.fecha_de_vinculaci_n_laboral is not null then 'corte 1' end as corte_evento,
        c.colocaciones_misma_fecha > 1 as cruce_ambiguo,
        coalesce(s.num_seguimientos,0) as num_seguimientos,
        coalesce(p.seguimientos_persona,0) as seguimientos_persona,
        s.primera_llamada,
        date_diff(current_date('America/Bogota'), c.fecha_de_vinculaci_n_laboral, day) as dias_transcurridos_contrato
    from colocaciones c
    left join seguimiento s on c.documento=s.documento
        and c.fecha_de_vinculaci_n_laboral=s.fecha_inicio_contrato and c.colocaciones_misma_fecha=1
    left join persona p on c.documento=p.documento
)
select *,
    case when fecha_inicio_contrato is null then 'Sin fecha de contrato'
         when cruce_ambiguo then 'Revisar cruce de contrato'
         when num_seguimientos=0 and seguimientos_persona>0 then 'Seguimiento sin correspondencia de contrato'
         when num_seguimientos=0 then 'Sin registro de postvinculación'
         when primera_llamada is null then 'Con registro sin llamada'
         else 'Con llamada' end as estado_cobertura,
    coalesce(dias_transcurridos_contrato >= 15, false) as seguimiento_exigible,
    {{ rm_post_vencida('dias_transcurridos_contrato','primera_llamada') }} as requiere_revision_15_dias
from base
