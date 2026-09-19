-- Una fila por vacante, incluso si nunca recibió remisiones.
-- Estados actuales de eventos; no representa historial de transiciones.
with eventos as (
    select buscar_vacante_id as vacante_id,
        count(*) as num_remisiones,
        count(distinct documento) as num_mujeres,
        countif(estado = 'envío de hoja de vida') as num_envios_actuales,
        countif(estado = 'asistió/está en proceso') as num_en_proceso,
        countif(estado = 'contratado') as num_contratadas,
        countif(estado in ('asistió/no superó el proceso', 'la asignación salarial no se ajusta a sus necesidades', 'no interesado por otro motivo ¿cual?')) as num_no_paso,
        countif(estado is null or estado not in ('envío de hoja de vida','asistió/está en proceso','contratado','asistió/no superó el proceso','la asignación salarial no se ajusta a sus necesidades','no interesado por otro motivo ¿cual?')) as num_otros_estados
    from {{ ref('stg_intermediaci_n_ruta_m') }} group by buscar_vacante_id
), novedad as (
    select buscar_vacante_id, id, fecha_intermediaci_n, novedad_intermediaci_n, estado
    from {{ ref('stg_intermediaci_n_ruta_m') }}
    where nullif(trim(novedad_intermediaci_n), '') is not null
    qualify row_number() over (partition by buscar_vacante_id
        order by fecha_intermediaci_n desc nulls last, modified_time desc nulls last, id desc) = 1
)
select v.id as vacante_id, v.codigo_vacante, v.nombre_vacante, v.nit_empresa, v.empresa,
    v.sector_normalizado, v.estado_de_la_vacante, v.fecha_de_inicio_de_la_vacante,
    v.corte_evento, v.n_mero_de_puestos_de_trabajo,
    coalesce(e.num_remisiones,0) as num_remisiones, coalesce(e.num_mujeres,0) as num_mujeres,
    coalesce(e.num_envios_actuales,0) as num_envios_actuales,
    coalesce(e.num_en_proceso,0) as num_en_proceso, coalesce(e.num_contratadas,0) as num_contratadas,
    coalesce(e.num_no_paso,0) as num_no_paso, coalesce(e.num_otros_estados,0) as num_otros_estados,
    v.estado_de_la_vacante = 'activa' and coalesce(e.num_remisiones,0) = 0 as activa_sin_remision,
    n.id as ultima_novedad_evento_id, n.fecha_intermediaci_n as ultima_novedad_fecha,
    n.novedad_intermediaci_n as ultima_novedad,
    cast(null as string) as motivo_sin_remision,
    case when coalesce(e.num_remisiones,0) = 0 then 'Motivo no registrado' end as estado_motivo_sin_remision
from {{ ref('dim_vacantes_rm') }} v
left join eventos e on v.id = e.vacante_id
left join novedad n on v.id = n.buscar_vacante_id
