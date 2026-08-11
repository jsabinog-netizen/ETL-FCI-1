select
    id,
    Primer_nombre                                   as primer_nombre,
    Primer_apellido                                 as primer_apellido,
    Name                                            as documento,
    lower(trim(Estado_de_calidad))                  as estado_calidad,
    Observaci_n_de_calidad                          as observacion_calidad,
    safe_cast(Fecha_de_revisi_n as timestamp)       as fecha_revision,

    -- lookups a cada etapa: el "puente" entre módulos
    json_value(Registro,      '$.id')               as registro_id,
    json_value(Orientaci_n,   '$.id')               as orientacion_id,
    json_value(Intermediaci_n,'$.id')               as intermediacion_id,
    json_value(Colocaci_n,    '$.id')               as colocacion_id,

    DATE(safe_cast(Modified_Time as timestamp))           as modified_time
from {{ source('zoho_raw_giz', 'calidad_giz') }}