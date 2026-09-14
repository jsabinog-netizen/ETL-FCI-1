# Pipelines, trazabilidad y guardrails

Cambios preparados en `codex/pipeline-guardrails`, desde `main` de `jsabinog-netizen/ETL-FCI-1`. Se incorporaron como base las ediciones locales de loader.py y reconciliar.py y el script de frescura aportado por Jorge.

## Resultado

- El cargador intenta todos los módulos y proyectos solicitados y luego falla si hubo errores. Archivos faltantes e IDs ausentes en cualquier registro lanzan excepción antes del MERGE. Los fallos registran status `error` sin avanzar el watermark.
- Una extracción incompleta lanza excepción después de intentar los módulos restantes, impidiendo que main o reconciliar consuman archivos anteriores. Para full refresh se rechaza un checkpoint previo: debe revisarse antes de reiniciar una reconciliación.
- La reconciliación registra `reconciled`, `reconcile_blocked`, `reconcile_skipped` o `reconcile_error`. Los fallos de lectura, JSON, IDs o BigQuery se propagan. El guardrail conserva su MERGE sin DELETE cuando bloquea un borrado. El orquestador no ejecuta dbt si hubo módulos fallidos, bloqueados u omitidos; una reconciliación parcial ya no se declara completa.
- La auditoría falla explícitamente si BigQuery rechaza la inserción de metadata.
- El CLI de reconciliación exige exactamente un proyecto válido antes de extraer. Se eliminó el NameError del manejo de fallos.
- Frescura usa exclusivamente `success`, `empty`, `error` en ambas consultas. Selecciona el último estado por módulo y falla ante módulos faltantes o con error: ya no permite que éxitos repetidos o un porcentaje global oculten fallos. No requiere cambios al esquema de metadata.
- En Actions se registra `PIPELINE_STARTED_AT` antes de main y se exige auditoría posterior a ese instante. Frescura corre también si main falla, sin borrar el fallo original del job. Fuera de Actions, el chequeo toma una ventana de dos horas anterior a la última actividad y una tolerancia máxima de 24h. Esa modalidad es un chequeo de salud reciente, no una identificación exacta de corrida.

## Validaciones

- 38 pruebas Python aprobadas: guardrails nuevos y regresiones de extracción, paginación, HTTP y backoff. Sin llamadas reales a Zoho ni borrados.
- Siete escenarios de las consultas SQL reales probados en BigQuery con datos sintéticos y sin crear tablas: sano, éxitos repetidos con módulo ausente, error reciente, solo reconciliación, reconciliación posterior a un error, éxitos anteriores al job y ejecución actual.
- `python reconciliar.py`, `python reconciliar.py inventado` y `python scripts/verificar_frescura.py inventado`: exit 1, sin extraer.
- Frescura real de Colsubsidio: exit 0, 16/16 módulos, última actividad 2026-09-14 15:04:52 UTC (10:04:52 Colombia).
- Frescura real de GIZ: exit 0, 10/10 módulos, última actividad 2026-09-14 10:27:56 UTC (05:27:56 Colombia). Al verificar habían pasado unas seis horas: cumple MAX_HORAS=24, pero no confirma ejecución horaria continua.
- Sintaxis Python y YAML válidas. Configuración, modelos dbt, horarios y nombres de secrets existentes sin cambios.

Build de Colsubsidio y GIZ: **PASS=190, WARN=14, ERROR=0, TOTAL=204**, exit 0. Duración: 215.9 segundos. Las advertencias provienen de tests existentes de calidad de datos; no se modificaron esos modelos ni sus tests.

| Test con advertencia | Filas observadas |
| --- | --- |
| `accepted_values_stg_calidad_giz_estado_calidad__aprobado__rechazado__en_revisi_n__pendiente` | 1 |
| `accepted_values_stg_colocacion_giz_colocacion_completada__true__false` | 1 |
| `accepted_values_stg_formacion_giz_nombre_curso__t_cnico_en_confecci_n__t_cnico_en_gastronom_a__lengua_de_se_as__intermediaci_n_laboral__estrategias_comerciales` | 8 |
| `accepted_values_stg_orientacion_giz_orientacion_completada__true__false` | 2 |
| `unique_stg_postvinculacion_giz_documento` | 7 |
| `accepted_values_stg_mitigacion_giz_tipo_mitigacion__pago_de_colocacion__pago_de_formacion` | 1 |
| `accepted_values_stg_registro_giz_inscripcion_completada__true__false` | 1 |
| `accepted_values_fct_formacion_giz_nombre_curso__t_cnico_en_confecci_n__t_cnico_en_gastronom_a__lengua_de_se_as__intermediaci_n_laboral__estrategias_comerciales` | 8 |
| `accepted_values_fct_mitigacion_giz_tipo_mitigacion__pago_de_formacion__pago_de_colocacion` | 1 |
| `accepted_values_fct_ruta_giz_estado_ruta__0_Sin_completar__1_Registrado_a__2_Orientado_a__3_Intermediado_a__4_Colocado_a` | 1 |
| `accepted_values_fct_ruta_giz_tiene_orientacion__S___No` | 2 |
| `accepted_values_fct_ruta_giz_tipo_participante__migrante_venezolano_a__colombiano_a_retornado_a__comunidad_de_acogida_nacional_colombiano_a_` | 4 |
| `not_null_fct_ruta_giz_tiene_orientacion` | 18 |
| `relationships_fct_servicios_nit__nit__ref_dim_empresa_` | 36 |


## Workflows

| Proyecto | Estado preparado |
| --- | --- |
| Colsubsidio | main.py colsubsidio, ocho horarios conservados, concurrencia existente y frescura añadida |
| GIZ | main.py giz, horario cada hora conservado, concurrencia pipeline-giz y frescura añadidas |
| Ruta Mujer | No se creó; requiere integrar primero su código a main |

Estos son cambios locales en una rama. No se hizo push, merge ni dispatch de Actions, por lo que todavía no están activos en producción. El build y la metadata respaldan las verificaciones de datos; las rutas nuevas de carga y error fueron probadas con mocks para ambos proyectos. No se ejecutó una carga completa nueva ni una reconciliación con borrado.

## Pendientes y recomendaciones

### Advertencias que requieren investigación de modelo

Los 14 WARN corresponden al build combinado: 13 a GIZ y 1 a Colsubsidio. Se documentan sin corregir modelos:

- **GIZ — unique_stg_postvinculacion_giz_documento (7 resultados):** documentos duplicados en un staging cuyo contrato declara documento único. El test unique devuelve grupos de claves duplicadas, por lo que 7 resultados no equivale necesariamente a solo 7 filas físicas. Revisar si el grano esperado es persona o seguimiento antes de decidir una deduplicación.
- **GIZ — not_null_fct_ruta_giz_tiene_orientacion (18 filas):** un indicador Sí/No no debería quedar nulo según el contrato actual. Se había planteado un CASE incompleto como hipótesis; el SQL real expone `o.orientacion_completada AS tiene_orientacion` desde el join, sin CASE ni COALESCE en esa asignación. Hay que revisar registros sin orientación asociada y valores nulos en la fuente, y decidir la semántica de ausencia.
- **Colsubsidio — relationships_fct_servicios_nit__nit__ref_dim_empresa_ (36 resultados):** servicios con NIT sin correspondencia en dim_empresa. El test está en `models/colsubsidio/marts/_fct_servicios.yml`, no en GIZ. Pueden quedar excluidos en cruces internos o filtros del dashboard, o aparecer bajo una categoría en blanco según el modelo de Power BI. El test por sí solo no demuestra que ya hayan desaparecido de un visual. Revisar integridad referencial y tratamiento de servicios huérfanos.


- Existe una llamada equivalente a run_load() sin argumentos: main.py sin proyecto usa projects=None. Ahora se preserva la posibilidad de intentar ambos proyectos y se reportan sus fallos al terminar.
- Los entrypoints directos de extractor.py y loader.py siguen apuntando a GIZ. Recomiendo exigir proyecto explícito si se desea conservar el uso independiente; no se cambiaron en esta tanda.
- Un flag --modulos validado contra PROJECTS resulta útil para recargas puntuales. Sigue pendiente, sin implementación.
- Conviene generalizar la migración como migrar_esquema.py <proyecto>, aditiva y con comprobación de tipos. No existe migración de Colsubsidio/GIZ en este main y no se creó aquí.
- El cron de GIZ declara explícitamente cada hora; el historial local consultado no permite determinar si fue una decisión de producción o de desarrollo. Se mantuvo. Prefijos ZOHO_GIZ y ZOHO diferentes no prueban por sí solos si las cuentas o cuotas son compartidas.
- Se observó otra deuda previa del extractor: extract_module no pasa since a fetch_page. No se modificó el alcance de extracción en esta tanda.

## Archivos

Modificados: loader.py, metadata.py, extractor.py, reconciliar.py, test_run_extraction.py, .github/workflows/pipeline.yml, .github/workflows/pipeline_giz.yml.

Creados/incorporados: scripts/verificar_frescura.py, test_guardrails.py, CLAUDE.md (recuperado del contexto de ruta-mujer, con repositorio corregido), docs/pipeline_guardrails.md.

## Diagnóstico de since previo al merge — 14-sep-2026

Confirmado en la rama de guardrails y en `origin/main` recién consultado (854d51a). No se modificó código:

1. El valor se calcula en **run_extraction**, no en extract_module:

```python
module_since = since or get_watermark(client, project_name, module_name, project_cfg["dataset_id"])
registros = extract_module(auth, module_name, fields, since=module_since)
```

2. extract_module lo recibe y solo lo usa para escribir el mensaje de modo incremental. No lo reenvía:

```python
registros,mas_paginas,_token = request_with_backoff(
    lambda:fetch_page(auth, module_name=module_name, fields=fields,page=page)
)
```

3. fetch_page tiene since=None por defecto, por lo que no ejecuta este bloque:

```python
if since is not None:
    parametros["sort_by"] = "Modified_Time"
    parametros["sort_order"] = "asc"
    headers["If-Modified-Since"] = since
```

La request es GET con fields/page/per_page; no hay body ni otro filtro temporal. ZohoAuth.get_header solo aporta Authorization. El error ya está en main remoto: la ruta habitual solicita registros sin filtro incremental aunque el log diga lo contrario.

El cargador sigue calculando max(Modified_Time) y guardándolo mediante write_run(..., "success", ..., watermark). get_watermark lo consulta y lo entrega, pero el valor se pierde antes de la llamada HTTP. Por tanto, existen watermarks almacenados que no filtran las solicitudes.

### Volumen observado

Se consultaron las últimas cinco cargas success/empty por módulo y COUNT(*) actual de raw, sin extraer Zoho ni escribir tablas. La última secuencia de los 16 módulos terminó entre 2026-09-14 20:17:43 y 20:19:16 UTC: **1.071 filas cargadas frente a 1.076 filas raw**, con igualdad en **15/16 módulos**. La suma de los promedios por módulo de las últimas cinco cargas es 1.001,2 filas; no se atribuye a cinco corridas exactas porque metadata no tiene run_id.

| Módulo | Última carga | Total raw | Mínimo–máximo últimas 5 cargas |
| --- | --- | --- | --- |
| Agenda_acompa_amiento | 379 | 379 | 328–379 |
| Agenda_inscripci_n | 44 | 49 | 44–49 |
| Asesor_a | 51 | 51 | 42–51 |
| Asesor_a_vacantes | 84 | 84 | 75–84 |
| Asistencia_Formaci_n_Com | 29 | 29 | 29–29 |
| Asistencia_Formaci_n_LS | 32 | 32 | 32–32 |
| Diagn_stico | 108 | 108 | 93–108 |
| Intermediaci_n_RE | 31 | 31 | 31–31 |
| Modulo_1 | 12 | 12 | 12–12 |
| Modulo_2 | 12 | 12 | 12–12 |
| Participantes_Bootcamps | 0 | 0 | 0–0 |
| Productos_Componente_IV | 6 | 6 | 6–6 |
| Profesional | 10 | 10 | 10–10 |
| Registro_empresas | 147 | 147 | 133–147 |
| Sensibilizaci_n | 124 | 124 | 102–124 |
| Transferencia | 2 | 2 | 1–2 |

Asistencia_Formaci_n_Com, Asistencia_Formaci_n_LS e Intermediaci_n_RE repiten 29, 32 y 31 registros respectivamente en las cinco últimas cargas; sus últimos watermarks siguen en 22-jul-2026. Esto respalda la repetición de datos sin cambios. Agenda_inscripci_n es la excepción (44 cargados frente a 49 raw); un MERGE sin borrado puede conservar registros históricos, pero no se determinó aquí la causa exacta de esas cinco filas.

Raw no es una medición independiente del total vigente en Zoho. La igualdad de conteos es evidencia de apoyo; la confirmación de que no se aplica el filtro proviene del recorrido del código. La corrección debe priorizarse como un bug funcional del incremental, no solo como optimización. No se ejecutó el fix.

### main.py sin argumentos y cambios locales

Recomendación: exigir un proyecto explícito en main.py y, si se necesita ejecución global, ofrecer una opción deliberada como --all. No modificar el comportamiento implícito sin aprobación. Esta rama/main conoce dos proyectos; tras incorporar Ruta Mujer serán tres.

Antes de este cambio documental, el workspace estaba limpio, en codex/pipeline-guardrails (1837313), con un único worktree registrado. No había cambios staged ni unstaged en pipeline.yml, extractor.py o loader.py. Los cambios de guardrails de esos archivos ya están en esta rama. No se pueden verificar buffers sin guardar del editor ni otro clon no registrado: de existir, guardar sus diferencias por archivo antes de sustituir o cambiar de rama. No usar reset --hard ni descartar copias locales para resolver el solapamiento. No se hizo merge ni push.
