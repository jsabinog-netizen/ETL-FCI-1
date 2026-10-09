with orientacion as (
    select * from {{ ref('stg_orientaci_n_colsubsidios') }}
    qualify row_number() over (
        partition by documento
        order by fecha_de_orientaci_n desc nulls last, modified_time desc nulls last, id desc
    ) = 1
), psicosocial as (
    -- Psicosocial Corte 1 (v1). Los registros sin corte son cascarones
    -- vacios de mujeres de Corte 2: su psicosocial vive en v2.
    select * from {{ ref('stg_psicosocial_rutam') }}
    where corte = 'corte 1'
    qualify row_number() over (
        partition by documento order by fecha_inicio_acompanamiento_sc_1 desc nulls last, 
        fecha_final_acompanamiento_sc_1 desc nulls last, modified_time desc nulls last, 
        created_time desc nulls last, id desc
    ) = 1
), psicosocial_v2 as (
    -- Psicosocial Corte 2. Una mujer de Corte 1 que sigue en Corte 2 puede
    -- tener ambos: v2 tiene prioridad en los campos descriptivos.
    select * from {{ ref('stg_psicosocial_rutam_v2') }}
    qualify row_number() over (
        partition by documento order by created_time desc nulls last, id desc
    ) = 1
), formacion as (
    select * from {{ ref('stg_formaci_n_colsubsidios') }}
    qualify row_number() over (
        partition by documento
        order by coalesce(fecha_formaci_n, fecha_curso) desc nulls last,
                 modified_time desc nulls last, id desc
    ) = 1
), formacion_agg as (
    -- Agrega ANTES del join para no romper el grano de persona.
    -- Se usa max() en vez del registro más reciente: si una mujer tiene
    -- varios registros de formación y al menos uno está completado,
    -- cuenta como completada. El CTE `formacion` (dedup) sigue sirviendo
    -- para traer atributos del último registro.
    select documento,
        count(*) as num_registros_formacion,
        max(coalesce(formaci_n_completada in ('si','sí','true'), false)) as alguna_completada
    from {{ ref('stg_formaci_n_colsubsidios') }}
    where documento is not null
    group by documento
), postvinculacion as (
    select * from {{ ref('stg_postvinculaci_n_colsub') }}
    qualify row_number() over (
        partition by documento
        order by fecha_inicio_contrato desc nulls last,
                 fecha_llamada_seguimiento desc nulls last,
                 modified_time desc nulls last, id desc
    ) = 1
), intermediacion_agg as (
    select documento, count(*) as num_intermediaciones,
        -- Un STRUCT conserva juntos los campos del mismo evento, incluso los nulos.
        array_agg(struct(id, fecha_intermediaci_n as fecha_intermediacion,
                         intermediaci_n_completada, estado, intermediador,
                         concepto_de_intermediaci_n as concepto_de_intermediacion,
                         buscar_vacante_id, nombre_vacante, nit_de_la_empresa, nombre_de_la_empresa_1)
            order by fecha_intermediaci_n desc nulls last,
                     modified_time desc nulls last, id desc limit 1)[offset(0)] as ultima
    from {{ ref('stg_intermediaci_n_ruta_m') }}
    group by documento
), colocacion as (
    select * from {{ ref('stg_colocaci_n_colsubsidios') }}
    qualify row_number() over (
        partition by documento
        order by fecha_de_vinculaci_n_laboral desc nulls last, modified_time desc nulls last, id desc
    ) = 1
), preregistro as (
    select * from {{ ref('stg_pre_registro_rutam') }}
    qualify row_number() over (
        partition by documento order by created_time desc nulls last, modified_time desc nulls last, id desc
    ) = 1
), base as (
    select r.id as inscripcion_id, r.documento,
        date(r._loaded_at) as fecha_carga_inscripcion,
        current_date('America/Bogota') as fecha_transformacion,
        r.corte,
        r.primer_nombre, r.segundo_nombre, r.primer_apellido, r.segundo_apellido,
        trim(concat(coalesce(r.primer_nombre, ''), ' ', coalesce(r.segundo_nombre, ''), ' ',
                    coalesce(r.primer_apellido, ''), ' ', coalesce(r.segundo_apellido, ''))) as nombre_completo,
        r.tipo_de_documento as tipo_documento, r.edad, r.rango_joven, r.sexo_al_nacer,
        r.nacionalidad, r.tipificaci_n_mujer as tipificacion_mujer,
        r.municipio_de_residencia1 as municipio, r.localidad,
        r.email, r.n_mero_de_celular as celular,
        r.profesional_de_registro, r.modalidad_de_atenci_n as modalidad_atencion,
        date(r.fecha_de_nacimiento) as fecha_nacimiento,
        date(r.fecha_de_registro) as fecha_inscripcion,
        date(o.fecha_de_orientaci_n) as fecha_orientacion,
        coalesce(date(p2.created_time), date(p.created_time)) as fecha_registro_psicosocial,
        -- Fecha de la primera atencion: Llamada 1 en v2, Sesion Corta 1 en v1.
        coalesce(p2.l1_fecha_inicio, p.fecha_inicio_acompanamiento_sc_1) as fecha_atencion_psicosocial,
        p.fecha_inicio_acompanamiento_sc_1 as fecha_inicio_acompanamiento_sc_1,
        p.fecha_final_acompanamiento_sc_1 as fecha_final_acompanamiento_sc_1, 
        coalesce(f.fecha_formaci_n, f.fecha_curso) as fecha_formacion,
        pv.fecha_llamada_seguimiento as fecha_postvinculacion,
        date(i.ultima.fecha_intermediacion) as fecha_intermediacion,
        date(c.fecha_de_vinculaci_n_laboral) as fecha_colocacion,
        date(pr.created_time) as fecha_preregistro,
        o.id as orientacion_id, coalesce(p2.id, p.id) as psicosocial_id,
        case when p2.id is not null then 'v2'
             when p.id  is not null then 'v1' end as psicosocial_version,
        f.id as formacion_id, pv.id as postvinculacion_id,
        i.ultima.id as intermediacion_id, c.id as colocacion_id, pr.id as preregistro_id,
        o.gestor_operativo as orientador,
        case
            when o.id is null then 'Aún no realizada la orientación'
            else coalesce(o.perfil_ocupacional, 'No diligenciado')
        end as perfil_ocupacional,
        -- v2 no registra la profesional psicosocial; se usa la orientadora que remite.
        if(p2.id is not null, p2.profesional_que_remite, p.gestor_operativo) as profesional_psicosocial,
        if(p2.id is not null,
           coalesce(p2.estado_final_del_caso, p2.estado_del_caso_llamada_1, p2.estado_del_diagnostico),
           p.estado_actual_del_proceso) as estado_psicosocial,
        coalesce(fa.num_registros_formacion, 0) as num_registros_formacion,
        coalesce(fa.alguna_completada, false) as alguna_formacion_completada,
        coalesce(i.num_intermediaciones, 0) as num_intermediaciones,
        case
            when coalesce(i.num_intermediaciones, 0) = 0 then 'No ha llegado a intermediación'
            else coalesce(i.ultima.estado, 'No diligenciado')
        end as estado_intermediacion,
        case
            when coalesce(i.num_intermediaciones, 0) = 0 then 'No ha llegado a intermediación'
            else coalesce(i.ultima.intermediador, 'No diligenciado')
        end as intermediador,
        case
            when coalesce(i.num_intermediaciones, 0) = 0 then 'No ha llegado a intermediación'
            else coalesce(i.ultima.concepto_de_intermediacion, 'No diligenciado')
        end as concepto_intermediacion,
        i.ultima.buscar_vacante_id as ultima_vacante_id,
        case
            when coalesce(i.num_intermediaciones, 0) = 0 then 'No ha llegado a intermediación'
            else coalesce(i.ultima.nombre_vacante, 'No diligenciado')
        end as ultima_vacante,
        -- ── Empresa de la última intermediación (expuesta desde el STRUCT `ultima`) ──
        case
            when coalesce(i.num_intermediaciones, 0) = 0 then 'No ha llegado a intermediación'
            else coalesce(i.ultima.nit_de_la_empresa, 'No diligenciado')
        end as nit_empresa_intermediacion,
        case
            when coalesce(i.num_intermediaciones, 0) = 0 then 'No ha llegado a intermediación'
            else coalesce(i.ultima.nombre_de_la_empresa_1, 'No diligenciado')
        end as empresa_intermediacion,
        coalesce(c.nombre_de_empresa_contratante_empleador, 'No colocada') as empresa_colocacion,
        coalesce(c.nit_de_empresa_contratante_empleador, 'No colocada') as nit_empresa_colocacion,
        coalesce(c.cargo_en_la_empresa, 'No colocada') as cargo,
        coalesce(c.tipo_de_contrato, 'No colocada') as tipo_contrato,
        coalesce(cast(c.salario_despu_s_de_la_colocaci_n as string), 'No colocada') as salario,
        -- ── Grupos poblacionales: campo ya parseado en el staging ──
        r.grupos_poblacionales,

        -- ── Campos de Orientación agregados para replicar vw_fact_Colsubsidio ──
        case
            when o.id is null then 'Aún no realizada la orientación'
            else coalesce(o.concepto_de_orientaci_n_colsubsidio, o.concepto_de_orientaci_n, 'No diligenciado')
        end as concepto_de_orientaci_n,
        case
            when o.id is null then 'Aún no realizada la orientación'
            else coalesce(o.inter_s_laboral, 'No diligenciado')
        end as inter_s_laboral,
        coalesce(o.modalidad_orientacion, 'Sin información') as modalidad_orientacion,
        coalesce(o.ocupacion_actual, 'Sin información') as ocupacion_actual,
        coalesce(o.area_experiencia, 'No aplica / Sin experiencia') as area_experiencia,
        coalesce(o.area_experiencia_normalizada, 'No aplica / Sin experiencia') as area_experiencia_normalizada,
        coalesce(o.area_experiencia_2, 'No aplica / Sin experiencia') as area_experiencia_2,
        coalesce(o.tiempo_de_experiencia_laboral, 'Sin información') as tiempo_de_experiencia_laboral,
        coalesce(o.tiempo_busqueda_empleo, 'Sin información') as tiempo_busqueda_empleo,
        coalesce(o.brecha_o_barrera_identificada, 'Sin información') as brecha_o_barrera_identificada,
        coalesce(o.profundice_la_barrera_o_brecha_identificada, 'Sin información') as profundice_la_barrera_o_brecha_identificada,

        -- ── Campos de Psicosocial agregados para replicar vw_fact_Colsubsidio ──
        coalesce(p2.barrera_1, p.seleccione_el_tipo_de_barrera, 'Sin información') as seleccione_el_tipo_de_barrera,
        coalesce(p2.barrera_2, p.seleccione_el_tipo_de_barrera_2, 'Sin información') as seleccione_el_tipo_de_barrera_2,
        coalesce(p2.barrera_3, p.seleccione_el_tipo_de_barrera_3, 'Sin información') as seleccione_el_tipo_de_barrera_3,
        -- Evolucion solo existe en v1.
        coalesce(if(p2.id is null, p.evoluci_n, null), 'Sin evolución registrada') as evoluci_n,

        -- ── Campos de Inscripción agregados para replicar vw_fact_Colsubsidio ──
        r.estrato,
        r.direcci_n_de_residencia,
        r.naturaleza_del_estrato_socioecon_mico,
        r.municipio_de_nacimiento,
        r.departamento_de_nacimiento,
        r.ultimo_nivel_educativo_alcanzado,
        r.nivel_educativo_normalizado,
        coalesce(r.tipo_de_poblacion, o.tipo_de_poblacion_orientacion, 'Sin información') as tipo_de_poblacion,
        r.tipo_de_poblacion_subsidio,
        r.pregunta_de_seguridad,
        r.respuesta_pregunta_seguridad,
        case
            when lower(trim(coalesce(r.tiene_clasificacion_sisben, ''))) in ('no', 'false') then 'No aplica'
            when r.seleccione_nivel_de_sisb_n is null or trim(r.seleccione_nivel_de_sisb_n) = '' then 'Sin información'
            else r.seleccione_nivel_de_sisb_n
        end as seleccione_nivel_de_sisb_n,
        r.tiene_alguna_de_estas_responsabilidades_de_cuidado,
        r.estado_civil,
        r.tiene_hijos,
        coalesce(nullif(trim(r.sede), ''), 'Sin diligenciar') as sede,
        r.validacion_habilitante,

        -- ── Campos Habilitantes SAE (Power BI) ──
        r.orientacion_sexual,
        o.genero_identifica,
        r.libreta_militar,
        r.categoria_licencia_carro as licencia,
        r.propiedad_medio_transporte as vehiculo,
        r.etnia,
        r.es_jefe_hogar,
        r.personas_a_cargo,
        r.ha_recibido_subsidio_gobierno,
        r.tipo_de_discapacidad,
        r.cuenta_con_documento_discapacidad,
        r.autoriza_uso_datos_personales,
        r.autoriza_cambio_prestador,

        coalesce(r.inscripci_n_completada in ('si', 'sí', 'true'), false) as inscrita,
        coalesce(o.orientaci_n_sociocupacion_completada in ('si', 'sí', 'true'), false) as orientada,
        -- OR: quien completo en Corte 1 no lo pierde al pasar a Corte 2.
        coalesce(p.acompa_amiento_psicosocial_completado in ('si', 'sí', 'true'), false)
            or coalesce(p2.psicosocial_completada, false) as psicosocial,
        coalesce(fa.alguna_completada, false) as formada,
        pv.permanencia_seguimiento is not null as postvinculada,
        coalesce(i.ultima.intermediaci_n_completada in ('si', 'sí', 'true'), false) as intermediada,
        c.fecha_de_vinculaci_n_laboral is not null as colocada
    from {{ ref('stg_inscripci_n_colsubsidios') }} r
    left join orientacion o on r.documento = o.documento
    left join psicosocial p on r.documento = p.documento
    left join psicosocial_v2 p2 on r.documento = p2.documento
    left join formacion f on r.documento = f.documento
    left join formacion_agg fa on r.documento = fa.documento
    left join postvinculacion pv on r.documento = pv.documento
    left join intermediacion_agg i on r.documento = i.documento
    left join colocacion c on r.documento = c.documento
    left join preregistro pr on r.documento = pr.documento
    where r.documento is not null
)
select *,
    -- Puerta de entrada al programa. Hay mujeres que se inscriben sin
    -- pasar por el formulario de preregistro (registro directo hecho
    -- por el equipo, presencial o virtual).
    preregistro_id is not null as tuvo_preregistro,
    case when preregistro_id is not null then 'Con preregistro'
         else 'Registro directo' end as via_de_ingreso,
    -- Estado de formación con tres valores. 'Sin iniciar' solo puede
    -- calcularse acá: si la mujer no tiene registro de formación, no
    -- existe en fct_formacion_rm y su ausencia es el dato.
    case
        when num_registros_formacion = 0    then 'Sin iniciar'
        when alguna_formacion_completada    then 'Completada'
        else                                     'Pendiente'
    end as estado_formacion_mujer,
    -- Rango etario para la pirámide del dashboard. El prefijo numérico
    -- garantiza el orden correcto en los ejes de Power BI sin tener que
    -- configurar "Ordenar por columna".
    case
        when edad is null then '7. Sin dato'
        when edad < 18 then '1. Menor de 18'
        when edad between 18 and 25 then '2. 18-25'
        when edad between 26 and 35 then '3. 26-35'
        when edad between 36 and 45 then '4. 36-45'
        when edad between 46 and 55 then '5. 46-55'
        else '6. 56 o más'
    end as rango_etario,

    -- ── Flags Sí/No para segmentadores rápidos de Power BI ──
    case when es_jefe_hogar in ('si', 'sí', 'true') then 'Sí' else 'No' end as es_jefa_hogar_txt,
    case when tiene_alguna_de_estas_responsabilidades_de_cuidado is not null
              and tiene_alguna_de_estas_responsabilidades_de_cuidado not in ('no', 'ninguna', '')
         then 'Sí' else 'No' end as tiene_cuidado_txt,
    case when tiene_hijos in ('si', 'sí', 'true') then 'Sí' else 'No' end as tiene_hijos_txt,

    -- ── Jerarquía territorial: Bogotá (por localidades) vs Otros Municipios ──
    case
        when regexp_contains(lower(trim(municipio)), r'bogot[aá]') or localidad is not null
            then '1. Bogotá D.C.'
        else '2. Otros Municipios'
    end as region_territorial,
    case
        when regexp_contains(lower(trim(municipio)), r'bogot[aá]') or localidad is not null
            then coalesce(initcap(localidad), 'Sin localidad')
        else coalesce(initcap(municipio), 'Sin municipio')
    end as subdivision_territorial,

    -- Etapa más avanzada completada en la ruta (6 niveles; Formación es
    -- un servicio transversal, no una etapa secuencial de la ruta).
    case
        when postvinculada  then '6. Postvinculación'
        when colocada       then '5. Colocación'
        when intermediada   then '4. Intermediación'
        when psicosocial    then '3. Atención Psicosocial'
        when orientada      then '2. Orientación'
        when inscrita       then '1. Registros'
        else                     '0. Sin completar'
    end as etapa_actual,

    -- ── Cortes por etapa: cada fecha de evento determina su propio corte ──
    -- Permite a Análisis Metas filtrar inscripciones, orientaciones,
    -- intermediaciones y colocaciones por corte independientemente.
    case when fecha_inscripcion    >= '2026-09-01' then 'corte 2' else 'corte 1' end as corte_inscripcion,
    case when fecha_orientacion    >= '2026-09-01' then 'corte 2'
         when fecha_orientacion    is null         then null
         else 'corte 1' end as corte_orientacion,
    case when fecha_intermediacion >= '2026-09-01' then 'corte 2'
         when fecha_intermediacion is null         then null
         else 'corte 1' end as corte_intermediacion,
    case when fecha_colocacion     >= '2026-09-01' then 'corte 2'
         when fecha_colocacion     is null         then null
         else 'corte 1' end as corte_colocacion,
    -- El corte psicosocial lo define el modulo: v1 = Corte 1, v2 = Corte 2.
    case psicosocial_version
        when 'v2' then 'corte 2'
        when 'v1' then 'corte 1'
    end as corte_psicosocial,

    date_diff(fecha_atencion_psicosocial, fecha_inscripcion, day) as dias_inscripcion_a_psicosocial,
    case when fecha_orientacion >= fecha_inscripcion
         then date_diff(fecha_orientacion, fecha_inscripcion, day) end as dias_inscripcion_a_orientacion,
    case when fecha_intermediacion >= fecha_orientacion
         then date_diff(fecha_intermediacion, fecha_orientacion, day) end as dias_orientacion_a_intermediacion,
    date_diff(fecha_colocacion, fecha_inscripcion, day) as dias_inscripcion_a_colocacion,

    case when inscrita then 'Sí' else 'No' end as tiene_inscripcion,
    case when orientada then 'Sí' else 'No' end as tiene_orientacion,
    case when psicosocial then 'Sí' else 'No' end as tiene_psicosocial,
    case when formada then 'Sí' else 'No' end as tiene_formacion,
    case when postvinculada then 'Sí' else 'No' end as tiene_postvinculacion,
    case when intermediada then 'Sí' else 'No' end as tiene_intermediacion,
    case when colocada then 'Sí' else 'No' end as tiene_colocacion
from base