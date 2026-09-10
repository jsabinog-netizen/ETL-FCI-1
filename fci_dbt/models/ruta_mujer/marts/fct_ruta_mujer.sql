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
        date(i.ultima.fecha_intermediacion) as fecha_intermediacion,
        date(c.fecha_de_vinculaci_n_laboral) as fecha_colocacion,
        date(pr.created_time) as fecha_preregistro,
        o.id as orientacion_id, p.id as psicosocial_id,
        i.ultima.id as intermediacion_id, c.id as colocacion_id, pr.id as preregistro_id,
        o.gestor_operativo as orientador, o.perfil_ocupacional,
        p.gestor_operativo as profesional_psicosocial,
        p.estado_actual_del_proceso as estado_psicosocial,
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
        coalesce(i.ultima.intermediaci_n_completada in ('si', 'sí', 'true'), false) as intermediada,
        c.fecha_de_vinculaci_n_laboral is not null as colocada
    from {{ ref('stg_inscripci_n_colsubsidios') }} r
    left join orientacion o on r.documento = o.documento
    left join psicosocial p on r.documento = p.documento
    left join intermediacion_agg i on r.documento = i.documento
    left join colocacion c on r.documento = c.documento
    left join preregistro pr on r.documento = pr.documento
    where r.documento is not null
)
select *,
    case when colocada then '5. Colocada'
         when intermediada then '4. Intermediada'
         when psicosocial then '3. Psicosocial'
         when orientada then '2. Orientada'
         when inscrita then '1. Inscrita'
         else '0. Sin completar' end as etapa_actual,
    date_diff(fecha_colocacion, fecha_inscripcion, day) as dias_inscripcion_a_colocacion,

    case when inscrita then 'Sí' else 'No' end as tiene_inscripcion,
    case when orientada then 'Sí' else 'No' end as tiene_orientacion,
    case when psicosocial then 'Sí' else 'No' end as tiene_psicosocial,
    case when intermediada then 'Sí' else 'No' end as tiene_intermediacion,
    case when colocada then 'Sí' else 'No' end as tiene_colocacion
from base

-- NOTA: "Sede" (columna presente en vw_fact_Colsubsidio de C2M) NO se incluye.
-- nuevo lo requiere, definir su origen de negocio desde cero.