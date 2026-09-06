-- Grano: un registro del modulo Zoho (id).
-- Name conserva el documento como texto; los eventos no se deduplican por persona.
select
    id,
    nullif(trim(Name), '') as documento,
    safe_cast(`Created_Time` as timestamp) as created_time,
    trim(`Primer_nombre`) as primer_nombre,
    trim(`Segundo_nombre`) as segundo_nombre,
    trim(`Primer_apellido`) as primer_apellido,
    trim(`Segundo_apellido`) as segundo_apellido,
    trim(`N_mero_de_celular_Principal`) as n_mero_de_celular_principal,
    trim(`N_mero_de_celular_Opcional`) as n_mero_de_celular_opcional,
    trim(`Email`) as email,
    safe_cast(`Fecha_y_hora_de_agendamiento` as timestamp) as fecha_y_hora_de_agendamiento,
    lower(trim(`Disponibilidad_Horario`)) as disponibilidad_horario,
    trim(`Asunto_de_la_reuni_n`) as asunto_de_la_reuni_n,
    trim(`Enlace_de_la_reuni_n`) as enlace_de_la_reuni_n,
    lower(trim(`Estado`)) as estado,
    lower(trim(`Modalidad`)) as modalidad,
    lower(trim(`Municipio_o_localidad`)) as municipio_o_localidad,
    trim(`Persona_que_realiza_el_reporte`) as persona_que_realiza_el_reporte,
    safe_cast(_loaded_at as timestamp) as _loaded_at,
    safe_cast(Modified_Time as timestamp) as modified_time
from {{ source('zoho_raw_ruta_mujer', 'agenda_orientadores_rutam') }}
