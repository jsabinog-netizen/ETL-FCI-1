WITH registro AS (
    SELECT 
        id,
        documento,
        archivo_documento,
        primer_nombre,
        segundo_nombre,
        primer_apellido,
        segundo_apellido,
        genero,
        tipo_participante,
        ciudad,
        departamento,
        inscripcion_completada, 
        fecha_registro,
        gestor,
        nivel_educativo,
        tipo_discapacidad,
        pais_nacimiento,
        edad,
        tipo_documento
    FROM {{ ref('stg_registro_giz') }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY documento 
        ORDER BY fecha_registro DESC NULLS LAST
    ) = 1
),

orientacion AS (
    -- Si existe riesgo de duplicados en orientación por errores de digitación, 
    -- puedes aplicar un QUALIFY ROW_NUMBER() OVER(PARTITION BY cedula ORDER BY fecha_orientacion DESC) = 1
    SELECT 
        documento,
        orientacion_completada,
        fecha_orientacion,
        orientador,
        ocupacion_actual,

        perfil_ocupacional,
        experiencia_formal,
        presenta_barreras,
        barrera_interna,
        barrera_externa,
        recomendado_vacante,
    FROM {{ ref('stg_orientacion_giz') }}
),

intermediacion_agg AS (
    SELECT 
        documento,
        COUNT(id)                                                                    AS num_intermediaciones,
        MAX(fecha_intermediacion)                                                    AS ultima_fecha_intermediacion,
        ARRAY_AGG(estado      ORDER BY fecha_intermediacion DESC LIMIT 1)[OFFSET(0)] AS estado_intermediacion,
        ARRAY_AGG(empresa     ORDER BY fecha_intermediacion DESC LIMIT 1)[OFFSET(0)] AS ultima_empresa_intermediada,
        ARRAY_AGG(intermediador ORDER BY fecha_intermediacion DESC LIMIT 1)[OFFSET(0)] AS intermediador,
        ARRAY_AGG(vacante ORDER BY fecha_intermediacion DESC LIMIT 1)[OFFSET(0)] AS ultima_vacante_intermediada,
        ARRAY_AGG(perfil_ocupacional ORDER BY fecha_intermediacion DESC LIMIT 1)[OFFSET(0)] AS ultimo_perfil_ocupasional_intermediado,
        ARRAY_AGG(estado_intermediacion_grupo ORDER BY fecha_intermediacion DESC LIMIT 1)[OFFSET(0)] AS estado_intermediacion_grupo
        -- empresa_intermediacion se elimina — es lo mismo que ultima_empresa_intermediada
    FROM {{ ref('stg_intermediacion_giz') }}
    GROUP BY documento
),

colocacion AS (
    SELECT
        documento,
        ARRAY_AGG(colocacion_completada  ORDER BY fecha_vinculacion DESC LIMIT 1)[OFFSET(0)] AS colocacion_completada,
        MAX(fecha_vinculacion)                                                               AS fecha_vinculacion,
        ARRAY_AGG(sector_empresa ORDER BY fecha_vinculacion DESC LIMIT 1)[OFFSET(0)] AS sector_empresa,
        ARRAY_AGG(certificado_laboral ORDER BY fecha_vinculacion DESC LIMIT 1)[OFFSET(0)] AS certificado_laboral,
        ARRAY_AGG(nombre_empresa ORDER BY fecha_vinculacion DESC LIMIT 1)[OFFSET(0)] AS nombre_empresa,
        ARRAY_AGG(nit_empresa ORDER BY fecha_vinculacion DESC LIMIT 1)[OFFSET(0)] AS nit_empresa_colocacion,
        ARRAY_AGG(cargo                  ORDER BY fecha_vinculacion DESC LIMIT 1)[OFFSET(0)] AS cargo,
        ARRAY_AGG(tipo_contrato          ORDER BY fecha_vinculacion DESC LIMIT 1)[OFFSET(0)] AS tipo_contrato,
        ARRAY_AGG(salario                ORDER BY fecha_vinculacion DESC LIMIT 1)[OFFSET(0)] AS salario,
        ARRAY_AGG(encargado_colocacion   ORDER BY fecha_vinculacion DESC LIMIT 1)[OFFSET(0)] AS encargado_colocacion,
        ARRAY_AGG(empleo_verde   ORDER BY fecha_vinculacion DESC LIMIT 1)[OFFSET(0)] AS empleo_verde,
        COUNT(*)                                                                               AS num_colocaciones,
    FROM {{ ref('stg_colocacion_giz') }}
    GROUP BY documento
),

mitigacion AS (
    SELECT 
        documento,
        estado_mitigacion,
        valor_recibido,
        encargado_mitigacion,
        fecha_mitigacion,
        tipo_mitigacion
    FROM {{ ref('stg_mitigacion_giz') }}
),

base as (
SELECT
    r.documento,
    r.tipo_documento,
    r.archivo_documento,
    r.primer_nombre,
    r.primer_apellido,
    r.genero,
    r.tipo_participante,
    r.ciudad,
    r.departamento,
    r.nivel_educativo,
    r.tipo_discapacidad,
    r.pais_nacimiento,
    r.edad,
    TRIM(
        CONCAT(
                COALESCE(NULLIF(r.primer_Nombre, ''), ''), ' ',
                COALESCE(NULLIF(r.segundo_Nombre, ''), ''), ' ',
                COALESCE(NULLIF(r.primer_Apellido, ''), ''), ' ',
                COALESCE(NULLIF(r.segundo_apellido, ''), '')
            )
        ) AS nombre_completo,

    -- Flags del embudo de ruta
    CASE LOWER(TRIM(r.inscripcion_completada))
        WHEN 'si' THEN 'Sí'
        WHEN 'sí' THEN 'Sí'
        WHEN 'no' THEN 'No'
        ELSE 'No'
    END AS inscripcion_completada,
    r.fecha_registro,
    r.gestor as gestor_registro,

    DATE(o.fecha_orientacion) AS fecha_orientacion,
    o.orientacion_completada AS tiene_orientacion,
    o.orientador,
    ocupacion_actual,
    perfil_ocupacional,
    experiencia_formal,
    presenta_barreras,
    barrera_interna,
    barrera_externa,
    recomendado_vacante,

    IF(i.estado_intermediacion IS NOT NULL, "Sí", "No") AS tiene_intermediacion,
    i.num_intermediaciones,
    i.ultima_fecha_intermediacion,
    i.intermediador,
    i.ultima_empresa_intermediada,
    i.ultima_vacante_intermediada,
    i.ultimo_perfil_ocupasional_intermediado,
    i.estado_intermediacion,
    i.estado_intermediacion_grupo,

    CASE LOWER(TRIM(c.colocacion_completada))
        WHEN 'si' THEN 'Sí'
        WHEN 'sí' THEN 'Sí'
        WHEN 'no' THEN 'No'
        ELSE 'No'
    END AS tiene_colocacion,
    DATE(c.fecha_vinculacion) AS fecha_colocacion,
    c.nombre_empresa,
    c.nit_empresa_colocacion,
    c.cargo,
    c.tipo_contrato,
    c.salario,
    c.encargado_colocacion,
    c.sector_empresa,
    c.certificado_laboral,
    c.empleo_verde,
    IF(c.certificado_laboral IS NOT NULL, "Sí","No") As soporte_colocacion,
    

    IF(m.tipo_mitigacion = "Pago exitoso colocación", "Sí", "No") AS mitigacion_colocacion,
    IF(m.tipo_mitigacion = "Pago exitoso Formación", "Sí", "No") AS mitigacion_formacion,
    m.estado_mitigacion,
    m.valor_recibido,
    m.encargado_mitigacion,
    m.fecha_mitigacion,
    m.tipo_mitigacion

FROM registro r
LEFT JOIN orientacion o      ON r.documento = o.documento
LEFT JOIN intermediacion_agg i ON r.documento = i.documento
LEFT JOIN colocacion c       ON r.documento = c.documento 
LEFT JOIN mitigacion m ON r.documento = m.documento
)

SELECT 
    *,
    case
        when tiene_colocacion      = 'Sí' then '4. Colocado/a'
        when tiene_intermediacion  = 'Sí' then '3. Intermediado/a'
        when tiene_orientacion     = 'Sí' then '2. Orientado/a'
        when inscripcion_completada = 'Sí' then '1. Inscrito/a'
        else '0. Sin completar'
    end as estado_ruta, 

    CASE
        WHEN Inscripcion_completada = 'Sí'
        AND tiene_orientacion      = 'Sí'
        AND tiene_intermediacion   = 'Sí'
        AND tiene_colocacion       = 'Sí'
        AND mitigacion_colocacion  = 'Sí'
        THEN 'Sí'
        ELSE 'No'
    END AS ruta_completa

FROM base