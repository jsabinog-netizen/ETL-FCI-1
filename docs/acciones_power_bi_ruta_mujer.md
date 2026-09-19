> Revisión anterior, sustituida por [pendientes_bi_actualizados.md](pendientes_bi_actualizados.md) y [inventario_pbix_actualizado.md](inventario_pbix_actualizado.md). Conservada como referencia histórica; no aplicar sin contrastar.

# Acciones concretas en Power BI Ruta Mujer

Auditoría del PBIX entregado el 18 de septiembre de 2026. Se leyeron su definición PBIR, las 63 medidas DAX, las 9 relaciones, las consultas M y las 22 páginas. El archivo original no fue modificado. Los ID permiten localizar cada visual en el inventario adjunto; en Desktop reconocerlo por título y campos.

## 1. Actualizar fuentes y relaciones antes de retocar gráficos

- [ ] Actualizar las tablas existentes desde BigQuery después del build. Mantener los Rename Columns actuales; las fórmulas entregadas respetan Documento, Fecha Inscripción y otros nombres reales de este PBIX.
- [ ] Importar dim_metas_convenio_rm con las 18 metas oficiales. Calcular el avance operativo con medidas sobre hechos en BI; mantener BLANK donde falta evidencia. El documento no distribuye metas por corte.
- [ ] Importar fct_resultados_vacante_rm, fct_cobertura_post_rm, fct_colocaciones_rm y bridge_grupos_poblacionales_rm. Los modelos auxiliares de avance, frescura, completitud y eventos psicosociales se aplazaron.
- [ ] Quitar la relación activa M:M bidireccional dim_vacantes_rm[nit_empresa] ↔ fct_intermediacion_rm[nit_de_la_empresa]. Reemplazar por dim_vacantes_rm[id] (1) → fct_intermediacion_rm[buscar_vacante_id] (*), activa y dirección única. El cruce por ID se verificó con 1.014/1.014 eventos al inicio de esta revisión.
- [ ] Quitar la relación activa M:M bidireccional agenda_comercial[empresa_id] ↔ dim_vacantes_rm[empresa_id]. Importar dim_empresas_rm, cuya clave única es nit. Relacionarla 1:* con dim_vacantes_rm[nit_empresa]. Para agenda usar dim_empresas_rm[nit] (1) → fct_agenda_comercial_rm[nit_empresa] (*), activa y dirección única. La clave nit_empresa se agregó en dbt resolviendo el lookup por ID y, como respaldo, por NIT. Revisar los casos sin correspondencia antes de excluirlos de visuales. No usar nombres de empresa como clave ni activar filtros bidireccionales para compensarlo.
- [ ] Cambiar las relaciones de fct_postvinculacion_rm y fct_mitigacion_rm con fct_ruta_mujer de 1:1/bidireccional a fct_ruta_mujer[Documento] (1) → documento (*), dirección única. El grano de los hechos es evento, aunque hoy haya pocos registros.
- [ ] Cambiar agendamiento_orientacion–persona de 1:1 a 1:*. Activarla si no genera otra ruta; no volver bidireccional. Activar persona → asistencia (hoy inactiva) para los filtros por participante, una vez eliminadas rutas ambiguas.
- [ ] Cambiar la relación preregistro–persona de Both a Single desde persona hacia preregistro. En la página Preregistro usar filtros del propio preregistro: así la población no se limita accidentalmente a las ya inscritas.
- [ ] Relacionar vacantes[id] → colocaciones[codigo_de_la_vacante_id] y vacantes[id] → resultados_vacante[vacante_id], dirección única. Relacionar persona → cobertura_post y persona → bridge_grupos por documento. No sumar num_mujeres de distintas vacantes para obtener mujeres únicas del programa.
- [ ] Mantener la dimensión de metas desconectada del calendario/personas para seleccionar indicador. Calcular avance desde los hechos bajo el alcance definido y distinguir convenio completo de cohorte o periodo.
- [ ] Ampliar Calendario: hoy solo abarca fechas de inscripción y no tiene ninguna relación en las 9 extraídas. Incluir las fechas de todos los eventos que se grafican, marcarla como tabla de fechas y definir relaciones de fecha por hecho. En fct_ruta_mujer usar una activa y las alternativas inactivas con medidas específicas, o calendarios por rol. No conectar varias rutas activas ambiguas.

## 2. Cambios por página

### Portada

- [ ] Conservar el navegador de páginas existente; no falta crear toda la navegación.
- [ ] Revisar la tarjeta de actualización 0358a37b1ec9b88e093d y rotularla como actualización del modelo BI. La auditoría raw por módulo sigue disponible en el pipeline, pero su visualización en BI queda aplazada.

### Preregistro

- [ ] Sustituir los filtros Fecha de Registro/Cohorte provenientes de fct_ruta_mujer por created_time/corte de fct_preregistro_rm. Los gráficos actuales de zona, tipificación y fecha también usan inscritas; si se mantienen, rotularlos como perfil de preregistradas que llegaron a inscripción.
- [ ] Corregir las dos tarjetas 5fcc5f1b964cb8b159ce y 86909d2b403060d230c1: ambas muestran Total Preregistros. Usar una para Preregistros Inscritos.
- [ ] Añadir barras de estado_inscripcion_final con DISTINCTCOUNT(documento) y la conversión preregistro→inscripción. No sumarlas para total si un documento pudiera tener varios formularios con estados distintos.

### Embudo ruta

- [ ] Visual 8d7670a8345bb3d9e08b: quitar Formación y Psicosocial del embudo contractual. Dejar Registro → Orientación → Intermediación → Colocación. Psicosocial y formación son servicios complementarios.
- [ ] No usar remisiones como si fueran mujeres en el embudo. Mostrar mujeres distintas para la ruta y la meta de 1.000 remisiones en un visual separado. Los estados actuales no reconstruyen conversiones históricas.
- [ ] Reemplazar la tabla Metas RM manual para el visual 3db657a7a7e0103cc6d1. Actualmente incluye 400 personas intermediadas y 240 postvinculadas: esas dos metas no corresponden al documento oficial.

### Tracker-Ruta

- [ ] Conservar la tabla Tracker Fases Ruta Mujer; Formación puede seguir como columna de servicio, no como fase obligatoria.
- [ ] Añadir Sede, validacion_habilitante y las fechas de carga/transformación si son útiles para seguimiento.

### Detalle Registros

- [ ] La tabla c9188fe6d5de73ee2e9a ya tiene Sede. No crear esa columna de nuevo. Añadir validacion_habilitante y un segmentador Sin diligenciar/valores del origen.

### Gestión General

- [ ] Añadir barras por Sede con Personas Registradas; incluir Sin diligenciar.
- [ ] Añadir barras por grupo_poblacional desde bridge_grupos_poblacionales_rm con documentos distintos. No usar grupos_poblacionales del mart central para contar todas las pertenencias: conserva solo la primera por compatibilidad.
- [ ] Añadir matriz Tipificación Mujer × Etapa Actual usando Personas Registradas. No usar la suma de las etapas como sesiones o servicios.

### Gestión Orientación

- [ ] El gráfico por Orientadora ya existe (ffaf5c9db527a1d71707). Solo agregar la línea promedio si se necesita.
- [ ] Renombrar % Derivadas a Psicosocial: su fórmula actual cuenta orientadas con psicosocial completada, NO derivaciones. Usar 'Orientadas con psicosocial completada' hasta contar con evento explícito de remisión.

### Detalle Orientaciones

- [ ] Conservar tabla actual. Para volumen de atenciones repetidas no usar la fila resumida por persona del mart central.

### Listado Habilitantes

- [ ] Tabla 52dd6df67ecdb13ffef2: agregar Sede y validacion_habilitante; mantener Documento y nombre para gestión. Añadir filtro de validación. No transformar los nulos en un estado de negocio inventado.

### Base Sae

- [ ] Sede ya existe. Agregar validacion_habilitante si forma parte del formato acordado de exportación; validar columnas con el receptor SAE antes de cambiar el contrato de entrega.

### Gestión Vacantes

- [ ] Conservar tarjetas de vacantes/puestos, pero reemplazar Puestos Ocupados: hoy cuenta todas las mujeres colocadas desde el mart central, sin garantía de segmentación por vacante. Usar colocaciones reportadas por vacante en fct_colocaciones_rm.
- [ ] No llamar 'Puestos Disponibles' a Total Puestos menos colocaciones del programa: pueden existir contrataciones ajenas al programa y puestos cerrados. Rotular 'Puestos ofertados menos colocaciones reportadas' o retirar el saldo hasta validar esa semántica.
- [ ] Tabla operativa: empresa, codigo_vacante, nombre_vacante, perfil_de_la_vacante, estado_de_la_vacante, es_enfoque_genero, es_desmasculinizacion.

### Análisis Vacantes

- [ ] Barras: rango_etario_vacante × Recuento Vacantes o Total Puestos (rotular unidad); tooltip con edad_m_nima y edad_m_xima.
- [ ] Barras geográficas: ciudad_municipio_de_la_vacante. No rotular Localidad: el dato disponible es municipio.
- [ ] Mapa: ubicacion_mapa; tamaño Total Puestos. No representa coordenadas exactas del lugar de trabajo.
- [ ] Barras Sí/No/Sin dato de es_enfoque_genero y es_desmasculinizacion. Las metas usan afirmativos, no NOT ISBLANK.
- [ ] Tabla/ranking: fct_resultados_vacante_rm filtrada por activa_sin_remision. Campos empresa, codigo_vacante, fecha_de_inicio_de_la_vacante, num_remisiones, estado_motivo_sin_remision. El motivo no se puede deducir de la ausencia de remisiones.

### Detalle Vacantes

- [ ] Agregar ubicacion_mapa, es_enfoque_genero, es_desmasculinizacion y ambas edades a la tabla existente; mantener código e ID.

### N Gestión Formación

- [ ] Reemplazar Personas Formadas por DISTINCTCOUNT(documento) filtrado por Completada. La fórmula actual usa COUNT y repite mujeres inscritas en varios cursos.
- [ ] Separar personas, inscripciones a curso (id_curso) y sesiones/talleres. El estado_formacion se hereda del registro padre, no acredita por sí solo finalización individual de cada curso.

### N Asistencia Formación

- [ ] Rehacer la tabla eb4f8604c71c2be7374d: actualmente usa personas de fct_ruta_mujer, no asistencias. Usar fct_asistencia_rm: documento, cursos, fecha_curso, jornada, modalidad_curso e id. Nombre de participante desde la relación 1:*.
- [ ] Cambiar fecha y tarjeta: fecha_curso y Asistencias Registradas/Personas Asistentes. Añadir columnas por jornada. No asumir que una fila equivale a un taller distinto.

### Gestión Intermediación

- [ ] Visual 83438805d30b2896b274, 'Intermediaciones Por Estado': su categoría es sector_economico_empresa. Cambiar a fct_intermediacion_rm[estado], o renombrar el gráfico a sector si se quiere conservar.
- [ ] Línea 1ae1598152c86a116b73: para remisiones por fecha usar fecha_intermediaci_n del hecho y Número Intermediaciones; la fecha del mart central es solo la última por mujer.
- [ ] Añadir matriz empresa/vacante/estado por ID con conteo de eventos y tarjeta separada de mujeres distintas. No hay USERELATIONSHIP necesario después de crear la relación activa por vacante y eliminar el M:M.

### Detalle Intermediaciones

- [ ] Cambiar el segmentador Fecha de intermediación para usar la fecha del hecho, no la última fecha de la persona.
- [ ] Tarjeta d4589dbe95900c5670ca: usa Personas Orientadas. Sustituir por Número Intermediaciones o Mujeres con Remisión.

### Agendamiento Empresarial

- [ ] Estado ya está en las tres tablas. Ese pendiente de tu lista está resuelto en el PBIX entregado.
- [ ] Corregir Cohorte (08a91de75597182ad3e1): usar fct_agenda_comercial_rm[Cohorte], no corte de intermediación. Para corte por fecha usar corte_evento y rotularlo distinto.
- [ ] Renombrar Reuniones Unicas a Empresas Agendadas: la medida realmente cuenta empresas_id distintos. Citas Empresariales cuenta eventos.

### Agendamiento Orientación

- [ ] Cambiar Cohorte a fct_agenda_orientacion_rm[corte] y Responsable a fct_agenda_orientacion_rm[responsable]. Actualmente vienen de intermediación y agenda comercial.
- [ ] Sustituir las tarjetas Dias Agendados y Citas Presenciales comerciales por Dias Agendados Orientacion y Citas Presenciales Orientacion.
- [ ] Agregar estado a la tabla 7b9cf31e0570b01b1cc6 si se necesita gestión detallada.

### Análisis Metas

- [ ] Corregir Meta Colocados rm: filtra '6. Personas Colocadas', pero la fila actual dice '5. Personas Colocadas'. Usar indicador_id C2_COLOCACION del catálogo nuevo (240).
- [ ] Corregir Meta Psicosocial: busca '4. Personas formadas', que no existe. La meta oficial es 600 SESIONES de mínimo una hora, no mujeres ni formaciones.
- [ ] Medidor dabb36051217101a5455: el título Psicosocial usa % Cumplimiento Formacion. Retirarlo como cumplimiento contractual hasta disponer de sesiones acreditadas. Puedes mostrar personas atendidas como actividad operativa, con título explícito.
- [ ] Cambiar intermediación a 1.000 remisiones. El número 400 del PBIX no está en el documento oficial.
- [ ] Quitar 240 como meta contractual de postvinculación: el documento no contiene esa meta. Mostrar cobertura operativa en su página.
- [ ] Crear una matriz con dim_metas_convenio_rm y medidas BI: indicador, unidad, meta, ejecutado, cumplimiento y faltante. Dejar sin dato los indicadores sin evidencia; no convertirlos a cero.
- [ ] Para metas por periodo/cohorte, usar hechos y medidas específicas; el documento no autoriza asignar la meta entera al corte 2 ni inventar cuotas.

### Gestión Empresarial

- [ ] Hoy repite agenda comercial. Importar dim_empresas_rm y usar nombre_de_la_empresa, nit, etapa_empresa, num_vacantes, num_intermediaciones y num_agendamientos.
- [ ] Consolidar las tres tablas tituladas 'Detalle De Orientaciones' (976b56f0a1d88e79b139, bca4ba3809e0b23b91e7, cb94d20bc58206c5d0c3): muestran empresa y estado de citas.
- [ ] 'Perfil Ocupacional' usa Tipo de actividad; corregir título. 'Intermediaciones Por fecha' usa Sector economico y Citas Empresariales; corregir título o usar el hecho correcto.
- [ ] Añadir estado de vacantes, remisiones y última novedad desde fct_resultados_vacante_rm. ultima_novedad ya se selecciona cronológicamente en dbt.
- [ ] Componente 1: mostrar metas 120 diagnósticos empresariales, 80 asesorías, 250 vacantes ajustadas con enfoque. Citas o empresas registradas no acreditan diagnósticos ni asesorías; mostrar Sin fuente validada hasta vincular los instrumentos del convenio.

### Postvinculación

- [ ] Sustituir filtros heredados: fecha_intermediaci_n por fecha_inicio_contrato o fecha_llamada_seguimiento; estado de intermediación por estado_post_calculado/estado_caso; sector de vacantes por sector del seguimiento; cohorte de intermediación por corte del seguimiento. Quitar Intermediador si no hay responsable de seguimiento en la fuente.
- [ ] Alertas Vencidas ya existe (9d87c28360b62b0baec1); al refrescar tomará el hito corregido a 15 días. Escalamiento sigue en 25: nadie autorizó cambiar ese segundo umbral.
- [ ] Añadir tarjeta y tabla desde fct_cobertura_post_rm para ausencia de registro. Campos documento, empresa, fecha_inicio_contrato, dias_transcurridos_contrato, estado_cobertura, requiere_revision_15_dias.
- [ ] La cobertura debe contar contratos exigibles con llamada confirmada. No usar DISTINCTCOUNT(documento del registro post)/Personas Colocadas: tener registro no significa haber llamado. Los cruces ambiguos o sin correspondencia de contrato deben figurar como pendientes de revisión.
- [ ] Unir novedad y remisión en barras apiladas: tipo_novedad, remitido_a, Total Postvinculaciones. Añadir matriz empresa/sector y proporción de casos con novedad. No interpretar un conteo como riesgo sin denominador ni volumen suficiente.

## 3. Pendientes externos que BI no puede inventar

- Sede y los nuevos flags de género requieren diligenciamiento de Zoho. Los modelos permiten distinguir vacío de No.
- Cupos por sede: el documento oficial no incluye distribución. No se creó el CSV de porcentajes propuesto en la conversación anterior.
- 600 sesiones requieren fecha, duración mínima de 60 minutos, participante y evidencia por sesión. El CRM actual no acredita esos datos mediante el flag de persona.
- 30 talleres y 16 cápsulas requieren sus registros. Los componentes 3 y 4 requieren documentos/evidencias de ejecución. La tabla de metas ya los incorpora, pero el ejecutado queda NULL.
- Sectores masculinizados: el documento cita construcción, transporte y otros oficios operativos, sin catálogo completo. El 25% usa colocaciones confirmadas, no vacantes con desmasculinización. Hace falta clasificación validada y soporte; no se calculó un porcentaje con reglas adivinadas.
- Las fuentes oficiales son SAE e instrumentos de soporte. Los conteos de Zoho se rotulan como avance operativo hasta conciliarlos.

## 4. Medidas y verificación

Ver medidas_ruta_mujer_corregidas.dax. Cada bloque se crea/reemplaza individualmente en Calculos; los nombres de columnas existentes fueron verificados contra el PBIX. Las medidas de tablas nuevas requieren importarlas primero. Son fórmulas preparadas, no ejecutadas dentro del motor DAX del PBIX.

Después de aplicar: comprobar una empresa con varias vacantes, una mujer con varios cursos, una colocación sin seguimiento y un filtro de fecha de evento. Contrastar totales con BigQuery. Los nuevos modelos no justifican publicar un cumplimiento contractual de sesiones, talleres o entregables que aún carecen de evidencia.
