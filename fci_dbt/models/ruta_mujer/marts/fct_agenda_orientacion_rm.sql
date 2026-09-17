select
    id,
    corte,
    case
        when date(fecha_y_hora_de_agendamiento, 'America/Bogota') >= '2026-09-01' then 'corte 2'
        else 'corte 1'
    end as corte_evento,
    documento,
    date(fecha_y_hora_de_agendamiento, 'America/Bogota') as fecha_cita,
    format_timestamp('%H:%M:%S', fecha_y_hora_de_agendamiento, 'America/Bogota') as hora_cita,

    case format_date('%A', date(fecha_y_hora_de_agendamiento, 'America/Bogota'))
        when 'Monday'    then 'Lunes'
        when 'Tuesday'   then 'Martes'
        when 'Wednesday' then 'Miércoles'
        when 'Thursday'  then 'Jueves'
        when 'Friday'    then 'Viernes'
        when 'Saturday'  then 'Sábado'
        when 'Sunday'    then 'Domingo'
    end as dia_semana,

    case format_date('%A', date(fecha_y_hora_de_agendamiento, 'America/Bogota'))
        when 'Monday'    then 1
        when 'Tuesday'   then 2
        when 'Wednesday' then 3
        when 'Thursday'  then 4
        when 'Friday'    then 5
        when 'Saturday'  then 6
        when 'Sunday'    then 7
    end as dia_semana_orden,

    trim(concat(coalesce(primer_nombre, ''), ' ', coalesce(segundo_nombre, ''), ' ',
                coalesce(primer_apellido, ''), ' ', coalesce(segundo_apellido, ''))) as nombre_completo,
    primer_nombre,
    segundo_nombre,
    primer_apellido,
    segundo_apellido,
    n_mero_de_celular_principal as celular,
    n_mero_de_celular_opcional as celular_opcional,
    email as correo,

    disponibilidad_horario,
    asunto_de_la_reuni_n as asunto,
    enlace_de_la_reuni_n as enlace,
    observaciones_agendamiento,
    estado,
    modalidad,
    municipio_o_localidad as municipio,
    persona_que_realiza_el_reporte as responsable,

    date(created_time) as fecha_creacion,
    date(modified_time) as fecha_modificacion,
    date(_loaded_at) as fecha_carga

from {{ ref('stg_agenda_orientadores_rutam') }}

-- NOTA: direccion_del_lugar no se expone acá. El campo
-- Direcci_n_del_lugar existe en el módulo Agenda_Orientadores_RutaM
-- en Zoho pero no está en config.py para este módulo. Si el dashboard
-- lo necesita, agregarlo primero a la extracción y al staging.