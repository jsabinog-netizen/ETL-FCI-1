# Ruta Mujer — cambios ETL del 10 de septiembre de 2026

Rama: `ruta-mujer`, creada desde la rama local `ruta_mujer`.
Las seis tareas están implementadas y materializadas en BigQuery.

## Validación

- Extracción y carga: **14 OK, 0 fallidos**. `getFields` reconoció todos los campos de los 14 módulos; ningún api_name rechazado.
- Build del bloque A, antes de editar dbt: **PASS=66 WARN=0 ERROR=0 SKIP=0**.
- Build final: **PASS=95 WARN=0 ERROR=0 SKIP=0**, `Completed successfully`: 14 vistas, 10 tablas y 71 tests.
- Tres pruebas de regresión del cargador correctas; verifican texto, lookup/nulo y aislamiento de otros proyectos/módulos.
- SQL real validado con datos sintéticos: 11 límites de edad, 6 escenarios postvinculación y 2 de mitigación, todos correctos.
- `fct_ruta_mujer`: **536 filas = 536 documentos únicos**. Las 11 columnas requeridas existen.
- Cohortes: **corte 1: 535; corte 2: 1**, sin nulos.
- `Corte` presente en las 14 tablas raw. Los 10 marts tienen tests de valores aceptados con `severity: warn`.
- Ningún mart expone TIMESTAMP. Mitigación tiene **51 columnas**, `valor_mitigacion` NUMERIC y fechas DATE.
- Postvinculación: **1 registro, 0 alertas vencidas, 1 discrepancia entre estado manual y calculado**; Empresa conservada en ese registro.
- Mitigación: **0 filas**. Los tests de datos pasan sobre tabla vacía; queda pendiente validar formatos reales cuando lleguen registros.

## Resultado por tarea

Se siguió el orden por bloques de la especificación. El build final integrado valida todas las tareas; no se ejecutaron seis builds individuales.

| Tarea | Archivos / resultado | Build final compartido |
|---|---|---|
| 1. Corte en extracción | `config.py`, solo MODULES_RUTA_MUJER; 14/14 módulos | PASS=95 / WARN=0 / ERROR=0 |
| 2. Propagación | 14 SQL y 14 YAML de staging; marts con SELECT explícito y YAML de los 10 marts | PASS=95 / WARN=0 / ERROR=0 |
| 3. Concepto | `marts/fct_ruta_mujer.sql` y `_fct_ruta_mujer.yml`; dentro del STRUCT del último evento | PASS=95 / WARN=0 / ERROR=0 |
| 4. Postvinculación | `config.py`, staging SQL/YAML, `fct_postvinculacion_rm.sql`, `_fct_postvinculacion.yml`; alertas de 20/25 días | PASS=95 / WARN=0 / ERROR=0 |
| 5. Mitigación | `config.py`, staging SQL/YAML, `fct_mitigacion_rm.sql`, `_fct_mitigacion.yml`; listo para poblarse | PASS=95 / WARN=0 / ERROR=0 |
| 6. Edad | `fct_ruta_mujer.sql`, `_fct_ruta_mujer.yml`; siete rangos y test warn | PASS=95 / WARN=0 / ERROR=0 |

Las rutas de modelos son relativas a `fci_dbt/models/ruta_mujer`.

## Adaptaciones necesarias al repositorio real

- `--modulos` no existe. Se ejecutó `python main.py ruta_mujer`, y después se recargó únicamente Postvinculación mediante `load_module` para aplicar la corrección de Empresa.
- El cargador agrega `id` automáticamente. Se omitió de las listas de config para evitar columnas duplicadas; sigue presente en raw y staging.
- Los conteos reales difieren del documento: Inscripción 40 campos, Vacantes 50, Postvinculación 34 y Mitigación 39. Todos cumplen el límite.
- `ensure_table` no evoluciona tablas existentes. Se agregó y ejecutó `scripts/migrar_esquema_ruta_mujer.py`, idempotente y aditivo, limitado a las 14 tablas raw de `proyecto_ruta_mujer`. No elimina columnas antiguas ni registros.
- Empresa de Postvinculación llega como texto, pero el esquema compartido la clasifica JSON. `loader.py` serializa ese texto como escalar JSON exclusivamente cuando proyecto=`ruta_mujer` y módulo=`Postvinculaci_n_Colsub`; el staging lee nombre de lookup o escalar JSON. Las pruebas verifican que otros proyectos y módulos conservan su comportamiento.
- Los archivos `fct_asistencia.sql` y `fct_preregistro.sql` se renombraron con `_rm`, alineándolos con sus YAML existentes y activando sus tests. Power BI debe usar `fct_asistencia_rm` y `fct_preregistro_rm`.
- BigQuery conserva las dos tablas históricas sin `_rm`; no forman parte de los 10 modelos activos ni se actualizarán en builds futuros. No se eliminaron objetos existentes.
- `nivel_educativo_normalizado` se conservó exactamente. El único cambio al SQL de Inscripción es agregar `corte`.
- No se cambiaron modelos, configuración de módulos ni workflows de Colsubsidio/GIZ. Tampoco extractor, metadata, reconciliación o paquetes dbt.

## Inventario de marts activos

| Mart | Filas |
|---|---:|
| `dim_vacantes_rm` | 164 |
| `fct_agenda_comercial_rm` | 109 |
| `fct_agenda_orientacion_rm` | 5 |
| `fct_asistencia_rm` | 220 |
| `fct_formacion_rm` | 516 |
| `fct_intermediacion_rm` | 944 |
| `fct_mitigacion_rm` | 0 |
| `fct_postvinculacion_rm` | 1 |
| `fct_preregistro_rm` | 701 |
| `fct_ruta_mujer` | 536 |

## Revisión cuando lleguen mitigaciones

No se ejecutaron consultas exploratorias de datos reales para una tabla vacía.

1. Comparar `valor_mitigacion_raw` con `valor_mitigacion`: la limpieza asume pesos enteros; valores con centavos podrían inflarse por 100.
2. Revisar categorías de `barrera_consolidada` y `servicio_consolidado`; normalizar variantes si aparecen.
3. Revisar la distribución de `etapa_mitigacion`: si domina `Sin clasificar`, confirmar el diligenciamiento de los checks de dispersión.

```sql
select valor_mitigacion_raw, valor_mitigacion
from `zoho-bq-pipeline-492116.proyecto_ruta_mujer.fct_mitigacion_rm`
where valor_mitigacion_raw is not null limit 20;

select barrera_consolidada, count(*) as n
from `zoho-bq-pipeline-492116.proyecto_ruta_mujer.fct_mitigacion_rm`
group by 1 order by 2 desc;

select servicio_consolidado, count(*) as n
from `zoho-bq-pipeline-492116.proyecto_ruta_mujer.fct_mitigacion_rm`
group by 1 order by 2 desc;

select etapa_mitigacion, count(*) as n
from `zoho-bq-pipeline-492116.proyecto_ruta_mujer.fct_mitigacion_rm`
group by 1;
```

## Reproducir verificaciones

Usar el entorno virtual `ETL-FCI/Scripts`, con dbt-core 1.11.12 y dbt-bigquery 1.11.3.

```powershell
.\ETL-FCI\Scripts\python.exe -m unittest test_ruta_mujer_loader
.\ETL-FCI\Scripts\python.exe scripts/probar_reglas_ruta_mujer.py
.\ETL-FCI\Scripts\dbt.exe build --project-dir fci_dbt --select path:models/ruta_mujer
.\ETL-FCI\Scripts\python.exe scripts/verificar_ruta_mujer.py
```

Evidencias locales (ignoradas por Git): `logs/ruta_mujer_pipeline_cambios.log`, `logs/ruta_mujer_build_final.log`, `logs/ruta_mujer_fields_verificados.json`, `logs/ruta_mujer_verificacion_final.json`.

## Archivos cambiados

- `config.py`
- `fci_dbt/models/ruta_mujer/marts/_dim_vacantes_rm.yml`
- `fci_dbt/models/ruta_mujer/marts/_fct_agenda_comercial_rm.yml`
- `fci_dbt/models/ruta_mujer/marts/_fct_agenda_orientacion_rm.yml`
- `fci_dbt/models/ruta_mujer/marts/_fct_asistencia.yml`
- `fci_dbt/models/ruta_mujer/marts/_fct_formacion_rm.yml`
- `fci_dbt/models/ruta_mujer/marts/_fct_intermediacion_rm.yml`
- `fci_dbt/models/ruta_mujer/marts/_fct_mitigacion.yml`
- `fci_dbt/models/ruta_mujer/marts/_fct_postvinculacion.yml`
- `fci_dbt/models/ruta_mujer/marts/_fct_preregistro.yml`
- `fci_dbt/models/ruta_mujer/marts/_fct_ruta_mujer.yml`
- `fci_dbt/models/ruta_mujer/marts/fct_agenda_comercial_rm.sql`
- `fci_dbt/models/ruta_mujer/marts/fct_agenda_orientacion_rm.sql`
- `fci_dbt/models/ruta_mujer/marts/fct_asistencia_rm.sql`
- `fci_dbt/models/ruta_mujer/marts/fct_mitigacion_rm.sql`
- `fci_dbt/models/ruta_mujer/marts/fct_postvinculacion_rm.sql`
- `fci_dbt/models/ruta_mujer/marts/fct_preregistro_rm.sql`
- `fci_dbt/models/ruta_mujer/marts/fct_ruta_mujer.sql`
- `fci_dbt/models/ruta_mujer/staging/_stg_agenda_orientadores_rutam.yml`
- `fci_dbt/models/ruta_mujer/staging/_stg_asist_pres_rutam.yml`
- `fci_dbt/models/ruta_mujer/staging/_stg_colocaci_n_colsubsidios.yml`
- `fci_dbt/models/ruta_mujer/staging/_stg_formaci_n_colsubsidios.yml`
- `fci_dbt/models/ruta_mujer/staging/_stg_ge_agendamiento.yml`
- `fci_dbt/models/ruta_mujer/staging/_stg_ge_vacantes_colsubsidios.yml`
- `fci_dbt/models/ruta_mujer/staging/_stg_inscripci_n_colsubsidios.yml`
- `fci_dbt/models/ruta_mujer/staging/_stg_intermediaci_n_ruta_m.yml`
- `fci_dbt/models/ruta_mujer/staging/_stg_mitigaci_n_colsubsidios.yml`
- `fci_dbt/models/ruta_mujer/staging/_stg_orientaci_n_colsubsidios.yml`
- `fci_dbt/models/ruta_mujer/staging/_stg_postvinculaci_n_colsub.yml`
- `fci_dbt/models/ruta_mujer/staging/_stg_pre_registro_empresarial.yml`
- `fci_dbt/models/ruta_mujer/staging/_stg_pre_registro_rutam.yml`
- `fci_dbt/models/ruta_mujer/staging/_stg_psicosocial_rutam.yml`
- `fci_dbt/models/ruta_mujer/staging/stg_agenda_orientadores_rutam.sql`
- `fci_dbt/models/ruta_mujer/staging/stg_asist_pres_rutam.sql`
- `fci_dbt/models/ruta_mujer/staging/stg_colocaci_n_colsubsidios.sql`
- `fci_dbt/models/ruta_mujer/staging/stg_formaci_n_colsubsidios.sql`
- `fci_dbt/models/ruta_mujer/staging/stg_ge_agendamiento.sql`
- `fci_dbt/models/ruta_mujer/staging/stg_ge_vacantes_colsubsidios.sql`
- `fci_dbt/models/ruta_mujer/staging/stg_inscripci_n_colsubsidios.sql`
- `fci_dbt/models/ruta_mujer/staging/stg_intermediaci_n_ruta_m.sql`
- `fci_dbt/models/ruta_mujer/staging/stg_mitigaci_n_colsubsidios.sql`
- `fci_dbt/models/ruta_mujer/staging/stg_orientaci_n_colsubsidios.sql`
- `fci_dbt/models/ruta_mujer/staging/stg_postvinculaci_n_colsub.sql`
- `fci_dbt/models/ruta_mujer/staging/stg_pre_registro_empresarial.sql`
- `fci_dbt/models/ruta_mujer/staging/stg_pre_registro_rutam.sql`
- `fci_dbt/models/ruta_mujer/staging/stg_psicosocial_rutam.sql`
- `loader.py`
- `scripts/migrar_esquema_ruta_mujer.py`
- `test_ruta_mujer_loader.py`
- `scripts/verificar_ruta_mujer.py`
- `scripts/probar_reglas_ruta_mujer.py`
- `docs/ruta_mujer_cambios_2026-09-10.md`
