with postvinculacion as (
    select *
    from {{ ref('stg_postvinculacion_giz') }}
    qualify row_number() over (
        partition by documento
        order by modified_time desc
    ) = 1
),

registro as (
    select
        documento,
        genero,
        tipo_participante,
        departamento,
        ciudad
    from {{ ref('stg_registro_giz') }}
),

fct_postvinculacion as (
    select
        -- identificación
        p.documento,
        p.primer_nombre,
        p.primer_apellido,
        p.nit_empresa,
        p.empresa,
        p.nombre_vacante,
        p.codigo_vacante,

        -- demográficos
        r.genero,
        r.tipo_participante,
        r.departamento,
        r.ciudad,

        -- gestores
        p.gestor_s1,
        p.gestor_s2,
        p.gestor_s3,

        -- seguimientos completados
        p.seguimiento_1_completado,
        p.seguimiento_2_completado,
        p.seguimiento_3_completado,

        -- permanencia
        p.permanencia_s1,
        p.permanencia_s2,
        p.permanencia_s3,

        -- motivos terminación
        p.motivo_terminacion_s1,
        p.motivo_terminacion_s2,
        p.motivo_terminacion_s3,

        -- barreras s1
        p.enfrenta_barrera_s1,
        p.tipo_barrera_s1,
        p.servicio_barrera_s1,

        -- barreras s2
        p.enfrenta_barrera_s2,
        p.tipo_barrera_s2,
        p.servicio_barrera_s2,

        -- satisfacción
        p.satisfaccion_empresa,
        p.satisfaccion_cargo,
        p.expectativas_cumplidas,
        p.valora_empleo,

        -- flag derivado
        case
            when p.permanencia_s3 = 'activo' then 'si'
            when p.permanencia_s3 is null and p.permanencia_s2 = 'activo' then 'si'
            when p.permanencia_s3 is null and p.permanencia_s2 is null and p.permanencia_s1 = 'activo' then 'si'
            else 'no'
        end as permanece_activo,

        -- fechas
        p.fecha_colocacion,
        p.fecha_seguimiento_s1,
        p.fecha_seguimiento_s2,
        p.fecha_seguimiento_s3,
        p.fecha_terminacion_s1,
        p.fecha_terminacion_s2,
        p.fecha_terminacion_s3,

        -- plumbing
        p.modified_time

    from postvinculacion p
    left join registro r on p.documento = r.documento
)

select * from fct_postvinculacion