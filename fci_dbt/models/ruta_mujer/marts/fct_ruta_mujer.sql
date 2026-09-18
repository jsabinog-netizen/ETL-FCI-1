with orientacion as (
    select * from {{ ref('stg_orientaci_n_colsubsidios') }}
    qualify row_number() over (
        partition by documento
        order by fecha_de_orientaci_n desc nulls last, modified_time desc nulls last, id desc
    ) = 1
), psicosocial as (
    select * from {{ ref('stg_psicosocial_rutam') }}
    qualify row_number() over (
        partition by documento order by modified_time desc nulls last, created_time desc nulls last, id desc
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
        r.corte,
        r.primer_nombre, r.segundo_nombre, r.primer_apellido, r.segundo_apellido,
        trim(concat(coalesce(r.primer_nombre, ''), ' ', coalesce(r.segundo_nombre, ''), ' ',
                    coalesce(r.primer_apellido, ''), ' ', coalesce(r.segundo_apellido, ''))) as nombre_completo,
        r.tipo_de_documento as tipo_documento, r.edad, r.sexo_al_nacer,
        r.nacionalidad, r.tipificaci_n_mujer as tipificacion_mujer,
        r.municipio_de_residencia1 as municipio, r.localidad,
        r.email, r.n_mero_de_celular as celular,
        r.profesional_de_registro, r.modalidad_de_atenci_n as modalidad_atencion,
        date(r.fecha_de_nacimiento) as fecha_nacimiento,
        date(r.fecha_de_registro) as fecha_inscripcion,
        date(o.fecha_de_orientaci_n) as fecha_orientacion,
        date(p.created_time) as fecha_registro_psicosocial,
        coalesce(f.fecha_formaci_n, f.fecha_curso) as fecha_formacion,
        pv.fecha_llamada_seguimiento as fecha_postvinculacion,
        date(i.ultima.fecha_intermediacion) as fecha_intermediacion,
        date(c.fecha_de_vinculaci_n_laboral) as fecha_colocacion,
        date(pr.created_time) as fecha_preregistro,
        o.id as orientacion_id, p.id as psicosocial_id,
        f.id as formacion_id, pv.id as postvinculacion_id,
        i.ultima.id as intermediacion_id, c.id as colocacion_id, pr.id as preregistro_id,
        o.gestor_operativo as orientador, o.perfil_ocupacional,
        p.gestor_operativo as profesional_psicosocial,
        p.estado_actual_del_proceso as estado_psicosocial,
        coalesce(fa.num_registros_formacion, 0) as num_registros_formacion,
        coalesce(fa.alguna_completada, false) as alguna_formacion_completada,
        coalesce(i.num_intermediaciones, 0) as num_intermediaciones,
        i.ultima.estado as estado_intermediacion, i.ultima.intermediador,
        i.ultima.concepto_de_intermediacion as concepto_intermediacion,
        i.ultima.buscar_vacante_id as ultima_vacante_id,
        i.ultima.nombre_vacante as ultima_vacante,
        -- ── Empresa de la última intermediación (expuesta desde el STRUCT `ultima`) ──
        i.ultima.nit_de_la_empresa as nit_empresa_intermediacion,
        i.ultima.nombre_de_la_empresa_1 as empresa_intermediacion,
        c.nombre_de_empresa_contratante_empleador as empresa_colocacion,
        c.nit_de_empresa_contratante_empleador as nit_empresa_colocacion,
        c.cargo_en_la_empresa as cargo, c.tipo_de_contrato as tipo_contrato,
        c.salario_despu_s_de_la_colocaci_n as salario,
        -- ── Grupos poblacionales: campo ya parseado en el staging ──
        r.grupos_poblacionales,

        -- ── Campos de Orientación agregados para replicar vw_fact_Colsubsidio ──
        o.concepto_de_orientaci_n,
        o.inter_s_laboral,
        o.modalidad_orientacion,
        o.ocupacion_actual,
        o.area_experiencia,
        o.tiempo_de_experiencia_laboral,

        -- ── Campos de Psicosocial agregados para replicar vw_fact_Colsubsidio ──
        p.seleccione_el_tipo_de_barrera,
        p.seleccione_el_tipo_de_barrera_2,
        p.seleccione_el_tipo_de_barrera_3,
        p.evoluci_n,

        -- ── Campos de Inscripción agregados para replicar vw_fact_Colsubsidio ──
        r.estrato,
        r.direcci_n_de_residencia,
        r.naturaleza_del_estrato_socioecon_mico,
        r.municipio_de_nacimiento,
        r.departamento_de_nacimiento,
        r.ultimo_nivel_educativo_alcanzado,
        r.nivel_educativo_normalizado,
        r.tipo_de_poblaci_n,
        r.pregunta_de_seguridad,
        r.respuesta_pregunta_seguridad,
        r.seleccione_nivel_de_sisb_n,
        r.tiene_alguna_de_estas_responsabilidades_de_cuidado,

        coalesce(r.inscripci_n_completada in ('si', 'sí', 'true'), false) as inscrita,
        coalesce(o.orientaci_n_sociocupacion_completada in ('si', 'sí', 'true'), false) as orientada,
        coalesce(p.acompa_amiento_psicosocial_completado in ('si', 'sí', 'true'), false) as psicosocial,
        coalesce(fa.alguna_completada, false) as formada,
        pv.fecha_llamada_seguimiento is not null as postvinculada,
        coalesce(i.ultima.intermediaci_n_completada in ('si', 'sí', 'true'), false) as intermediada,
        c.fecha_de_vinculaci_n_laboral is not null as colocada
    from {{ ref('stg_inscripci_n_colsubsidios') }} r
    left join orientacion o on r.documento = o.documento
    left join psicosocial p on r.documento = p.documento
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

    date_diff(fecha_colocacion, fecha_inscripcion, day) as dias_inscripcion_a_colocacion,

    case when inscrita then 'Sí' else 'No' end as tiene_inscripcion,
    case when orientada then 'Sí' else 'No' end as tiene_orientacion,
    case when psicosocial then 'Sí' else 'No' end as tiene_psicosocial,
    case when formada then 'Sí' else 'No' end as tiene_formacion,
    case when postvinculada then 'Sí' else 'No' end as tiene_postvinculacion,
    case when intermediada then 'Sí' else 'No' end as tiene_intermediacion,
    case when colocada then 'Sí' else 'No' end as tiene_colocacion
from base