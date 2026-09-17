select * replace (
        date(created_time) as created_time,
        date(last_activity_time) as last_activity_time,
        date(_loaded_at) as _loaded_at,
        date(modified_time) as modified_time
    ),
    case
        when coalesce(fecha_intermediaci_n, date(created_time)) >= '2026-09-01' then 'corte 2'
        else 'corte 1'
    end as corte_evento
from {{ ref('stg_intermediaci_n_ruta_m') }}
