-- Una fila por participante y pertenencia; nunca multiplica fct_ruta_mujer.
select distinct r.documento, lower(trim(grupo)) as grupo_poblacional
from {{ ref('stg_inscripci_n_colsubsidios') }} r,
unnest(ifnull(json_value_array(r.grupos_poblacionales_json), array<string>[])) grupo
where r.documento is not null and nullif(trim(grupo), '') is not null
