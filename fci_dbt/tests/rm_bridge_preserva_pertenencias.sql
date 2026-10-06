{{ config(severity='warn') }}
with esperado as (
    select distinct documento, lower(trim(grupo)) as grupo_poblacional
    from {{ ref('stg_inscripci_n_colsubsidios') }},
    unnest(
        case
            when starts_with(trim(grupos_poblacionales_json), '[')
            then ifnull(json_value_array(grupos_poblacionales_json), array<string>[])
            when nullif(trim(grupos_poblacionales_json), '') is not null
            then [grupos_poblacionales_json]
            else array<string>[]
        end
    ) grupo
    where documento is not null and nullif(trim(grupo),'') is not null
)
(select * from esperado except distinct select * from {{ ref('bridge_grupos_poblacionales_rm') }})
union all
(select * from {{ ref('bridge_grupos_poblacionales_rm') }} except distinct select * from esperado)
