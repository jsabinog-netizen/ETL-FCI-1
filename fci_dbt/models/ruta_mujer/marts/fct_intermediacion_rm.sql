with intermediacion as (
    select * from {{ ref('stg_intermediaci_n_ruta_m') }}
),
colocaciones as (
    -- Casos donde la contratacion se registro en Colocacion pero no se
    -- actualizo el estado en Intermediacion. Se empareja por documento y empresa.
    select
        documento,
        nit_de_empresa_contratante_empleador as nit_coloc,
        lower(trim(nombre_de_empresa_contratante_empleador)) as emp_coloc
    from {{ ref('stg_colocaci_n_colsubsidios') }}
    where documento is not null
    qualify row_number() over (
        partition by documento, coalesce(nit_de_empresa_contratante_empleador, nombre_de_empresa_contratante_empleador)
        order by fecha_de_vinculaci_n_laboral desc nulls last, id desc
    ) = 1
)
select i.* replace (
        date(i.created_time) as created_time,
        date(i.last_activity_time) as last_activity_time,
        date(i._loaded_at) as _loaded_at,
        date(i.modified_time) as modified_time,
        coalesce(nullif(trim(i.novedad_intermediaci_n), ''), 'Sin novedad registrada') as novedad_intermediaci_n
    ),
    case
        when coalesce(i.fecha_intermediaci_n, date(i.created_time)) >= '2026-09-01' then 'corte 2'
        else 'corte 1'
    end as corte_evento,

    -- Indicador si fue confirmada como colocada en esta misma empresa
    (c.documento is not null) as colocada_en_esta_empresa,

    -- Estado macro para embudos ejecutivos
    case
        when i.estado = 'contratado' or lower(i.estado) like '%contratad%' or c.documento is not null
            then '3. Contratada'
        when i.estado in (
            'asistió/está en proceso',
            'en proceso de exámenes médicos',
            'aprobó proceso/pendiente firma del contrato'
        )
        or regexp_contains(lower(i.estado), r'entrevista|m[eé]dic|firma.*contrato')
            then '2. En proceso de selección'
        when i.estado in ('envío de hoja de vida', 'remitida', 'envio de hoja de vida')
             or regexp_contains(lower(coalesce(i.estado, '')), r'retroalimentaci|no se (ha )?comunica|nunca contact|no contact|sin contacto|sin respuesta')
             or regexp_contains(lower(coalesce(i.novedad_intermediaci_n, '')), r'retroalimentaci|no se (ha )?comunica|nunca contact|no contact|sin contacto|sin respuesta')
            then '1. Remitida (Envío HV)'
        when i.estado in (
            'asistió/no superó el proceso',
            'no asistió a la citación',
            'asistió/ no le interesa la vacante',
            'ya consiguió trabajo formal',
            'la asignación salarial no se ajusta a sus necesidades',
            'no interesado por otro motivo ¿cual?',
            'participante estudia'
        )
        or regexp_contains(lower(i.estado), r'no super[oó]|no asisti[oó]|no le interesa|consigui[oó] trabajo')
            then '4. No vinculada'
        else '5. Sin información'
    end as estado_normalizado,

    -- Etapa secuencial del embudo para gráficos de funnel en Power BI
    case
        when i.estado = 'contratado' or lower(i.estado) like '%contratad%' or c.documento is not null
            then '6. Contratada'
        when i.estado in (
            'aprobó proceso/pendiente firma del contrato',
            'pendiente firma del contrato',
            'pendiente firma de contrato',
            'en proceso de exámenes médicos',
            'en proceso de examenes medicos',
            'exámenes médicos',
            'examenes medicos'
        ) or lower(i.estado) like '%firma%contrato%' or regexp_contains(lower(i.estado), r'm[eé]dic')
            then '4. En proceso de selección'
        when i.estado in (
            'asistió/está en proceso',
            'en entrevista',
            'asistió a entrevista',
            'entrevista'
        ) or regexp_contains(lower(i.estado), r'entrevista')
            then '5. En entrevista'
        when regexp_contains(lower(coalesce(i.estado, '')), r'retroalimentaci|no se (ha )?comunica|nunca contact|no contact|sin contacto|sin respuesta')
             or (
                (i.estado in ('envío de hoja de vida', 'remitida', 'en espera', '') or i.estado is null)
                and regexp_contains(lower(coalesce(i.novedad_intermediaci_n, '')), r'retroalimentaci|no se (ha )?comunica|nunca contact|no contact|sin contacto|sin respuesta')
             )
            then '3. Sin retroalimentación'
        when i.estado in ('envío de hoja de vida', 'remitida', 'envio de hoja de vida')
            then '1. Remitida'
        when i.estado in (
            'asistió/no superó el proceso',
            'no asistió a la citación',
            'asistió/ no le interesa la vacante',
            'ya consiguió trabajo formal',
            'la asignación salarial no se ajusta a sus necesidades',
            'no interesado por otro motivo ¿cual?',
            'participante estudia'
        ) or regexp_contains(lower(i.estado), r'no super[oó]|no asisti[oó]|no le interesa|consigui[oó] trabajo')
            then '2. No vinculada'
        else '7. Sin información'
    end as etapa_embudo,

    -- Subetapa detallada dentro de cada macro-estado
    -- Abre 'En proceso de selección' en fases concretas y distingue
    -- dentro de 'No vinculada' el motivo específico. Permite drill-down
    -- desde el embudo ejecutivo sin perder claridad en el nivel superior.
    case
        -- 3. Contratada
        when i.estado = 'contratado' or lower(i.estado) like '%contratad%' or c.documento is not null
            then '3a. Contratada'

        -- 2. En proceso de selección
        when i.estado in (
            'aprobó proceso/pendiente firma del contrato',
            'pendiente firma del contrato',
            'pendiente firma de contrato'
        ) or lower(i.estado) like '%firma%contrato%'
            then '2c. Pendiente firma de contrato'

        when i.estado in (
            'en proceso de exámenes médicos',
            'en proceso de examenes medicos',
            'exámenes médicos',
            'examenes medicos'
        ) or regexp_contains(lower(i.estado), r'm[eé]dic')
            then '2b. Fase médica / pre-ingreso'

        when i.estado in (
            'asistió/está en proceso',
            'en entrevista',
            'asistió a entrevista',
            'entrevista'
        ) or regexp_contains(lower(i.estado), r'entrevista')
            then '2a. En entrevista / proceso activo'

        -- 1. Remitida / Sin contacto de empresa
        when regexp_contains(lower(coalesce(i.estado, '')), r'retroalimentaci|no se (ha )?comunica|nunca contact|no contact|sin contacto|sin respuesta')
             or (
                (i.estado in ('envío de hoja de vida', 'remitida', 'en espera', '') or i.estado is null)
                and regexp_contains(lower(coalesce(i.novedad_intermediaci_n, '')), r'retroalimentaci|no se (ha )?comunica|nunca contact|no contact|sin contacto|sin respuesta')
             )
            then '1b. Sin retroalimentación / Nunca contactada por empresa'

        when i.estado in ('envío de hoja de vida', 'remitida', 'envio de hoja de vida')
            then '1a. Remitida - En espera'

        -- 4. No vinculada (motivo específico)
        when i.estado = 'asistió/no superó el proceso' or lower(i.estado) like '%no superó%' or lower(i.estado) like '%no supero%'
            then '4a. No superó el proceso'
        when i.estado = 'no asistió a la citación' or lower(i.estado) like '%no asistió%' or lower(i.estado) like '%no asistio%'
            then '4b. No asistió a la citación'
        when i.estado in ('asistió/ no le interesa la vacante', 'asistió/no le interesa la vacante') or lower(i.estado) like '%no le interesa%'
            then '4c. No le interesa la vacante'
        when i.estado = 'ya consiguió trabajo formal' or lower(i.estado) like '%consiguió trabajo%' or lower(i.estado) like '%consiguio trabajo%'
            then '4d. Ya consiguió trabajo'
        when i.estado = 'la asignación salarial no se ajusta a sus necesidades' or lower(i.estado) like '%salarial%'
            then '4e. Salario no se ajusta'
        when i.estado in ('no interesado por otro motivo ¿cual?', 'participante estudia')
            then '4f. Otro motivo'

        else '5a. Sin información'
    end as subetapa_seleccion
from intermediacion i
left join colocaciones c
    on i.documento = c.documento
    and (
        i.nit_de_la_empresa = c.nit_coloc
        or regexp_replace(coalesce(i.nit_de_la_empresa, ''), r'[- ]', '') = regexp_replace(coalesce(c.nit_coloc, ''), r'[- ]', '')
        or (nullif(trim(i.nombre_de_la_empresa_1), '') is not null and lower(trim(i.nombre_de_la_empresa_1)) = c.emp_coloc)
    )
