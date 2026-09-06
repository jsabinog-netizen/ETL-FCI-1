-- Grano: un registro del modulo Zoho (id).
-- Name conserva el documento como texto; los eventos no se deduplican por persona.
select
    id,
    nullif(trim(Name), '') as documento,
    json_value(`Owner`, '$.id') as owner_id,
    json_value(`Owner`, '$.name') as owner_nombre,
    trim(`Email`) as email,
    safe_cast(`Created_Time` as timestamp) as created_time,
    safe_cast(`Last_Activity_Time` as timestamp) as last_activity_time,
    trim(`Primer_apellido`) as primer_apellido,
    trim(`Segundo_apellido`) as segundo_apellido,
    date(safe_cast(`Fecha_curso` as timestamp)) as fecha_curso,
    trim(`Primer_Nombre`) as primer_nombre,
    trim(`N_mero_de_t_lefono`) as n_mero_de_t_lefono,
    trim(`Segundo_Nombre`) as segundo_nombre,
    lower(trim(`Jornada`)) as jornada,
    lower(trim(`Tipo_de_documento`)) as tipo_de_documento,
    trim(`Cursos`) as cursos,
    lower(trim(`Modalidad_curso`)) as modalidad_curso,
    safe_cast(_loaded_at as timestamp) as _loaded_at,
    safe_cast(Modified_Time as timestamp) as modified_time
from {{ source('zoho_raw_ruta_mujer', 'asist_pres_rutam') }}
