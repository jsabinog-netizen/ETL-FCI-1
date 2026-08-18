with formacion as (
    select *
    from {{ ref('stg_formacion_giz') }}
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

final as (
    select
        -- identificación
        f.documento,

        -- demográficos
        r.genero,
        r.tipo_participante,
        r.departamento,
        r.ciudad,

        -- formación
        f.nombre_curso,
        f.gestor_formacion,
        f.formacion_completada,

        -- calidad diplomas
        f.validacion_diploma_tecnico,
        f.validacion_diploma_habilidades,

        -- flags archivos
        f.tiene_diploma_tecnico,
        f.tiene_diploma_blando,
        f.tiene_certificado_bancario,

        -- flag derivado
        case
            when f.validacion_diploma_tecnico    = 'aprobado'
            and f.validacion_diploma_habilidades = 'aprobado'
            then 'si'
            else 'no'
        end as calidad_completa,

        -- plumbing
        f.modified_time

    from formacion f
    left join registro r on f.documento = r.documento
)

select * from final