# Ruta Mujer — Arquitectura y Reglas

GCP: `zoho-bq-pipeline-492116` · Dataset: `proyecto_ruta_mujer` · Grano central: 1 fila = 1 mujer.

## 1. Módulos Zoho (14) y Stagings (view)

| Módulo Zoho | Staging |
|---|---|
| `Pre_registro_RutaM` | `stg_pre_registro_rutam` |
| `Inscripci_n_Colsubsidios` | `stg_inscripci_n_colsubsidios` (dedup por documento) |
| `Orientaci_n_Colsubsidios` | `stg_orientaci_n_colsubsidios` |
| `Psicosocial_RutaM` | `stg_psicosocial_rutam` |
| `Intermediaci_n_Ruta_M` | `stg_intermediaci_n_ruta_m` |
| `Colocaci_n_Colsubsidios` | `stg_colocaci_n_colsubsidios` |
| `Formaci_n_Colsubsidios` | `stg_formaci_n_colsubsidios` |
| `GE_Vacantes_Colsubsidios` | `stg_ge_vacantes_colsubsidios` |
| `Pre_registro_Empresarial` | `stg_pre_registro_empresarial` |
| `Asist_Pres_RutaM` | `stg_asist_pres_rutam` |
| `Agenda_Orientadores_RutaM` | `stg_agenda_orientadores_rutam` |
| `GE_Agendamiento` | `stg_ge_agendamiento` |
| `Postvinculaci_n_Colsub` | `stg_postvinculaci_n_colsub` |
| `Mitigaci_n_Colsubsidios` | `stg_mitigaci_n_colsubsidios` |

## 2. Marts para Power BI (11, table)

| Mart | Grano y descripción |
|---|---|
| `fct_ruta_mujer` | 1 fila = 1 mujer. Central del programa. |
| `dim_vacantes_rm` | 1 vacante enriquecida con empresa y `rango_etario_vacante`. |
| `dim_empresas_rm` | 1 empresa deduplicada por NIT (`etapa_empresa` 1–4). |
| `fct_intermediacion_rm` | 1 evento de intermediación (`corte_evento`). |
| `fct_formacion_rm` | 1 inscripción a curso (`id_curso` = id + slot 1–6, `corte_evento`). |
| `fct_asistencia_rm` | 1 asistencia presencial a curso (`corte_evento`). |
| `fct_preregistro_rm` | 1 preregistro (`corte_evento`, `se_inscribio`). |
| `fct_agenda_comercial_rm` | 1 cita comercial con empresa (`corte_evento`). |
| `fct_agenda_orientacion_rm` | 1 cita de orientación con participante (`corte_evento`). |
| `fct_postvinculacion_rm` | 1 seguimiento post-contrato (alerta 20/25 días, `corte_evento`). |
| `fct_mitigacion_rm` | 1 apoyo económico/servicio entregado (`corte_evento`). |

## 3. Reglas Críticas de Arquitectura y Grano

- **Grano de persona sagrado:** En `fct_ruta_mujer`, `count(*)` = `count(distinct documento)`.
- **Pre-agregación de eventos N→1:** Intermediación y formación tienen N filas por mujer. Nunca hacer `LEFT JOIN` directo. Se colapsan antes del join:
  - Intermediación: `ARRAY_AGG(STRUCT(...) ORDER BY fecha DESC NULLS LAST, modified_time DESC, id DESC LIMIT 1)[OFFSET(0)]`.
  - Formación: `formacion_agg` (`COUNT(*)`, `MAX(completada)`), conservando atributos del último registro.
- **Deduplicación:** `QUALIFY ROW_NUMBER() OVER (PARTITION BY documento ORDER BY ... DESC NULLS LAST) = 1`.
- **Fechas:** Siempre `DATE` en marts. `TIMESTAMP`/`DATETIME` rompen el conector ADBC de Power BI. Auditoría: timestamp en staging, date en mart vía `SELECT * REPLACE`.
- **Cohortes transversales:**
  - `corte`: `corte 1` / `corte 2` en minúsculas en los 14 módulos.
  - `corte_evento`: En marts de evento, `>= '2026-09-01'` -> `'corte 2'`, else `'corte 1'`.
- **Etapas de la participante (`etapa_actual`):**
  `0. Sin completar` | `1. Registros` | `2. Orientación` | `3. Atención Psicosocial` | `4. Formación` | `5. Intermediación` | `6. Colocación` | `7. Postvinculación`.
- **Embudo de empresas (`dim_empresas_rm`):**
  `1. Solo registrada` -> `2. Agendada` -> `3. Con vacantes` -> `4. Intermediada`.
- **Rango etario de vacantes (`dim_vacantes_rm`):**
  `1. Hasta 25` … `5. Sin tope superior` | `7. Hasta X` | `8. Desde Y` | `9. Sin restricción`.
- **Normalización de sectores (`stg_ge_vacantes_colsubsidios`):**
  `json_value(Sector_econ_mico, '$[0]')` con regex a categorías estándar; no reconocidos a `'Otro'`.
- **Tests dbt:** Configurados con `severity: warn` para no bloquear builds por calidad de datos.
- **Power BI:** Medidas con `DISTINCTCOUNT(documento)` para personas; marts son la única fuente.
