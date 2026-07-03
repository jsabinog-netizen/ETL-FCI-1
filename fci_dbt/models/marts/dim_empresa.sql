{{ config(materialized='table') }}
select
    id,
    nit,
    razon_social,
    sector_economico,
    municipio,
    cluster,
    estado_en_la_ruta,

    -- banderitas: 1 si el servicio esta ejecutado, 0 si no
    case when estado_diagnostico = 'ejecutado' then 1 else 0 end as tiene_diagnostico,
    case when estado_asesoria = 'ejecutado' then 1 else 0 end as tiene_asesoria,
    case when estado_transferencia = 'ejecutado' then 1 else 0 end as tiene_transferencia,
    case when estado_sensibilizacion = 'ejecutado' then 1 else 0 end as tiene_sensibilizacion,
    -- pendiente añadir estado de vacanta o asesoria legal

    case when estado_diagnostico = 'ejecutado'
            or estado_asesoria = 'ejecutado'
            or estado_transferencia = 'ejecutado'
            or estado_sensibilizacion = 'ejecutado'
            then 1 else 0 end as atendida

from {{ ref('stg_registro_empresas') }}
