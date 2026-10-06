-- Grano: una fila por documento; prevalece la inscripción más reciente.
-- Desempates deterministas por modificación, creación e id de Zoho.
select
    id,
    nullif(trim(Name), '') as documento,
    safe_cast(`Created_Time` as timestamp) as created_time,
    trim(`Primer_nombre`) as primer_nombre,
    trim(`Segundo_nombre`) as segundo_nombre,
    trim(`Primer_apellido`) as primer_apellido,
    trim(`Segundo_apellido`) as segundo_apellido,
    date(safe_cast(`Fecha_de_registro` as timestamp)) as fecha_de_registro,
    date(safe_cast(`Fecha_de_nacimiento` as timestamp)) as fecha_de_nacimiento,
    safe_cast(`Edad` as int64) as edad,
    case
        when safe_cast(`Edad` as int64) between 18 and 28 then '18-28'
        when safe_cast(`Edad` as int64) between 29 and 35 then '29-35'
        when safe_cast(`Edad` as int64) between 36 and 45 then '36-45'
        when safe_cast(`Edad` as int64) >= 46 then '46 o más'
        else null
    end as rango_joven,
    lower(trim(`Tipo_de_documento`)) as tipo_de_documento,
    trim(`Email`) as email,
    trim(`N_mero_de_celular`) as n_mero_de_celular,
    lower(trim(`Sexo_al_nacer`)) as sexo_al_nacer,
    lower(trim(`Nacionalidad`)) as nacionalidad,
    trim(`Otra_nacionalidad`) as otra_nacionalidad,
    lower(trim(`Tipificaci_n_Mujer`)) as tipificaci_n_mujer,
    `Grupos_poblacionales` as grupos_poblacionales_json,
    case
        when starts_with(trim(`Grupos_poblacionales`), '[') then lower(trim(json_value(`Grupos_poblacionales`, '$[0]')))
        else lower(trim(`Grupos_poblacionales`))
    end as grupos_poblacionales,
    lower(trim(`Tipo_de_poblaci_n`)) as tipo_de_poblacion_subsidio,
    lower(trim(`Tipo_de_poblaci_n1`)) as tipo_de_poblacion,
    lower(trim(`Tipo_de_poblaci_n1`)) as tipo_de_poblaci_n,
    lower(trim(`Modalidad_de_atenci_n`)) as modalidad_de_atenci_n,
    lower(trim(`Inscripci_n_completada`)) as inscripci_n_completada,
    trim(`Profesional_de_registro`) as profesional_de_registro,
    lower(trim(`Municipio_de_residencia1`)) as municipio_de_residencia1,
    lower(trim(`Municipio_de_nacimiento`)) as municipio_de_nacimiento,
    lower(trim(`Departamento_de_nacimiento`)) as departamento_de_nacimiento,
    lower(trim(`Localidad`)) as localidad,
    trim(`Direcci_n_de_residencia`) as direcci_n_de_residencia,
    lower(trim(`Estrato`)) as estrato,
    lower(trim(`Estado_Civil`)) as estado_civil,
    lower(trim(`Tiene_hijos`)) as tiene_hijos,
    json_value(`Pre_registro`, '$.id') as pre_registro_id,
    json_value(`Pre_registro`, '$.name') as pre_registro_nombre,
    lower(trim(`Desea_generar_acompa_amiento_psicosocial`)) as desea_generar_acompa_amiento_psicosocial,
    lower(trim(`D_nde_te_enteraste_de_esta_vacante`)) as d_nde_te_enteraste_de_esta_vacante,
    lower(trim(`Corte`)) as corte,
    safe_cast(_loaded_at as timestamp) as _loaded_at,
    safe_cast(Modified_Time as timestamp) as modified_time,
    lower(trim(`Naturaleza_del_estrato_socioecon_mico`)) as naturaleza_del_estrato_socioecon_mico,
    lower(trim(`Ultimo_nivel_educativo_alcanzado`)) as ultimo_nivel_educativo_alcanzado,
    case
        when `Ultimo_nivel_educativo_alcanzado` is null
            then null
        when regexp_contains(lower(trim(`Ultimo_nivel_educativo_alcanzado`)),
                r'doctor|postdoctor|posdoctor')
            then 'Doctorado o postdoctorado'
        when regexp_contains(lower(trim(`Ultimo_nivel_educativo_alcanzado`)),
                r'especializaci|maestr|mag[íi]ster|posgrado|postgrado')
            then 'Especialización o maestría'
        when regexp_contains(lower(trim(`Ultimo_nivel_educativo_alcanzado`)),
                r'universitar|pregrado|profesional')
            then 'Universitario (pregrado)'
        when regexp_contains(lower(trim(`Ultimo_nivel_educativo_alcanzado`)),
                r't[ée]cn')
            then 'Técnico o Tecnológico'
        when regexp_contains(lower(trim(`Ultimo_nivel_educativo_alcanzado`)),
                r'bachill|media|secundar')
            then 'Bachillerato'
        when regexp_contains(lower(trim(`Ultimo_nivel_educativo_alcanzado`)),
                r'primaria|b[áa]sica')
            then 'Primaria'
        when regexp_contains(lower(trim(`Ultimo_nivel_educativo_alcanzado`)),
                r'ninguno|ningun|sin estudi')
            then 'Ninguno'
        else 'Sin clasificar'
    end as nivel_educativo_normalizado,
    trim(`Pregunta_de_seguridad`) as pregunta_de_seguridad,
    trim(`Respuesta_pregunta_seguridad`) as respuesta_pregunta_seguridad,
    lower(trim(`Seleccione_nivel_de_Sisb_n`)) as seleccione_nivel_de_sisb_n,
    lower(trim(`Tiene_clasificaci_n_Sisb_n`)) as tiene_clasificacion_sisben,
    lower(trim(`Tiene_alguna_de_estas_responsabilidades_de_cuidado`)) as tiene_alguna_de_estas_responsabilidades_de_cuidado,
    lower(trim(`Sede_de_atenci_n`)) as sede,
    lower(trim(`Validaci_n_habilitante`)) as validacion_habilitante,
    -- Campos SAE
    lower(trim(`Orientacion_Sexual`)) as orientacion_sexual,
    lower(trim(`Etnia`)) as etnia,
    lower(trim(`Barrio_de_residencia`)) as barrio,
    lower(trim(`Si_es_hombre_Tiene_libreta_militar`)) as libreta_militar,
    lower(trim(`Tiene_licencia_de_conducci_n_para_carro`)) as tiene_licencia_carro,
    lower(trim(`Categor_a_Licencia_para_carro`)) as categoria_licencia_carro,
    lower(trim(`Tiene_licencia_de_conducci_n_para_moto`)) as tiene_licencia_moto,
    lower(trim(`Categor_a_Licencia_para_moto`)) as categoria_licencia_moto,
    lower(trim(`Propiedad_de_medio_de_transporte`)) as propiedad_medio_transporte,
    lower(trim(`Modelo_de_vehiculo`)) as modelo_de_vehiculo,
    lower(trim(`Autoriza_el_uso_de_sus_datos_personales`)) as autoriza_uso_datos_personales,
    lower(trim(`Autoriza_el_cambio_de_prestador_a_Colsubsidio`)) as autoriza_cambio_prestador,
    trim(`Url_tratamiento_de_datos`) as url_tratamiento_de_datos,
    lower(trim(`Tipo_de_discapacidad`)) as tipo_de_discapacidad,
    lower(trim(`Cuenta_con_documento_acreditativo_de_discapacidad`)) as cuenta_con_documento_discapacidad,
    trim(`Url_discapacidad`) as certificado_discapacidad_url,
    trim(`Certificado_prestador`) as certificado_prestador_url,
    lower(trim(`Es_el_jefe_o_jefa_de_hogar`)) as es_jefe_hogar,
    lower(trim(`Cuantas_personas_dependen_econ_micamente_de_uste`)) as personas_a_cargo,
    lower(trim(`Ha_recibido_alg_n_subsidio_del_gobierno`)) as ha_recibido_subsidio_gobierno,
    lower(trim(`Estado_de_estudio`)) as estado_de_estudio,
    lower(trim(`Tiene_t_tulo_o_certificaci_n_de_estudios`)) as tiene_titulo_o_certificacion,
    lower(trim(`Sus_t_tulos_o_diplomas_se_encuentran_convalidados`)) as titulo_homologado,
    trim(`Nombre_de_la_instituci_n`) as nombre_de_la_institucion,
    lower(trim(`En_qu_Pa_s_realiz_sus_ultimos_estudios`)) as pais_ultimos_estudios,
    trim(`Nombre_de_carrera_o_curso_que_actualmente_cursa`) as carrera_o_curso_actual,
    trim(`rea_Sector_de_formaci_n`) as rea_sector_de_formaci_n,
    trim(`Otra_rea_de_formaci_n_si_no_se_encuentra_arriba`) as otra_area_formacion,
    date(safe_cast(`Fecha_del_grado` as timestamp)) as fecha_del_grado,
    lower(trim(`Tienes_formaci_n_t_cnica_o_certificaciones_espec`)) as tiene_formacion_tecnica,
    lower(trim(`Cursos_habilidades_terminados_en_ltimos_24_meses`)) as cursos_ultimos_24_meses,
    lower(trim(`Usa_computador_u_otros_dispositivos`)) as usa_computador,
    lower(trim(`Utiliza_internet`)) as utiliza_internet,
    trim(`Nombre_de_la_empresa_1`) as nombre_empresa_experiencia,
    lower(trim(`Sector_u_ocupaci_n_principal_de_tu_ltimo_empleo`)) as sector_ultimo_empleo,
    lower(trim(`Tipo_de_vinculaci_n`)) as tipo_vinculacion_experiencia,
    date(safe_cast(`Fecha_de_inicio_experiencia_laboral` as timestamp)) as fecha_inicio_experiencia,
    date(safe_cast(`Fecha_de_finalizaci_n_experiencia` as timestamp)) as fecha_fin_experiencia,
    lower(trim(`Pa_s_de_la_empresa`)) as pais_empresa_experiencia,
    trim(`Funciones_y_logros_en_la_empresa`) as funciones_logros_experiencia,

from {{ source('zoho_raw_ruta_mujer', 'inscripci_n_colsubsidios') }}
qualify row_number() over (
    partition by documento
    order by fecha_de_registro desc nulls last,
             modified_time desc nulls last, created_time desc nulls last, id desc
) = 1
