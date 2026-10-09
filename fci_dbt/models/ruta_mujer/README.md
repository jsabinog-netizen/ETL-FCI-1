# Ruta Mujer

Fuente: `zoho_raw_ruta_mujer`, las 15 tablas raw de
`zoho-bq-pipeline-492116.proyecto_ruta_mujer`. Las tablas temporales `_stg_`
del cargador no son fuentes dbt.

## Stagings

Materialización `view`. `Name` se conserva como `documento` de texto en los
módulos de personas. Inscripción aplica `QUALIFY ROW_NUMBER()` por documento,
ordenando por fecha de registro, modificación, creación e id descendentes.
Los demás módulos conservan un registro por id de Zoho.
`modified_time` es TIMESTAMP y la última columna del staging.

Los nombres abreviados del diseño corresponden a estos modelos existentes:

| Nombre del diseño | Modelo del repositorio |
|---|---|
| stg_inscripcion_rm | stg_inscripci_n_colsubsidios |
| stg_orientacion_rm | stg_orientaci_n_colsubsidios |
| stg_psicosocial_rm | stg_psicosocial_rutam (Corte 1) |
| stg_psicosocial_v2_rm | stg_psicosocial_rutam_v2 (Corte 2) |
| stg_intermediacion_rm | stg_intermediaci_n_ruta_m |
| stg_colocacion_rm | stg_colocaci_n_colsubsidios |
| stg_preregistro_rm | stg_pre_registro_rutam |
| stg_formacion_rm | stg_formaci_n_colsubsidios |
| stg_ge_vacantes_rm | stg_ge_vacantes_colsubsidios |
| stg_pre_registro_empresarial_rm | stg_pre_registro_empresarial |
| stg_agenda_orientadores_rm | stg_agenda_orientadores_rutam |
| stg_ge_agendamiento_rm | stg_ge_agendamiento |

## Marts para Power BI

Todos son `table` en `proyecto_ruta_mujer`. Las fechas son DATE, incluidas las
de auditoría; no se exponen TIMESTAMP ni DATETIME.

| Modelo | Grano y clave |
|---|---|
| fct_ruta_mujer | Una mujer por documento |
| fct_intermediacion_rm | Un evento por id; conserva todas las intermediaciones |
| fct_formacion_rm | Una inscripción a curso por `id_curso` (`id` de Zoho + slot 1–6); `documento` se repite por curso |
| dim_vacantes_rm | Una vacante por id, enriquecida con empresa |
| fct_agendamientos_rm | Una cita por id compuesto: tipo + id de origen |
| fct_psicosocial_rm | Un diagnóstico psicosocial de Corte 2 por id (solo v2) |
| fct_actividad_rm | Un registro de módulo de persona por `actividad_id` (8 módulos), con el corte de su módulo |
| dim_corte_rm | Un corte (`corte 1`, `corte 2`, `sin corte`) |

### Filtro de corte

Cada módulo de Zoho tiene su propio campo `Corte`, y una mujer puede tener la
orientación en Corte 1 y la intermediación en Corte 2. Por eso el `corte` de
`fct_ruta_mujer` (el de la inscripción) no puede filtrar bien todos los módulos.

- Los stagings convierten el `Corte` vacío en `'sin corte'`, para que el Total
  sea igual a Corte 1 + Corte 2 + Sin corte.
- `fct_actividad_rm` reúne con `UNION ALL` los registros de pre-registro,
  registro, orientación, psicosocial (v1 corte 1 + v2), formación,
  intermediación, colocación y postvinculación. Solo tiene columnas comunes:
  `modulo`, `documento`, `corte`, `fecha_evento`, `completado` y `estado`.
- En Power BI, `dim_corte_rm` es el único slicer y se relaciona solo con
  `fct_actividad_rm`. Vacantes, empresas, pre-registro e intermediación se
  filtran con `TREATAS(VALUES(dim_corte_rm[corte]), tabla[corte])` en la medida.
- Las columnas `corte_orientacion`, `corte_intermediacion` y `corte_colocacion`
  de `fct_ruta_mujer` usan el campo `Corte` de Zoho del registro seleccionado.
  Antes se calculaban por fecha y contradecían al CRM.
- Las columnas `corte_evento` de otros marts siguen calculándose por fecha.
  No se deben usar para filtrar.

Guía de Power BI: `docs/guia_filtro_corte_ruta_mujer.md`.

### Psicosocial por corte

Hay dos módulos psicosociales con campos distintos:

- `Psicosocial_RutaM` (v1) es **Corte 1**. Solo se usan sus registros con
  `corte = 'corte 1'`. Los registros con corte vacío son cascarones de mujeres
  de Corte 2 (0 completados) y se ignoran.
- `Psicosocial_RutaM_v2` es **Corte 2**: un diagnóstico por ejes con llamadas
  L1/L2. No tiene campo `Corte`; el staging lo fija en `'corte 2'`.

Una mujer de Corte 1 que sigue en el programa puede tener registro en ambos.
En `fct_ruta_mujer` y `fct_registro_sae_rm`, v2 tiene prioridad en los campos
descriptivos (`psicosocial_id`, profesional, estado, barreras, fechas). El
flag `psicosocial` es v1 OR v2, para que quien completó en Corte 1 no lo pierda.
`fct_preregistro_rm` une ambas fuentes con `UNION ALL` y agrega por documento.

En v2 el profesional es `Profesional_que_remite`, porque el `Owner` es la
plataforma. "Acompañamiento completado" en v2 está pendiente de definir: por
ahora `psicosocial_completada` es false.

### Ruta central

La base se deduplica exclusivamente en el staging de inscripción. En el mart,
los CTE de orientación, psicosocial, colocación y preregistro seleccionan el
registro más reciente por documento para evitar multiplicaciones futuras.
Intermediación usa `ARRAY_AGG(STRUCT(...) ORDER BY fecha DESC NULLS LAST,
modified_time DESC NULLS LAST, id DESC LIMIT 1)[OFFSET(0)]`: conserva todos los
atributos de un mismo evento, incluidos valores nulos, y cuenta todos los eventos.

Los flags inscrita, orientada, psicosocial e intermediada son verdaderos cuando
el indicador de completitud del registro seleccionado es `si`, `sí` o `true`.
Un valor vacío o diferente produce false. Colocada requiere fecha de vinculación.
`etapa_actual` prioriza colocada, intermediada, psicosocial, orientada e inscrita;
si ningún flag está activo, es `0. Sin completar`.
`dias_inscripcion_a_colocacion` es DATE_DIFF; conserva NULL cuando falta una
fecha y valores negativos si hay inconsistencias en el origen.
Las inscripciones sin documento se excluyen del mart de personas; no se inventa
una identidad. `fecha_registro_psicosocial` es la fecha de creación del registro,
no una fecha de atención inferida.

### Empresa y citas

Vacantes enlaza empresa por `buscar_empresa_id = empresa.id`. Si no hay
coincidencia, usa el NIT del nombre del lookup. Cada clave empresarial se reduce
a un registro reciente antes del JOIN. Las vacantes sin empresa se conservan.

Agendamientos usa UNION ALL y distingue `individual` y `empresarial`.
`id_origen` conserva el id de Zoho; el prefijo en `id` evita colisiones entre
módulos. `fecha_cita` corresponde a America/Bogota y `hora_cita` conserva la
hora local como texto, sin TIMESTAMP para Power BI.

## Validación

Todos los tests tienen `config.severity: warn`. Las claves de marts tienen
unique y not_null; documento en inscripción tiene unique. No se imponen
not_null a campos opcionales de Zoho.

Desde `fci_dbt`:

```sh
dbt build --select path:models/ruta_mujer
```

Después de construir el mart central:

```sql
SELECT COUNT(*) AS total, COUNT(DISTINCT documento) AS unicos
FROM proyecto_ruta_mujer.fct_ruta_mujer;
```

Total y únicos deben coincidir. Para eventos y formación se compara además la
cantidad con el staging; vacantes debe conservar todas sus filas; citas debe
igualar la suma de sus dos fuentes.
