select
    id,
    Primer_nombre                                   as primer_nombre,
    Primer_apellido                                 as primer_apellido,
    Segundo_nombre                                  as segundo_nombre,
    Segundo_apellido                                as segundo_apellido,
    Name                                            as documento,

    -- empresa empleadora (campos DIRECTOS, no lookup JSON)
    NIT_de_empresa_contratante_empleador            as nit_empresa,
    Nombre_de_empresa_contratante_empleador         as nombre_empresa,
    lower(trim(Sector_econ_mico_empresa_contratante_empleador)) as sector_empresa,

    -- detalle de la vinculación
    Cargo_en_la_empresa                             as cargo,
    lower(trim(Tipo_de_contrato))                   as tipo_contrato,
    safe_cast(Salario as numeric)                   as salario,
    lower(trim(Es_un_empleo_verde))                 as empleo_verde,
    safe_cast(Fecha_de_vinculaci_n as timestamp)    as fecha_vinculacion,

    -- resultado / calidad
    lower(trim(Colocaci_n_Completada))              as colocacion_completada,
    coalesce(nullif(trim(json_value(Encargado_Colocaci_n, '$.name')), ''), 'Sin encargado') as encargado,

    safe_cast(Modified_Time as timestamp)           as modified_time
from {{ source('zoho_raw_giz', 'colocaci_n_giz') }}