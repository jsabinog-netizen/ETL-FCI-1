select -- identificador y texto: se dejan como vienen por ahora
    id,
    Name as nit,
    Raz_n_social_de_la_empresa as razon_social,
    Municipio as municipio,
    Departamento as departamento,
    Sector_econ_mico_de_la_empresa as sector_economico,
    Cluster as cluster,

    -- fechas: STRING -> DATE con SAFE_CAST
    safe_cast(Fecha_de_registro as date) as fecha_registro,
    safe_cast(Fecha_diagn_stico_programado as date) as fecha_diagnostico_programado,
    safe_cast(Fecha_diagn_stico_ejecutado as date) as fecha_diagnostico_ejecutado,
    safe_cast(Fecha_sensibilizaci_n_programada as date) as fecha_sensibilizacion_programada,
    safe_cast(Fecha_sensibilizaci_n_ejecutada as date) as fecha_sensibilizacion_ejecutada,
    safe_cast(Fecha_asesor_a_programada as date) as fecha_asesoria_programada,
    safe_cast(Fecha_asesor_a_ejecutada as date) as fecha_asesoria_ejecutada,
    safe_cast(Fecha_transferencia_programada as date) as fecha_transferencia_programada,
    safe_cast(Fecha_transferencia_ejecutada as date) as fecha_transferencia_ejecutada,
    safe_cast(Fecha_m_dulo_1_programado as date) as fecha_modulo_1_programado,
    safe_cast(Fecha_m_dulo_1_ejecutado as date) as fecha_modulo_1_ejecutado,
    safe_cast(Fecha_m_dulo_2_programado as date) as fecha_modulo_2_programado,
    safe_cast(Fecha_m_dulo_2_ejecutado as date) as fecha_modulo_2_ejecutado,

    -- estados: normalizados a minuscula y sin espacio de borde
    lower(trim(Estado_en_la_ruta)) as estado_en_la_ruta,
    lower(trim(Estado_diagn_stico)) as estado_diagnostico,
    lower(trim(Estado_asesor_a)) as estado_asesoria,
    lower(trim(Estado_transferencia)) as estado_transferencia,
    lower(trim(Estado_m_dulo_1)) as estado_modulo_1,
    lower(trim(Estado_m_dulo_2)) as estado_modulo_2,
    lower(trim(Estado_sensibilizaci_n)) as estado_sensibilizacion,

    -- plumbing: la fecha de sistema tambien a timestamp
    safe_cast(Modified_Time as timestamp) as modified_time
from {{ source('zoho_raw', 'registro_empresas') }}