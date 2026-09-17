-- Grano: una mitigación por id de Zoho.
-- Una participante puede recibir varias mitigaciones, así que el grano
-- es el evento. Para contar personas: DISTINCTCOUNT(documento) en DAX.
--
-- ⚠️ Tabla vacía al momento de construirla (0 filas en Zoho).
-- El modelo compila y queda listo; verificar cuando lleguen datos.
with base as (
    select * replace (
            date(created_time) as created_time,
            date(_loaded_at) as _loaded_at,
            date(modified_time) as modified_time
        ),
        -- Flags booleanos para medidas DAX
        coalesce(mitigacion_completada_txt in ('si', 'sí', 'true'), false)
            as mitigacion_completada,
        coalesce(es_micromitigacion_txt in ('si', 'sí', 'true'), false)
            as es_micromitigacion,
        -- Días entre el registro de la mitigación y el pago efectivo.
        -- Mide la agilidad operativa del desembolso.
        date_diff(fecha_pago, fecha_registro, day) as dias_registro_a_pago
    from {{ ref('stg_mitigaci_n_colsubsidios') }}
)
select *,
    case
        when coalesce(fecha_pago, fecha_registro, date(created_time)) >= '2026-09-01' then 'corte 2'
        else 'corte 1'
    end as corte_evento,

    -- Etapa de la ruta en la que se entregó el apoyo, derivada de
    -- los checks de dispersión.
    case
        when dispersion_colocacion in ('si', 'sí', 'true') then 'Colocación'
        when dispersion_formacion in ('si', 'sí', 'true') then 'Formación'
        else 'Sin clasificar'
    end as etapa_mitigacion,

    -- Barrera consolidada: usa el campo abierto cuando el picklist
    -- dice "otro", para no perder la información en los gráficos.
    case
        when tipo_barrera like '%otro%' and otro_tipo_barrera is not null
            then otro_tipo_barrera
        else tipo_barrera
    end as barrera_consolidada,

    -- Servicio consolidado, misma lógica
    case
        when servicio_recibido like '%otro%' and otro_servicio is not null
            then otro_servicio
        else servicio_recibido
    end as servicio_consolidado,

    -- Versiones de texto para segmentadores de Power BI
    case when mitigacion_completada_txt in ('si', 'sí', 'true')
         then 'Sí' else 'No' end as tiene_mitigacion_completada,
    case when es_micromitigacion_txt in ('si', 'sí', 'true')
         then 'Sí' else 'No' end as tiene_micromitigacion,

    -- Pago pendiente: mitigación aprobada sin fecha de pago
    coalesce(
        mitigacion_completada_txt in ('si', 'sí', 'true')
        and fecha_pago is null,
        false
    ) as pago_pendiente
from base
