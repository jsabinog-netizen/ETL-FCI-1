select
    -- identificación
    id,
    Name                                                as documento,
    Primer_Nombre                                       as primer_nombre,
    Primer_Apellido                                     as primer_apellido,
    Segundo_Nombre                                      as segundo_nombre,
    Segundo_Apellido                                    as segundo_apellido,

    -- formación
    lower(trim(Nombre_del_curso_T_cnico))               as nombre_curso,
    lower(trim(Gestor_formaci_n))                       as gestor_formacion,

    -- estado
    CASE LOWER(TRIM(Formaci_n_Completadas))
        WHEN 'sí' THEN 'si'
        WHEN 'si' THEN 'si'
        WHEN 'no' THEN 'no'
        ELSE NULL
    END                                                 as formacion_completada,

    -- calidad diplomas
    CASE LOWER(TRIM(Validaci_n_Diploma_T_cnicas))
        WHEN 'aprobado'       THEN 'aprobado'
        WHEN 'rechazo'        THEN 'rechazo'
        WHEN 'reverificación' THEN 'reverificacion'
        ELSE NULL
    END                                                 as validacion_diploma_tecnico,

    CASE LOWER(TRIM(Validaci_n_diploma_Habilidades_para_el_trabajo))
        WHEN 'aprobado'       THEN 'aprobado'
        WHEN 'rechazo'        THEN 'rechazo'
        WHEN 'reverificación' THEN 'reverificacion'
        ELSE NULL
    END                                                 as validacion_diploma_habilidades,

    -- flags de archivos adjuntos
    CASE WHEN Diploma_T_cnicas   IS NOT NULL THEN 'si' ELSE 'no' END  as tiene_diploma_tecnico,
    CASE WHEN Diploma_Blandas    IS NOT NULL THEN 'si' ELSE 'no' END  as tiene_diploma_blando,
    CASE WHEN Certificado_Bancario IS NOT NULL THEN 'si' ELSE 'no' END as tiene_certificado_bancario,

    -- datos bancarios (para mitigaciones futuras)
    lower(trim(Entidad_Bancaria))                       as entidad_bancaria,
    Nombre_del_Beneficiario_de_la_cuenta                as nombre_beneficiario_cuenta,
    Tipo_de_cuenta                                      as tipo_cuenta,

    -- plumbing
    DATE(safe_cast(Modified_Time as timestamp))         as modified_time,
    DATE(safe_cast(Created_Time  as timestamp))         as _loaded_at

from {{ source('zoho_raw_giz', 'formaci_n_giz') }}


