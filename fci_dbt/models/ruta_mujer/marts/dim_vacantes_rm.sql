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
    case when lower(trim(v.vacante_con_enfoque_de_genero)) in ('sí','si','true') then true
         when lower(trim(v.vacante_con_enfoque_de_genero)) in ('no','false') then false end as es_enfoque_genero,
    case when lower(trim(v.vacante_de_desmasculinizacion)) in ('sí','si','true') then true
         when lower(trim(v.vacante_de_desmasculinizacion)) in ('no','false') then false end as es_desmasculinizacion,
    case when nullif(trim(v.ciudad_municipio_de_la_vacante), '') is not null
         then concat(v.ciudad_municipio_de_la_vacante,
                     if(nullif(trim(v.departamento_de_la_vacante),'') is null, '', concat(', ', v.departamento_de_la_vacante)), ', Colombia')
    end as ubicacion_mapa,
    coalesce(e.id, n.id) as empresa_id,
    coalesce(e.nit, n.nit, v.buscar_empresa_nombre) as nit_empresa,
    coalesce(e.nombre_de_la_empresa, n.nombre_de_la_empresa, v.nombre_de_la_empresa_1, v.nombre_de_la_empresa) as empresa,
    -- Sector: proviene de la empresa asociada, no de la vacante (campo inexistente en Zoho vacantes)
    coalesce(e.sector_normalizado, n.sector_normalizado) as sector_normalizado,
    coalesce(e.sector_econ_mico, n.sector_econ_mico) as sector_economico_empresa,
    coalesce(e.tama_o_de_la_empresa, n.tama_o_de_la_empresa) as tamano_empresa,
    coalesce(e.departamento, n.departamento) as departamento_empresa,
    coalesce(e.ciudad_municipio_principal, n.ciudad_municipio_principal) as municipio_empresa,
    case
        when v.edad_m_nima is null and v.edad_m_xima is null then '9. Sin restricción'
        when v.edad_m_xima is null then concat('8. Desde ', cast(v.edad_m_nima as string))
        when v.edad_m_nima is null then concat('7. Hasta ', cast(v.edad_m_xima as string))
        when v.edad_m_xima <= 25 then '1. Hasta 25'
        when v.edad_m_xima <= 35 then '2. Hasta 35'
        when v.edad_m_xima <= 45 then '3. Hasta 45'
        when v.edad_m_xima <= 55 then '4. Hasta 55'
        else '5. Sin tope superior'
    end as rango_etario_vacante,
    -- Corte de la vacante basado en su fecha de inicio
    case
        when coalesce(v.fecha_de_inicio_de_la_vacante, date(v.created_time)) >= '2026-09-01' then 'corte 2'
        else 'corte 1'
    end as corte_evento
from {{ ref('stg_ge_vacantes_colsubsidios') }} v
left join empresas_id e on v.buscar_empresa_id = e.id
left join empresas_nit n on e.id is null and v.buscar_empresa_nombre = n.nit
