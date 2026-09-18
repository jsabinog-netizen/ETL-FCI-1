-- Grano: una fila por documento; prevalece la inscripción más reciente.
-- Desempates deterministas por modificación, creación e id de Zoho.
select
    id,
    nullif(trim(Name), '') as documento,
    safe_cast(`Created_Time` as timestamp) as created_time,
    trim(`Primer_nombre`) as primer_nombre,
    trim(`Segundo_nombre`) as segundo_nombre,
    trim(`Primer_apellido`) as primer_apellido,
    trim(`Segundo_apellido`) as segundo_apellido,
    date(safe_cast(`Fecha_de_registro` as timestamp)) as fecha_de_registro,
    date(safe_cast(`Fecha_de_nacimiento` as timestamp)) as fecha_de_nacimiento,
    safe_cast(`Edad` as int64) as edad,
    lower(trim(`Tipo_de_documento`)) as tipo_de_documento,
    trim(`Email`) as email,
    trim(`N_mero_de_celular`) as n_mero_de_celular,
    lower(trim(`Sexo_al_nacer`)) as sexo_al_nacer,
    lower(trim(`Nacionalidad`)) as nacionalidad,
    trim(`Otra_nacionalidad`) as otra_nacionalidad,
    lower(trim(`Tipificaci_n_Mujer`)) as tipificaci_n_mujer,
    `Grupos_poblacionales` as grupos_poblacionales_json,
    lower(trim(json_value(`Grupos_poblacionales`, '$[0]'))) as grupos_poblacionales,
    lower(trim(`Tipo_de_poblaci_n`)) as tipo_de_poblaci_n,
    lower(trim(`Modalidad_de_atenci_n`)) as modalidad_de_atenci_n,
    lower(trim(`Inscripci_n_completada`)) as inscripci_n_completada,
    trim(`Profesional_de_registro`) as profesional_de_registro,
    lower(trim(`Municipio_de_residencia1`)) as municipio_de_residencia1,
    lower(trim(`Municipio_de_nacimiento`)) as municipio_de_nacimiento,
    lower(trim(`Departamento_de_nacimiento`)) as departamento_de_nacimiento,
    lower(trim(`Localidad`)) as localidad,
    trim(`Direcci_n_de_residencia`) as direcci_n_de_residencia,
    lower(trim(`Estrato`)) as estrato,
    lower(trim(`Estado_Civil`)) as estado_civil,
    lower(trim(`Tiene_hijos`)) as tiene_hijos,
    json_value(`Pre_registro`, '$.id') as pre_registro_id,
    json_value(`Pre_registro`, '$.name') as pre_registro_nombre,
    lower(trim(`Desea_generar_acompa_amiento_psicosocial`)) as desea_generar_acompa_amiento_psicosocial,
    lower(trim(`D_nde_te_enteraste_de_esta_vacante`)) as d_nde_te_enteraste_de_esta_vacante,
    lower(trim(`Corte`)) as corte,
    safe_cast(_loaded_at as timestamp) as _loaded_at,
    safe_cast(Modified_Time as timestamp) as modified_time,
    lower(trim(`Naturaleza_del_estrato_socioecon_mico`)) as naturaleza_del_estrato_socioecon_mico,
    lower(trim(`Ultimo_nivel_educativo_alcanzado`)) as ultimo_nivel_educativo_alcanzado,
    case
        when `Ultimo_nivel_educativo_alcanzado` is null
            then null
        when regexp_contains(lower(trim(`Ultimo_nivel_educativo_alcanzado`)),
                r'doctor|postdoctor|posdoctor')
            then 'Doctorado o postdoctorado'
        when regexp_contains(lower(trim(`Ultimo_nivel_educativo_alcanzado`)),
                r'especializaci|maestr|mag[íi]ster|posgrado|postgrado')
            then 'Especialización o maestría'
        when regexp_contains(lower(trim(`Ultimo_nivel_educativo_alcanzado`)),
                r'universitar|pregrado|profesional')
            then 'Universitario (pregrado)'
        when regexp_contains(lower(trim(`Ultimo_nivel_educativo_alcanzado`)),
                r't[ée]cn')
            then 'Técnico o Tecnológico'
        when regexp_contains(lower(trim(`Ultimo_nivel_educativo_alcanzado`)),
                r'bachill|media|secundar')
            then 'Bachillerato'
        when regexp_contains(lower(trim(`Ultimo_nivel_educativo_alcanzado`)),
                r'primaria|b[áa]sica')
            then 'Primaria'
        when regexp_contains(lower(trim(`Ultimo_nivel_educativo_alcanzado`)),
                r'ninguno|ningun|sin estudi')
            then 'Ninguno'
        else 'Sin clasificar'
    end as nivel_educativo_normalizado,
    trim(`Pregunta_de_seguridad`) as pregunta_de_seguridad,
    trim(`Respuesta_pregunta_seguridad`) as respuesta_pregunta_seguridad,
    lower(trim(`Seleccione_nivel_de_Sisb_n`)) as seleccione_nivel_de_sisb_n,
    lower(trim(`Tiene_alguna_de_estas_responsabilidades_de_cuidado`)) as tiene_alguna_de_estas_responsabilidades_de_cuidado,
    lower(trim(`Sede_de_atenci_n`)) as sede,
    lower(trim(`Validaci_n_habilitante`)) as validacion_habilitante,

from {{ source('zoho_raw_ruta_mujer', 'inscripci_n_colsubsidios') }}
qualify row_number() over (
    partition by documento
    order by fecha_de_registro desc nulls last,
             modified_time desc nulls last, created_time desc nulls last, id desc
) = 1
