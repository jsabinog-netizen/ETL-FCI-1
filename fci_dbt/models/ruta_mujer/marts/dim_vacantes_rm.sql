with empresas_id as (
    select * from {{ ref('stg_pre_registro_empresarial') }}
    qualify row_number() over (partition by id order by modified_time desc nulls last, created_time desc nulls last) = 1
), empresas_nit as (
    select * from empresas_id where nit is not null
    qualify row_number() over (partition by nit order by modified_time desc nulls last, id desc) = 1
)
select v.* replace (
        date(v.created_time) as created_time,
        date(v._loaded_at) as _loaded_at,
        date(v.modified_time) as modified_time
    ),
    coalesce(e.id, n.id) as empresa_id,
    coalesce(e.nit, n.nit, v.buscar_empresa_nombre) as nit_empresa,
    coalesce(e.nombre_de_la_empresa, n.nombre_de_la_empresa, v.nombre_de_la_empresa_1, v.nombre_de_la_empresa) as empresa,
    coalesce(e.sector_econ_mico, n.sector_econ_mico) as sector_economico_empresa,
    coalesce(e.tama_o_de_la_empresa, n.tama_o_de_la_empresa) as tamano_empresa,
    coalesce(e.departamento, n.departamento) as departamento_empresa,
    coalesce(e.ciudad_municipio_principal, n.ciudad_municipio_principal) as municipio_empresa
from {{ ref('stg_ge_vacantes_colsubsidios') }} v
left join empresas_id e on v.buscar_empresa_id = e.id
left join empresas_nit n on e.id is null and v.buscar_empresa_nombre = n.nit
