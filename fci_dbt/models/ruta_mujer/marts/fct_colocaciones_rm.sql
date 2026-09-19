-- Evento de colocación: permite segmentar por vacante sin perder múltiples empleos.
select * replace (date(created_time) as created_time, date(modified_time) as modified_time,
                  date(_loaded_at) as _loaded_at),
    case when fecha_de_vinculaci_n_laboral >= '2026-09-01' then 'corte 2'
         when fecha_de_vinculaci_n_laboral is not null then 'corte 1' end as corte_evento
from {{ ref('stg_colocaci_n_colsubsidios') }}
