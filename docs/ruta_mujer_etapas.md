# Siete etapas de Ruta Mujer

`fct_ruta_mujer.etapa_actual` muestra la etapa más avanzada completada:

1. Registros
2. Orientación
3. Atención Psicosocial
4. Formación
5. Intermediación
6. Colocación
7. Postvinculación

Se conserva `0. Sin completar` cuando ningún indicador es verdadero. Una etapa posterior no exige que todas las anteriores estén completas.

Formación usa `Formaci_n_Completada` (si/sí/true) del registro más reciente por fecha de formación, fecha de curso como alternativa, modificación e id. Postvinculación usa la fecha de llamada del seguimiento seleccionado, priorizando el contrato más reciente, luego llamada, modificación e id. Ambas tablas se reducen a una fila por documento antes del JOIN.

Se agregaron `formada`, `postvinculada`, `tiene_formacion`, `tiene_postvinculacion`, `fecha_formacion`, `fecha_postvinculacion`, `formacion_id` y `postvinculacion_id`. Las fechas son DATE.

Los indicadores Sí/No representan etapas completadas, no la mera existencia de un registro.

## Validación del 10 de septiembre de 2026

- Build completo: **PASS=96 WARN=0 ERROR=0 SKIP=0**, 14 vistas, 10 tablas y 72 tests.
- 536 filas y 536 documentos únicos.
- 128 combinaciones de indicadores verificadas contra el CASE real; todas correctas.
- 50 mujeres con formación completada; 6 tienen Formación como etapa más avanzada.
- 507 mujeres tienen un registro relacionado de formación.
- Ninguna mujer inscrita tiene un seguimiento relacionado por documento. El único registro de Postvinculación existente no coincide por documento con la población del mart; no se forzó una asociación.
- Ningún mart expone TIMESTAMP.

| Etapa actual | Mujeres |
|---|---:|
| 0. Sin completar | 3 |
| 1. Registros | 15 |
| 2. Orientación | 157 |
| 3. Atención Psicosocial | 57 |
| 4. Formación | 6 |
| 5. Intermediación | 293 |
| 6. Colocación | 5 |
| 7. Postvinculación | 0 |

## Power BI

Actualizar el modelo para incorporar las nuevas columnas. Los textos de `etapa_actual` cambiaron al vocabulario de la ruta y se renumeraron Intermediación y Colocación. Ajustar medidas o filtros que comparen literalmente las etiquetas anteriores.

Para contar todas las formadas, usar `formada` o `tiene_formacion`; filtrar `etapa_actual = '4. Formación'` cuenta solo a quienes no tienen una etapa posterior completada.
