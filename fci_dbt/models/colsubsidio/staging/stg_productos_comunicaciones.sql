-- models/staging/stg_productos_comunicaciones.sql
select
    id,
    Name                                    as nombre_producto,
    Tipo_de_producto                        as tipo_producto,
    Estado                                  as estado_raw,
    safe_cast(de_avance as float64)         as porcentaje_avance,
    safe_cast(Cantidad_total as int64)      as cantidad_total,
    safe_cast(Cantidad_finalizada as int64) as cantidad_finalizada,
    safe_cast(Cantidad_en_proceso as int64) as cantidad_en_proceso,
    safe_cast(Cantidad_sin_iniciar as int64)as cantidad_sin_iniciar,
    safe_cast(Fecha_compromiso as date)     as fecha_compromiso,
    Observaciones                           as observaciones,
    safe_cast(Modified_Time as timestamp)   as modified_time
from {{ source('zoho_raw', 'productos_componente_iv') }}