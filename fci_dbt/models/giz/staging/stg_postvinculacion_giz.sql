select
    -- identificación  
    id,
    Name                                                                     as documento,
    Nit_de_la_empresa                                                        as nit_empresa,
    coalesce(nullif(trim(json_value(Empresa, '$.name')), ''),'Sin empresa')  as empresa,
    lower(trim(Nombre_de_la_vacante))                                        as nombre_vacante,
    C_digo_de_la_vacante                                                     as codigo_vacante,
    Primer_Nombre                                                            as primer_nombre,
    Primer_apellido                                                          as primer_apellido,
    Segundo_nombre                                                           as segundo_nombre,
    Segundo_apellido                                                         as segundo_apellido,
    N_mero_de_celular                                                        as celular,
    Whatsapp_de_contacto                                                     as whatsapp,

    -- gestores
    lower(trim(Nombre_del_Gestor_Operativo))                                 as gestor_s1,
    lower(trim(Nombre_del_Gestor_Operativo_S2))                              as gestor_s2,
    lower(trim(Nombre_del_Gestor_Operativo_S3))                              as gestor_s3,

    -- seguimientos completados
    CASE LOWER(TRIM(Seguimiento_Postvinculaci_n_1_completado))
        WHEN 'sí' THEN 'si' WHEN 'si' THEN 'si'
        WHEN 'no' THEN 'no' ELSE NULL
    END                                                                      as seguimiento_1_completado,
    CASE LOWER(TRIM(Seguimiento_Postvinculaci_n_2_completado))
        WHEN 'sí' THEN 'si' WHEN 'si' THEN 'si'
        WHEN 'no' THEN 'no' ELSE NULL
    END                                                                      as seguimiento_2_completado,
    CASE LOWER(TRIM(Seguimiento_Postvinculaci_n_S3_completado))
        WHEN 'sí' THEN 'si' WHEN 'si' THEN 'si'
        WHEN 'no' THEN 'no' ELSE NULL
    END                                                                      as seguimiento_3_completado,

    -- permanencia
    lower(trim(Permanencia_en_seguimiento_1))                                as permanencia_s1,
    lower(trim(Permanencia_en_seguimiento_S2))                               as permanencia_s2,
    lower(trim(Permanencia_en_seguimiento_3))                                as permanencia_s3,

    -- motivos de terminación
    lower(trim(Motivo_de_terminaci_n_contrato_renuncia_despido_se))          as motivo_terminacion_s1,
    lower(trim(Motivo_de_terminaci_n_contrato_renuncia_despido_s1))          as motivo_terminacion_s2,
    lower(trim(Motivo_de_terminaci_n_contrato_renuncia_despido_s2))          as motivo_terminacion_s3,

    -- barreras S1
    CASE LOWER(TRIM(Enfrenta_alg_n_de_tipo_de_barrera_para_la_permanen))
        WHEN 'sí' THEN 'si' WHEN 'si' THEN 'si'
        WHEN 'no' THEN 'no'
        WHEN 'no responde' THEN 'no responde'
        ELSE NULL
    END                                                                      as enfrenta_barrera_s1,
    lower(trim(Seleccione_el_tipo_de_barrera_interna_externa_que))           as tipo_barrera_s1,
    lower(trim(Cu_l_es_servicio_recibi_para_superar_la_barrera_1))           as servicio_barrera_s1,

    -- barreras S2
    CASE LOWER(TRIM(Enfrenta_alg_n_de_tipo_de_barrera_2_para_la_perman))
        WHEN 'sí' THEN 'si' WHEN 'si' THEN 'si'
        WHEN 'no' THEN 'no'
        WHEN 'no responde' THEN 'no responde'
        ELSE NULL
    END                                                                      as enfrenta_barrera_s2,
    lower(trim(Seleccione_el_tipo_de_barrera_interna_externa_que1))          as tipo_barrera_s2,
    lower(trim(Cu_l_es_servicio_recibi_para_superar_la_barrera_11))          as servicio_barrera_s2,

    -- satisfacción
    CASE LOWER(TRIM(Se_siente_a_gusto_en_la_empresa_para_la_cu_l_traba))
        WHEN 'sí' THEN 'si' WHEN 'si' THEN 'si'
        WHEN 'no' THEN 'no' ELSE NULL
    END                                                                      as satisfaccion_empresa,
    CASE LOWER(TRIM(Se_siente_a_gusto_con_el_cargo_que_desempe_a))
        WHEN 'sí' THEN 'si' WHEN 'si' THEN 'si'
        WHEN 'no' THEN 'no' ELSE NULL
    END                                                                      as satisfaccion_cargo,
    CASE LOWER(TRIM(Siente_que_el_empleo_actual_a_cumplido_con_sus_exp))
        WHEN 'sí' THEN 'si' WHEN 'si' THEN 'si'
        WHEN 'no' THEN 'no' ELSE NULL
    END                                                                      as expectativas_cumplidas,

    -- fechas
    DATE(safe_cast(Fecha_de_colocaci_n as timestamp))                                as fecha_colocacion,
    DATE(safe_cast(Fecha_del_seguimiento_1 as timestamp))                            as fecha_seguimiento_s1,
    DATE(safe_cast(Fecha_del_seguimiento_S2 as timestamp))                           as fecha_seguimiento_s2,
    DATE(safe_cast(Fecha_del_seguimiento_S3 as timestamp))                           as fecha_seguimiento_s3,
    DATE(safe_cast(Fecha_de_terminaci_n_contrato_renuncia_despido_seg as timestamp)) as fecha_terminacion_s1,
    DATE(safe_cast(Fecha_de_terminaci_n_contrato_renuncia_despido_se1 as timestamp)) as fecha_terminacion_s2,
    DATE(safe_cast(Fecha_de_terminaci_n_contrato_renuncia_despido_se2 as timestamp)) as fecha_terminacion_s3,

    -- plumbing
    DATE(safe_cast(Modified_Time as timestamp))                                      as modified_time,
    DATE(safe_cast(Created_Time as timestamp))                                       as _loaded_at

from {{ source('zoho_raw_giz', 'postvinculaci_n_giz') }}