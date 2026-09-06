select * replace (
    date(created_time) as created_time,
    date(_loaded_at) as _loaded_at,
    date(modified_time) as modified_time
)
from {{ ref('stg_formaci_n_colsubsidios') }}
