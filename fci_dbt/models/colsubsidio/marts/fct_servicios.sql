with servicios as (
select
    concat('diagnostico', '_', id) as servicio_id,
    nit,
    nombre_empresa,
    'diagnostico' as tipo_servicio,
    asesor_diagnostico as asesor,
    estado_diagnostico as estado,
    inicio,
    fin,
    date(inicio) as fecha_inicio,
    date(fin) as fecha_fin,
    tiene_informe,
    vinculo_empresa_directo,
    case when estado_diagnostico = 'ejecutado' then 1 else 0 end as es_ejecutado
from {{ ref('stg_diagnostico') }}

union all

select
    concat('asesoria_legal', '_', id) as servicio_id,
    nit,
    nombre_empresa,
    'asesoria_legal' as tipo_servicio,
    asesor_legal as asesor,
    estado_asesoria_legal as estado,
    inicio,
    fin,
    date(inicio) as fecha_inicio,
    date(fin) as fecha_fin,
    tiene_informe,
    vinculo_empresa_directo,
    case when estado_asesoria_legal = 'ejecutado' then 1 else 0 end as es_ejecutado
from {{ ref('stg_asesoria_legal') }}

union all

select
    concat('sensibilizacion', '_', id) as servicio_id,
    nit,
    nombre_empresa,
    'sensibilizacion' as tipo_servicio,
    asesor_sensibilizacion as asesor,
    estado_sensibilizacion as estado,
    inicio,
    fin,
    date(inicio) as fecha_inicio,
    date(fin) as fecha_fin,
    tiene_informe,
    vinculo_empresa_directo,
    case when estado_sensibilizacion = 'ejecutado' then 1 else 0 end as es_ejecutado
from {{ ref('stg_sensibilizacion') }}

union all

select
    concat('transferencia', '_', id) as servicio_id,
    nit,
    nombre_empresa,
    'transferencia' as tipo_servicio,
    asesor_transferencia as asesor,
    estado_transferencia as estado,
    inicio,
    fin,
    date(inicio) as fecha_inicio,
    date(fin) as fecha_fin,
    tiene_informe,
    vinculo_empresa_directo,
    case when estado_transferencia = 'ejecutado' then 1 else 0 end as es_ejecutado
from {{ ref('stg_transferencia') }}


union all
select
    concat('asesoria_vacantes', '_', id) as servicio_id,
    nit,
    nombre_empresa,
    'asesoria_vacantes' as tipo_servicio,
    asesor_vacante as asesor,
    estado_asesoria_vacante as estado,
    inicio,
    fin,
    date(inicio) as fecha_inicio,
    date(fin) as fecha_fin,
    tiene_informe,
    vinculo_empresa_directo,
    case when estado_asesoria_vacante = 'ejecutado' then 1 else 0 end as es_ejecutado
from {{ ref('stg_asesoria_vacantes') }}

)

select
    servicios.*,
    case when dim_empresa.nit is not null then true else false end as tiene_empresa,
    -- Etiquetas servicios y estado para visualizaciones
    case servicios.tipo_servicio
        when 'diagnostico'        then 'Diagnóstico'
        when 'asesoria_legal'     then 'Asesoría legal'
        when 'sensibilizacion'    then 'Sensibilización'
        when 'transferencia'      then 'Transferencia'
        when 'asesoria_vacantes'  then 'Asesoría de vacantes'
    end as tipo_servicio_label,
    case servicios.estado
        when 'programado' then 'Programado'
        when 'ejecutado'  then 'Ejecutado'
        when 'cancelado'  then 'Cancelado'
    end as estado_label
from servicios
left join {{ ref('dim_empresa') }} as dim_empresa
    on servicios.nit = dim_empresa.nit