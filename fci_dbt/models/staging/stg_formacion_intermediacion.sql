with base as (
    select
        id,
        Nombre_Completo as nombre,
        Name as cedula,
        Cargo as cargo,
        lower(trim(Estado_del_curso)) as estado_curso,
        Evaluacion_1 as evaluacion_1,
        (
            case when lower(trim(Asistencia))   = 'asistió' then 1 else 0 end +
            case when lower(trim(Asistencia_2)) = 'asistió' then 1 else 0 end +
            case when lower(trim(Asistencia_3)) = 'asistió' then 1 else 0 end +
            case when lower(trim(Asistencia_4)) = 'asistió' then 1 else 0 end
        ) as sesiones_asistidas
    from {{ source('zoho_raw', 'intermediaci_n_re') }}
)

select
    *,
    round(sesiones_asistidas / 4.0 * 100, 1) as porcentaje_asistencia
from base