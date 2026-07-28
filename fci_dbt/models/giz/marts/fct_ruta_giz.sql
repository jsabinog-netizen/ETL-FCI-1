WITH registro AS (
    SELECT 
        id,
        documento,
        primer_nombre,
        primer_apellido,
        genero,
        tipo_participante,
        ciudad,
        departamento
    FROM {{ ref('stg_registro_giz') }}
),

orientacion AS (
    -- Si existe riesgo de duplicados en orientación por errores de digitación, 
    -- puedes aplicar un QUALIFY ROW_NUMBER() OVER(PARTITION BY cedula ORDER BY fecha_orientacion DESC) = 1
    SELECT 
        documento,
        orientacion_completada,
        fecha_orientacion
    FROM {{ ref('stg_orientacion_giz') }}
),

intermediacion_agg AS (
    -- Agrupamos para evitar multiplicar filas en el JOIN principal
    SELECT 
        documento,
        COUNT(id) AS num_intermediaciones,
        MAX(fecha_intermediacion) AS ultima_fecha_intermediacion,
        MAX(empresa) AS ultima_empresa_intermediada
    FROM {{ ref('stg_intermediacion_giz') }}
    GROUP BY 1
),

colocacion AS (
    SELECT 
        documento,
        colocacion_completada,
        fecha_vinculacion,
        nombre_empresa AS empresa_colocacion,
        cargo,
        tipo_contrato,
        salario
    FROM {{ ref('stg_colocacion_giz') }}
)

SELECT
    r.documento,
    r.primer_nombre,
    r.primer_apellido,
    r.genero,
    r.tipo_participante,
    r.ciudad,
    r.departamento,

    -- Flags del embudo de ruta
    IF(o.documento IS NOT NULL, true, false) AS tiene_orientacion,
    o.fecha_orientacion,
    o.orientacion_completada,

    IF(i.documento IS NOT NULL, true, false) AS tiene_intermediacion,
    i.num_intermediaciones,
    i.ultima_fecha_intermediacion,

    IF(c.documento IS NOT NULL, true, false) AS tiene_colocacion,
    c.fecha_vinculacion,
    c.colocacion_completada,
    c.empresa_colocacion,
    c.cargo,
    c.tipo_contrato,
    c.salario

FROM registro r
LEFT JOIN orientacion o      ON r.documento = o.documento
LEFT JOIN intermediacion_agg i ON r.documento = i.documento
LEFT JOIN colocacion c       ON r.documento = c.documento