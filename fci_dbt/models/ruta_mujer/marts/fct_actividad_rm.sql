-- Grano: un registro de un modulo de persona de Zoho (actividad_id).
-- Une los modulos de la ruta con SOLO las columnas que aplican a todos,
-- y cada fila lleva el Corte de SU modulo (no el de la inscripcion).
-- Es la base del filtro unico de corte: dim_corte_rm -> fct_actividad_rm.
--
-- Contar registros: COUNTROWS con filtro de modulo.
-- Contar mujeres:   DISTINCTCOUNT(documento) con filtro de modulo.
-- Psicosocial: Corte 1 sale de v1 (solo corte = 'corte 1'; los registros
-- sin corte son cascarones de Corte 2) y Corte 2 sale de v2.

with actividad as (
    select 'preregistro' as modulo_key, '1. Pre-registro' as modulo, 'Pre_registro_RutaM' as modulo_zoho,
        id, documento, corte, date(created_time) as fecha_evento,
        coalesce(preinscripci_n_completad in ('si', 'sí', 'true'), false) as completado,
        cast(null as string) as estado
    from {{ ref('stg_pre_registro_rutam') }}

    union all
    select 'registro', '2. Registro', 'Inscripci_n_Colsubsidios',
        id, documento, corte, fecha_de_registro,
        coalesce(inscripci_n_completada in ('si', 'sí', 'true'), false),
        cast(null as string)
    from {{ ref('stg_inscripci_n_colsubsidios') }}

    union all
    select 'orientacion', '3. Orientación', 'Orientaci_n_Colsubsidios',
        id, documento, corte, fecha_de_orientaci_n,
        coalesce(orientaci_n_sociocupacion_completada in ('si', 'sí', 'true'), false),
        cast(null as string)
    from {{ ref('stg_orientaci_n_colsubsidios') }}

    union all
    select 'psicosocial', '4. Psicosocial', 'Psicosocial_RutaM',
        id, documento, corte, coalesce(fecha_inicio_acompanamiento_sc_1, date(created_time)),
        coalesce(acompa_amiento_psicosocial_completado in ('si', 'sí', 'true'), false),
        estado_actual_del_proceso
    from {{ ref('stg_psicosocial_rutam') }}
    where corte = 'corte 1'

    union all
    select 'psicosocial', '4. Psicosocial', 'Psicosocial_RutaM_v2',
        id, documento, corte, coalesce(l1_fecha_inicio, date(created_time)),
        coalesce(psicosocial_completada, false),
        estado_del_diagnostico
    from {{ ref('stg_psicosocial_rutam_v2') }}

    union all
    select 'formacion', '5. Formación', 'Formaci_n_Colsubsidios',
        id, documento, corte, coalesce(fecha_formaci_n, fecha_curso),
        coalesce(formaci_n_completada in ('si', 'sí', 'true'), false),
        cast(null as string)
    from {{ ref('stg_formaci_n_colsubsidios') }}

    union all
    select 'intermediacion', '6. Intermediación', 'Intermediaci_n_Ruta_M',
        id, documento, corte, fecha_intermediaci_n,
        coalesce(intermediaci_n_completada in ('si', 'sí', 'true'), false),
        estado
    from {{ ref('stg_intermediaci_n_ruta_m') }}

    union all
    select 'colocacion', '7. Colocación', 'Colocaci_n_Colsubsidios',
        id, documento, corte, fecha_de_vinculaci_n_laboral,
        fecha_de_vinculaci_n_laboral is not null,
        cast(null as string)
    from {{ ref('stg_colocaci_n_colsubsidios') }}

    union all
    select 'postvinculacion', '8. Postvinculación', 'Postvinculaci_n_Colsub',
        id, documento, corte, coalesce(fecha_llamada_seguimiento, fecha_inicio_contrato),
        fecha_llamada_seguimiento is not null,
        estado_caso
    from {{ ref('stg_postvinculaci_n_colsub') }}
)
select
    concat(modulo_key, '-', id) as actividad_id,
    id as registro_id,
    modulo,
    modulo_zoho,
    documento,
    corte,
    fecha_evento,
    completado,
    estado
from actividad
