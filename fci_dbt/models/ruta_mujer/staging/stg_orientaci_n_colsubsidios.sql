-- Grano: un registro del modulo Zoho (id).
-- Name conserva el documento como texto; los eventos no se deduplican por persona.
select
    id,
    nullif(trim(Name), '') as documento,
    safe_cast(`Created_Time` as timestamp) as created_time,
    json_value(`Inscripci_n`, '$.id') as inscripci_n_id,
    json_value(`Inscripci_n`, '$.name') as inscripci_n_nombre,
    trim(`Primer_nombre`) as primer_nombre,
    trim(`Segundo_nombre`) as segundo_nombre,
    trim(`Primer_apellido`) as primer_apellido,
    trim(`Segundo_apellido`) as segundo_apellido,
    date(safe_cast(`Fecha_de_orientaci_n` as timestamp)) as fecha_de_orientaci_n,
    lower(trim(`Orientaci_n_sociocupacion_Completada`)) as orientaci_n_sociocupacion_completada,
    trim(`Concepto_de_Orientaci_n`) as concepto_de_orientaci_n,
    trim(`Concepto_de_orientaci_n_colsubsidio`) as concepto_de_orientaci_n_colsubsidio,
    lower(trim(`Modalidad_Orientacion`)) as modalidad_orientacion,
    trim(`Gestor_operativo`) as gestor_operativo,
    trim(`Perfil_Ocupacional`) as perfil_ocupacional,
    `Grupos_poblacionales` as grupos_poblacionales_json,
    case
        when starts_with(trim(`Grupos_poblacionales`), '[') then lower(trim(json_value(`Grupos_poblacionales`, '$[0]')))
        else lower(trim(`Grupos_poblacionales`))
    end as grupos_poblacionales,
    lower(trim(`Nivel_de_necesidad_de_acompa_amiento_psicosocial`)) as nivel_de_necesidad_de_acompa_amiento_psicosocial,
    trim(`Sientes_que_actualmente_necesitas_apoyo_adicional`) as sientes_que_actualmente_necesitas_apoyo_adicional,
    trim(`N_mero_de_celular_Principal`) as n_mero_de_celular_principal,
    lower(trim(`Municipio_de_residencia`)) as municipio_de_residencia,
    lower(trim(`rea_de_Experiencia_Laboral_experiencia_2`)) as area_experiencia_2,
    lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)) as area_experiencia,
    case
        when nullif(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`), '') is null or lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)) in ('nan', '') 
            then 'Sin información'
        when lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)) in ('n/a', 'no aplica') 
            then 'No aplica / Sin experiencia'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'¿otro\?|otra$|^otro$') 
            then 'Otro / Por clasificar'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'comercio|venta|comercial|tienda|cajer|impulsador|recaudo|caja|retail|cliente|papeler[íi]a') 
            then 'Comercio y Ventas'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'administra|secretari|recepci|digitador|archivo|archivista|facturaci|documentaci|asistente|reclutamiento|informaci|investigaci') 
            then 'Servicios Administrativos y Oficina'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'alimento|bebida|comida|helader|restaurante|ec[óo]nomo|alimentaci') 
            then 'Alimentos y Gastronomía'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'manufactur|producci|operari|operativ|metalmec|carpinter|empaque|icopor') 
            then 'Industria y Manufactura'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'contact center|call center|bpo|teleoperad') 
            then 'Contact Center y BPO'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'domestico|doméstico|limpieza|aseador|conserje|jardiner|servicios generales') 
            then 'Servicios Generales y Limpieza'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'transporte|logistic|logístic|almacen|almacén|bodega|conductor|mensajer') 
            then 'Transporte y Logística'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'financier|finanza|contab|auditor|credit|crédit|tesorer|poliza|cobranza') 
            then 'Finanzas y Contabilidad'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'salud|farmac|medicamento|hospital|droger|laborat') 
            then 'Salud y Farmacia'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'textil|confecci|moda|prenda|tapete') 
            then 'Textil y Confección'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'tecnolog|software|sofware|sistema|telecomunicac|tic|soporte') 
            then 'Tecnología y Telecomunicaciones'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'seguridad|vigilanc') 
            then 'Seguridad y Vigilancia'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'arte|diseño|diseñ|comunicaci|publicidad') 
            then 'Artes, Diseño y Comunicación'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'belleza|estilista|esteticista|cosmetic') 
            then 'Belleza y Cuidado Personal'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'educaci|social|psicolog|antropolog|infancia|empleabilidad|cuidador|sena') 
            then 'Educación y Social'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'agropecuari|agricola|agrícola|verde|ambiental|flor') 
            then 'Agropecuario y Ambiental'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'construcci|mantenimiento|reparaci|mecanic|mecánic|repuesto|ingenier') 
            then 'Construcción y Mantenimiento'
        when lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)) = 'servicios temporales' 
            then 'Servicios Temporales'
        else 'Otro / Por clasificar'
    end as area_experiencia_normalizada,
    trim(`Tiempo_de_experiencia_Laboral`) as tiempo_de_experiencia_laboral,
    lower(trim(`Localidad`)) as localidad,
    lower(trim(`Actitud_y_disposici_n`)) as actitud_y_disposici_n,
    lower(trim(`actualmente_cu_l_es_su_ocupaci_n`)) as ocupacion_actual,
    lower(trim(`Inter_s_Laboral`)) as inter_s_laboral,
    lower(trim(`Corte`)) as corte,
    safe_cast(_loaded_at as timestamp) as _loaded_at,
    safe_cast(Modified_Time as timestamp) as modified_time,
    -- Campos SAE
    lower(trim(`G_nero`)) as genero_identifica,
    lower(trim(`Tipo_de_poblaci_n`)) as tipo_de_poblacion_orientacion,
    lower(trim(`Hace_parte_de_poblaci_n_focalizada`)) as poblacion_focalizada,
    trim(`Brecha_o_barrera_identificada`) as brecha_o_barrera_identificada,
    trim(`Pregunta_de_seguridad`) as pregunta_seguridad_orientacion,
    lower(trim(`Tipo_de_discapacidad`)) as tipo_de_discapacidad,
    lower(trim(`Cuenta_con_documento_que_acredite_su_discapacidad`)) as acredita_discapacidad,
    lower(trim(`Grado_de_discapacidad`)) as grado_discapacidad,
    lower(trim(`Origen_de_la_discapacidad`)) as origen_discapacidad,
    lower(trim(`Vigencia_de_la_condici_n_de_discapacidad`)) as vigencia_discapacidad,
    trim(`Cargue_el_documento_de_discapacidad`) as doc_discapacidad_url,
    lower(trim(`Tarjeta_profesional`)) as tarjeta_profesional,
    trim(`Numero_de_tarjeta`) as numero_tarjeta_profesional,
    date(safe_cast(`Fecha_de_expedici_n_de_la_tarjeta` as timestamp)) as fecha_expedicion_tarjeta,
    trim(`Nombre_de_la_formaci_n_complementaria`) as formacion_complementaria,
    lower(trim(`Cantidad_de_horas`)) as cantidad_de_horas,
    trim(`Nombre_de_la_instituci_n_complementaria`) as institucion_formacion_complementaria,
    date(safe_cast(`Fecha_final_formaci_n_complementaria` as timestamp)) as fecha_fin_formacion_complementaria,
    lower(trim(`Certificados_por_competencias_SENA`)) as certificados_competencias_sena,
    lower(trim(`Pa_s`)) as pais_formacion_complementaria,
    trim(`Describa_el_programa_certificado_por_competencias`) as programa_certificado_competencias,
    trim(`url_certificado_sena`) as certificado_competencias_url,
    trim(`Tipo_de_capacitaci_n_o_certificaci_n`) as tipo_de_capacitacion_o_certificacion,
    trim(`Estado`) as estado_formacion_complementaria,
    trim(`Otra_rea_de_formaci_n`) as otra_area_formacion,
    trim(`Conocimientos_de_idiomas_diferentes_al_nativo`) as otros_idiomas,
    lower(trim(`Maneja_paquetes_de_Office`)) as maneja_office,
    trim(`Excel`) as excel,
    trim(`Word`) as word,
    trim(`Power_Point`) as Power_Point,
    lower(trim(`Maneja_alg_n_programa_tecnol_gico_diferente`)) as maneja_programa_tecnologico_diferente,
    trim(`Otro_programa_tecn_logico`) as otro_programa_tecnologico,
    trim(`Cargo_que_desempe_o_en_el_cargo_Cuoc`) as cargo_desempeno_cuoc,
    lower(trim(`Trabaja_actualmente_en_la_empresa`)) as trabaja_actualmente,
    lower(trim(`Cu_l_fue_el_motivo_de_retiro_de_su_empleo_anterior`)) as motivo_retiro,
    lower(trim(`Ultimo_Ingreso_Laboral`)) as ultimo_ingreso_laboral,
    lower(trim(`Situaci_n_Actual`)) as situacion_ocupacional_actual,
    lower(trim(`Cu_nto_tiempo_lleva_buscando_empleo`)) as tiempo_busqueda_empleo,
    trim(`Medios_que_usa_para_la_b_squeda_de_trabajo`) as medios_busqueda_trabajo,
    trim(`Qu_dificultades_ha_tenido_para_conseguir_empleo`) as dificultades_conseguir_empleo,
    trim(`Describa_y_ampl_e_las_dificultades_previas`) as detalle_dificultades_empleo,
    trim(`Perfil_capacidades`) as perfil_capacidades,
    trim(`Profundice_la_barrera_o_brecha_identificada`) as profundice_la_barrera_o_brecha_identificada,
    lower(trim(`Disponibilidad_para_la_jornada_laboral`)) as disponibilidad_jornada,
    lower(trim(`Posibilidad_de_trasladarse`)) as posibilidad_trasladarse,
    lower(trim(`Posibilidad_de_Viajar`)) as posibilidad_viajar,
    lower(trim(`Tiene_Inter_s_en_ofertas_de_Teletrabajo`)) as interes_teletrabajo,
    lower(trim(`Aspiraci_n_salarial`)) as aspiracion_salarial,
    trim(`Interes_Ocupacional_Cuoc`) as interes_ocupacional_cuoc,
    lower(trim(`Esta_interesado_en_realizar_practica_empresarial`)) as interes_practica_empresarial,
    lower(trim(`Clasificaci_n`)) as clasificacion_orientacion,
    trim(`Construcci_n_de_concepto_de_entrevista`) as construccion_concepto_entrevista
from {{ source('zoho_raw_ruta_mujer', 'orientaci_n_colsubsidios') }}
