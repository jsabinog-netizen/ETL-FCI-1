# Ruta Mujer

Fuentes: las 14 tablas raw de `zoho-bq-pipeline-492116.proyecto_ruta_mujer`.
Se excluyen las tablas temporales `_stg_` del cargador.

Los 14 stagings son vistas, con un registro por id de Zoho. El modulo principal
es `stg_inscripci_n_colsubsidios`: `Name` se expone como `documento` de texto.
Los modulos de eventos pueden contener varios registros por documento.
Vacantes, empresas y agenda empresarial conservan su grano propio.

Fechas de negocio: DATE. Horas de agenda y auditoria: TIMESTAMP.
`modified_time` siempre es la ultima columna y usa SAFE_CAST a TIMESTAMP.
Los lookups exponen id y nombre mediante JSON_VALUE. Los multiselect conservan
el JSON completo ademas de la primera seleccion, siguiendo la referencia GIZ.
Los unicos tests obligatorios son unique y not_null en id, todos severity warn.

La carpeta marts queda preparada con materializacion table. Este primer paso
implementa las fuentes y los 14 stagings solicitados; no define aun marts ni
reglas de negocio para estado_ruta o ruta_completa. El futuro mart de personas
debe deduplicar inscripciones y agregar eventos antes de hacer los JOINs.

Desde fci_dbt:
```sh
dbt build --select path:models/ruta_mujer
```
