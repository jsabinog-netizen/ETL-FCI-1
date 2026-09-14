-- Grano: una cita comercial con empresa por id de Zoho.

select
    id,
    corte,
    nombre_agendamiento,      
    buscar_empresa_id as empresa_id,
    buscar_empresa_nombre as empresa_lookup,
    nombre_de_la_empresa as empresa,

    date(fecha_y_hora, 'America/Bogota') as fecha_cita,
    format_timestamp('%H:%M:%S', fecha_y_hora, 'America/Bogota') as hora_cita,

    case format_date('%A', date(fecha_y_hora, 'America/Bogota'))
        when 'Monday'    then 'Lunes'
        when 'Tuesday'   then 'Martes'
        when 'Wednesday' then 'Miércoles'
        when 'Thursday'  then 'Jueves'
        when 'Friday'    then 'Viernes'
        when 'Saturday'  then 'Sábado'
        when 'Sunday'    then 'Domingo'
    end as dia_semana,

    case format_date('%A', date(fecha_y_hora, 'America/Bogota'))
        when 'Monday'    then 1
        when 'Tuesday'   then 2
        when 'Wednesday' then 3
        when 'Thursday'  then 4
        when 'Friday'    then 5
        when 'Saturday'  then 6
        when 'Sunday'    then 7
    end as dia_semana_orden,

    disponibilidad_horario,
    asunto_de_la_reuni_n as asunto,
    enlace_de_la_reuni_n as enlace,
    observaciones_agendamiento,
    direcci_n_del_lugar as direccion_del_lugar,
    estado,
    modalidad,
    tipo_actividad,
    invitador as responsable,    
    persona_de_contacto,
    correo,

    departamento,
    municipio,
    sector_econ_mico as sector_economico,

    date(created_time) as fecha_creacion,
    date(modified_time) as fecha_modificacion,
    date(_loaded_at) as fecha_carga

from {{ ref('stg_ge_agendamiento') }}