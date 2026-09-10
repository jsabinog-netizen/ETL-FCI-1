-- Grano: un registro del modulo Zoho (id).
select
    id,
    nullif(trim(Name), '') as codigo_vacante,
    safe_cast(`Created_Time` as timestamp) as created_time,
    trim(`Nombre_vacante`) as nombre_vacante,
    safe_cast(`N_mero_de_puestos_de_trabajo` as int64) as n_mero_de_puestos_de_trabajo,
    lower(trim(`Tipo_de_contrato`)) as tipo_de_contrato,
    lower(trim(`Estado_de_la_vacante`)) as estado_de_la_vacante,
    lower(trim(`Ciudad_Municipio_de_la_vacante`)) as ciudad_municipio_de_la_vacante,
    lower(trim(`Departamento_de_la_vacante`)) as departamento_de_la_vacante,
    lower(trim(`Departamento`)) as departamento,
    lower(trim(`Municipio`)) as municipio,
    lower(trim(`Rango_salarial`)) as rango_salarial,
    safe_cast(`Tiempo_de_experiencia_requerido_meses` as int64) as tiempo_de_experiencia_requerido_meses,
    lower(trim(`Jornada_laboral`)) as jornada_laboral,
    trim(`Horario_de_trabajo`) as horario_de_trabajo,
    json_value(`Buscar_empresa`, '$.id') as buscar_empresa_id,
    json_value(`Buscar_empresa`, '$.name') as buscar_empresa_nombre,
    trim(`Nombre_de_la_empresa_1`) as nombre_de_la_empresa_1,
    trim(`Nombre_de_la_empresa`) as nombre_de_la_empresa,
    trim(`Ocupaci_n_CUOC_2`) as ocupaci_n_cuoc_2,
    trim(`Ocupaci_n_CUOC_3`) as ocupaci_n_cuoc_3,
    trim(`Email_de_Contacto`) as email_de_contacto,
    trim(`Nombre_de_contacto`) as nombre_de_contacto,
    date(safe_cast(`Fecha_de_inicio_de_la_vacante` as timestamp)) as fecha_de_inicio_de_la_vacante,
    date(safe_cast(`Fecha_final_de_la_vacante` as timestamp)) as fecha_final_de_la_vacante,
    lower(trim(`Posibilidad_de_trabajo_h_brido_remoto`)) as posibilidad_de_trabajo_h_brido_remoto,
    lower(trim(`Acepta_migrantes_regulares`)) as acepta_migrantes_regulares,

    -- ── Campos agregados para replicar view_fact_empresas (dashboard C2M) ──
    lower(trim(`Acepta_v_ctima_del_conflicto_armado`)) as acepta_v_ctima_del_conflicto_armado,
    lower(trim(`Acepta_personas_en_condici_n_de_discapacidad`)) as acepta_personas_en_condici_n_de_discapacidad,
    lower(trim(`Tipo_de_discapacidad`)) as tipo_de_discapacidad,
    lower(trim(`Certificado_de_discapacidad`)) as certificado_de_discapacidad,
    trim(`rea_de_experiencia_laboral`) as rea_de_experiencia_laboral,
    trim(`Descripci_n_de_la_capacitaci_n_espec_fica`) as descripci_n_de_la_capacitaci_n_espec_fica,
    lower(trim(`Requiere_capacitaci_n_espec_fica`)) as requiere_capacitaci_n_espec_fica,
    safe_cast(`Edad_M_nima` as int64) as edad_m_nima,
    safe_cast(`Edad_M_xima` as int64) as edad_m_xima,
    date(safe_cast(`Fecha_compromiso` as timestamp)) as fecha_compromiso,
    date(safe_cast(`Fecha_estimada_de_contrataci_n` as timestamp)) as fecha_estimada_de_contrataci_n,
    trim(`Funciones_del_cargo`) as funciones_del_cargo,
    trim(`Perfil_de_la_vacante`) as perfil_de_la_vacante,
    lower(trim(`Proceso_confidencial`)) as proceso_confidencial,
    lower(trim(`Puede_estar_estudiando`)) as puede_estar_estudiando,
    lower(trim(`Requiere_qu_cuente_con_veh_culo`)) as requiere_qu_cuente_con_veh_culo,
    lower(trim(`Requiere_licencia_para_conducir_carro`)) as requiere_licencia_para_conducir_carro,
    lower(trim(`Requiere_licencia_para_conducir_moto`)) as requiere_licencia_para_conducir_moto,
    lower(trim(`Requiere_manejar_alg_n_idioma`)) as requiere_manejar_alg_n_idioma,
    lower(trim(`Requiere_disponibilidad_para_viajar`)) as requiere_disponibilidad_para_viajar,
    lower(trim(`Requiere_vivir_en_barrio_zona_espec_fica`)) as requiere_vivir_en_barrio_zona_espec_fica,
    lower(trim(`Tiene_personas_a_cargo`)) as tiene_personas_a_cargo,

    -- Titulo_Homologado (C2M) no tiene equivalente exacto en Zoho.
    -- Se usa Requiere_tarjeta_profesional como aproximación disponible:
    -- ambos apuntan a validación de credenciales educativas/profesionales
    -- de la vacante. Pendiente confirmar con el equipo si esto cubre
    -- el mismo concepto de negocio.
    lower(trim(`Requiere_tarjeta_profesional`)) as titulo_homologado,

    lower(trim(`Corte`)) as corte,
    safe_cast(_loaded_at as timestamp) as _loaded_at,
    safe_cast(Modified_Time as timestamp) as modified_time
from {{ source('zoho_raw_ruta_mujer', 'ge_vacantes_colsubsidios') }}