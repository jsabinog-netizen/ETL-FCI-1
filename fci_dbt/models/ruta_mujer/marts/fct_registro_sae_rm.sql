-- fct_registro_sae_rm: Consolidado de información SAE (Servicio Público de Empleo)
-- Fuente exclusiva: participantes registradas en módulos post-registro de Ruta Mujer
-- (Inscripción Colsubsidios, Orientación Colsubsidios, Psicosocial y Formación).
-- CERO dependencias de Pre_registro_RutaM.

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

    -- ── MÓDULO 1: INFORMACIÓN GENERAL Y HABILITANTES ──
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
    r.nacionalidad as pais_de_nacimiento,
    r.departamento_de_nacimiento,
    r.municipio_de_nacimiento,
    r.nacionalidad,
    'Colombia' as pais_de_residencia,
    'Bogotá D.C.' as departamento_de_residencia,
    r.municipio_de_residencia1 as municipio_de_residencia,
    coalesce(o.localidad, r.localidad) as localidad,
    r.estrato as estrato_socioeconomico,
    r.naturaleza_del_estrato_socioecon_mico,
    cast(null as string) as barrio_de_residencia,
    r.direcci_n_de_residencia as direccion_de_residencia,
    coalesce(r.n_mero_de_celular, o.n_mero_de_celular_principal) as celular,
    coalesce(r.tipo_de_poblaci_n, o.tipo_de_poblacion_orientacion) as tipo_de_poblacion,
    r.modalidad_de_atenci_n as modalidad_de_atencion,
    r.libreta_militar,
    r.categoria_licencia_carro as licencia_conduccion,
    r.propiedad_medio_transporte as vehiculo,
    cast(null as string) as modelo_carro,
    coalesce(r.pregunta_de_seguridad, o.pregunta_seguridad_orientacion) as pregunta_de_seguridad,
    r.respuesta_pregunta_seguridad,
    r.sexo_al_nacer,
    o.genero_identifica as con_cual_genero_se_identifica,
    r.orientacion_sexual as cual_es_su_orientacion_sexual,
    r.etnia,
    r.autoriza_uso_datos_personales,
    r.autoriza_cambio_prestador,

    -- ── MÓDULO 2: INFORMACIÓN PSICOSOCIAL Y FAMILIAR ──
    r.es_jefe_hogar as es_el_jefe_o_jefa_de_hogar,
    r.personas_a_cargo as cuantas_personas_dependen_economicamente,
    r.tiene_alguna_de_estas_responsabilidades_de_cuidado as responsabilidades_de_cuidado,
    r.tiene_hijos,
    r.estado_civil,
    r.seleccione_nivel_de_sisb_n as nivel_sisben,
    r.ha_recibido_subsidio_gobierno as subsidio_gobierno,
    r.tipo_de_discapacidad,
    coalesce(r.cuenta_con_documento_discapacidad, o.acredita_discapacidad) as cuenta_con_documento_discapacidad,
    o.grado_discapacidad,
    o.origen_discapacidad,
    o.vigencia_discapacidad,
    o.doc_discapacidad_url,
    o.poblacion_focalizada,
    p.seleccione_el_tipo_de_barrera as barrera_psicosocial_1,
    p.seleccione_el_tipo_de_barrera_2 as barrera_psicosocial_2,
    p.seleccione_el_tipo_de_barrera_3 as barrera_psicosocial_3,
    p.estrategia_para_la_superaci_n_de_la_barrera as estrategia_superacion_barrera_1,
    p.estrategia_para_la_superaci_n_de_la_barrera_2 as estrategia_superacion_barrera_2,
    p.estrategia_para_la_superaci_n_de_la_barrera_3 as estrategia_superacion_barrera_3,
    p.evoluci_n as evolucion_psicosocial,

    -- ── MÓDULO 3: EDUCACIÓN Y FORMACIÓN ──
    r.ultimo_nivel_educativo_alcanzado,
    r.nivel_educativo_normalizado,
    r.estado_de_estudio,
    r.tiene_titulo_o_certificacion,
    r.nombre_de_la_institucion,
    r.pais_ultimos_estudios,
    r.carrera_o_curso_actual as nombre_de_carrera_o_curso,
    cast(null as string) as titulo_homologado,
    o.tarjeta_profesional,
    o.numero_tarjeta_profesional,
    o.fecha_expedicion_tarjeta,
    o.formacion_complementaria,
    o.institucion_formacion_complementaria,
    o.fecha_fin_formacion_complementaria,
    o.certificados_competencias_sena,
    o.programa_certificado_competencias,
    o.certificado_competencias_url,
    r.tiene_formacion_tecnica as tiene_formacion_tecnica_especifica,
    r.cursos_ultimos_24_meses,
    o.otros_idiomas as conocimientos_idiomas_diferentes,
    o.maneja_office,
    r.usa_computador,
    r.utiliza_internet,

    -- ── MÓDULO 4: EXPERIENCIA LABORAL ──
    r.nombre_empresa_experiencia,
    r.sector_ultimo_empleo,
    o.area_experiencia as area_experiencia_orientacion,
    o.area_experiencia_normalizada,
    o.cargo_desempeno_cuoc,
    r.tipo_vinculacion_experiencia,
    r.fecha_inicio_experiencia,
    r.fecha_fin_experiencia,
    o.tiempo_de_experiencia_laboral,
    r.pais_empresa_experiencia,
    r.funciones_logros_experiencia,
    o.trabaja_actualmente,
    o.motivo_retiro,
    o.ultimo_ingreso_laboral,

    -- ── MÓDULO 5: SITUACIÓN OCUPACIONAL Y EXPECTATIVAS ──
    coalesce(o.situacion_ocupacional_actual, o.ocupacion_actual) as situacion_ocupacional_actual,
    o.tiempo_busqueda_empleo,
    o.medios_busqueda_trabajo,
    o.dificultades_conseguir_empleo,
    o.detalle_dificultades_empleo,
    o.perfil_capacidades,
    o.disponibilidad_jornada,
    o.posibilidad_trasladarse,
    o.posibilidad_viajar,
    o.interes_teletrabajo,
    o.aspiracion_salarial,
    o.interes_ocupacional_cuoc,
    o.inter_s_laboral as interes_laboral,
    o.interes_practica_empresarial,
    o.clasificacion_orientacion,
    o.concepto_de_orientaci_n,
    o.modalidad_orientacion

from inscripcion r
left join orientacion o on r.documento = o.documento
left join psicosocial p on r.documento = p.documento
where r.documento is not null
