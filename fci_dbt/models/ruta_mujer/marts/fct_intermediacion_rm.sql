select * replace (
        date(created_time) as created_time,
        date(last_activity_time) as last_activity_time,
        date(_loaded_at) as _loaded_at,
        date(modified_time) as modified_time,
        coalesce(nullif(trim(novedad_intermediaci_n), ''), 'Sin novedad registrada') as novedad_intermediaci_n
    ),
    case
        when coalesce(fecha_intermediaci_n, date(created_time)) >= '2026-09-01' then 'corte 2'
        else 'corte 1'
    end as corte_evento,

    -- Estado macro para embudos ejecutivos
    case
        when estado = 'contratado' or lower(estado) like '%contratad%'
            then '3. Contratada'
        when estado in (
            'asistió/está en proceso',
            'en proceso de exámenes médicos',
            'aprobó proceso/pendiente firma del contrato'
        )
        or regexp_contains(lower(estado), r'entrevista|m[eé]dic|firma.*contrato')
            then '2. En proceso de selección'
        when estado in ('envío de hoja de vida', 'remitida', 'envio de hoja de vida')
             or regexp_contains(lower(coalesce(estado, '')), r'retroalimentaci|no se (ha )?comunica|nunca contact|no contact|sin contacto|sin respuesta')
             or regexp_contains(lower(coalesce(novedad_intermediaci_n, '')), r'retroalimentaci|no se (ha )?comunica|nunca contact|no contact|sin contacto|sin respuesta')
            then '1. Remitida (Envío HV)'
        when estado in (
            'asistió/no superó el proceso',
            'no asistió a la citación',
            'asistió/ no le interesa la vacante',
            'ya consiguió trabajo formal',
            'la asignación salarial no se ajusta a sus necesidades',
            'no interesado por otro motivo ¿cual?',
            'participante estudia'
        )
        or regexp_contains(lower(estado), r'no super[oó]|no asisti[oó]|no le interesa|consigui[oó] trabajo')
            then '4. No vinculada'
        else '5. Sin información'
    end as estado_normalizado,

    -- Etapa secuencial del embudo para gráficos de funnel en Power BI
    case
        when estado = 'contratado' or lower(estado) like '%contratad%'
            then '6. Contratada'
        when estado in (
            'aprobó proceso/pendiente firma del contrato',
            'pendiente firma del contrato',
            'pendiente firma de contrato',
            'en proceso de exámenes médicos',
            'en proceso de examenes medicos',
            'exámenes médicos',
            'examenes medicos'
        ) or lower(estado) like '%firma%contrato%' or regexp_contains(lower(estado), r'm[eé]dic')
            then '4. En proceso de selección'
        when estado in (
            'asistió/está en proceso',
            'en entrevista',
            'asistió a entrevista',
            'entrevista'
        ) or regexp_contains(lower(estado), r'entrevista')
            then '5. En entrevista'
        when regexp_contains(lower(coalesce(estado, '')), r'retroalimentaci|no se (ha )?comunica|nunca contact|no contact|sin contacto|sin respuesta')
             or (
                (estado in ('envío de hoja de vida', 'remitida', 'en espera', '') or estado is null)
                and regexp_contains(lower(coalesce(novedad_intermediaci_n, '')), r'retroalimentaci|no se (ha )?comunica|nunca contact|no contact|sin contacto|sin respuesta')
             )
            then '3. Sin retroalimentación'
        when estado in ('envío de hoja de vida', 'remitida', 'envio de hoja de vida')
            then '1. Remitida'
        when estado in (
            'asistió/no superó el proceso',
            'no asistió a la citación',
            'asistió/ no le interesa la vacante',
            'ya consiguió trabajo formal',
            'la asignación salarial no se ajusta a sus necesidades',
            'no interesado por otro motivo ¿cual?',
            'participante estudia'
        ) or regexp_contains(lower(estado), r'no super[oó]|no asisti[oó]|no le interesa|consigui[oó] trabajo')
            then '2. No vinculada'
        else '7. Sin información'
    end as etapa_embudo,

    -- Subetapa detallada dentro de cada macro-estado
    -- Abre 'En proceso de selección' en fases concretas y distingue
    -- dentro de 'No vinculada' el motivo específico. Permite drill-down
    -- desde el embudo ejecutivo sin perder claridad en el nivel superior.
    case
        -- 3. Contratada
        when estado = 'contratado' or lower(estado) like '%contratad%'
            then '3a. Contratada'

        -- 2. En proceso de selección
        when estado in (
            'aprobó proceso/pendiente firma del contrato',
            'pendiente firma del contrato',
            'pendiente firma de contrato'
        ) or lower(estado) like '%firma%contrato%'
            then '2c. Pendiente firma de contrato'

        when estado in (
            'en proceso de exámenes médicos',
            'en proceso de examenes medicos',
            'exámenes médicos',
            'examenes medicos'
        ) or regexp_contains(lower(estado), r'm[eé]dic')
            then '2b. Fase médica / pre-ingreso'

        when estado in (
            'asistió/está en proceso',
            'en entrevista',
            'asistió a entrevista',
            'entrevista'
        ) or regexp_contains(lower(estado), r'entrevista')
            then '2a. En entrevista / proceso activo'

        -- 1. Remitida / Sin contacto de empresa
        when regexp_contains(lower(coalesce(estado, '')), r'retroalimentaci|no se (ha )?comunica|nunca contact|no contact|sin contacto|sin respuesta')
             or (
                (estado in ('envío de hoja de vida', 'remitida', 'en espera', '') or estado is null)
                and regexp_contains(lower(coalesce(novedad_intermediaci_n, '')), r'retroalimentaci|no se (ha )?comunica|nunca contact|no contact|sin contacto|sin respuesta')
             )
            then '1b. Sin retroalimentación / Nunca contactada por empresa'

        when estado in ('envío de hoja de vida', 'remitida', 'envio de hoja de vida')
            then '1a. Remitida - En espera'

        -- 4. No vinculada (motivo específico)
        when estado = 'asistió/no superó el proceso' or lower(estado) like '%no superó%' or lower(estado) like '%no supero%'
            then '4a. No superó el proceso'
        when estado = 'no asistió a la citación' or lower(estado) like '%no asistió%' or lower(estado) like '%no asistio%'
            then '4b. No asistió a la citación'
        when estado in ('asistió/ no le interesa la vacante', 'asistió/no le interesa la vacante') or lower(estado) like '%no le interesa%'
            then '4c. No le interesa la vacante'
        when estado = 'ya consiguió trabajo formal' or lower(estado) like '%consiguió trabajo%' or lower(estado) like '%consiguio trabajo%'
            then '4d. Ya consiguió trabajo'
        when estado = 'la asignación salarial no se ajusta a sus necesidades' or lower(estado) like '%salarial%'
            then '4e. Salario no se ajusta'
        when estado in ('no interesado por otro motivo ¿cual?', 'participante estudia')
            then '4f. Otro motivo'

        else '5a. Sin información'
    end as subetapa_seleccion
from {{ ref('stg_intermediaci_n_ruta_m') }}
