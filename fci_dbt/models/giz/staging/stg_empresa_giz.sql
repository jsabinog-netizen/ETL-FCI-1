select
    id,
    Nombre_de_la_empresa                            as nombre_empresa,
    Name                                             as nit,
    D_gito_de_verificaci_n                          as digito_verificacion,
    lower(trim(Sector_al_que_pertenece))            as sector,
    Nombre_Contacto                                 as contacto,
    DATE(safe_cast(Modified_Time as timestamp)) as modified_time
from {{ source('zoho_raw_giz', 'empresa_giz') }}