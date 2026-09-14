# Ruta Mujer — Tanda 2

Validación ejecutada el 14-sep-2026 en `zoho-bq-pipeline-492116.proyecto_ruta_mujer`, rama `ruta-mujer`.

## Implementación y recarga

- Formación: 14 campos añadidos (12 solicitados más `Fecha_curso_2` y `Fecha_curso_blandas`, autorizados al detectar que faltaban). El módulo tiene 40 campos, por debajo de 50.
- Migración de esquema antes de reextraer, conservando datos. Se añadieron también las observaciones de las dos agendas.
- Recarga completa con `extract_module(..., since=None)` y `load_module`, con MERGE por id sin borrado: formación 525 registros (5 insertados, 520 actualizados); agenda comercial 132 (18 insertados, 114 actualizados); orientación 5 (0 insertados, 5 actualizados).
- Todos los campos configurados fueron recibidos de Zoho y verificados en el esquema de BigQuery. Ningún api_name rechazado ni columna nueva ausente.
- Staging de formación ancho; mart desanidado con UNION ALL de seis slots. Clave `id_curso = id de Zoho + ':' + slot`. Texto de cursos y observaciones conserva mayúsculas; categóricos normalizados; fechas de curso DATE.
- `estado_formacion_mujer` y `formada` consideran cualquier formación completada. El registro más reciente sigue proporcionando los atributos de formación. La vía de ingreso conserva el cruce por documento.
- Las nueve fechas del mart central ya eran DATE antes del cambio; no fue necesario corregirlas.
- Configuración de Colsubsidio y GIZ idéntica a HEAD inicial; únicamente se añadieron campos en los tres módulos autorizados de Ruta Mujer. Sin cambios en extractor.py, metadata.py, loader.py ni modelos de otros proyectos.

## Validación

Build final: **PASS=101 · WARN=0 · ERROR=0 · SKIP=0** (14 vistas, 10 tablas y 77 tests). Comando: `dbt build --project-dir fci_dbt --select path:models/ruta_mujer`.

`dbt parse` pasó y las tres pruebas existentes de `test_ruta_mujer_loader` pasaron. Las pruebas SQL sintéticas del script nuevo verificaron los seis slots, un registro sin cursos, un registro completado seguido de uno pendiente, los tres estados y la vía de ingreso.

El primer build detectó que `accepted_values` convierte los valores de slot en literales STRING por defecto. Se agregó `arguments.quote: false` para compararlos con INT64, conservando `severity: warn`.

## Los siete resultados solicitados

### 1. Grano de persona

| filas | documentos |
| --- | --- |
| 539 | 539 |

El total actual es 539, frente a la referencia histórica de 536. No hay duplicación por joins.

### 2. Columnas nuevas

| column_name |
| --- |
| alguna_formacion_completada |
| estado_formacion_mujer |
| num_registros_formacion |
| tuvo_preregistro |
| via_de_ingreso |

### 3. Grano de curso

| filas | ids | personas |
| --- | --- | --- |
| 559 | 559 | 441 |

COUNTROWS pasó a **559**: **+43 (+8,33%)** respecto de las 516 filas de la especificación; **+39 (+7,50%)** respecto de las 520 observadas inmediatamente antes de esta ejecución. La recarga raw añadió 5 registros: la diferencia observada combina actualización de datos y cambio de grano.

Para personas usar `DISTINCTCOUNT(documento)`. El flag de completada pertenece al registro Zoho y se replica en sus cursos; no identifica cuál curso completó cada mujer.

### 4. Estados de formación

| estado_formacion_mujer | mujeres |
| --- | --- |
| Completada | 50 |
| Pendiente | 461 |
| Sin iniciar | 28 |

### 5. Vía de ingreso

| via_de_ingreso | mujeres |
| --- | --- |
| Con preregistro | 440 |
| Registro directo | 99 |

### 6. Etapas

| etapa_actual | mujeres |
| --- | --- |
| 0. Sin completar | 3 |
| 1. Registros | 14 |
| 2. Orientación | 160 |
| 3. Atención Psicosocial | 57 |
| 4. Formación | 6 |
| 5. Intermediación | 294 |
| 6. Colocación | 5 |

Postvinculación: 0 mujeres (no aparece en el GROUP BY). Las distribuciones de estados, vías y etapas suman 539.

### 7. Fechas

| column_name | data_type |
| --- | --- |
| fecha_colocacion | DATE |
| fecha_formacion | DATE |
| fecha_inscripcion | DATE |
| fecha_intermediacion | DATE |
| fecha_nacimiento | DATE |
| fecha_orientacion | DATE |
| fecha_postvinculacion | DATE |
| fecha_preregistro | DATE |
| fecha_registro_psicosocial | DATE |

## Distribución de cursos

| slot | tipo_curso | n |
| --- | --- | --- |
| 1 | técnica | 388 |
| 2 | técnica | 161 |
| 3 | técnica | 6 |
| 4 | técnica | 1 |
| 5 | blandas | 3 |
| 6 | blandas | 0 |

El slot 6 está implementado y su columna se recibió de Zoho; no contiene cursos en la fuente actual. La prueba sintética confirmó que genera una fila cuando tiene curso.

| curso | inscripciones | personas |
| --- | --- | --- |
| Formación Integral del Ser | 411 | 405 |
| Digitalización e Informática | 93 | 92 |
| Habilidades Verdes | 24 | 24 |
| Procesos de Calidad y Manejo de Procesos Básicos Contables | 20 | 18 |
| Procesos de Calidad y Manejo de Procesos Básicos contables | 8 | 8 |
| Conexión comunitaria | 2 | 2 |
| Gestión Productiva de Equipos de Trabajo | 1 | 1 |

Hay siete nombres exactos, con dos variantes que solo difieren en la mayúscula de “Contables/contables”. Se conserva `trim()` según la especificación; no se añadió una homologación de nombres.

## Observaciones de agendas

| agenda | filas | con_observaciones |
| --- | --- | --- |
| comercial | 132 | 30 |
| orientacion | 5 | 0 |

## Archivos

Creados:

- `scripts/verificar_tanda2_ruta_mujer.py`: verificaciones reproducibles y escenarios SQL sintéticos; solo consultas, sin escrituras en BigQuery.
- `docs/ruta_mujer_tanda2.md`: este informe.

Modificados:

- `config.py`
- `fci_dbt/models/ruta_mujer/README.md`
- `fci_dbt/models/ruta_mujer/marts/_fct_agenda_comercial_rm.yml`
- `fci_dbt/models/ruta_mujer/marts/_fct_agenda_orientacion_rm.yml`
- `fci_dbt/models/ruta_mujer/marts/_fct_formacion_rm.yml`
- `fci_dbt/models/ruta_mujer/marts/_fct_ruta_mujer.yml`
- `fci_dbt/models/ruta_mujer/marts/fct_agenda_comercial_rm.sql`
- `fci_dbt/models/ruta_mujer/marts/fct_agenda_orientacion_rm.sql`
- `fci_dbt/models/ruta_mujer/marts/fct_formacion_rm.sql`
- `fci_dbt/models/ruta_mujer/marts/fct_ruta_mujer.sql`
- `fci_dbt/models/ruta_mujer/staging/_stg_agenda_orientadores_rutam.yml`
- `fci_dbt/models/ruta_mujer/staging/_stg_formaci_n_colsubsidios.yml`
- `fci_dbt/models/ruta_mujer/staging/_stg_ge_agendamiento.yml`
- `fci_dbt/models/ruta_mujer/staging/stg_agenda_orientadores_rutam.sql`
- `fci_dbt/models/ruta_mujer/staging/stg_formaci_n_colsubsidios.sql`
- `fci_dbt/models/ruta_mujer/staging/stg_ge_agendamiento.sql`

La edición previa del usuario en `fct_ruta_mujer.sql` se conserva fuera de los commits de esta tanda. `claude..md` permanece sin seguimiento.

Los JSON de recarga y los scripts operativos temporales permanecen en `output/`, ignorado por Git. El resultado agregado completo se guarda en `output/tanda2_resultados.json`.

## Fuera de alcance

No se implementó Departamento_de_residencia: requiere crear el campo en Zoho o una decisión de negocio sobre una referencia DIVIPOLA. Tampoco se implementaron los campos de gestión de vacantes ausentes en Zoho ni se modificó la deuda técnica D1–D5.
