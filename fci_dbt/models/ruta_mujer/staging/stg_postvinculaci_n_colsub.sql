-- Grano: un registro de seguimiento post-vinculación por id de Zoho.
--
-- El módulo fue reconstruido en Zoho el 2026-09-09 implementando el
-- requerimiento de post-vinculación. Dos api_names tienen anomalías
-- que se usan tal cual: Peramencia_de_seguimiento (falta la "n" de
-- Permanencia) y Tipo_de_novedad1 (sufijo "1").
select
    id,
    nullif(trim(Name), '') as documento,
    lower(trim(`Corte`)) as corte,

    -- Identificación
    trim(`Primer_nombre`) as primer_nombre,
    trim(`Segundo_nombre`) as segundo_nombre,
    trim(`Primer_apellido`) as primer_apellido,
    lower(trim(`Tipo_de_documento`)) as tipo_de_documento,
    lower(trim(`Sexo_al_nacer`)) as sexo_al_nacer,
    safe_cast(`Edad` as int64) as edad,
    lower(trim(`Estado_civil`)) as estado_civil,
    trim(`N_mero_de_Celular_principal`) as celular,
    lower(trim(`Nivel_de_Escolaridad`)) as nivel_de_escolaridad,
    lower(trim(`Ciudad_Municipio`)) as ciudad_municipio,
    lower(trim(`Departamento`)) as departamento,
    date(safe_cast(`Fecha_de_Registro` as timestamp)) as fecha_de_registro,

    -- Lookups
    json_value(`Id_participante`, '$.id') as id_participante,
    json_value(`Id_participante`, '$.name') as id_participante_nombre,
    json_value(`Id_Vacante`, '$.id') as id_vacante,
    json_value(`Id_Vacante`, '$.name') as id_vacante_nombre,

    -- Contrato y empresa
    trim(coalesce(json_value(`Empresa`, '$.name'), json_value(`Empresa`, '$'))) as empresa,
    lower(trim(`Sector`)) as sector,
    date(safe_cast(`Fecha_de_inicio_de_contrato` as timestamp)) as fecha_inicio_contrato,

    -- Seguimiento
    lower(trim(`Tiene_postvinculaci_n`)) as tiene_postvinculacion,
    date(safe_cast(`Fecha_llamada_de_seguimiento` as timestamp)) as fecha_llamada_seguimiento,
    safe_cast(`D_as_faltantes` as int64) as dias_faltantes_zoho,
    lower(trim(`Estado_de_Post`)) as estado_post_zoho,
    lower(trim(`Estado_de_caso`)) as estado_caso,
    lower(trim(`Peramencia_de_seguimiento`)) as permanencia_seguimiento,
    trim(`Resultado_llamada`) as resultado_llamada,

    -- Novedad y remisión
    lower(trim(`Tipo_de_novedad1`)) as tipo_novedad,
    trim(`Otra_novedad`) as otra_novedad,
    lower(trim(`Motivo_de_retiro`)) as motivo_retiro,
    trim(`Remitido_a`) as remitido_a,
    date(safe_cast(`Fecha_de_remision` as timestamp)) as fecha_remision,
    trim(`Observaciones`) as observaciones,

    -- Auditoría
    safe_cast(_loaded_at as timestamp) as _loaded_at,
    safe_cast(`Created_Time` as timestamp) as created_time,
    safe_cast(`Modified_Time` as timestamp) as modified_time
from {{ source('zoho_raw_ruta_mujer', 'postvinculaci_n_colsub') }}
