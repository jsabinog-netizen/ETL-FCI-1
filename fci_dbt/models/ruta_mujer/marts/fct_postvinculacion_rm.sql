-- Grano: un seguimiento post-vinculación por id de Zoho.
--
-- Columnas calculadas: Zoho tiene D_as_faltantes y Estado_de_Post
-- como campos MANUALES, no calculados. Se traen ambos (con sufijo
-- _zoho) para ver qué reporta el equipo, y se calculan las versiones
-- reales para saber la verdad. La discrepancia entre ambos es en sí
-- misma un indicador de calidad de gestión.
--
-- Regla de negocio: el hito de seguimiento es a los 20 días
-- calendario desde el inicio del contrato.
with base as (
    select * replace (
            date(created_time) as created_time,
            date(_loaded_at) as _loaded_at,
            date(modified_time) as modified_time
        ),
        date_diff(current_date('America/Bogota'), fecha_inicio_contrato, day)
            as dias_transcurridos_contrato
    from {{ ref('stg_postvinculaci_n_colsub') }}
)
select *,
    -- Estado calculado del hito de 20 días
    case
        when fecha_inicio_contrato is null then null
        when fecha_llamada_seguimiento is not null then 'Post realizada'
        when dias_transcurridos_contrato >= 20 then 'Pendiente por post'
        else 'En plazo'
    end as estado_post_calculado,

    -- Alerta operativa: pasó el hito sin llamada registrada
    coalesce(
        dias_transcurridos_contrato >= 20
        and fecha_llamada_seguimiento is null,
        false
    ) as alerta_vencida,

    -- Escalamiento sugerido en el requerimiento (25-30 días)
    coalesce(
        dias_transcurridos_contrato >= 25
        and fecha_llamada_seguimiento is null,
        false
    ) as alerta_escalada,

    -- Días entre el hito y la llamada efectiva. Negativo = se
    -- gestionó antes de los 20 días.
    case
        when fecha_llamada_seguimiento is not null
            then date_diff(fecha_llamada_seguimiento, fecha_inicio_contrato, day) - 20
    end as dias_desviacion_hito
from base
