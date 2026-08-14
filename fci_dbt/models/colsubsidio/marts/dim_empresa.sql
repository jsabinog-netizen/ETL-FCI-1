{{ config(materialized='table') }}
select
    id,
    nit,
    razon_social,
    sector_economico,
    municipio,
    cluster,
    fecha_registro,
    estado_en_la_ruta,
    tamano,
    direccion,
    departamento,


    -- banderitas: 1 si el servicio esta ejecutado, 0 si no
    case when estado_diagnostico = 'ejecutado' then 1 else 0 end as tiene_diagnostico,
    case when estado_asesoria = 'ejecutado' then 1 else 0 end as tiene_asesoria_legal,
    case when estado_transferencia = 'ejecutado' then 1 else 0 end as tiene_transferencia,
    case when estado_sensibilizacion = 'ejecutado' then 1 else 0 end as tiene_sensibilizacion,
    -- pendiente añadir estado de vacanta o asesoria legal

    case when estado_diagnostico = 'ejecutado'
            or estado_asesoria = 'ejecutado'
            or estado_transferencia = 'ejecutado'
            or estado_sensibilizacion = 'ejecutado'
            then 1 else 0 end as atendida,

    case estado_en_la_ruta
        when 'sin iniciar'              then 'Sin iniciar'
        when 'en diagnóstico'           then 'En diagnóstico'
        when 'en asesoría legal'        then 'En asesoría legal'
        when 'en sensibilización'       then 'En sensibilización'
        when 'en asesoría de vacantes'  then 'En asesoría de vacantes'
    end as estado_en_la_ruta_label

from {{ ref('stg_registro_empresas') }}
