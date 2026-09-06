-- Grano: un registro del modulo Zoho (id).
select
    id,
    nullif(trim(Name), '') as nombre_agendamiento,
    safe_cast(`Created_Time` as timestamp) as created_time,
    trim(`Nombre_de_la_empresa`) as nombre_de_la_empresa,
    safe_cast(`Fecha_y_hora` as timestamp) as fecha_y_hora,
    lower(trim(`Disponibilidad_Horario`)) as disponibilidad_horario,
    trim(`Asunto_de_la_reuni_n`) as asunto_de_la_reuni_n,
    trim(`Enlace_de_la_reuni_n`) as enlace_de_la_reuni_n,
    lower(trim(`Estado`)) as estado,
    lower(trim(`Modalidad`)) as modalidad,
    trim(`Invitador`) as invitador,
    lower(trim(`Departamento`)) as departamento,
    lower(trim(`Municipio`)) as municipio,
    lower(trim(`Tipo_Actividad`)) as tipo_actividad,
    trim(`Correo`) as correo,
    trim(`Persona_de_contacto`) as persona_de_contacto,
    json_value(`Buscar_empresa`, '$.id') as buscar_empresa_id,
    json_value(`Buscar_empresa`, '$.name') as buscar_empresa_nombre,
    lower(trim(`Sector_Econ_mico`)) as sector_econ_mico,

    -- ── Campo agregado para replicar vw_agendamientos_comerciales (dashboard C2M) ──
    trim(`Direcci_n_del_lugar`) as direcci_n_del_lugar,

    safe_cast(_loaded_at as timestamp) as _loaded_at,
    safe_cast(Modified_Time as timestamp) as modified_time
from {{ source('zoho_raw_ruta_mujer', 'ge_agendamiento') }}