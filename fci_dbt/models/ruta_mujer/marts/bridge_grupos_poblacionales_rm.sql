-- Una fila por participante y pertenencia; nunca multiplica fct_ruta_mujer.
select distinct r.documento, lower(trim(grupo)) as grupo_poblacional
from {{ ref('stg_inscripci_n_colsubsidios') }} r,
unnest(
    case
        when starts_with(trim(r.grupos_poblacionales_json), '[')
        then ifnull(json_value_array(r.grupos_poblacionales_json), array<string>[])
        when nullif(trim(r.grupos_poblacionales_json), '') is not null
        then [r.grupos_poblacionales_json]
        else array<string>[]
    end
) grupo
where r.documento is not null and nullif(trim(grupo), '') is not null
