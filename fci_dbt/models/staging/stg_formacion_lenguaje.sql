with base as(
    SELECT 
        id,
        Nombre_Completo as nombre,
        Name as cedula,
        Cargo as cargo,
        lower(trim(Estado_del_curso)) as estado_curso,
        Evaluaci_n_1 as evaluacion_1,
        Evaluaci_n_2 as evaluacion_2,
        (
            CASE WHEN lower(trim(Asistencia)) = 'asistió' THEN 1 else 0 end +
            CASE WHEN lower(trim(Asistencia_2)) = 'asistió' THEN 1 else 0 end +
            CASE WHEN lower(trim(Asistencia_3)) = 'asistió' THEN 1 else 0 end +
            CASE WHEN lower(trim(Asistencia_4)) = 'asistió' THEN 1 else 0 end +
            CASE WHEN lower(trim(Asistencia_5)) = 'asistió' THEN 1 else 0 end +
            CASE WHEN lower(trim(Asistencia_6)) = 'asistió' THEN 1 else 0 end +
            CASE WHEN lower(trim(Asistencia_7)) = 'asistió' THEN 1 else 0 end +
            CASE WHEN lower(trim(Asistencia_8)) = 'asistió' THEN 1 else 0 end 
        ) as sesiones_asistidas 
    from {{ source ('zoho_raw', 'asistencia_formaci_n_ls') }}
) 

SELECT 
    *,
    round(sesiones_asistidas/8 *100,1) as porcentaje_asistencia
from base