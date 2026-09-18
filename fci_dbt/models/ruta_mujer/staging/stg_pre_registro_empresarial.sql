-- Grano: un registro del modulo Zoho (id).
select
    id,
    nullif(trim(Name), '') as nit,
    json_value(`Owner`, '$.id') as owner_id,
    json_value(`Owner`, '$.name') as owner_nombre,
    trim(`Email`) as email,
    safe_cast(`Created_Time` as timestamp) as created_time,
    safe_cast(`Last_Activity_Time` as timestamp) as last_activity_time,
    trim(`N_mero_de_whatsapp_2`) as n_mero_de_whatsapp_2,
    trim(`Tel_fono_de_contacto_fijo_o_celular_2`) as tel_fono_de_contacto_fijo_o_celular_2,
    trim(`Cargo`) as cargo,
    trim(`N_mero_de_whatsapp`) as n_mero_de_whatsapp,
    trim(`Tel_fono_de_contacto_fijo_o_celular`) as tel_fono_de_contacto_fijo_o_celular,
    trim(`Nombre_Completo_2`) as nombre_completo_2,
    trim(`Cargo_2`) as cargo_2,
    trim(`Nombre_de_la_empresa`) as nombre_de_la_empresa,
    trim(`Correo_electr_nico_2`) as correo_electr_nico_2,
    trim(`Nombre_Completo`) as nombre_completo,
    trim(`rea`) as rea,
    lower(trim(`Cuenta_con_un_segundo_contacto`)) as cuenta_con_un_segundo_contacto,
    trim(`rea_2`) as rea_2,

    -- Campo crudo (con todo el multiselect) para auditoría
    lower(trim(`Sector_econ_mico`)) as sector_econ_mico,

    -- Primer valor del multiselect separado por pipe '|' (Zoho).
    -- Ej: 'OTRAS ACTIVIDADES DE SERVICIOS|OTRO' → 'otras actividades de servicios'
    lower(trim(split(`Sector_econ_mico`, '|')[safe_offset(0)])) as sector_econ_mico_principal,

    -- Sector normalizado a categorías estándar para Power BI.
    case
        when split(`Sector_econ_mico`, '|')[safe_offset(0)] is null
             or trim(split(`Sector_econ_mico`, '|')[safe_offset(0)]) = ''
            then null
        when regexp_contains(lower(trim(split(`Sector_econ_mico`, '|')[safe_offset(0)])),
                r'transporte|almacenamiento')
            then 'Transporte y almacenamiento'
        when regexp_contains(lower(trim(split(`Sector_econ_mico`, '|')[safe_offset(0)])),
                r'construcci[óo]n')
            then 'Construcción'
        when regexp_contains(lower(trim(split(`Sector_econ_mico`, '|')[safe_offset(0)])),
                r'manufactur')
            then 'Industrias manufactureras'
        when regexp_contains(lower(trim(split(`Sector_econ_mico`, '|')[safe_offset(0)])),
                r'textil')
            then 'Fabricación de productos textiles'
        when regexp_contains(lower(trim(split(`Sector_econ_mico`, '|')[safe_offset(0)])),
                r'financier|seguros|pensiones')
            then 'Actividades financieras y de seguros'
        when regexp_contains(lower(trim(split(`Sector_econ_mico`, '|')[safe_offset(0)])),
                r'tecnolog[íi]a|informaci[óo]n|comunicaciones')
            then 'Información y comunicaciones'
        when regexp_contains(lower(trim(split(`Sector_econ_mico`, '|')[safe_offset(0)])),
                r'turismo')
            then 'Turismo'
        when regexp_contains(lower(trim(split(`Sector_econ_mico`, '|')[safe_offset(0)])),
                r'comercio')
            then 'Comercio'
        when regexp_contains(lower(trim(split(`Sector_econ_mico`, '|')[safe_offset(0)])),
                r'hogares')
            then 'Actividades de los hogares'
        when regexp_contains(lower(trim(split(`Sector_econ_mico`, '|')[safe_offset(0)])),
                r'otras actividades de servicios')
            then 'Otras actividades de servicios'
        else 'Otro'
    end as sector_normalizado,

    lower(trim(`Tama_o_de_la_empresa`)) as tama_o_de_la_empresa,
    lower(trim(`Departamento`)) as departamento,
    lower(trim(`Ciudad_municipio_principal`)) as ciudad_municipio_principal,
    lower(trim(`Corte`)) as corte,
    safe_cast(_loaded_at as timestamp) as _loaded_at,
    safe_cast(Modified_Time as timestamp) as modified_time
from {{ source('zoho_raw_ruta_mujer', 'pre_registro_empresarial') }}
