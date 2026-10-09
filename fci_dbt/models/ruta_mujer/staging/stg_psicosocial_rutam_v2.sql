-- Grano: un registro del modulo Zoho (id). Hoy hay uno por documento.
-- Psicosocial de Corte 2: diagnostico por ejes + llamadas L1/L2.
-- Corte 1 vive en stg_psicosocial_rutam.
-- Typos de Zoho usados tal cual: L1_Hora_de_inico, Puntaje_Eje_5_Barreras_0_151.
select
    id,
    nullif(trim(Name), '') as documento,
    -- El modulo no tiene campo Corte: v2 = Corte 2 por regla de negocio.
    'corte 2' as corte,
    safe_cast(`Created_Time` as timestamp) as created_time,
    json_value(`Participante_RutaM`, '$.id') as participante_rutam_id,
    json_value(`Participante_RutaM`, '$.name') as participante_rutam_nombre,
    -- Owner es la plataforma (InClúyete 4.0), no la profesional.
    json_value(`Owner`, '$.name') as owner_nombre,
    trim(`Profesional_que_remite`) as profesional_que_remite,

    -- ── Diagnostico ──
    lower(trim(`Estado_del_diagn_stico`)) as estado_del_diagnostico,
    lower(trim(`Fuente_del_diagn_stico`)) as fuente_del_diagnostico,
    lower(trim(`C_mo_llegaste_a_este_acompa_amiento`)) as como_llego_al_acompanamiento,
    lower(trim(`Canal_de_env_o_del_enlace`)) as canal_envio_enlace,
    lower(trim(`Nivel_de_riesgo_autom_tico`)) as nivel_riesgo_automatico,
    coalesce(lower(trim(`Alerta_prioritaria_inmediata`)) in ('true', 'sí', 'si'), false) as alerta_prioritaria_inmediata,
    coalesce(lower(trim(`Alerta_de_revisi_n_posible_control_econ_mico`)) in ('true', 'sí', 'si'), false) as alerta_control_economico,
    nullif(array_to_string(json_value_array(`Banderas_rojas_activas`), ', '), '') as banderas_rojas_activas,

    -- ── Ejes: porcentaje y puntaje bruto (escalas distintas por eje) ──
    safe_cast(`Eje_1_Violencias` as float64) as eje_1_violencias_pct,
    safe_cast(`Eje_2_Redes_de_apoyo` as float64) as eje_2_redes_de_apoyo_pct,
    safe_cast(`Eje_3_Bienestar_emocional` as float64) as eje_3_bienestar_emocional_pct,
    safe_cast(`Eje_4_Autonom_a` as float64) as eje_4_autonomia_pct,
    safe_cast(`Eje_5_Barreras` as float64) as eje_5_barreras_pct,
    safe_cast(`Puntaje_Eje_1_Violencias_0_30` as int64) as puntaje_eje_1_violencias,
    safe_cast(`Puntaje_Eje_2_Redes_de_apoyo_0_20` as int64) as puntaje_eje_2_redes_de_apoyo,
    safe_cast(`Puntaje_Eje_3_Bienestar_emocional_0_20` as int64) as puntaje_eje_3_bienestar_emocional,
    safe_cast(`Puntaje_Eje_4_Autonom_a_0_15` as int64) as puntaje_eje_4_autonomia,
    safe_cast(`Puntaje_Eje_5_Barreras_0_151` as int64) as puntaje_eje_5_barreras,
    safe_cast(`Puntaje_total_0_100` as int64) as puntaje_total,

    -- ── Barreras (multiselect, hasta 3) ──
    json_value(`Marca_hasta_3_barreras_que_sientes_que_m_s_te_difi`, '$[0]') as barrera_1,
    json_value(`Marca_hasta_3_barreras_que_sientes_que_m_s_te_difi`, '$[1]') as barrera_2,
    json_value(`Marca_hasta_3_barreras_que_sientes_que_m_s_te_difi`, '$[2]') as barrera_3,

    -- ── Llamada 1 ──
    date(safe_cast(`L1_Hora_de_inico` as timestamp)) as l1_fecha_inicio,
    date(safe_cast(`L1_Hora_fin` as timestamp)) as l1_fecha_fin,
    safe_cast(`L1_Duraci_n_total_min` as int64) as l1_duracion_min,
    lower(trim(`L1_Canal`)) as l1_canal,
    lower(trim(`L1_Contacto_efectivo`)) as l1_contacto_efectivo,
    safe_cast(`L1_N_de_intento_de_contacto` as int64) as l1_intentos_contacto,
    lower(trim(`L1_Nivel_de_riesgo_final`)) as l1_nivel_riesgo_final,
    lower(trim(`L1_Alertas`)) as l1_alertas,
    date(safe_cast(`L1_Fecha_agendada_Llamada_2` as timestamp)) as l1_fecha_agendada_llamada_2,
    lower(trim(`Estado_del_caso_Llamada_1`)) as estado_del_caso_llamada_1,

    -- ── Llamada 2 ──
    date(safe_cast(`L2_Hora_inicio` as timestamp)) as l2_fecha_inicio,
    date(safe_cast(`L2_Hora_fin` as timestamp)) as l2_fecha_fin,
    safe_cast(`L2_Duraci_n_total_min` as int64) as l2_duracion_min,
    lower(trim(`L2_Canal`)) as l2_canal,
    lower(trim(`L2_Contacto_efectivo`)) as l2_contacto_efectivo,
    safe_cast(`L2_N_de_intento_de_contacto` as int64) as l2_intentos_contacto,
    lower(trim(`L2_Alertas`)) as l2_alertas,
    lower(trim(`L2_Estado_del_proceso_de_empleabilidad`)) as l2_estado_empleabilidad,
    nullif(array_to_string(json_value_array(`L2_Remisi_n_tipo1`), ', '), '') as l2_remision_tipo,
    lower(trim(`L2_Remisi_n_activaci_n_verificada`)) as l2_remision_activacion_verificada,

    -- ── Cierre ──
    lower(trim(`Estado_final_del_caso`)) as estado_final_del_caso,
    -- TODO: definicion de "acompañamiento completado" en v2 pendiente de
    -- confirmar con coordinacion psicosocial. Mientras tanto, false.
    false as psicosocial_completada,

    safe_cast(_loaded_at as timestamp) as _loaded_at,
    safe_cast(Modified_Time as timestamp) as modified_time,
from {{ source('zoho_raw_ruta_mujer', 'psicosocial_rutam_v2') }}
