# Ruta Mujer

Fuente: `zoho_raw_ruta_mujer`, las 14 tablas raw de
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
| stg_psicosocial_rm | stg_psicosocial_rutam |
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
