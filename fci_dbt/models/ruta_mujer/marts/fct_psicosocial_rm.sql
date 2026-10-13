-- Grano: un diagnostico psicosocial de Corte 2 (id de Psicosocial_RutaM_v2).
-- Solo v2: el psicosocial de Corte 1 tiene otros campos y vive en fct_ruta_mujer.
-- Alimenta el tablero psicosocial (ejes, riesgo, llamadas L1/L2).

with inscripcion as (
    select documento, corte,
        trim(concat(coalesce(primer_nombre, ''), ' ', coalesce(segundo_nombre, ''), ' ',
                    coalesce(primer_apellido, ''), ' ', coalesce(segundo_apellido, ''))) as nombre,
        n_mero_de_celular as telefono
    from {{ ref('stg_inscripci_n_colsubsidios') }}
    where documento is not null
    qualify row_number() over (
        partition by documento order by modified_time desc nulls last, id desc
    ) = 1
), base as (
    select
        p.* replace (
            date(p.created_time) as created_time,
            date(p.modified_time) as modified_time,
            date(p._loaded_at) as _loaded_at
        ),
        -- Una mujer de Corte 1 puede seguir en el programa en Corte 2:
        -- su diagnostico es de Corte 2 aunque su inscripcion sea de Corte 1.
        coalesce(i.corte, 'no inscrita') as corte_inscripcion,
        coalesce(nullif(i.nombre, ''), 'No inscrita') as nombre,
        i.telefono as telefono_principal,
        -- El riesgo validado por la profesional en L1 reemplaza al automatico.
        coalesce(p.l1_nivel_riesgo_final, p.nivel_riesgo_automatico) as nivel_riesgo_vigente,
        p.estado_del_diagnostico = 'diligenciado' as diagnostico_diligenciado,
        coalesce(p.l1_contacto_efectivo in ('sí', 'si'), false) as contacto_l1,
        coalesce(p.l2_contacto_efectivo in ('sí', 'si'), false) as contacto_l2,
        p.estado_final_del_caso is not null as caso_cerrado,

        -- ── Respuestas clave (columnas Sí/No de la Base de Seguimiento) ──
        -- Solo tienen sentido con diagnostico diligenciado; sin el quedan false.
        coalesce(
            p.violencia_familiar = 'sí' or p.violencia_laboral = 'sí' or p.violencia_comunidad = 'sí'
            or exists (select 1 from unnest(p.violencia_pareja_opciones) o
                       where o not in ('Ninguna de las anteriores', 'No tengo pareja actualmente / no aplica')),
            false) as reporta_violencia,
        exists (select 1 from unnest(p.indicadores_alerta_opciones) o
                where starts_with(o, 'En las últimas semanas he pensado que no vale la pena seguir')) as marca_ideas_autolesivas,
        exists (select 1 from unnest(p.indicadores_alerta_opciones) o
                where o not in ('Ninguna de las anteriores', 'Prefiero no responder')) as marca_indicadores_emocionales,
        coalesce(p.personas_de_apoyo = 'ninguna', false) as sin_redes_de_apoyo,
        -- 'En ocasiones' cuenta como que el cuidado si afecta la permanencia.
        coalesce(p.tiene_responsabilidades_cuidado = 'sí'
                 and p.cuidado_dificulta_permanencia in ('sí', 'en ocasiones'), false) as cuidado_afecta_permanencia,
        array_length(p.barreras_opciones) as num_barreras,
        exists (select 1 from unnest(p.barreras_opciones) o
                where o in ('Falta de recursos para alimentación o transporte',
                            'Falta de apoyo para el cuidado de hijos/as u otras personas a cargo')) as barreras_alimentacion_transporte_cuidado,
        p.factores_permanencia is not null as reporta_factores_permanencia,
        coalesce(p.en_tratamiento_psicologico = 'sí', false) as en_tratamiento_psicologico_flag
    from {{ ref('stg_psicosocial_rutam_v2') }} p
    left join inscripcion i on p.documento = i.documento
)
select
    -- Power BI no importa columnas ARRAY: se exponen como flags y conteos.
    * except (profesional_que_remite, violencia_pareja_opciones, indicadores_alerta_opciones, barreras_opciones),
    case when psicosocial_completada then 'Sí' else 'No' end as tiene_psicosocial_completada,
    coalesce(profesional_que_remite, 'Sin información') as profesional_que_remite,
    -- Estado mas avanzado del caso: cierre > llamada 1 > diagnostico.
    coalesce(estado_final_del_caso, estado_del_caso_llamada_1, estado_del_diagnostico, 'sin información') as estado_caso,
    -- Prefijo numerico para ordenar en Power BI sin "Ordenar por columna".
    case nivel_riesgo_vigente
        when 'bajo'     then '1. Bajo'
        when 'moderado' then '2. Moderado'
        when 'alto'     then '3. Alto'
        else                 '4. Sin diagnóstico'
    end as nivel_riesgo,
    case when diagnostico_diligenciado then 'Sí' else 'No' end as tiene_diagnostico,
    case when contacto_l1 then 'Sí' else 'No' end as tiene_contacto_l1,
    case when contacto_l2 then 'Sí' else 'No' end as tiene_contacto_l2,
    case when caso_cerrado then 'Sí' else 'No' end as tiene_cierre,

    -- ── Columnas de la Base de Seguimiento (Excel) ──
    -- Respuestas clave en texto Sí/No; null si no diligenció el diagnóstico.
    if(diagnostico_diligenciado, if(reporta_violencia, 'Sí', 'No'), null) as reporta_violencia_txt,
    if(diagnostico_diligenciado, if(marca_ideas_autolesivas, 'Sí', 'No'), null) as marca_ideas_autolesivas_txt,
    if(diagnostico_diligenciado, if(marca_indicadores_emocionales, 'Sí', 'No'), null) as marca_indicadores_emocionales_txt,
    if(diagnostico_diligenciado, if(sin_redes_de_apoyo, 'Sí', 'No'), null) as sin_redes_de_apoyo_txt,
    if(diagnostico_diligenciado, if(cuidado_afecta_permanencia, 'Sí', 'No'), null) as cuidado_afecta_permanencia_txt,
    if(diagnostico_diligenciado, if(barreras_alimentacion_transporte_cuidado, 'Sí', 'No'), null) as barreras_alimentacion_transporte_cuidado_txt,
    if(diagnostico_diligenciado, if(reporta_factores_permanencia, 'Sí', 'No'), null) as factores_permanencia_txt,
    if(diagnostico_diligenciado, if(en_tratamiento_psicologico_flag, 'Sí', 'No'), null) as en_tratamiento_txt,
    -- Alertas activas: misma logica que la formula de la columna H del Excel.
    case
        when not diagnostico_diligenciado then null
        else coalesce(nullif(array_to_string([
            if(reporta_violencia, 'Violencia', null),
            if(marca_ideas_autolesivas, 'Seguridad personal', null),
            if(marca_indicadores_emocionales, 'Emocional', null),
            if(sin_redes_de_apoyo, 'Sin red de apoyo', null),
            if(cuidado_afecta_permanencia, 'Carga de cuidado', null),
            if(barreras_alimentacion_transporte_cuidado, 'Barreras críticas', null),
            if(reporta_factores_permanencia, 'Riesgo de deserción', null),
            if(en_tratamiento_psicologico_flag, 'Tratamiento en curso', null)
        ], '; '), ''), 'Sin alertas')
    end as alertas_activas,
    nullif(array_to_string([
        concat('Participante: ', l1_compromisos_participante),
        concat('Profesional: ', l1_compromisos_profesional)
    ], ' | '), '') as l1_acuerdos_plan_trabajo,
    nullif(array_to_string([l2_remision_tipo, l2_remision_entidad, cast(l2_remision_fecha as string)], ' · '), '') as remisiones_realizadas
from base
