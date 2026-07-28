select
    id,
    Primer_nombre                                   as primer_nombre,
    Primer_apellido                                 as primer_apellido,
    Name                                            as documento,

    Perfil_ocupacional                              as perfil_ocupacional,
    lower(trim(Estado))                             as estado,
    Nombre_de_la_vacante                            as vacante,
    Nit_de_la_empresa                               as nit_empresa,
    coalesce(nullif(trim(json_value(Empresa, '$.name')), ''), 'SIN_EMPRESA') as empresa,
    coalesce(nullif(trim(json_value(Responsable_de_la_Intermediaci_n, '$.name')), ''), 'Sin responsable') as responsable,
    safe_cast(Fecha_de_intermediaci_n as timestamp) as fecha_intermediacion,
    lower(trim(Desea_hacer_otra_intermediaci_n))    as desea_otra,

    safe_cast(Modified_Time as timestamp)           as modified_time
from {{ source('zoho_raw_giz', 'intermediaci_n_giz') }}