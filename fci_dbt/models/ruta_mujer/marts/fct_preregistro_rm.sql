-- Grano: un preregistro por id de Zoho.
-- Alimenta la página PREREGISTRO del dashboard.

with inscritas as (
    -- Documentos que efectivamente llegaron a inscripción.
    select distinct documento
    from {{ ref('stg_inscripci_n_colsubsidios') }}
    where documento is not null
), base as (
    select p.* replace (
            date(p.created_time) as created_time,
            date(p._loaded_at) as _loaded_at,
            date(p.modified_time) as modified_time
        ),
        -- Flag de conversión: el preregistro se volvió inscripción
        i.documento is not null as se_inscribio
    from {{ ref('stg_pre_registro_rutam') }} p
    left join inscritas i on p.documento = i.documento
)
select *,
    -- Estado final del preregistro. Replica la columna
    case
        when se_inscribio then 'Inscritos'
        when lower(trim(coalesce(preinscripci_n_completad, ''))) like '%no aplica%'
            then 'No aplica'
        else 'Pendiente'
    end as estado_inscripcion_final
from base