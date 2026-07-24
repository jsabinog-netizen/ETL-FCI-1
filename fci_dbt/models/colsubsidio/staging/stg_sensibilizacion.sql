select 
    -- id y texto se mantinen así
    id,
    Name as nombre_empresa,
    Conclusiones as conclusiones,
    Recomendaciones as recomendaciones,
    Tipo_de_sesi_n as tipo_de_sesion,

    --Datos tipo json
    coalesce(
        json_value(Empresa, '$.name'), 
        json_value(Agenda, '$.name'),
        'SIN_EMPRESA'
    
    ) as nit,

    case when json_value(Empresa, '$.name') is not null then true else false end as vinculo_empresa_directo,
    coalesce(nullif(trim(json_value(Profesional_asignado1, '$.name')), ''), 'Sin asesor asignado') as asesor_sensibilizacion,

    -- fechas: STRING -> DATE con SAFE_CAST
    safe_cast(Fecha_y_hora_inicio  as timestamp) as inicio,
    safe_cast(Fecha_y_hora_fin  as timestamp) as fin,

    -- estados: normalizados a minuscula y sin espacio de borde
    lower(trim(Estado_de_la_sensibilizaci_n)) as estado_sensibilizacion,

    --validacion informe
    case when Informe_PDF is not null and Informe_PDF != '' then 1 else 0 end as tiene_informe,

    -- plumbing: la fecha de sistema tambien a timestamp
    safe_cast(Modified_Time as timestamp) as modified_time
from {{ source('zoho_raw', 'sensibilizaci_n') }}
