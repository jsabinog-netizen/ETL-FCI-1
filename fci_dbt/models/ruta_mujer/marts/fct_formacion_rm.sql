select * replace (
        date(created_time) as created_time,
        date(_loaded_at) as _loaded_at,
        date(modified_time) as modified_time
    ),
    fortalecimiento_de_habilidades_t_cnica as curso,

    case when formaci_n_completada in ('si', 'sí', 'true')
         then 'Completada'
         else 'Pendiente'
    end as estado_formacion

from {{ ref('stg_formaci_n_colsubsidios') }}

