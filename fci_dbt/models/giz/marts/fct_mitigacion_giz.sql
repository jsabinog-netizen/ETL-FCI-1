with mitigacion as (
    select *
    from {{ ref('stg_mitigacion_giz') }}
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

fct_mitigacion as (
    select
        -- identificación
        m.id,
        m.documento,
        m.primer_nombre,
        m.primer_apellido,

        -- demográficos
        r.genero,
        r.tipo_participante,
        r.departamento,
        r.ciudad,

        -- mitigación
        m.tipo_mitigacion,
        m.es_micromitigacion,
        m.estado_mitigacion,
        m.enfrenta_barrera,
        m.tipo_barrera,
        m.servicio_recibido,
        m.valor_recibido,
        m.encargado_mitigacion,

        -- fechas
        m.fecha_mitigacion,
        m.modified_time

    from mitigacion m
    left join registro r on m.documento = r.documento
)

select * from fct_mitigacion

