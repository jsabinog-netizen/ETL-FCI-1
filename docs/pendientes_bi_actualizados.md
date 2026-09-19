# Pendientes BI actualizados — Ruta Mujer

Revisión del PBIX guardado el 18/09/2026 a las 17:24:45 (Colombia): 24 páginas, 270 objetos, 74 medidas y 10 relaciones. Se analizaron las consultas de los visuales, DAX, relaciones y Power Query. No se modificó el PBIX ni se ejecutaron sus medidas en Desktop. Este informe sustituye los pendientes de la revisión de la mañana; no aplicar esa lista antigua sin comparar.

## Avances confirmados

- [x] Gráfico y segmentador por Sede en Registros.
- [x] Validación habilitante en Listado Habilitantes.
- [x] Barras por rango etario y municipio de vacantes.
- [x] Gráficos de enfoque de género y desmasculinización.
- [x] Estado en tablas de Agendamiento Empresarial.
- [x] Nuevas páginas Detalle Postvinculaciones y Detalle Preregistro.
- [x] Incorporación de dim_empresas_rm y tabla empresarial de vacantes/intermediaciones/agendamientos.
- [x] Meta de intermediación corregida de 400 a 1.000 remisiones.
- [x] Referencias de Meta Colocados rm y Meta Psicosocial rm corregidas a las etiquetas existentes.
- [x] Tarjeta de Detalle Intermediaciones ahora usa Personas Intermediadas y tiene otra de Número Intermediaciones.

Existencia del visual no certifica calidad ni completitud de los datos. Los nuevos campos ya no se deben listar como gráficos por construir.

## Prioridad 1: resultados que hoy pueden ser incorrectos

- [ ] Corregir `% Cumplimiento Colocados`: usa `[Posvinculadas sin gestionar]` como numerador. Debe usar colocadas del alcance acordado. Para conservar temporalmente el alcance actual: `DIVIDE([Mujeres colocadas], [Meta Colocados rm])`. Esto corrige el numerador, pero NO resuelve la asignación de la meta completa al corte 2.
- [ ] Corregir `% Colocadas de Intermediadas` y `% Colocadas de Registros`: también usan pendientes de postvinculación. Contar mujeres colocadas y denominadores de mujeres de la MISMA cohorte. No mezclar colocaciones por fecha del evento con registradas/intermediadas históricas y llamarlo conversión.
- [ ] Corregir `% Cobertura Posvinculacion`: está invertida (colocadas / posvinculadas). Además `[Mujeres posvinculadas]` cuenta filas de postvinculación, no mujeres ni llamadas. Para cobertura operativa usar contratos exigibles con llamada / contratos exigibles desde `fct_cobertura_post_rm`; mostrar cruces ambiguos por separado.
- [ ] Retirar 240 como meta contractual de postvinculación: el documento oficial no establece ese número. Si se adopta internamente, identificarlo como objetivo operativo con su aprobación, no como obligación del convenio.
- [ ] Resolver la etiqueta `6. Personas Posviculadas` frente a `6. Personas posvinculadas` en el SWITCH de Ejecutados Ruta Mujer: actualmente esa rama no coincide. Al retirar la meta contractual, retirar también esa fila del gráfico de cumplimiento.
- [ ] No presentar mujeres con atención psicosocial / 600 como cumplimiento: la meta exige 600 sesiones de mínimo una hora. Mostrar mujeres atendidas como indicador operativo; cumplimiento contractual queda sin dato hasta acreditar sesiones.
- [ ] Separar convenio completo, cohorte de inscripción y fecha de atención. Hoy Mujeres registradas/Orientadas/Psicosocial filtran corte 2 de la persona; Mujeres colocadas filtra corte de colocación; Número Intermediaciones impone fecha >= 01/09/2026. El documento no distribuye las metas por corte.
- [ ] Corregir Dias Orientacion a Intermediacion: todavía calcula Fecha Inscripción → Fecha Orientación. Usar Fecha Orientación → Fecha Intermediación, excluyendo nulos y secuencias negativas; el mart central representa fechas resumidas por mujer, no todos sus eventos.

## Relaciones y filtros

- [ ] Sustituir M:M bidireccional vacantes[nit_empresa] ↔ intermediación[nit_de_la_empresa] por vacantes[id] (1) → intermediación[buscar_vacante_id] (*). El NIT no identifica una vacante; usarlo atribuye remisiones de una empresa a varias vacantes.
- [ ] La nueva relación empresas → vacantes está hecha por nombre (`empresa` ↔ `nombre_de_la_empresa`). Cambiar a NIT normalizado, validando unicidad del lado empresa y correspondencias antes de activar.
- [ ] Sustituir M:M bidireccional agenda–vacantes por empresa[nit] (1) → agenda[nit_empresa] (*) y empresa[nit] (1) → vacantes[nit_empresa] (*). El nit_empresa de agenda está preparado en la rama de correcciones; requiere publicar esa versión antes de depender de él.
- [ ] Persona → postvinculación y mitigación: usar 1:* y dirección única, no 1:1 bidireccional. Permitir varios eventos por mujer.
- [ ] Revisar relaciones inactivas de asistencia y agenda de orientación. Usar persona 1 → eventos * y activar solo tras eliminar rutas ambiguas.
- [ ] Evitar que el vínculo bidireccional preregistro–persona convierta filtros de inscritas en filtros de todo el preregistro. Mantener población de preregistro con campos propios.
- [ ] Calendario sigue sin relaciones entre las 10 extraídas y solo abarca fechas de inscripción. Ampliar el rango y definir fechas por evento antes de usarlo como filtro transversal.

## Pendientes por vista para Notion

### Portada y transversal

- [ ] Probar los botones/imágenes de retorno en Desktop: se detectan imágenes en múltiples páginas, pero su presencia no acredita que naveguen correctamente. Conservar el navegador de Portada.
- [ ] Distinguir actualización del modelo BI de última carga raw. El visual de auditoría por módulo queda aplazado; consultar el estado en los guardrails del pipeline.

### Preregistro y Detalle Preregistro

- [ ] Mantener el segmentador de created_time ya corregido. Cambiar los filtros de corte/documento y perfil provenientes de fct_ruta_mujer por campos de fct_preregistro_rm para incluir pendientes aún no inscritos.
- [ ] Los gráficos de estrato, tipificación y evolución todavía usan Personas Registradas/Fecha Inscripción. Convertirlos a perfil de preregistro donde exista campo o rotularlos como inscritas provenientes de preregistro.
- [ ] Añadir tarjeta Preregistros Inscritos y % Conversion Preregistro. Usar barras estado_inscripcion_final × documentos distintos.

### Registros, Detalle Registros, Listado Habilitantes y Base Sae

- [ ] Conservar sede y validación ya construidas. Añadir categoría Sin diligenciar; no equiparar vacío a No.
- [ ] Corregir el gráfico de Grupos poblacionales: el campo escalar conserva una sola pertenencia. Usar bridge_grupos_poblacionales_rm[grupo_poblacional] y DISTINCTCOUNT(documento) después de importar el bridge. La suma por grupo puede superar el total de mujeres.
- [ ] En Detalle Registros, agregar Validación habilitante si también se necesita allí; ya existe en Listado Habilitantes. Base Sae: ajustar únicamente al formato de entrega acordado.

### Embudo ruta y Tracker-Ruta

- [ ] El embudo mezcla mujeres, remisiones y registros post. Usar mujeres distintas para Registro → Orientación → Intermediación → Colocación con alcance común. Mostrar remisiones y atención psicosocial como indicadores separados.
- [ ] Actualizar el gráfico Ejecutados/Faltante con unidades oficiales; no conservar 240 de postvinculación como meta contractual.
- [ ] Tracker: conservar las fases y fechas; agregar Sede/Validación habilitante si se requieren operativamente. Formación puede mostrarse como servicio opcional.

### Gestión Orientación y Detalle Orientaciones

- [ ] Corregir los tiempos de tránsito indicados arriba. El gráfico por orientadora ya existe.
- [ ] Alinear filtro de fecha de orientación con indicadores de orientación; las tarjetas de otros servicios deben explicitar que describen esa población filtrada.

### Gestión Vacantes, Análisis Vacantes y Detalle Vacantes

- [ ] Falta mapa: usar ubicación de municipio/departamento/Colombia y tamaño por puestos o vacantes, con unidad explícita. No presentarlo como dirección exacta ni como localidad de Bogotá.
- [ ] Edad, municipio, género y desmasculinización ya existen. Añadir controles de Sin dato; para la meta 250 contar afirmativos históricos en el alcance del convenio, no solo Vacantes Vigentes.
- [ ] Cambiar filtros de documento, nacimiento y corte de persona en Detalle Vacantes por empresa, código, estado y fecha de vacante cuando el propósito sea consultar la oferta.
- [ ] Puestos Ocupados actualmente cuenta colocadas del mart persona. Usar colocaciones vinculadas al ID de vacante. No inferir disponibilidad real restando solo colocaciones del programa a todos los puestos.

### Gestión Intermediación y Detalle Intermediaciones

- [ ] Reemplazar segmentadores de la última Fecha Intermediación de persona por fct_intermediacion_rm[Fecha intermediación] para consultar eventos.
- [ ] Quitar el límite fijo 01/09/2026 de la medida general Número Intermediaciones; crear una medida explícita de corte 2 si se necesita. Contar eventos por id y mujeres por documento, separadamente.
- [ ] Revisar promedio por mujer: numerador desde septiembre y denominador histórico producen alcances diferentes.
- [ ] El donut 83438805d30b2896b274 agrupa por sector_economico_empresa. Si el título promete estados, cambiar categoría a fct_intermediacion_rm[estado].

### Agendamiento Empresarial

- [ ] Estado pendiente/agendada ya aparece en las tablas: no construirlo otra vez.
- [ ] El segmentador de corte aún viene de intermediación. Usar cohorte/fecha del agendamiento según el criterio requerido.
- [ ] Renombrar Reuniones Unicas a Empresas Agendadas: cuenta empresa_id distintos, no reuniones.

### Agendamiento Orientación

- [ ] Cambiar Responsable comercial por responsable del agendamiento de orientación y corte de intermediación por corte de agenda.
- [ ] Dos tarjetas siguen usando Dias Agendados y Citas Presenciales de agenda comercial. Sustituir por medidas de fct_agenda_orientacion_rm.
- [ ] Añadir estado a la tabla de citas si se requiere gestión de pendientes.

### Análisis Metas

- [ ] Aplicar las correcciones prioritarias de numeradores, unidades y alcance. Los seis medidores ya están: falta validar su significado, no crearlos.
- [ ] Añadir matriz de las 18 metas oficiales: indicador, unidad, meta, ejecutado, cumplimiento y estado de evidencia. Usar dim_metas_convenio_rm y medidas sobre los hechos existentes y conservados. Mantener BLANK para ejecutados sin evidencia; el resumen de avance en dbt queda aplazado.
- [ ] Incluir los componentes empresariales, 25% de colocaciones en sectores masculinizados, talleres, cápsulas y entregables de componentes 3/4. Sin fuente acreditada mostrar Sin dato, no cero.

### Gestión Empresarial

- [ ] Conservar la nueva tabla dim_empresas_rm con nit, empresa, etapa, Vacantes, Intermediaciones y Agendamientos. Corregir sus relaciones por NIT antes de confiar en los filtros.
- [ ] Añadir ranking desde fct_resultados_vacante_rm: filtrar activa_sin_remision; columnas empresa, codigo_vacante, nombre_vacante, num_remisiones y estado_motivo_sin_remision. El motivo real requiere captura; no deducirlo.
- [ ] Añadir matriz de resultados por empresa/vacante: num_remisiones, num_en_proceso, num_contratadas, num_no_paso y num_otros_estados. Son estados actuales, no historial acumulativo de un embudo.
- [ ] Añadir lista de novedades: empresa, codigo_vacante, ultima_novedad_fecha y ultima_novedad.

### Postvinculación y Detalle Postvinculaciones

- [ ] Conservar tarjetas de pendientes y sin gestionar y la nueva tabla de colocadas sin post. Diferenciar existencia de registro, llamada realizada y contrato exigible.
- [ ] Cambiar filtros heredados de fecha/estado/intermediador por fecha de contrato/llamada, estado del seguimiento y responsable disponible. En Detalle Postvinculaciones quitar Fecha Intermediación como filtro de tiempo principal.
- [ ] Tabla de alertas a 15 días: fct_cobertura_post_rm con documento, empresa, fecha_inicio_contrato, dias_transcurridos_contrato, estado_cobertura; filtrar requiere_revision_15_dias. Incluye contratos sin registro post, que no aparecen en el hecho de seguimientos.
- [ ] Completar barras apiladas de novedades: tipo_novedad como eje, remitido_a como leyenda, recuento de eventos como valor. El gráfico actual por documento/tipo no responde completamente a remisión psicosocial vs compromisos.
- [ ] Añadir matriz empresa/sector con casos con novedad y total de casos comparables; mostrar porcentaje y volumen. Evitar llamar riesgo a un simple conteo.

### N Gestión Formación y N Asistencia Formación

- [ ] N Gestión Formación aún muestra gráficos de vacantes, empresas y puestos. Rehacer con fct_formacion_rm o mantenerla fuera de navegación hasta completar: personas distintas, registros por curso y estado_formacion.
- [ ] Personas Formadas usa COUNT(documento); cambiar a DISTINCTCOUNT para contar mujeres y mantener el filtro Completada. No asumir que el estado del registro padre acredita cada curso.
- [ ] N Asistencia Formación todavía usa la tabla de inscritas. Usar fct_asistencia_rm: documento, cursos, fecha_curso, jornada y modalidad_curso; tarjeta de asistencias y otra de personas distintas.

## Pipeline — comprobación rápida a las 17:38 de Colombia

- Colsubsidio: ejecución 35401975842 finalizada con success a las 17:36; frescura posterior 16/16 módulos OK.
- GIZ: ejecución 35397131663 success; frescura 10/10 módulos OK.
- Ruta Mujer: ejecución 35394425585 success; frescura 14/14 módulos OK.
- Las ejecuciones consultadas usan d7ee9de. Los cambios locales de main 3cee901 y los de codex/ruta-bi-ready no están incorporados a esos runs.
- La primera verificación de Colsubsidio coincidió con la carga y falló con -0.0h. El código captura ahora antes de consultar max(run_at), por lo que una escritura concurrente puede quedar después de ese instante. La segunda pasó. Hay una condición de carrera por revisar; no fue una pérdida de frescura confirmada. No se modificó el verificador en esta revisión.
- La rama de correcciones tuvo un build previo de 133 resultados aprobados y 31 pruebas Python aprobadas. Eso acredita esa versión probada; no demuestra que Actions esté ejecutándola ni que un run posterior no haya reconstruido tablas con SQL antiguo.

## Qué falta fuera de BI

Publicar las correcciones backend sigue pendiente. También falta evidencia de sesiones de una hora, talleres/cápsulas/entregables, clasificación validada de sectores masculinizados y motivos de no remisión. El documento no aporta cupos por sede ni metas por corte. No es correcto afirmar que todo eso se resuelve dibujando gráficos.

Para cerrar BI: probar una empresa con varias vacantes, una mujer con varios eventos, un contrato sin post y un cambio de fecha/corte; verificar totales y comportamiento de filtros en Desktop. El inventario adjunto permite localizar cada visual por ID.

## Alcance reducido antes del commit

Se conservan tres hechos nuevos (cobertura post, resultados por vacante y colocaciones), la dimensión de metas y el puente poblacional. Se aplazan los modelos auxiliares de avance del convenio, eventos psicosociales, frescura y completitud. Se retiran sus pruebas y la declaración de fuente usada exclusivamente para el modelo de frescura. Las medidas BI deben respetar la unidad oficial y dejar sin dato los indicadores sin evidencia.

Este cambio retira definiciones del proyecto; no elimina tablas ya materializadas en BigQuery por una prueba anterior. No importar esas tablas auxiliares al PBIX.

Validación del alcance reducido: `dbt build --select path:models/ruta_mujer` completó 122 resultados (16 tablas, 14 vistas y 92 pruebas), con 0 WARN, 0 ERROR y 0 SKIP. Registro local: `output/dbt_build_ruta_reducido.log`. No implica publicación en GitHub.
