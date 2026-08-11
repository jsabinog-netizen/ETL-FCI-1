select
    id,
    Nombre_de_la_vacante                            as vacante,
    Nombre_de_la_empresa                            as nombre_empresa,

    COALESCE(
        json_value(Nit_de_la_empresa, '$.name'),
        Nit_de_la_empresa
    ) AS nit_empresa,
    lower(trim(Ciudad_Municipio_de_la_vacante))     as ciudad,
    lower(trim(Departamendo_de_la_vacante))         as departamento,  -- typo de Zoho: "Departamendo"
    lower(trim(Sector_al_que_pertenece))            as sector,
    safe_cast(N_mero_de_puestos_de_trabajo as int64) as puestos,
    Perfil_de_la_vacante                            as perfil,
    DATE(safe_cast(Modified_Time as timestamp))                as modified_time,
    DATE(safe_cast(Fecha_de_inicio_de_la_vacante as timestamp)) as fecha_inicio,
    DATE(safe_cast(Fecha_de_finalizaci_n_de_la_vacante as timestamp)) as fecha_fin
from {{ source('zoho_raw_giz', 'vacantes_giz') }}