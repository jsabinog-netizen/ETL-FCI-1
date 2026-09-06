select concat('individual:', id) as id, id as id_origen,
    'individual' as tipo, documento,
    cast(null as string) as empresa_id, cast(null as string) as empresa,
    date(fecha_y_hora_de_agendamiento, 'America/Bogota') as fecha_cita,
    format_timestamp('%H:%M:%S', fecha_y_hora_de_agendamiento, 'America/Bogota') as hora_cita,
    disponibilidad_horario, asunto_de_la_reuni_n as asunto,
    enlace_de_la_reuni_n as enlace, estado, modalidad,
    municipio_o_localidad as municipio, cast(null as string) as departamento,
    email as correo, n_mero_de_celular_principal as celular,
    persona_que_realiza_el_reporte as responsable,
    date(created_time) as fecha_creacion, date(modified_time) as fecha_modificacion,
    date(_loaded_at) as fecha_carga
from {{ ref('stg_agenda_orientadores_rutam') }}
union all
select concat('empresarial:', id) as id, id as id_origen,
    'empresarial' as tipo, cast(null as string) as documento,
    buscar_empresa_id as empresa_id, nombre_de_la_empresa as empresa,
    date(fecha_y_hora, 'America/Bogota') as fecha_cita,
    format_timestamp('%H:%M:%S', fecha_y_hora, 'America/Bogota') as hora_cita,
    disponibilidad_horario, asunto_de_la_reuni_n as asunto,
    enlace_de_la_reuni_n as enlace, estado, modalidad,
    municipio, departamento, correo, cast(null as string) as celular,
    invitador as responsable,
    date(created_time) as fecha_creacion, date(modified_time) as fecha_modificacion,
    date(_loaded_at) as fecha_carga
from {{ ref('stg_ge_agendamiento') }}
