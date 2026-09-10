-- Grano: un registro de asistencia por id de Zoho.

select * replace (
        date(created_time) as created_time,
        date(last_activity_time) as last_activity_time,
        date(_loaded_at) as _loaded_at,
        date(modified_time) as modified_time
    )
from {{ ref('stg_asist_pres_rutam') }}