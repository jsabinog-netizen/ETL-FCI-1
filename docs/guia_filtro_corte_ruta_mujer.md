# Guía: un solo filtro de Corte para todo el dashboard Ruta Mujer

> 9-oct-2026. Basada en la copia PBIP de `Colsubsidio-Ruta mujer` (`Calculos.tmdl`, `relationships.tmdl`, `Metas RM.tmdl`) y en los datos de BigQuery.
> Las fórmulas están en [`medidas_corte_ruta_mujer.dax`](medidas_corte_ruta_mujer.dax).

## 1. Por qué el filtro de corte no funcionaba

Los datos en BigQuery estaban bien: **Corte 1 cuadra exacto con el CRM en todos los módulos**. El problema estaba en el modelo de Power BI:

1. **Corte fijo dentro de las medidas.**
   - `Inscripciones Completadas`, `Mujeres colocadas`, `Mujeres posvinculadas` y `Mujeres con Acompañamiento individual` tenían `corte = "corte 2"` dentro del `CALCULATE`.
   - Ese filtro **reemplaza** al del slicer, así que al elegir Corte 1 seguían mostrando Corte 2.
2. **El `corte` de `fct_ruta_mujer` es el de la inscripción.**
   - Una mujer puede orientarse en Corte 1 e intermediarse en Corte 2.
   - Además, `fct_ruta_mujer` tiene una fila por mujer inscrita: no puede contar las 805 orientaciones (hay ~37 mujeres orientadas sin inscripción) ni las 1.223 intermediaciones.
3. **Cada página filtraba con otra columna.** Había 24 slicers sobre 7 columnas distintas:
   - Embudo tenía dos.
   - Agendamiento usaba el corte de **intermediación**.
   - Pre-registro y Gestión Empresarial usaban `corte_evento`, que se calcula por fecha y contradice a Zoho.
4. **Relaciones que filtran en ambas direcciones.** `fct_ruta_mujer` ↔ psicosocial / postvinculación / mitigación / preregistro.
   - El slicer de una página se "colaba" a las demás.
   - Ejemplo: el corte de la página Psicosocial reducía `fct_ruta_mujer` solo a las mujeres de v2.
5. **Los 268 vs 309 de intermediadas en C1.**
   - El slicer `fct_ruta_mujer[corte]` del Embudo descartaba las intermediaciones de mujeres no inscritas.
   - El número correcto, según el campo Corte de Zoho, es **309**.

## 2. La solución

```
dim_corte_rm (Corte 1 | Corte 2 | Sin corte)   ← único slicer, sincronizado en todas las páginas
      │ 1:* (única)
      ▼
fct_actividad_rm  ◄── 1:* (única) ── fct_ruta_mujer   (sede, localidad, habilitantes… siguen filtrando)
(1 fila = 1 registro de cada módulo, con el Corte de SU módulo)

Intermediación, vacantes, empresas, pre-registro, postvinculación, psicosocial v2, agendas:
→ la medida aplica TREATAS(VALUES(dim_corte_rm[corte]), tabla[corte])
```

- **`dim_corte_rm`** tiene 3 filas: `corte` (llave), `corte_nombre` (lo que se ve) y `corte_orden`.
- **`fct_actividad_rm`**: pre-registro, registro, orientación, psicosocial (v1 Corte 1 + v2 Corte 2), formación, intermediación, colocación y postvinculación.
  - Columnas: `modulo`, `documento`, `corte`, `fecha_evento`, `completado`, `estado`.
- En dbt, los registros sin corte en Zoho ahora dicen `sin corte`, para que **Total = C1 + C2 + Sin corte**.

## 3. Pasos en Power BI Desktop (en este orden)

> Haga una copia del `.pbix` antes de empezar.

### Paso 1 — Actualizar e importar tablas
1. **Inicio → Transformar datos → Actualizar vista previa** sobre `dim_vacantes_rm`. Debe aparecer la columna nueva `motivo_cierre`.
2. **Obtener datos → Google BigQuery → `zoho-bq-pipeline-492116` → `proyecto_ruta_mujer`**:
   - Marcar `dim_corte_rm` y `fct_actividad_rm` → **Cargar**.
   - **No** renombrar sus columnas: el DAX usa los nombres originales.
3. En `dim_corte_rm`, seleccionar `corte_nombre` → **Herramientas de columnas → Ordenar por columna → `corte_orden`**.

### Paso 2 — Corregir relaciones existentes (Vista de modelo)

| # | Relación actual | Acción |
|---|---|---|
| 1 | `fct_registro_sae_rm[nombre_completo]` → `fct_agenda_orientacion_rm[nombre_completo]` (autodetectada) | **Eliminar**. Une tablas por nombre de persona. |
| 2 | `fct_psicosocial_rm[corte]` → `fct_postvinculacion_rm[corte]` (autodetectada, inactiva) | **Eliminar**. |
| 3 | `fct_psicosocial_rm[documento]` ↔ `fct_ruta_mujer[Documento]` (1:1, ambas) | Cardinalidad **Varios a uno (\*:1)**, dirección **Única**. Power BI no permite dirección única en 1:1. |
| 4 | `fct_postvinculacion_rm[documento]` ↔ `fct_ruta_mujer[Documento]` (1:1, ambas) | Igual que la 3. |
| 5 | `fct_ruta_mujer[Documento]` ↔ `fct_mitigacion_rm[documento]` (1:1, ambas) | Igual que la 3. |
| 6 | `fct_preregistro_rm[documento]` → `fct_ruta_mujer[Documento]` (ambas) | Dirección **Única**. |

Con dirección única, `fct_ruta_mujer` filtra a esas tablas, pero ellas ya no filtran a `fct_ruta_mujer`.

### Paso 3 — Crear las 3 relaciones nuevas

| Desde (1) | Hacia (\*) | Cardinalidad | Dirección | Activa |
|---|---|---|---|---|
| `dim_corte_rm[corte]` | `fct_actividad_rm[corte]` | 1:\* | Única | Sí |
| `fct_ruta_mujer[Documento]` | `fct_actividad_rm[documento]` | 1:\* | Única | Sí |
| `Calendario[Date]` | `fct_actividad_rm[fecha_evento]` | 1:\* | Única | **No** (se activa con `USERELATIONSHIP`) |

`dim_corte_rm` **no** se relaciona con ninguna otra tabla. El resto se filtra con `TREATAS` dentro de cada medida, así no hay rutas ambiguas.

### Paso 4 — Reemplazar las medidas
1. Corregir la tabla calculada `Metas RM` (sección 0 del `.dax`). El typo `Posviculadas` dejaba vacía la barra 6 del Embudo.
2. Para cada medida del `.dax`: abrirla en `Calculos` y **reemplazar la fórmula, manteniendo el mismo nombre**. Así los visuales no se rompen.
3. Crear las marcadas **(NUEVA)**.

### Paso 5 — Quitar los 24 slicers de corte viejos

| Página | ID del visual | Campo actual |
|---|---|---|
| Embudo ruta | `2eed09e37f83f6137bb0` | `fct_ruta_mujer[corte]` |
| Embudo ruta | `fbb685957e330664d404` | `fct_intermediacion_rm[corte]` |
| Pre-registro | `f56a64a17e5090089645` | `fct_preregistro_rm[corte_evento]` |
| Detalle Pre-registro | `330e470a16943d7c5003` | `fct_preregistro_rm[corte_evento]` |
| Tracker-Ruta | `55cfe6df6b05a7166890` | `fct_ruta_mujer[corte]` |
| Análisis de población | `f50854cdb81a45d0e9fb` | `fct_ruta_mujer[corte]` |
| Registros | `6ef7767e3e7ecf305c12` | `fct_ruta_mujer[corte]` |
| Detalle Registros | `1816501cd817e2764877` | `fct_ruta_mujer[corte]` |
| Gestión Orientación | `96addd67eb09109850ce` | `fct_ruta_mujer[corte]` |
| Psicosocial | `c6c930b1e3861f32cd03` | `fct_psicosocial_rm[corte]` |
| Detalle psicosocial | `16f7e59821a7fbb996a5` | `fct_ruta_mujer[corte]` |
| Detalle Orientaciones | `17066130755d5c68e735` | `fct_ruta_mujer[corte]` |
| Listado Habilitantes | `14034a8f0268b6010627` | `fct_ruta_mujer[corte]` |
| Base Sae | `d93c8cff6b685d900985` | `fct_registro_sae_rm[corte]` |
| Gestión Vacantes | `0710c081d517b40e7d40` | `dim_vacantes_rm[corte]` |
| Análisis Vacantes | `cf8c1144ae2a79e01192` | `dim_vacantes_rm[corte]` |
| Detalle Vacantes | `56e7fb65a956160ebbcc` | `dim_vacantes_rm[corte]` |
| N Gestión Formación | `df6939502c1b044d903e` | `fct_ruta_mujer[corte]` |
| Gestión Intermediación | `7dc8e0338bd1e825247a` | `fct_intermediacion_rm[corte]` |
| Detalle Intermediaciones | `9e8d9e80a6422c02e113` | `fct_ruta_mujer[corte_intermediacion]` |
| Gestión Empresarial | `0a2d51680b90de4537c1` | `fct_intermediacion_rm[corte_evento]` |
| Agendamiento Empresarial | `08a91de75597182ad3e1` | `fct_intermediacion_rm[corte]` |
| Agendamiento Orientación | `263da3f7aa16cb61668d` | `fct_intermediacion_rm[corte]` |
| Detalle Postvinculaciones | `5d7b7d2da66640725b00` | `fct_ruta_mujer[corte]` |

Además, quitar el filtro de visual por corte de estas tablas:
- Listado Habilitantes (`52dd6df67ecdb13ffef2`)
- Gestión Vacantes (`fab54a26165a1b7601b4`)
- Análisis Vacantes (`73a07e218e612b803202`)
- Detalle Vacantes (`4bdf7b151b990c89d186`)
- Postvinculación (`922210fc95bcde95695b`)

> El ID del visual se ve en el panel **Selección** solo si el visual no tiene título. Si no lo encuentra, ubíquelo por la página y el campo.

### Paso 6 — Poner el slicer único y sincronizarlo
1. En una página, crear una segmentación con `dim_corte_rm[corte_nombre]`, en estilo **Mosaico** o **Lista**, con selección múltiple permitida y la opción **Seleccionar todo**.
2. **Ver → Sincronizar segmentaciones**: marcar **Sincronizar** y **Visible** en todas las páginas, excepto Portada.
3. Sin selección = **Total** (Corte 1 + Corte 2 + Sin corte).

### Paso 7 — Filtros en las tablas de detalle

En cada tabla: **panel Filtros → Filtros en este objeto visual → arrastrar la medida → "es" 1 → Aplicar filtro**.

| Página | Tabla (ID) | Medida filtro |
|---|---|---|
| Tracker-Ruta | `6c306f26a9c7acd18e9c` | `Filtro corte Registro` |
| Detalle Registros | `c9188fe6d5de73ee2e9a` | `Filtro corte Registro` |
| Listado Habilitantes | `52dd6df67ecdb13ffef2` | `Filtro corte Registro` |
| N Asistencia Formación | `eb4f8604c71c2be7374d` | `Filtro corte Registro` |
| Detalle Orientaciones | `9560c27f3c94b3039269` | `Filtro corte Orientación` |
| Detalle psicosocial | `28836831e6910b564be9` | `Filtro corte Psicosocial` |
| Postvinculación | `922210fc95bcde95695b` (fct_ruta_mujer) | `Filtro corte Colocación` |
| Postvinculación | `5af085e0755d43be6586` | `Filtro corte Postvinculación` |
| Detalle Postvinculaciones | `19e00d4797d3baa00d7a` | `Filtro corte Postvinculación` |
| Detalle Pre-registro | `9574d97906080051cd57` | `Filtro corte Preregistro` |
| Base Sae | `73b77d383db1264a0256` | `Filtro corte SAE` |
| Gestión Vacantes | `fab54a26165a1b7601b4` | `Filtro corte Vacantes` |
| Análisis Vacantes | `73a07e218e612b803202` | `Filtro corte Vacantes` |
| Detalle Vacantes | `4bdf7b151b990c89d186` | `Filtro corte Vacantes` |
| Detalle Vacantes | `8a2dcdbda550cd29635a` | `Filtro corte Intermediación` |
| Detalle Intermediaciones | `c59605cf3e307ac1acbd` | `Filtro corte Intermediación` |
| Gestión Empresarial | `cb94d20bc58206c5d0c3`, `e7ea91fc3c259ec224a0` | `Filtro corte Empresas` |
| Agendamiento Empresarial | `29357e40888631260d13` | `Filtro corte Empresas` |
| Agendamiento Empresarial | `2b507b8a3e85d524873e` | `Filtro corte Agenda Comercial` |
| Agendamiento Orientación | `7b9cf31e0570b01b1cc6` | `Filtro corte Agenda Orientación` |

### Paso 8 — Metas: siempre Corte 2
- Los `% Cumplimiento *` y `Ejecutados Ruta Mujer` calculan **siempre Corte 2**, porque es el único corte con metas. El slicer no los mueve.
- Cambiar los títulos de los medidores a **"Avance meta Corte 2"**.
- Las tarjetas de conteo de Análisis Metas **sí** siguen el slicer.

## 4. Tabla de control

Valores de BigQuery al 9-oct-2026. Validar cada tarjeta con el slicer en Total, Corte 1 y Corte 2. Pueden subir un poco si entran registros nuevos.

| Medida | Total | Corte 1 | Corte 2 | Sin corte |
|---|---|---|---|---|
| Mujeres registradas | 768 | 535 | 233 | 0 |
| Mujeres habilitantes | 313 | 251 | 62 | — |
| Mujeres Orientadas | 805 | 573 | 232 | 0 |
| Mujeres con Acompañamiento individual | 681 | 566 | 115 | 0 |
| Personas con Atención Psicosocial (completadas) | 201 | 201 | 0 | 0 |
| Número Intermediaciones / Total Postulaciones | 1.223 | 868 | 353 | 2 |
| Personas intermediadas | 518 \* | 309 | 251 | 2 |
| Mujeres Contratadas (estado intermediación) | 14 | 6 | 8 | 0 |
| Mujeres colocadas (módulo colocación) | 9 | 6 | 3 | 0 |
| Total Pre-registros | 1.171 | 694 | 476 | 1 |
| Total empresas | 106 | 83 | 23 | — |
| Total de Vacantes | 295 | 108 | 187 | — |
| Total Puestos | 3.096 | 1.616 | 1.480 | — |
| Vacantes Activas | 274 | 92 | 182 | — |
| Vacantes Cerradas | 17 | 15 | 2 | — |
| Vacantes Vigentes (fecha final > hoy) | 180 | 2 | 178 | — |
| Empresas con vacantes | 57 \* | 34 | 47 | — |

\* El Total es menor que C1 + C2: hay 42 mujeres con intermediaciones en ambos cortes y 24 empresas con vacantes en ambos. Es correcto, porque cada una se cuenta una sola vez en el Total.

**Sobre los "únicos 394 / 181" del CRM:** no se pudieron reproducir con ninguna llave (documento, lookup de documento, vacante, estado ni corte de inscripción). Por el campo Corte de cada intermediación son 309 / 251. Si en el CRM sale otra cifra, revisar qué filtro tiene ese reporte.

## 5. Sugerencias adicionales (no bloquean el filtro)

1. **Errores corregidos en el `.dax`:**
   - `% Cumplimiento Colocados` y `% Colocadas de Registros` usaban `Posvinculadas sin gestionar` como numerador.
   - `% Cobertura Posvinculacion` estaba invertida.
   - `Dias Orientacion a Intermediacion` era una copia de otra medida.
   - `Total Postulaciones` no contaba postulaciones.
   - `Personas Formadas` contaba cursos.
   - `N° de llamadas1` contaba todas las filas.
   - `Con responsabilidades de cuidado` contaba los vacíos como "sí".
2. **Colocadas y contratadas son indicadores distintos:** 9 salen del módulo de colocación y 14 del estado de intermediación. Titúlelos explícitamente; hoy se confunden.
3. **No usar `corte_evento`** (en vacantes, intermediación, pre-registro, etc.) para filtrar: se calcula por fecha y contradice a Zoho en ~60 vacantes.
4. **Filtros de página heredados:** Detalle Pre-registro, Detalle Orientaciones y Detalle psicosocial tienen filtro de página por `dim_vacantes_rm[fecha_final_de_la_vacante]`, que no aplica ahí. Revisar y quitar.
5. **Relaciones muchos a muchos por NIT** (vacantes ↔ intermediación ↔ agenda comercial, bidireccionales). Recomendado:
   - Reemplazarlas por `fct_intermediacion_rm[buscar_vacante_id]` → `dim_vacantes_rm[id]` (1:\*, única).
   - Relacionar la agenda comercial con `dim_empresas_rm`.
   - Hoy filtran por empresa cosas que no tienen que ver.
6. **Cobertura Sectorial:** el CRM dice 12 sectores; `sector_economico_empresa` da 26. Confirmar qué columna considera "sector" el CRM; probablemente `sector_normalizado`.
7. **Meta psicosocial:** son 600 **sesiones** de mínimo una hora, pero hoy se compara con mujeres. Dejarlo dicho en el título hasta que v2 registre sesiones; `l1_duracion_min` y `l2_duracion_min` podrían acreditarlas.
8. **Psicosocial completado en v2:** sigue pendiente de definir. Hoy Corte 2 muestra 0 completadas.
9. **Medidas duplicadas:** `Personas intermediadas_`, `TABLA INTER`, `Total Remisiones`, `N Vacantes Activas` y `Puestos aportados al convenio` ya apuntan a la medida principal. Bórrelas cuando ningún visual las use.
10. **Conector BigQuery:** las consultas usan `GoogleBigQuery.Database([Implementation="2.0"])`. El proyecto recomienda **sin** `Implementation="2.0"`, porque el ADBC v2 falla con TIMESTAMP. Hoy los marts exponen DATE y no falla, pero conviene quitarlo.
11. **Tablas huérfanas en BigQuery:** `fct_psicosocial_eventos_rm` ya no la genera dbt. Si no se usa, se puede borrar del dataset.

## 6. ¿Qué es el archivo PBIP y para qué sirve?

**PBIP (Proyecto de Power BI)** es otra forma de guardar el mismo informe. En lugar de un `.pbix` binario, Desktop guarda una carpeta de archivos de texto:

- `*.SemanticModel/definition/tables/*.tmdl`: cada tabla, columna y **medida DAX** en texto legible.
- `*.SemanticModel/definition/relationships.tmdl`: todas las relaciones.
- `*.Report/definition/pages/...`: cada página y cada visual en JSON.

Sirve para:
- **Revisar y entender el modelo.** Con su copia se encontraron los cortes fijos, el typo de metas y las relaciones bidireccionales.
- **Control de versiones (git):** se ve qué medida cambió, cuándo y por qué, igual que con el código dbt.
- **Editar en bloque:** cambiar muchas medidas a la vez sin hacer clic visual por visual.

Su copia está en `Descargas` y **no se subió al repo**. Si quiere versionar el dashboard en git, se puede guardar el PBIP original dentro de `pbi/` en el repo. Abra el `.pbip` con Power BI Desktop como cualquier `.pbix`.
