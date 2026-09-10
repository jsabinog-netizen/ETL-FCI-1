-- Grano: una mitigación por id de Zoho.
--
-- ⚠️ El módulo tiene 0 filas en Zoho al construir este modelo.
-- Los casteos usan safe_cast para que un formato inesperado devuelva
-- NULL en vez de romper el build. Cuando lleguen los primeros
-- registros hay que re-verificar tipos, especialmente el campo de
-- valor monetario.
select
    id,
    nullif(trim(Name), '') as documento,
    lower(trim(`Corte`)) as corte,

    -- Identificación
    trim(`Primer_nombre`) as primer_nombre,
    trim(`Segundo_nombre`) as segundo_nombre,
    trim(`Primer_apellido`) as primer_apellido,
    trim(`Segundo_apellido`) as segundo_apellido,
    lower(trim(`Tipo_de_documento`)) as tipo_de_documento,
    lower(trim(`Sexo_al_nacer`)) as sexo_al_nacer,
    safe_cast(`Edad` as int64) as edad,
    trim(`N_mero_de_Celular_principal`) as celular,

    -- Perfil
    lower(trim(`Tipificaci_n_Mujer`)) as tipificacion_mujer,
    lower(trim(`Nacionalidad`)) as nacionalidad,
    lower(trim(`Grupo_tnico`)) as grupo_etnico,
    lower(trim(`Tipo_de_discapacidad`)) as tipo_de_discapacidad,
    lower(trim(`Nivel_de_Escolaridad`)) as nivel_de_escolaridad,

    -- Territorio
    lower(trim(`Ciudad_Municipio`)) as ciudad_municipio,
    lower(trim(`Departamento`)) as departamento,
    lower(trim(`Zona_geogr_fica`)) as zona_geografica,

    -- Mitigación
    date(safe_cast(`Fecha_de_Registro` as timestamp)) as fecha_registro,
    date(safe_cast(`Fecha_de_pago_mitigaci_n` as timestamp)) as fecha_pago,
    lower(trim(`Tipo_de_mitigaci_n`)) as tipo_mitigacion,
    lower(trim(`Estado_de_mitigaci_n`)) as estado_mitigacion,
    lower(trim(`Estado_de_mitigaci_n_2`)) as estado_mitigacion_2,
    trim(`Descripci_n_de_mitigacion`) as descripcion_mitigacion,
    lower(trim(`Mitigaci_n_Completada`)) as mitigacion_completada_txt,
    lower(trim(`Es_micromitigaci_n`)) as es_micromitigacion_txt,
    trim(`Gestor_Operativo`) as gestor_operativo,
    trim(`Nombre_de_encargado`) as nombre_encargado,

    -- Barrera atendida
    lower(trim(`Enfrenta_alg_n_tipo_de_barrera_1`)) as enfrenta_barrera,
    lower(trim(`Seleccione_el_tipo_de_barrera_individual`)) as tipo_barrera,
    trim(`Otro_tipo_de_barrera`) as otro_tipo_barrera,
    lower(trim(`Qu_servicio_recibi_para_superar_la_barrera_1`)) as servicio_recibido,
    trim(`Otro_servicio`) as otro_servicio,

    -- Valor monetario. El campo en Zoho es texto y puede llegar con
    -- símbolos ($, puntos, comas). Se limpia todo lo que no sea dígito
    -- y luego se castea. Se conserva el crudo al lado para auditoría.
    trim(`Qu_valor_recibi_para_superar_la_barrera_1`) as valor_mitigacion_raw,
    safe_cast(
        nullif(regexp_replace(
            coalesce(`Qu_valor_recibi_para_superar_la_barrera_1`, ''),
            r'[^0-9]', ''
        ), '') as numeric
    ) as valor_mitigacion,

    -- Dispersión
    lower(trim(`Dispersion_formacion_check`)) as dispersion_formacion,
    lower(trim(`Dispersion_colocacion_check`)) as dispersion_colocacion,
    lower(trim(`Entidad_Bancaria`)) as entidad_bancaria,

    -- Auditoría
    safe_cast(_loaded_at as timestamp) as _loaded_at,
    safe_cast(`Created_Time` as timestamp) as created_time,
    safe_cast(`Modified_Time` as timestamp) as modified_time
from {{ source('zoho_raw_ruta_mujer', 'mitigaci_n_colsubsidios') }}
