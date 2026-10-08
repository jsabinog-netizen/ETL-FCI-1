-- fct_registro_sae_rm: Consolidado de información SAE (Servicio Público de Empleo)
-- Fuente exclusiva: participantes registradas en módulos post-registro de Ruta Mujer
-- (Inscripción Colsubsidios, Orientación Colsubsidios, Psicosocial y Formación).
-- Contiene las llaves/metadatos y los 95 campos exactos del modelo oficial SAE.

with inscripcion as (
    select * from {{ ref('stg_inscripci_n_colsubsidios') }}
),
orientacion as (
    select * from {{ ref('stg_orientaci_n_colsubsidios') }}
    qualify row_number() over (
        partition by documento
        order by fecha_de_orientaci_n desc nulls last,
                 modified_time desc nulls last, id desc
    ) = 1
),
psicosocial as (
    select * from {{ ref('stg_psicosocial_rutam') }}
    qualify row_number() over (
        partition by documento
        order by created_time desc nulls last,
                 modified_time desc nulls last, id desc
    ) = 1
)

select
    -- ── LLAVES Y METADATOS ──
    r.id as inscripcion_id,
    o.id as orientacion_id,
    p.id as psicosocial_id,
    r.corte,
    r.validacion_habilitante,
    r.fecha_de_registro as fecha_inscripcion,
    o.fecha_de_orientaci_n as fecha_orientacion,
    date(p.created_time) as fecha_psicosocial,

    -- ── 1. INFORMACIÓN GENERAL ──
    r.tipo_de_documento,
    r.documento as numero_de_documento,
    r.email as correo_electronico,
    r.primer_nombre,
    r.segundo_nombre,
    r.primer_apellido,
    r.segundo_apellido,
    trim(concat(coalesce(r.primer_nombre, ''), ' ', coalesce(r.segundo_nombre, ''), ' ',
                coalesce(r.primer_apellido, ''), ' ', coalesce(r.segundo_apellido, ''))) as nombre_completo,
    r.fecha_de_nacimiento,
    r.edad,
    r.rango_joven,
    'Colombia' as pais_de_nacimiento,
    r.departamento_de_nacimiento,
    r.municipio_de_nacimiento,
    r.nacionalidad,
    'Colombia' as pais_de_residencia,
    'Bogotá D.C.' as departamento_de_residencia,
    r.municipio_de_residencia1 as municipio_de_residencia,
    coalesce(o.localidad, r.localidad) as localidades,
    r.estrato as estrato_socioeconomico,
    r.naturaleza_del_estrato_socioecon_mico,
    r.barrio as barrio_de_residencia,
    r.direcci_n_de_residencia as direccion_de_residencia,
    coalesce(r.n_mero_de_celular, o.n_mero_de_celular_principal) as celular,
    coalesce(r.tipo_de_poblacion, o.tipo_de_poblacion_orientacion) as tipo_de_poblacion,
    r.tipo_de_poblacion_subsidio,
    r.modalidad_de_atenci_n as modalidad_de_atencion,
    r.libreta_militar,
    case
        when r.categoria_licencia_carro is not null and lower(trim(r.categoria_licencia_carro)) not in ('no aplica', 'none', '')
             and r.categoria_licencia_moto is not null and lower(trim(r.categoria_licencia_moto)) not in ('no aplica', 'none', '')
            then concat(r.categoria_licencia_carro, ', ', r.categoria_licencia_moto)
        when r.categoria_licencia_carro is not null and lower(trim(r.categoria_licencia_carro)) not in ('no aplica', 'none', '')
            then r.categoria_licencia_carro
        when r.categoria_licencia_moto is not null and lower(trim(r.categoria_licencia_moto)) not in ('no aplica', 'none', '')
            then r.categoria_licencia_moto
        else 'No aplica'
    end as licencia_conduccion,
    case
        when r.categoria_licencia_carro is not null and lower(trim(r.categoria_licencia_carro)) not in ('no aplica', 'none', '')
             and r.categoria_licencia_moto is not null and lower(trim(r.categoria_licencia_moto)) not in ('no aplica', 'none', '')
            then concat(r.categoria_licencia_carro, ', ', r.categoria_licencia_moto)
        when r.categoria_licencia_carro is not null and lower(trim(r.categoria_licencia_carro)) not in ('no aplica', 'none', '')
            then r.categoria_licencia_carro
        when r.categoria_licencia_moto is not null and lower(trim(r.categoria_licencia_moto)) not in ('no aplica', 'none', '')
            then r.categoria_licencia_moto
        else 'No aplica'
    end as licencia,
    r.propiedad_medio_transporte as vehiculo,
    case
        when r.propiedad_medio_transporte is null or lower(trim(r.propiedad_medio_transporte)) in ('ninguno', 'no', 'no aplica') then 'No aplica'
        else r.modelo_de_vehiculo
    end as modelo_carro,
    case
        when r.propiedad_medio_transporte is null or lower(trim(r.propiedad_medio_transporte)) in ('ninguno', 'no', 'no aplica') then 'No aplica'
        else r.modelo_de_vehiculo
    end as Modelo_de_vehiculo,
    coalesce(r.pregunta_de_seguridad, o.pregunta_seguridad_orientacion) as pregunta_de_seguridad,
    r.respuesta_pregunta_seguridad,
    r.sexo_al_nacer as sexo_asignado_al_nacer,
    o.genero_identifica as con_cual_genero_se_identifica,
    r.orientacion_sexual as cual_es_su_orientacion_sexual,
    r.etnia as grupo_etnico,
    r.autoriza_uso_datos_personales as autorizacion_de_tratamiento_de_datos_personales,
    r.autoriza_cambio_prestador as cambio_de_prestador,
    r.url_tratamiento_de_datos,
    r.certificado_prestador_url as url_cambio_de_prestador,

    -- ── 2. INFORMACIÓN PSICOSOCIAL Y FAMILIAR ──
    r.es_jefe_hogar as se_considera_jefe_de_hogar,
    r.personas_a_cargo as cuantas_personas_dependen_economicamente,
    r.tiene_alguna_de_estas_responsabilidades_de_cuidado as responsabilidades_de_cuidado,
    r.tiene_hijos,
    r.estado_civil,
    coalesce(r.tiene_clasificacion_sisben, case when r.seleccione_nivel_de_sisb_n is not null then 'si' else null end) as tiene_clasificacion_de_sisben,
    case
        when lower(trim(coalesce(r.tiene_clasificacion_sisben, ''))) in ('no', 'false') then 'No aplica'
        when r.seleccione_nivel_de_sisb_n is null or trim(r.seleccione_nivel_de_sisb_n) = '' then 'Sin información'
        else r.seleccione_nivel_de_sisb_n
    end as nivel_sisben,
    r.ha_recibido_subsidio_gobierno as ha_recibido_algun_subsidio_del_gobierno,
    case
        when coalesce(r.tipo_de_discapacidad, o.tipo_de_discapacidad) is null
             or lower(trim(coalesce(r.tipo_de_discapacidad, o.tipo_de_discapacidad))) in ('none', 'ninguna', 'no aplica', 'no', 'nan', '')
        then 'no'
        else 'si'
    end as tiene_discapacidad,
    case
        when coalesce(r.tipo_de_discapacidad, o.tipo_de_discapacidad) is null
             or lower(trim(coalesce(r.tipo_de_discapacidad, o.tipo_de_discapacidad))) in ('none', 'ninguna', 'no aplica', 'no', 'nan', '')
        then 'No aplica'
        else coalesce(nullif(trim(r.tipo_de_discapacidad), ''), 'No diligenciado')
    end as tipo_de_discapacidad,
    case
        when coalesce(r.tipo_de_discapacidad, o.tipo_de_discapacidad) is null
             or lower(trim(coalesce(r.tipo_de_discapacidad, o.tipo_de_discapacidad))) in ('none', 'ninguna', 'no aplica', 'no', 'nan', '')
        then 'No aplica'
        else coalesce(nullif(trim(coalesce(r.cuenta_con_documento_discapacidad, o.acredita_discapacidad)), ''), 'No diligenciado')
    end as cuenta_con_documento_discapacidad,
    case
        when coalesce(r.tipo_de_discapacidad, o.tipo_de_discapacidad) is null
             or lower(trim(coalesce(r.tipo_de_discapacidad, o.tipo_de_discapacidad))) in ('none', 'ninguna', 'no aplica', 'no', 'nan', '')
        then 'No aplica'
        else coalesce(nullif(trim(o.grado_discapacidad), ''), 'No diligenciado')
    end as grado_de_discapacidad,
    case
        when coalesce(r.tipo_de_discapacidad, o.tipo_de_discapacidad) is null
             or lower(trim(coalesce(r.tipo_de_discapacidad, o.tipo_de_discapacidad))) in ('none', 'ninguna', 'no aplica', 'no', 'nan', '')
        then 'No aplica'
        else coalesce(nullif(trim(o.origen_discapacidad), ''), 'No diligenciado')
    end as origen_de_la_discapacidad,
    case
        when coalesce(r.tipo_de_discapacidad, o.tipo_de_discapacidad) is null
             or lower(trim(coalesce(r.tipo_de_discapacidad, o.tipo_de_discapacidad))) in ('none', 'ninguna', 'no aplica', 'no', 'nan', '')
        then 'No aplica'
        else coalesce(nullif(trim(o.vigencia_discapacidad), ''), 'No diligenciado')
    end as vigencia_discapacidad,
    case
        when coalesce(r.tipo_de_discapacidad, o.tipo_de_discapacidad) is null
             or lower(trim(coalesce(r.tipo_de_discapacidad, o.tipo_de_discapacidad))) in ('none', 'ninguna', 'no aplica', 'no', 'nan', '')
        then 'No aplica'
        else coalesce(nullif(trim(r.certificado_discapacidad_url), ''), 'No diligenciado')
    end as url_de_discapacidad,
    o.poblacion_focalizada,

    -- ── 3. EDUCACIÓN Y FORMACIÓN ──
    r.ultimo_nivel_educativo_alcanzado as nivel_de_escolaridad,
    r.nivel_educativo_normalizado,
    r.estado_de_estudio as estado_formatuvo,
    r.tiene_titulo_o_certificacion,
    r.nombre_de_la_institucion as institucion_academica,
    r.pais_ultimos_estudios as pais_estudios,
    o.pais_formacion_complementaria as pais_curso,
    coalesce(r.carrera_o_curso_actual, r.rea_sector_de_formaci_n, r.otra_area_formacion, o.otra_area_formacion) as nombre_de_carrera_o_curso,
    r.tiene_titulo_o_certificacion as titulo_obtenido,
    r.titulo_homologado,
    coalesce(r.rea_sector_de_formaci_n, r.otra_area_formacion, o.otra_area_formacion) as nucleo_de_conocimiento,
    r.fecha_del_grado as fecha_fin_estudios,
    r.fecha_del_grado as fecha_fin_formacion,
    o.tarjeta_profesional,
    o.numero_tarjeta_profesional as numero_de_tarjeta,
    o.fecha_expedicion_tarjeta as fecha_de_expedicion_de_la_tarjeta,
    o.formacion_complementaria,
    o.institucion_formacion_complementaria,
    o.fecha_fin_formacion_complementaria,
    o.certificados_competencias_sena as certificados_por_competencias_sena,
    o.programa_certificado_competencias as describa_el_programa_certificado_por_competencias,
    o.certificado_competencias_url,
    r.tiene_formacion_tecnica as tiene_formacion_tecnica_especifica,
    r.cursos_ultimos_24_meses,
    o.otros_idiomas as dominio_de_segunda_lengua,
    o.maneja_office,
    r.usa_computador as usa_equipo_de_computo_u_otros_dispositivos_tecnologicos,
    r.utiliza_internet,
    o.cantidad_de_horas,
    o.tipo_de_capacitacion_o_certificacion,
    o.estado_formacion_complementaria,
    nullif(array_to_string([
        case when o.excel is not null and lower(trim(o.excel)) not in ('ninguno', 'ninguna', 'no', 'no aplica', 'nan', '') then 'Excel' end,
        case when o.word is not null and lower(trim(o.word)) not in ('ninguno', 'ninguna', 'no', 'no aplica', 'nan', '') then 'Word' end,
        case when lower(trim(o.maneja_office)) in ('si', 'true') then 'Paquete Office' end,
        case when lower(trim(o.Power_Point)) not in ('ninguno', 'ninguna', 'no', 'no aplica', 'nan', '') then 'Power point' end,
        case when lower(trim(o.maneja_programa_tecnologico_diferente)) in ('si', 'true')
                  and o.otro_programa_tecnologico is not null
                  and lower(trim(o.otro_programa_tecnologico)) not in ('no aplica', 'ninguno', 'ninguna', 'no', 'nan', '')
             then trim(o.otro_programa_tecnologico) end
    ], ', '), '') as programas_que_maneja,

    -- ── 4. EXPERIENCIA LABORAL ──
    coalesce(r.nombre_empresa_experiencia, 'No aplica / Sin experiencia') as empresa,
    coalesce(r.sector_ultimo_empleo, 'No aplica / Sin experiencia') as industria,
    coalesce(o.area_experiencia, 'No aplica / Sin experiencia') as area_experiencia_orientacion,
    coalesce(o.area_experiencia_normalizada, 'No aplica / Sin experiencia') as area_experiencia_normalizada,
    coalesce(o.cargo_desempeno_cuoc, 'No aplica / Sin experiencia') as cargo,
    coalesce(r.tipo_vinculacion_experiencia, 'No aplica / Sin experiencia') as tipo_de_experiencia,
    r.fecha_inicio_experiencia as fecha_de_ingreso,
    r.fecha_fin_experiencia as fecha_de_retiro,
    coalesce(o.tiempo_de_experiencia_laboral, 'Sin información') as tiempo_de_experiencia_laboral,
    r.pais_empresa_experiencia,
    r.pais_empresa_experiencia as pais_experiencia,
    coalesce(r.funciones_logros_experiencia, 'No aplica / Sin experiencia') as descripcion_de_la_experiencia_laboral,
    coalesce(o.trabaja_actualmente, 'no') as trabaja_actualmente_en_la_empresa,
    coalesce(o.motivo_retiro, 'Sin información') as razon_retiro_empleo_anterior,
    coalesce(o.ultimo_ingreso_laboral, 'Sin información') as ultimo_ingreso_laboral,

    -- ── 5. SITUACIÓN OCUPACIONAL Y EXPECTATIVAS ──
    coalesce(o.situacion_ocupacional_actual, o.ocupacion_actual, 'Sin información') as situacion_ocupacional_actual,
    coalesce(o.tiempo_busqueda_empleo, 'Sin información') as tiempo_de_cesion_laboral,
    coalesce(o.medios_busqueda_trabajo, 'Sin información') as medios_que_usa_para_buscar_trabajo,
    coalesce(o.dificultades_conseguir_empleo, 'Sin información') as dificultades_conseguir_empleo,
    coalesce(o.detalle_dificultades_empleo, 'Sin información') as profundice_dificultades_empleo,
    coalesce(o.perfil_capacidades, 'Sin información') as perfil_capacidades,
    coalesce(o.disponibilidad_jornada, 'Sin información') as tiempo_para_trabajar,
    coalesce(o.posibilidad_trasladarse, 'Sin información') as tiene_posibilidad_de_trasladarse,
    coalesce(o.posibilidad_viajar, 'Sin información') as tiene_posibilidad_para_viajar,
    coalesce(o.interes_teletrabajo, 'Sin información') as le_interesa_el_teletrabajo,
    coalesce(o.aspiracion_salarial, 'Sin información') as aspiracion_salarial,
    coalesce(o.interes_ocupacional_cuoc, 'Sin información') as cargo_de_interes,
    coalesce(o.interes_practica_empresarial, 'Sin información') as interes_practica_empresarial,
    coalesce(o.clasificacion_orientacion, 'Sin información') as clasificacion_orientacion,
    case
        when o.id is null then 'Aún no realizada la orientación'
        else coalesce(o.concepto_de_orientaci_n_colsubsidio, o.concepto_de_orientaci_n, 'No diligenciado')
    end as concepto_de_orientaci_n,
    coalesce(o.modalidad_orientacion, 'Sin información') as modalidad_orientacion,

    -- ── RESULTADO SOCIO-OCUPACIONAL / BARRERAS ──
    coalesce(o.brecha_o_barrera_identificada, 'Sin información') as brecha_o_barrera_identificada,
    coalesce(o.profundice_la_barrera_o_brecha_identificada, 'Sin información') as profundice_la_barrera_o_brecha_identificada,
    coalesce(o.construccion_concepto_entrevista, 'Sin información') as contruccion_de_concepto_de_entrevista

from inscripcion r
left join orientacion o on r.documento = o.documento
left join psicosocial p on r.documento = p.documento
where r.documento is not null
