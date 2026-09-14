# ETL FCI — Contexto para agentes de codificación

> Leé este archivo completo antes de tocar cualquier cosa.
> Última actualización: 9-sep-2026.

---

## Quién soy y cómo trabajo

Soy Jorge Sabino, practicante en FCI, a cargo del área de datos y BI.

- **Un concepto a la vez:** entender → implementar → probar → seguir.
- **Esqueletos con comentarios**, no soluciones completas para copiar.
- **Español.** Validación-first. Advertime de errores, no me des la razón.
- **Un cambio lógico = un commit** (Conventional Commits). Build verde antes de pushear.
- **Colsubsidio y GIZ están en producción y no se tocan** sin verificar que siguen igual.
- **No inventes api_names de Zoho ni nombres de modelos.** Si algo no existe, reportalo — no busques un nombre parecido. Este fue el error más costoso del proyecto.

---

## Stack

```
Zoho CRM v8 (OAuth2) → Python → Google BigQuery → dbt → Power BI
Orquestación: GitHub Actions
GCP project: zoho-bq-pipeline-492116  ·  región US (multi)
Repo: github.com/jsabinog-netizen/ETL-FCI-1
dbt: 1.11.12 + dbt-bigquery 1.11.3 (pinneado; 1.12.0 rompe compat. binaria)
```

---

## Los tres proyectos

| | Colsubsidio | GIZ | Ruta Mujer |
|---|---|---|---|
| Programa | Ruta Empresarial | Talento sin Fronteras | Ruta Mujer |
| Grano | empresa | persona | persona |
| Dataset BQ | `colsubsidio_ruta_empresas` | `proyecto_giz` | `proyecto_ruta_mujer` |
| env_prefix | `ZOHO` | `ZOHO_GIZ` | `ZOHO` (misma cuenta que Colsubsidio) |
| arg main.py | `colsubsidio` | `giz` | `ruta_mujer` |
| Estado | Producción | Pipeline completo, dashboard en curso | Pipeline completo, dashboard en construcción |

---

## Estructura del repo

```
ETL-FCI/
├── config.py          # PROJECT_ID, PROJECTS dict, MODULES_* por proyecto
├── main.py            # python main.py <proyecto> [--modulos <Modulo>]
├── auth.py            # ZohoAuth(env_prefix) — OAuth2
├── extractor.py       # extracción con fields explícitos
├── loader.py          # carga a BigQuery, param. por dataset_id
├── metadata.py        # watermarks, param. por dataset_id
├── reconciliar.py     # ⚠️ aún hardcodeado a Colsubsidio
└── fci_dbt/
    └── models/
        ├── colsubsidio/
        ├── giz/
        └── ruta_mujer/
            ├── staging/   _sources.yml · _stg_*.yml · stg_*.sql
            └── marts/     _*.yml · fct_*.sql · dim_*.sql
```

**`MODULES_*` es un `dict`**, no una lista: `{"Nombre_Modulo": ["Campo1", "Campo2", ...]}`.

---

## Ruta Mujer — estado real

### Módulos Zoho (14) y sus stagings

Los nombres de staging derivan del snake_case del módulo Zoho, **no** de un alias corto.

| Módulo Zoho | Staging |
|---|---|
| `Pre_registro_RutaM` | `stg_pre_registro_rutam` |
| `Inscripci_n_Colsubsidios` | `stg_inscripci_n_colsubsidios` |
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

### Marts (10)

| Mart | Grano | Filas aprox. |
|---|---|---|
| `fct_ruta_mujer` | **1 fila = 1 mujer** | 535 |
| `fct_intermediacion_rm` | 1 evento de intermediación | 887 |
| `fct_formacion_rm` | 1 inscripción a curso | 516 |
| `fct_asistencia_rm` | 1 asistencia a curso | 220 |
| `fct_preregistro_rm` | 1 preregistro | 695 |
| `fct_agenda_comercial_rm` | 1 cita con empresa | 109 |
| `fct_agenda_orientacion_rm` | 1 cita con participante | 5 |
| `dim_vacantes_rm` | 1 vacante (+ datos de empresa) | 111 |
| `fct_postvinculacion_rm` | 1 seguimiento post-contrato | 0+ |
| `fct_mitigacion_rm` | 1 apoyo entregado | 0 |

No existe `dim_empresas_rm`: los datos de empresa se resuelven dentro de `dim_vacantes_rm` con `COALESCE` sobre el lookup `Buscar_empresa`.

Los dos últimos marts pueden estar vacíos — es estado del dato en Zoho, no un bug.

El mart de agendamientos **estaba unificado** (`fct_agendamientos_rm` con `UNION ALL` y un campo `tipo`) y se dividió en dos: la mitad de las columnas no aplicaba a la mitad de las filas, y una tarjeta de "Total Citas" sin filtro sumaba reuniones con empresas junto a sesiones con participantes.

### `fct_ruta_mujer` — el mart central

Una fila por mujer. **El grano es sagrado:** `count(*)` debe igualar `count(distinct documento)`.

```
Base:  stg_inscripci_n_colsubsidios  (clave: documento = Name)
LEFT JOIN stg_orientaci_n_colsubsidios     (dedup por QUALIFY)
LEFT JOIN stg_psicosocial_rutam            (dedup por QUALIFY)
LEFT JOIN stg_colocaci_n_colsubsidios      (dedup por QUALIFY)
LEFT JOIN stg_pre_registro_rutam           (dedup por QUALIFY)
LEFT JOIN intermediacion_agg               (ARRAY_AGG + STRUCT, última intermediación)
```

**Intermediación y formación tienen N filas por mujer.** Nunca hacer LEFT JOIN directo — multiplica el grano. Se colapsan antes con `ARRAY_AGG(STRUCT(...) ORDER BY fecha DESC LIMIT 1)[OFFSET(0)]`.

Regla de dedup acordada: **la intermediación más reciente**.

Columnas derivadas (en dbt, no DAX):
- `etapa_actual` — etapa más avanzada, formato `'5. Colocada'` (prefijo numérico para ordenar)
- `dias_inscripcion_a_colocacion`
- `rango_etario`
- `nivel_educativo_normalizado`
- Flags BOOL: `inscrita`, `orientada`, `psicosocial`, `intermediada`, `colocada` → para medidas DAX
- Flags texto: `tiene_inscripcion` … `tiene_colocacion` (Sí/No) → para segmentadores de Power BI

### `Corte` — el campo de cohorte

Picklist en Zoho con valores `Corte 1` / `Corte 2`. **Existe en los 14 módulos.** Es la segmentación transversal del programa.

⚠️ Durante una sesión se creyó erróneamente que `Corte` era un artefacto de texto y se eliminó de tres módulos. Es un campo real, verificado con `getFields` y COQL.

### Anomalías en api_names de Zoho

Usalos **tal cual**. No los "corrijas".

| api_name | Anomalía | Módulo |
|---|---|---|
| `Peramencia_de_seguimiento` | falta la "n" de Permanencia | `Postvinculaci_n_Colsub` |
| `Tipo_de_novedad1` | sufijo "1" | `Postvinculaci_n_Colsub` |
| `rea_de_Experiencia_Laboral_experiencia_2` | sin la "Á" inicial | `Orientaci_n_Colsubsidios` |
| `rea_de_experiencia_laboral` | sin la "Á" inicial | `GE_Vacantes_Colsubsidios` |

### Cambio reciente en Zoho (9-sep-2026)

`Postvinculaci_n_Colsub` fue **reconstruido** con 19 campos nuevos, implementando el requerimiento de post-vinculación (alerta a los 20 días del inicio de contrato). Los campos viejos (`Fecha_vinculaci_n`, `Estado_Seguimiento_1`, `Permanencia_en_seguimiento_1`, etc.) **ya no existen**.

El requerimiento de gestión de vacantes (Módulo 2: `estado_agendamiento`, `enfoque_genero`, `resultado_seguimiento`) **no está implementado** en Zoho todavía.

### Scheduling (UTC)

```
40 9, 40 12, 40 14, 10 17, 40 18, 40 20, 40 22, 40 0 * * *
```

8 ejecuciones diarias, desplazadas 20 min respecto a Colsubsidio (misma cuenta Zoho, mismo pool de tokens).

---

## Principios de arquitectura (NO rediscutir)

### dbt

- **Power BI consume marts (`fct_`/`dim_`), NUNCA stagings.** Si una página necesita un staging, se crea un mart passthrough.
- **Stagings = `view` · Marts = `table`**
- `coalesce`, `case when` simple, `lower`, `trim`, `safe_cast`, `json_value`, normalización de un campo → **staging**
- JOINs, agregaciones, `UNION ALL`, flags que cruzan tablas, columnas derivadas de derivadas → **mart**
- **Lógica de negocio en dbt, display en DAX.** Si el valor no cambia según filtros de Power BI, va en dbt.
- **Tests con `severity: warn`**, nunca `error`. El pipeline no debe fallar por calidad de dato.
- dbt 1.11: `accepted_values` requiere envolver `values:` en `arguments:`, y `severity` va dentro de `config:` de cada test, no a nivel de columna:

```yaml
- accepted_values:
    arguments:
      values: ['a', 'b']
    config:
      severity: warn
```

- `dataset_id` siempre el nombre bare, nunca project-qualified
- `PROJECT_ID` centralizado en `config.py`, importado por `loader.py` y `metadata.py`
- `metadata.py` parametrizado por `dataset_id` para evitar contaminación de watermarks entre proyectos
- Si se agrega paquete dbt → el workflow necesita paso `dbt deps`

### SQL / BigQuery

```sql
-- Fechas: siempre DATE. TIMESTAMP con microsegundos rompe el ADBC de Power BI.
date(safe_cast(`Campo` as timestamp)) as campo

-- Auditoría: timestamp en staging, date en mart vía SELECT * REPLACE
safe_cast(`Created_Time` as timestamp) as created_time   -- staging
date(created_time) as created_time                        -- mart

-- Categóricos/picklist: lower + trim.  Texto libre: solo trim.
lower(trim(`Estado`)) as estado
trim(`Observaciones`) as observaciones

-- Lookups de Zoho llegan como JSON
json_value(`Buscar_empresa`, '$.id')   as buscar_empresa_id
json_value(`Buscar_empresa`, '$.name') as buscar_empresa_nombre
json_value(`Campo`, '$[0]')            as campo          -- multiselect

-- NITs mixtos
coalesce(json_value(`Nit`, '$.name'), `Nit`) as nit

-- Deduplicación
qualify row_number() over (
    partition by documento
    order by fecha desc nulls last, modified_time desc nulls last, id desc
) = 1

-- Colapsar N→1 conservando campos del mismo evento juntos.
-- ARRAY_AGG separado por campo puede mezclar valores de eventos distintos.
array_agg(struct(a, b, c) order by fecha desc nulls last, id desc limit 1)[offset(0)] as ultima

-- Columna que depende de otra derivada: CTE base + SELECT * FROM base.
-- BigQuery no garantiza visibilidad de alias en el mismo SELECT list.

-- Booleanos de Zoho llegan como texto 'sí'/'no'
coalesce(campo in ('si', 'sí', 'true'), false) as flag

-- Regex en español: clase de caracteres para vocales acentuadas.
-- lower() NO quita tildes.
regexp_contains(lower(trim(campo)), r't[ée]cn')   -- ✅ matchea técnico y tecnico
regexp_contains(lower(trim(campo)), r'tecn')      -- ❌ NO matchea 'técnico'

-- Quitar diacríticos (NORMALIZE con NFC no sirve):
regexp_replace(normalize(campo, NFD), r'\pM', '')
```

**Especificidad en `case` ordenado:** un patrón demasiado amplio en la primera rama secuestra casos de las de abajo, y el error es invisible porque el gráfico se ve bien. Ejemplo real: `especi` capturaba `"especialista en desarrollo humano-universitario (pregrado)"` como posgrado, cuando es pregrado. El patrón correcto es `especializaci`.

### Power BI / DAX

- **`DISTINCTCOUNT([documento])`** para contar personas, nunca `COUNTROWS`
- Los BOOL (`inscrita`…) para medidas; los `tiene_*` (texto) para segmentadores
- Columnas que no dependen del contexto de filtro → dbt
- BigQuery/SQL es la fuente de verdad cuando DAX y SQL discrepan
- Conector BigQuery **sin** `[Implementation="2.0"]` — el ADBC v2 explota con TIMESTAMP
- Nombres limpios en dbt (snake_case sin tildes), nombres bonitos en el paso **Rename Columns** de Power Query
- Tarjetas: Unidades de visualización = `Ninguno` para que no abrevie 2.000 como "2 mil"
- Días de semana en texto se ordenan alfabéticamente → usar columna `*_orden` + "Ordenar por columna"

### Zoho CRM v8

- **Límite duro: 50 campos por request.** Módulos con más campos requieren selección explícita
- El campo `Name` almacena el documento en módulos persona-céntricos, y el NIT en los de empresa
- COQL: `select campo1, campo2 from Modulo where id is not null limit 200`
- COQL no soporta `count()` con `group by` sobre columnas no agrupadas
- `getFields` requiere el param `include`
- El picklist de Zoho **no valida** importaciones masivas ni escrituras por API — de ahí vienen los valores sucios en el histórico

---

## Trampas de grano conocidas

| Error | Síntoma | Solución |
|---|---|---|
| `COUNTROWS(fct_intermediacion_rm)` para contar personas | 887 en vez de ~280 | `DISTINCTCOUNT(documento)` |
| `COUNTROWS(fct_formacion_rm)` para contar personas | 516 en vez de ~170 | `DISTINCTCOUNT(documento)` |
| Donut de estados usando `fct_ruta_mujer[estado_intermediacion]` | Solo cuenta la última intermediación por mujer | Usar `fct_intermediacion_rm[estado]` |
| LEFT JOIN directo de intermediación en `fct_ruta_mujer` | Multiplica filas, rompe el grano | `ARRAY_AGG` + `STRUCT` antes del join |

---

## Calidad de datos conocida (corte 6-sep-2026)

| Campo | Completitud |
|---|---|
| `documento`, `nombre_completo` | 100% |
| `tipificacion_mujer` | 96% |
| `perfil_ocupacional` | 96% |
| `seleccione_nivel_de_sisb_n` | 60% |
| `estado_psicosocial`, `evoluci_n` | 38% |
| `area_experiencia` | 33% |
| `formaci_n_completada` | 10% |
| `fecha_colocacion` | 1% (6 registros de meta 150) |
| `gestor_operativo` (formación) | 0% |

Antes de construir un gráfico sobre un campo, mirá su completitud. Un visual sobre un campo con 90% de nulos reporta calidad de dato, no resultado del programa.

---

## Dashboard Ruta Mujer

Se replica el `.pbix` de C2M (14 páginas) y se agregan 5 nuevas. C2M conectaba a `ruta-empleo-475616.ds_Colsubsidio` (proyecto de la consultora, sin acceso); se reemplaza por `zoho-bq-pipeline-492116.proyecto_ruta_mujer`.

**Réplica (14):** INICIO · ANALISIS METAS · PREREGISTRO · EMBUDO · GESTION GENERAL · GESTION ORIENTACION · LISTADO HABILITANTES · BASE SAE · GESTION VACANTES · GESTION FORMACION · BD ASISTENCIA FORMACION · GESTION INTERMEDIACION · AGENDAMIENTO EMPRESARIAL · AGENDAMIENTO ORIENTACION

**Nuevas (5):** COLOCACIONES · CALIDAD DE DATOS · PRODUCTIVIDAD DEL EQUIPO · POSTVINCULACIÓN · ESTADO DE EMPRESA (bloqueada hasta que Zoho implemente el Módulo 2)

Metas conocidas: orientación 600 · formación 600 · colocación 150. Faltan las de inscripción, psicosocial e intermediación, y está pendiente confirmar si son del programa completo o por corte.

---

## Pendientes

- Construcción del dashboard en Power BI (19 páginas)
- `reconciliar.py` sigue hardcodeado a Colsubsidio — hay que parametrizarlo
- Módulo 2 del requerimiento (gestión de vacantes) — esperando a tecnología
- Reportar a tecnología los typos `Peramencia_de_seguimiento` y `Tipo_de_novedad1`
- Confirmar si el cálculo de los 20 días de post-vinculación lo hace un workflow de Zoho o se calcula en dbt
- Migración de la cuenta GCP a corporativa (pendiente verificación de Google)