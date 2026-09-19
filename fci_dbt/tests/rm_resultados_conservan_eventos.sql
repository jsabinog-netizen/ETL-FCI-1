{{ config(severity='warn') }}
select 'eventos' as error from (select 1)
where (select sum(num_remisiones) from {{ ref('fct_resultados_vacante_rm') }})
 != (select count(*) from {{ ref('stg_intermediaci_n_ruta_m') }} i
     where exists (select 1 from {{ ref('dim_vacantes_rm') }} v where v.id=i.buscar_vacante_id))
union all
select 'estados' from {{ ref('fct_resultados_vacante_rm') }}
where num_remisiones != num_envios_actuales+num_en_proceso+num_contratadas+num_no_paso+num_otros_estados
