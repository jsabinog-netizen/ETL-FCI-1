# Plan de construcción — Dashboard Ruta Mujer

Documento de trabajo para replicar y mejorar el dashboard de C2M sobre el pipeline propio.

Fuente de datos: `zoho-bq-pipeline-492116.proyecto_ruta_mujer`
Marts disponibles: `fct_ruta_mujer` · `fct_intermediacion_rm` · `fct_formacion_rm` · `dim_vacantes_rm` · `fct_agendamientos_rm`
Stagings sin mart: `stg_asist_pres_rutam` · `stg_pre_registro_rutam` · `stg_pre_registro_empresarial`

---

## 0. Advertencias antes de construir

Estas cosas cambian decisiones de diseño. Léelas antes de abrir Power BI.

**0.1 La colocación está prácticamente vacía**
`fct_ruta_mujer.fecha_colocacion` tiene 99,1% de nulos. El gauge de colocación va a mostrar un cumplimiento muy bajo. Antes de presentarlo, confirmá con la coordinación si el módulo `Colocaci_n_Colsubsidios` se está diligenciando o si se registran en otro lado.

**0.2 `Ultimo_nivel_educativo_alcanzado` está sucio**
Valores encontrados en el CRM para el mismo concepto (Ej: Bachillerato · Bachiller · Bachiller Academico). Un gráfico por nivel educativo produce 12+ categorías para lo que son 4. Normalizado en dbt (ver §18.1).

**0.3 Dos stagings están (casi) vacíos**
`stg_mitigaci_n_colsubsidios` y `stg_postvinculaci_n_colsub` tienen de 0 a 1 filas. Todo gráfico de retención o mitigación queda para Fase 2.

**0.4 Campos 100% nulos que no sirven para nada**
* `fct_formacion_rm`: `gestor_operativo`, `estado_de_mitigacion` (100% nulos)
* `fct_intermediacion_rm`: `observaci_n_calidad`, `validaci_n_calidad` (100% nulos)
* `fct_ruta_mujer`: `seleccione_el_tipo_de_barrera_3` y `2` (>97% nulos)

**0.5 `dia_semana` viene en inglés**
Traducido en DAX o dbt (ver §18.5).

**0.6 Límite de campos en Vacantes (Zoho)**
Para evitar fallos de extracción por el límite de 50 campos de Zoho, se eliminaron 18 campos no utilizados de `GE_Vacantes_Colsubsidios` (ej: certificaciones de discapacidad, acepta víctimas del conflicto, etc). Los visuales que dependían de ellos ya no aplican.

**0.7 Relación inactiva obligatoria para Embudos (NUEVO P21)**
Debe existir una relación **INACTIVA** entre `dim_vacantes_rm[codigo_vacante]` y `fct_intermediacion_rm[buscar_vacante_nombre]`. Se activará vía DAX (`USERELATIONSHIP`) para los embudos por vacante.

---

## 1. Medidas DAX base (crear primero)

Creá una tabla `_Medidas` vacía (Datos → Escribir consulta DAX → tabla en blanco) y poné todo ahí.

**1.1 Conteos del embudo**
```dax
Registros = DISTINCTCOUNT(fct_ruta_mujer[documento])

Inscritas = CALCULATE(DISTINCTCOUNT(fct_ruta_mujer[documento]), fct_ruta_mujer[inscrita] = TRUE())
Orientadas = CALCULATE(DISTINCTCOUNT(fct_ruta_mujer[documento]), fct_ruta_mujer[orientada] = TRUE())
Psicosociales = CALCULATE(DISTINCTCOUNT(fct_ruta_mujer[documento]), fct_ruta_mujer[psicosocial] = TRUE())
Intermediadas = CALCULATE(DISTINCTCOUNT(fct_ruta_mujer[documento]), fct_ruta_mujer[intermediada] = TRUE())
Colocadas = CALCULATE(DISTINCTCOUNT(fct_ruta_mujer[documento]), fct_ruta_mujer[colocada] = TRUE())
```

**1.2 Metas (tabla desconectada)**
```dax
Metas = 
DATATABLE(
    "Etapa", STRING,
    "Meta", INTEGER,
    {
        {"Orientación", 600},
        {"Formación", 600},
        {"Colocación", 150}
    }
)

Meta Orientacion = CALCULATE(SUM(Metas[Meta]), Metas[Etapa] = "Orientación")
Meta Formacion   = CALCULATE(SUM(Metas[Meta]), Metas[Etapa] = "Formación")
Meta Colocacion  = CALCULATE(SUM(Metas[Meta]), Metas[Etapa] = "Colocación")
```

**1.3 Cumplimiento**
```dax
% Cumplimiento Orientacion = DIVIDE([Orientadas], [Meta Orientacion], 0)
% Cumplimiento Formacion = DIVIDE([Talleres Realizados], [Meta Formacion], 0)
% Cumplimiento Colocacion = DIVIDE([Colocadas], [Meta Colocacion], 0)
```

**1.4 Conversión del embudo**
```dax
% Inscritas de Registros    = DIVIDE([Inscritas],      [Registros], 0)
% Orientadas de Inscritas   = DIVIDE([Orientadas],     [Inscritas], 0)
% Psicosocial de Orientadas = DIVIDE([Psicosociales],  [Orientadas], 0)
% Intermediadas de Orient   = DIVIDE([Intermediadas],  [Orientadas], 0)
% Colocadas de Intermediadas= DIVIDE([Colocadas],      [Intermediadas], 0)
% Colocadas de Registros    = DIVIDE([Colocadas],      [Registros], 0)
```

**1.5 Fecha de actualización**
```dax
Fecha Actualizacion = 
"Actualizado: " & FORMAT(MAX(fct_ruta_mujer[_loaded_at]), "dd/MM/yyyy hh:mm AM/PM")
```

**1.6 Tabla de calendario**
```dax
Calendario = 
ADDCOLUMNS(
    CALENDAR(MIN(fct_ruta_mujer[fecha_inscripcion]), MAX(fct_ruta_mujer[fecha_inscripcion])),
    "Año", YEAR([Date]),
    "Mes", MONTH([Date]),
    "NombreMes", FORMAT([Date], "MMMM"),
    "AñoMes", FORMAT([Date], "yyyy-MM"),
    "Trimestre", "T" & QUARTER([Date]),
    "DiaSemana", FORMAT([Date], "dddd")
)
```

---

## 2. Página INICIO (portada)
* **Logos**: FCI · Gender Knowledge Lab · Pro Mujer · Colsubsidio
* **Fecha actualización**: Tarjeta `[Fecha Actualizacion]`
* **Navegación**: Botones tipo "Navegador de páginas".

---

## 3. Página ANALISIS METAS
* **Registros, Inscritas, Orientadas, Psicosociales, Intermediadas** (Tarjetas).
* **Gauges de cumplimiento**: Orientación, Formación y Colocación. (Máximo: 1).
* **Avance vs. tiempo transcurrido (NUEVO)**: Gráfico de líneas y columnas apiladas mostrando el acumulado mensual frente a la meta proyectada.

---

## 4. Página PREREGISTRO
Fuente: `stg_pre_registro_rutam` (o `fct_preregistro_rm`)
* **KPIs**: `[Total Preregistros]`, `[Preregistros Inscritos]`, `[Preregistros No Aplican]`, `[Preregistros Pendientes]`.
* **Canal de captación**: Barras horizontales por `d_nde_te_enteraste_de_esta_vacante`.

---

## 5. Página EMBUDO
* **Embudo Proyecto**: Usar tabla desconectada de etapas para forzar el orden (Registros → Inscritas → Orientadas → Psicosocial → Intermediadas → Colocadas).
* **Tiempos entre etapas**: Tarjetas mostrando el promedio de días entre inscripción y orientación, etc.
* **Mujeres Estancadas (>30d)**: Tarjeta de alerta (DAX incluido en el prompt base).

---

## 6. Página GESTION GENERAL
* **Slicers**: `inscrita_txt`, `orientada_txt`, etc (Sí/No).
* **Gráficos**: Registros por Fecha, Tipificaciones (Anillo), Modalidad Atención (Circular).
* **Perfil de vulnerabilidad cruzado (NUEVO)**: Matriz (Filas: `tipificacion_mujer`, Columnas: `etapa_actual`, Valores: `[Registros]`).
* **Pirámide etaria (NUEVO)**: Barras apiladas por `rango_etario` y `tipificacion_mujer`.
* **Distribución Sisbén**: Barras horizontales.

---

## 7. Página GESTION ORIENTACION
* **Gráficos**: Inscripciones Curso por Orientador, Modalidad.
* **Productividad por orientadora (NUEVO)**: Barras con línea promedio del equipo.
* **Derivación a psicosocial (NUEVO)**: % de orientadas derivadas por profesional.

---

## 8. Página LISTADO HABILITANTES
* Tabla plana y segmentadores.
* **Ficha 360 (NUEVO)**: Seleccionando un documento, ver tarjetas de estado general y tablas asociadas de intermediación y formación.

---

## 9. Página BASE SAE
Igual a Habilitantes, pero habilitada para exportación masiva.

---

## 10. Página GESTION VACANTES
Fuente: `dim_vacantes_rm` y `fct_agenda_comercial_rm`

**Visuales Base:**
* **Tarjetas:** Vacantes Activas, Puestos de Trabajo, Total Empresas, Sectores.
* **Gráficos:** Puestos por Empresa, Tipo de Contratos (Anillo), Sectores Vacantes (Barras).

**NUEVOS REPORTES P21:**

**10.1 Estado de Agendamiento por Empresa**
```dax
Vacantes_Agendadas = CALCULATE(DISTINCTCOUNT(dim_vacantes_rm[codigo_vacante]), fct_agenda_comercial_rm[estado] = "agendada")
Vacantes_Pendientes = CALCULATE(DISTINCTCOUNT(dim_vacantes_rm[codigo_vacante]), fct_agenda_comercial_rm[estado] = "pendiente")
Vacantes_Canceladas = CALCULATE(DISTINCTCOUNT(dim_vacantes_rm[codigo_vacante]), fct_agenda_comercial_rm[estado] = "cancelada")
```
*Visual recomendado:* Barras agrupadas por `dim_empresas_rm[nombre_empresa]`.

**10.2 Vacantes Activadas con Marca de Género**
```dax
Total_Vacantes_Activas = CALCULATE(DISTINCTCOUNT(dim_vacantes_rm[codigo_vacante]), dim_vacantes_rm[estado_de_la_vacante] = "activa")
Total_Vacantes_Enfoque_Genero = CALCULATE(DISTINCTCOUNT(dim_vacantes_rm[codigo_vacante]), dim_vacantes_rm[estado_de_la_vacante] = "activa", NOT ISBLANK(dim_vacantes_rm[vacante_con_enfoque_de_genero]))
Total_Vacantes_Desmasculinizacion = CALCULATE(DISTINCTCOUNT(dim_vacantes_rm[codigo_vacante]), dim_vacantes_rm[estado_de_la_vacante] = "activa", NOT ISBLANK(dim_vacantes_rm[vacante_de_desmasculinizacion]))
```

*Nota: Se descarta el gráfico de "Inclusión en vacantes" (discapacidad, víctimas) al haberse eliminado esos campos del CRM por límites técnicos.*

---

## 11. Página GESTION FORMACION
* **Métricas**: Personas Inscritas, Cursos Realizados, Cursos Activos.
* **Tasa de Finalización por curso (NUEVO)**: Barras horizontales (ojo: `formaci_n_completada` tiene 90% nulos).

---

## 12. Página BD ASISTENCIA FORMACION
* **Tabla**: Asistentes reales desde `stg_asist_pres_rutam`.
* **Asistencia por jornada (NUEVO)**: Columnas apiladas de Mañana/Tarde.

---

## 13. Página GESTION INTERMEDIACION
Fuente: `fct_intermediacion_rm`

**NUEVOS REPORTES P21 (Embudo y Novedades por Vacante)**
*Crucial: La relación inactiva entre vacantes e intermediación permite este análisis cruzado.*

**13.1 Embudo de Contratación por Vacante**
```dax
Embudo_01_Remitidas = CALCULATE(DISTINCTCOUNT(fct_intermediacion_rm[documento]), USERELATIONSHIP(dim_vacantes_rm[codigo_vacante], fct_intermediacion_rm[buscar_vacante_nombre]), fct_intermediacion_rm[estado] = "envío de hoja de vida")
Embudo_02_En_Proceso = CALCULATE(DISTINCTCOUNT(fct_intermediacion_rm[documento]), USERELATIONSHIP(dim_vacantes_rm[codigo_vacante], fct_intermediacion_rm[buscar_vacante_nombre]), fct_intermediacion_rm[estado] = "asistió/está en proceso")
Embudo_03_Contratadas = CALCULATE(DISTINCTCOUNT(fct_intermediacion_rm[documento]), USERELATIONSHIP(dim_vacantes_rm[codigo_vacante], fct_intermediacion_rm[buscar_vacante_nombre]), fct_intermediacion_rm[estado] = "contratado")
Embudo_04_No_Paso = CALCULATE(DISTINCTCOUNT(fct_intermediacion_rm[documento]), USERELATIONSHIP(dim_vacantes_rm[codigo_vacante], fct_intermediacion_rm[buscar_vacante_nombre]), fct_intermediacion_rm[estado] IN {"asistió/no superó el proceso", "la asignación salarial no se ajusta a sus necesidades", "no interesado por otro motivo ¿cual?"})
```

**13.2 Novedad Reciente (Último estado narrativo)**
```dax
Novedad_Reciente = CALCULATE(LASTNONBLANK(fct_intermediacion_rm[novedad_intermediaci_n], fct_intermediacion_rm[fecha_intermediaci_n]), USERELATIONSHIP(dim_vacantes_rm[codigo_vacante], fct_intermediacion_rm[buscar_vacante_nombre]))
```

*Visual recomendado:* Matriz con filas por Empresa y Vacante, y Valores con las 5 medidas de arriba.

---

## 14. Página AGENDAMIENTO EMPRESARIAL
* **Gráficos**: Reuniones Únicas, Virtuales vs Presenciales, Estados de Agendamiento.
* **Conversión a vacante (NUEVO)**: % de empresas agendadas que abren vacante.

---

## 15. Página AGENDAMIENTO ORIENTACION
* Solo útil como tabla plana (muy pocos registros).

---

## 16. Página COLOCACIONES
* **Visuales**: Salario Promedio, Colocaciones por Mes, Tipo de Contrato (Anillo).

---

## 17. Campos que faltan extraer o modelar
* `motivo_de_atenci_n`, `nivel_de_riesgo_psicosocial_identificado`, etc., deben agregarse al `SELECT` de `fct_ruta_mujer` desde `stg_psicosocial_rutam`.
* Crear `fct_asistencia_rm` a partir de su respectivo staging.
* `Sede_de_atenci_n` fue agregado recientemente, pero falta crear la semilla `distribucion_sedes.csv` para homologar geografías.

---

## 18. Transformaciones dbt requeridas
* Ya aplicadas o pendientes de merge: normalización de nivel educativo, flags de texto (Sí/No), rangos etarios, limpieza de Sisbén.

---

## 19. Página CALIDAD DE DATOS
* Matriz de % de completitud (Tipificación, Sisbén, Perfil, etc).
* Alertas de integridad (Fechas inconsistentes, Mujeres estancadas sin gestión).

---

## 20. Página PRODUCTIVIDAD DEL EQUIPO
* Análisis de carga laboral (Registros por profesional, Orientaciones, Intermediaciones).

---

## 21. Orden de implementación sugerido
*(Mismo del plan original: Fase A Preparación -> Fase B Modelo Power BI -> Fase C Réplica -> Fase D Mejoras).*

---

## 22. Validación antes de publicar
Verificar conteos principales contra Zoho (Ej: `Total mujeres` vs total en Inscripciones).

---

## 23. Resumen de decisiones pendientes
* Metas faltantes — inscripción, psicosocial, intermediación.
* Definición exacta de "taller realizado".
* Colocación casi vacía — ¿se está registrando en el módulo correcto?
* Orden real del embudo (¿Es Intermediados > Psicosocial?).
* `titulo_homologado` — validar si usar `Requiere_tarjeta_profesional` como proxy es correcto.
* Semilla `distribucion_sedes.csv` (esperando mapeo del usuario).
