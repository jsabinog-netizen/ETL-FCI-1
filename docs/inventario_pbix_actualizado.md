# Inventario PBIX actualizado — 18 septiembre 2026, guardado 17:24

Campos extraídos de las consultas efectivas de los visuales; se excluyen referencias antiguas de formato/queryRef. No es una prueba de renderizado en Desktop.

## Portada

| ID | Visual | Campos/medidas |
|---|---|---|
| 0358a37b1ec9b88e093d | card | Fecha Actualización[Fecha y hora] |
| fc4d941788d770da9730 | pageNavigator |  |

## Preregistro

| ID | Visual | Campos/medidas |
|---|---|---|
| 00f1d7c5309050da2c33 | clusteredColumnChart | fct_ruta_mujer[Naturaleza del Estrato]; Calculos[Personas Registradas] |
| 07df314b68105a21d57e | donutChart | fct_ruta_mujer[Tipo de Población]; Calculos[Personas Registradas] |
| 0ca4a4a0649660096ac7 | slicer | fct_preregistro_rm[created_time] |
| 5fcc5f1b964cb8b159ce | cardVisual | Calculos[Total Preregistros] |
| 6e30d88e3394c2bd61ed | cardVisual | Calculos[Preregistros Pendientes] |
| 76968778806d4e9a78b0 | clusteredBarChart | fct_ruta_mujer[Tipificación Mujer]; Calculos[Personas Registradas] |
| b0786a708c490e23502c | cardVisual | Calculos[Preregistros No Aplican] |
| f2df6622205e854205ac | lineChart | fct_ruta_mujer[Fecha Inscripción]; Calculos[Personas Registradas] |
| f56a64a17e5090089645 | slicer | fct_ruta_mujer[corte] |
| f5a3ba79902e426abd1d | donutChart | fct_ruta_mujer[Inscrita]; Calculos[Personas Registradas] |
| bb850d11c55dad2a6853 | image |  |

## Embudo ruta

| ID | Visual | Campos/medidas |
|---|---|---|
| 0158be94c32d80205764 | cardVisual | Calculos[% Inscritas de Registros] |
| 09a5b81d03c506067315 | image |  |
| 38b941d96b0374990a37 | cardVisual | Calculos[% Intermediadas de Orientaciones] |
| 3db657a7a7e0103cc6d1 | barChart | Metas RM[Etapa]; Calculos[Ejecutados Ruta Mujer]; Calculos[Faltante Metas ruta] |
| 8d7670a8345bb3d9e08b | funnel | Calculos[Mujeres registradas]; Calculos[Mujeres Orientadas]; Calculos[Mujeres con Acompañamiento individual]; Calculos[Número Intermediaciones]; Calculos[Mujeres colocadas]; Calculos[Mujeres posvinculadas] |
| 9340a27d1b04185ca07b | cardVisual | Calculos[% Psicosocial de Orientadas] |
| a4b32da42c620ee1c95a | cardVisual | Calculos[% Colocadas de Intermediadas] |
| fa4ef09c334e00108e0b | cardVisual | Calculos[% Orientadas de Inscritas] |
| fbb685957e330664d404 | slicer | fct_ruta_mujer[corte_inscripcion] |

## Tracker-Ruta

| ID | Visual | Campos/medidas |
|---|---|---|
| 164f9f5577be958692bb | slicer | fct_ruta_mujer[Tipo de Documento] |
| 27899ab6ba48c85b453e | image |  |
| 51d15b88dd2d051b5303 | slicer | fct_ruta_mujer[Localidad] |
| 55cfe6df6b05a7166890 | slicer | fct_ruta_mujer[corte] |
| 6c306f26a9c7acd18e9c | tableEx | fct_ruta_mujer[Tipo de Documento]; fct_ruta_mujer[Documento]; fct_ruta_mujer[Primer Nombre]; fct_ruta_mujer[Segundo Nombre]; fct_ruta_mujer[Primer Apellido]; fct_ruta_mujer[Segundo Apellido]; fct_ruta_mujer[Rango edad]; fct_ruta_mujer[Tiene Inscripción]; fct_ruta_mujer[Tiene Orientación]; fct_ruta_mujer[Tiene Atención Psicosocial]; fct_ruta_mujer[Tiene formación]; fct_ruta_mujer[Tiene Intermediación]; fct_ruta_mujer[Tiene Colocación]; fct_ruta_mujer[Tiene postvinculación]; fct_ruta_mujer[Fecha Inscripción]; fct_ruta_mujer[Fecha Orientación]; fct_ruta_mujer[Fecha Atención Psicosocial]; fct_ruta_mujer[Fecha Intermediación]; fct_ruta_mujer[Fecha Colocación]; fct_ruta_mujer[Número de Intermediaciones]; fct_ruta_mujer[corte] |
| dbbf14d9853e3860b91d | slicer | fct_ruta_mujer[Fecha Inscripción] |
| e348e4ea4475dd07354b | slicer | fct_ruta_mujer[Documento] |

## Detalle Registros

| ID | Visual | Campos/medidas |
|---|---|---|
| 1466144025e04d933098 | slicer | fct_ruta_mujer[Tipo de Documento] |
| 1816501cd817e2764877 | slicer | fct_ruta_mujer[corte] |
| 663aad0ea7432213a23b | slicer | fct_ruta_mujer[Departamento de Nacimiento] |
| 6cbdf9962a5600a02468 | slicer | fct_ruta_mujer[Documento] |
| 820c7aff6ae000b92051 | image |  |
| ab7ff7c28c51bdd4a0a8 | slicer | fct_ruta_mujer[Fecha Inscripción] |
| ac1dd1690a5741590ed2 | cardVisual | Calculos[Personas Registradas] |
| c9188fe6d5de73ee2e9a | tableEx | fct_ruta_mujer[Fecha Inscripción]; fct_ruta_mujer[Profesional de Registro]; fct_ruta_mujer[Documento]; fct_ruta_mujer[Primer Nombre]; fct_ruta_mujer[Segundo Nombre]; fct_ruta_mujer[Primer Apellido]; fct_ruta_mujer[Segundo Apellido]; fct_ruta_mujer[Celular]; fct_ruta_mujer[Fecha de Nacimiento]; fct_ruta_mujer[Edad]; fct_ruta_mujer[Nivel educativo]; fct_ruta_mujer[Nacionalidad]; fct_ruta_mujer[Municipio de Residencia]; fct_ruta_mujer[Departamento de Nacimiento]; fct_ruta_mujer[Nivel Sisbén]; fct_ruta_mujer[Responsabilidades de Cuidado]; fct_ruta_mujer[Modalidad de Atención]; fct_ruta_mujer[Interés Laboral]; fct_ruta_mujer[Área de Experiencia]; fct_ruta_mujer[Tiempo de Experiencia Laboral]; fct_ruta_mujer[Tiene Inscripción]; fct_ruta_mujer[Tiene Orientación]; fct_ruta_mujer[Concepto de Orientación]; fct_ruta_mujer[Perfil Ocupacional]; fct_ruta_mujer[Tiene Atención Psicosocial]; fct_ruta_mujer[Evolución Psicosocial]; fct_ruta_mujer[Fecha Intermediación]; fct_ruta_mujer[NIT Empresa Intermediación]; fct_ruta_mujer[Empresa Intermediación]; fct_ruta_mujer[Última Vacante]; fct_ruta_mujer[Concepto intermediación]; fct_ruta_mujer[Intermediador]; fct_ruta_mujer[Tiene Intermediación]; fct_ruta_mujer[Estado Última Intermediación]; fct_ruta_mujer[Sede] |

## Registros

| ID | Visual | Campos/medidas |
|---|---|---|
| 28e06e31560efd656c10 | slicer | fct_ruta_mujer[Sede] |
| 2f417f4508120ca13c07 | image |  |
| 45ec7040e576b3120508 | slicer | fct_ruta_mujer[corte] |
| 536043f209e04242c691 | cardVisual | Calculos[Personas Registradas] |
| 63a74c0fd1cce356b3ed | cardVisual | Calculos[Personas con Atención Psicosocial] |
| 8d122a49d0a9d7e004a4 | cardVisual | Calculos[Inscripciones Completadas] |
| 905582a90a1d846bee06 | cardVisual | Calculos[Personas Intermediadas] |
| 96954d91299df70bb7cd | lineChart | fct_ruta_mujer[Fecha Inscripción]; fct_ruta_mujer[Documento] |
| a44358399efdcf110036 | donutChart | fct_ruta_mujer[Modalidad de Atención]; fct_ruta_mujer[Documento] |
| c96938e0c915197fd95f | donutChart | fct_ruta_mujer[Tipificación Mujer]; fct_ruta_mujer[Documento] |
| f56f7684ab9434d20589 | cardVisual | Calculos[Personas Orientadas] |
| 3278e9cecdba7eb73c68 | clusteredColumnChart | fct_ruta_mujer[Sede]; Calculos[Personas Registradas] |
| 86c2456d39b9e88ea507 | clusteredColumnChart | fct_ruta_mujer[Grupos poblacionales]; Calculos[Personas Registradas] |

## Gestión Orientación

| ID | Visual | Campos/medidas |
|---|---|---|
| 071502715ca4493e02e8 | cardVisual | Calculos[Personas Intermediadas] |
| 3648d8470e96a6a26848 | slicer | fct_ruta_mujer[Fecha Orientación] |
| 8a4221be4c00a92d8e11 | cardVisual | Calculos[Personas con Atención Psicosocial] |
| 91e6feb9e003c6e748c1 | pieChart | fct_ruta_mujer[Tiene Orientación]; Calculos[Personas Registradas] |
| 96addd67eb09109850ce | slicer | fct_ruta_mujer[corte] |
| 9ed04a4f40ed060e999e | cardVisual | Calculos[Personas Orientadas] |
| af529d56000db0ab746b | image |  |
| cd08fa03d0c37d091808 | lineChart | fct_ruta_mujer[Fecha Orientación]; Calculos[Personas Orientadas] |
| d04ea5ef55c4391512b0 | cardVisual | Calculos[Personas Registradas] |
| ecbb28b6c077609bc11b | donutChart | fct_ruta_mujer[Modalidad de Orientación]; Calculos[Personas Orientadas] |
| ed36e6963986b674ded5 | slicer | fct_ruta_mujer[Orientadora] |
| f974e50c260d4a066dc6 | clusteredBarChart | fct_ruta_mujer[Perfil Ocupacional]; Calculos[Personas Orientadas] |
| fb837421c15600d81b9c | cardVisual | Calculos[Inscripciones Completadas] |
| ffaf5c9db527a1d71707 | clusteredColumnChart | fct_ruta_mujer[Orientadora]; Calculos[Personas Orientadas] |

## Detalle Orientaciones

| ID | Visual | Campos/medidas |
|---|---|---|
| 17066130755d5c68e735 | slicer | fct_ruta_mujer[corte] |
| 44719ce1c2d20c128bc4 | cardVisual | Calculos[Personas Orientadas] |
| 46618d3221d30a6dd448 | image |  |
| 5c1566d71798a18604a9 | slicer | fct_ruta_mujer[Documento] |
| 9560c27f3c94b3039269 | tableEx | fct_ruta_mujer[Fecha Orientación]; fct_ruta_mujer[Orientadora]; fct_ruta_mujer[Documento]; fct_ruta_mujer[Primer Nombre]; fct_ruta_mujer[Segundo Nombre]; fct_ruta_mujer[Primer Apellido]; fct_ruta_mujer[Segundo Apellido]; fct_ruta_mujer[Celular]; fct_ruta_mujer[Fecha de Nacimiento]; fct_ruta_mujer[Perfil Ocupacional]; fct_ruta_mujer[Interés Laboral]; fct_ruta_mujer[Ocupación Actual]; fct_ruta_mujer[Área de Experiencia]; fct_ruta_mujer[Tiempo de Experiencia Laboral]; fct_ruta_mujer[Nivel educativo] |
| dba52898e27d30e1c210 | slicer | fct_ruta_mujer[Fecha Orientación] |
| ec785fe046ebec61a4a9 | slicer | fct_ruta_mujer[Departamento de Nacimiento] |
| f2cadd1e890015d469b3 | slicer | fct_ruta_mujer[Tipo de Documento] |

## Listado Habilitantes

| ID | Visual | Campos/medidas |
|---|---|---|
| 06b3054b8fe0d4acdbcb | slicer | fct_ruta_mujer[Tiene Orientación] |
| 14034a8f0268b6010627 | slicer | fct_ruta_mujer[corte] |
| 1a61f1cb89fe218fb64c | slicer | fct_ruta_mujer[Documento] |
| 2798684c622c6866a835 | slicer | fct_ruta_mujer[Tipo de Documento] |
| 52dd6df67ecdb13ffef2 | tableEx | fct_ruta_mujer[Fecha Inscripción]; fct_ruta_mujer[Tipo de Documento]; fct_ruta_mujer[Documento]; fct_ruta_mujer[Correo Electrónico]; fct_ruta_mujer[Primer Nombre]; fct_ruta_mujer[Segundo Nombre]; fct_ruta_mujer[Primer Apellido]; fct_ruta_mujer[Segundo Apellido]; fct_ruta_mujer[Celular]; fct_ruta_mujer[Fecha de Nacimiento]; fct_ruta_mujer[Departamento de Nacimiento]; fct_ruta_mujer[Municipio de Nacimiento]; fct_ruta_mujer[Dirección de Residencia]; fct_ruta_mujer[Municipio de Residencia]; fct_ruta_mujer[Estrato]; fct_ruta_mujer[Naturaleza del Estrato]; fct_ruta_mujer[Tipo de Población]; fct_ruta_mujer[Modalidad de Atención]; fct_ruta_mujer[Sexo al Nacer]; fct_ruta_mujer[Pregunta de Seguridad]; fct_ruta_mujer[Respuesta Pregunta de Seguridad]; fct_ruta_mujer[Barrera 1]; fct_ruta_mujer[Barrera 2]; fct_ruta_mujer[Barrera 3]; fct_ruta_mujer[corte]; fct_ruta_mujer[Validación habilitante] |
| 64af034d1b9c9bc0d488 | image |  |
| e5a52c20661c540d6257 | slicer | fct_ruta_mujer[Fecha Inscripción] |
| ef4d22ed0c50bf9c23fb | cardVisual | Calculos[Personas Registradas] |

## Base Sae

| ID | Visual | Campos/medidas |
|---|---|---|
| 19eca9cfd2f26952293a | image |  |
| 2b73b26a6a5108d40942 | slicer | fct_ruta_mujer[Documento] |
| 73b77d383db1264a0256 | tableEx | fct_ruta_mujer[Fecha Inscripción]; fct_ruta_mujer[Tipo de Documento]; fct_ruta_mujer[Documento]; fct_ruta_mujer[Correo Electrónico]; fct_ruta_mujer[Primer Nombre]; fct_ruta_mujer[Segundo Nombre]; fct_ruta_mujer[Primer Apellido]; fct_ruta_mujer[Segundo Apellido]; fct_ruta_mujer[Celular]; fct_ruta_mujer[Fecha de Nacimiento]; fct_ruta_mujer[Municipio de Residencia]; fct_ruta_mujer[Nacionalidad]; fct_ruta_mujer[Departamento de Nacimiento]; fct_ruta_mujer[Municipio de Nacimiento]; fct_ruta_mujer[Dirección de Residencia]; fct_ruta_mujer[Estrato]; fct_ruta_mujer[Naturaleza del Estrato]; fct_ruta_mujer[Tipo de Población]; fct_ruta_mujer[Modalidad de Atención]; fct_ruta_mujer[Sexo al Nacer]; fct_ruta_mujer[Pregunta de Seguridad]; fct_ruta_mujer[Respuesta Pregunta de Seguridad]; fct_ruta_mujer[Sede]; fct_ruta_mujer[Barrera 1]; fct_ruta_mujer[Barrera 2]; fct_ruta_mujer[Barrera 3] |
| 97edb56224e9a298d04d | slicer | fct_ruta_mujer[Tipo de Documento] |
| 9a52238351171ff25e16 | slicer | fct_ruta_mujer[Departamento de Nacimiento] |
| a58db5e94b242ef58310 | slicer | fct_ruta_mujer[Fecha Inscripción] |
| b8bac54e2684c4b690d0 | cardVisual | Calculos[Personas Registradas] |
| d93c8cff6b685d900985 | slicer | fct_ruta_mujer[corte] |

## Gestión Vacantes

| ID | Visual | Campos/medidas |
|---|---|---|
| 0710c081d517b40e7d40 | slicer | fct_ruta_mujer[corte] |
| 5794af0c2cc7051d8981 | cardVisual | Calculos[Total Empresas] |
| 5d789b43be4b5cc73b86 | slicer | dim_vacantes_rm[empresa] |
| 62a9545398025eec6ce6 | clusteredBarChart | dim_vacantes_rm[nombre_vacante]; Calculos[Total Puestos] |
| 6a9501b3ab8208403aed | slicer | dim_vacantes_rm[sector_economico_empresa] |
| 9fbc61369e0e63b5c213 | cardVisual | Calculos[Puestos Solicitados] |
| acbf2c72a8704a8059ca | donutChart | dim_vacantes_rm[tamano_empresa]; Calculos[Total Empresas] |
| b411c73cc6acb81cee9b | slicer | dim_vacantes_rm[estado_de_la_vacante] |
| c701c3ac4970d1dca572 | image |  |
| dc57fb0bda7b722821cd | clusteredColumnChart | dim_vacantes_rm[empresa]; Calculos[Total Puestos] |
| eb8cb4b1b208bbbb1061 | clusteredBarChart | dim_vacantes_rm[sector_economico_empresa]; Calculos[Vacantes Vigentes] |
| eda6cdc5148ab949a732 | cardVisual | Calculos[Vacantes Vigentes] |
| f4a045a83b905086a206 | cardVisual | Calculos[Total Sectores] |
| f97c941b111a2eb1ba67 | tableEx | dim_vacantes_rm[codigo_vacante]; dim_vacantes_rm[nombre_vacante]; dim_vacantes_rm[empresa]; dim_vacantes_rm[nombre_de_contacto]; dim_vacantes_rm[email_de_contacto]; dim_vacantes_rm[municipio]; dim_vacantes_rm[fecha_final_de_la_vacante]; dim_vacantes_rm[perfil_de_la_vacante]; dim_vacantes_rm[vacante_con_enfoque_de_genero]; dim_vacantes_rm[vacante_de_desmasculinizacion] |

## Análisis Vacantes

| ID | Visual | Campos/medidas |
|---|---|---|
| 0c22738fbb6c8ed3607b | slicer | dim_vacantes_rm[sector_economico_empresa] |
| 1567d48f49895507219c | slicer | dim_vacantes_rm[estado_de_la_vacante] |
| 17d0d00ea405c04301ce | cardVisual | Calculos[Puestos Solicitados] |
| 25e7c9e900a43501a11e | slicer | dim_vacantes_rm[empresa] |
| 48472aa48bb012ebaae4 | clusteredBarChart | dim_vacantes_rm[nombre_vacante]; dim_vacantes_rm[tiempo_de_experiencia_requerido_meses] |
| 703ad261b9ca82e8403a | cardVisual | Calculos[Total Empresas] |
| 73a07e218e612b803202 | tableEx | dim_vacantes_rm[codigo_vacante]; dim_vacantes_rm[nombre_vacante]; dim_vacantes_rm[empresa]; dim_vacantes_rm[nombre_de_contacto]; dim_vacantes_rm[email_de_contacto]; dim_vacantes_rm[municipio]; dim_vacantes_rm[fecha_final_de_la_vacante]; dim_vacantes_rm[perfil_de_la_vacante] |
| 8ac5c2ee732928c88a30 | image |  |
| 8c0d08de02856b2b4c96 | cardVisual | Calculos[Vacantes Vigentes] |
| a5c4500b7bac0e5de0e2 | cardVisual | Calculos[Total Sectores] |
| cf8c1144ae2a79e01192 | slicer | fct_ruta_mujer[corte] |
| d07ed8bbd0288755a735 | clusteredColumnChart | dim_vacantes_rm[rango_etario_vacante]; Calculos[Vacantes Vigentes] |
| e90542ee92430034ac07 | donutChart | dim_vacantes_rm[vacante_con_enfoque_de_genero]; Calculos[Vacantes Vigentes] |
| f076ede850b5c5166a7d | donutChart | dim_vacantes_rm[tipo_de_contrato]; Calculos[Vacantes Vigentes] |
| f231a37c36bc1ddb02ac | clusteredColumnChart | dim_vacantes_rm[ciudad_municipio_de_la_vacante]; Calculos[Vacantes Vigentes] |
| 3b283add9e5a19d3e1ca | donutChart | dim_vacantes_rm[vacante_de_desmasculinizacion]; Calculos[Vacantes Vigentes] |

## Detalle Vacantes

| ID | Visual | Campos/medidas |
|---|---|---|
| 18ca4d4988453f28c120 | slicer | fct_ruta_mujer[Documento] |
| 4bdf7b151b990c89d186 | tableEx | dim_vacantes_rm[codigo_vacante]; dim_vacantes_rm[departamento]; dim_vacantes_rm[municipio]; dim_vacantes_rm[email_de_contacto]; dim_vacantes_rm[empresa]; dim_vacantes_rm[nombre_de_contacto]; dim_vacantes_rm[vacante_de_desmasculinizacion]; dim_vacantes_rm[vacante_con_enfoque_de_genero]; dim_vacantes_rm[ocupaci_n_cuoc_2]; dim_vacantes_rm[ocupaci_n_cuoc_3]; dim_vacantes_rm[fecha_final_de_la_vacante]; dim_vacantes_rm[fecha_compromiso]; dim_vacantes_rm[fecha_estimada_de_contrataci_n]; dim_vacantes_rm[nombre_vacante]; dim_vacantes_rm[rango_salarial]; dim_vacantes_rm[tipo_de_contrato]; dim_vacantes_rm[jornada_laboral]; dim_vacantes_rm[tiene_personas_a_cargo]; dim_vacantes_rm[requiere_capacitaci_n_espec_fica]; dim_vacantes_rm[descripci_n_de_la_capacitaci_n_espec_fica]; dim_vacantes_rm[requiere_disponibilidad_para_viajar]; dim_vacantes_rm[funciones_del_cargo]; dim_vacantes_rm[tiempo_de_experiencia_requerido_meses]; dim_vacantes_rm[rea_de_experiencia_laboral]; dim_vacantes_rm[requiere_qu_cuente_con_veh_culo]; dim_vacantes_rm[requiere_licencia_para_conducir_carro]; dim_vacantes_rm[requiere_licencia_para_conducir_moto]; dim_vacantes_rm[sector_economico_empresa]; dim_vacantes_rm[tipo_de_discapacidad]; dim_vacantes_rm[edad_m_nima]; dim_vacantes_rm[edad_m_xima]; dim_vacantes_rm[requiere_vivir_en_barrio_zona_espec_fica]; dim_vacantes_rm[puede_estar_estudiando]; dim_vacantes_rm[requiere_manejar_alg_n_idioma]; dim_vacantes_rm[acepta_v_ctima_del_conflicto_armado]; dim_vacantes_rm[acepta_personas_en_condici_n_de_discapacidad]; dim_vacantes_rm[certificado_de_discapacidad]; dim_vacantes_rm[posibilidad_de_trabajo_h_brido_remoto]; dim_vacantes_rm[perfil_de_la_vacante]; dim_vacantes_rm[n_mero_de_puestos_de_trabajo]; dim_vacantes_rm[corte] |
| 560cc85baeb301862081 | slicer | dim_vacantes_rm[sector_economico_empresa] |
| 56e7fb65a956160ebbcc | slicer | fct_ruta_mujer[corte] |
| 6436bd500a0c1dee7acc | cardVisual | Calculos[Vacantes Vigentes] |
| 7a576e51b2b7303504cc | image |  |
| 949fc6cc9f39e7597f55 | slicer | fct_ruta_mujer[Departamento de Nacimiento] |
| 9c38e6e4e5f646c88aed | slicer | fct_ruta_mujer[Tipo de Documento] |

## N Gestión Formación

| ID | Visual | Campos/medidas |
|---|---|---|
| 06ea850f3a1592ac9041 | donutChart | dim_vacantes_rm[tamano_empresa]; Calculos[Total Empresas] |
| 07578250569fdb2edfc0 | clusteredColumnChart | dim_vacantes_rm[empresa]; Calculos[Total Puestos] |
| 2ee6b7ad661bc8ac8319 | clusteredBarChart | dim_vacantes_rm[nombre_vacante]; dim_vacantes_rm[tiempo_de_experiencia_requerido_meses] |
| 3d2ce50d60bfb7715dc7 | clusteredBarChart | dim_vacantes_rm[sector_economico_empresa]; Calculos[Recuento Vacantes] |
| 5f10d7bba0e02b10b384 | cardVisual | Calculos[Total Empresas] |
| 71216a3a14959d979cd4 | slicer | dim_vacantes_rm[sector_economico_empresa] |
| 81b38bf7c3ea91e741a7 | slicer | dim_vacantes_rm[empresa] |
| 87de63ad20a0b1353608 | slicer | dim_vacantes_rm[estado_de_la_vacante] |
| b8632b88bbe36da3e485 | cardVisual | Calculos[Vacantes Vigentes] |
| d769343b0d8059477398 | cardVisual | Calculos[Puestos Solicitados] |
| d8e19baf8aacfcb268f5 | donutChart | dim_vacantes_rm[tipo_de_contrato]; Calculos[Recuento Vacantes] |
| de02a9f7d9f9f7ca84b7 | cardVisual | Calculos[Total Sectores] |
| df6939502c1b044d903e | slicer | fct_ruta_mujer[corte] |
| eed1d3c7aeca4c318637 | clusteredBarChart | dim_vacantes_rm[nombre_vacante]; Calculos[Total Puestos] |

## N Asistencia Formación

| ID | Visual | Campos/medidas |
|---|---|---|
| 0761ed39ee9de7bcb654 | slicer | fct_ruta_mujer[Documento] |
| 16706cab69a27dc5eed2 | slicer | fct_ruta_mujer[Departamento de Nacimiento] |
| 4dc96ab719a41d290b64 | image |  |
| 944bdef249b0ed030c05 | cardVisual | Calculos[Personas Registradas] |
| cd497e90eb03bcb0720c | slicer | fct_ruta_mujer[Fecha Inscripción] |
| ded82bfb2e0385912e3a | slicer | fct_ruta_mujer[Tipo de Documento] |
| eb4f8604c71c2be7374d | tableEx | fct_ruta_mujer[Fecha Inscripción]; fct_ruta_mujer[Tipo de Documento]; fct_ruta_mujer[Documento]; fct_ruta_mujer[Correo Electrónico]; fct_ruta_mujer[Primer Nombre]; fct_ruta_mujer[Segundo Nombre]; fct_ruta_mujer[Primer Apellido]; fct_ruta_mujer[Segundo Apellido]; fct_ruta_mujer[Celular]; fct_ruta_mujer[Fecha de Nacimiento]; fct_ruta_mujer[Municipio de Residencia]; fct_ruta_mujer[Localidad] |

## Gestión Intermediación

| ID | Visual | Campos/medidas |
|---|---|---|
| 1ae1598152c86a116b73 | lineChart | fct_ruta_mujer[Fecha Intermediación]; Calculos[Personas Intermediadas] |
| 246ee15e04bdab803a71 | cardVisual | Calculos[Inscripciones Completadas] |
| 37b4c6d5400c01ec44c1 | clusteredBarChart | fct_intermediacion_rm[empresa]; Calculos[Número Intermediaciones] |
| 45c413f659aab40de74e | cardVisual | Calculos[Promedio Intermediaciones por Mujer] |
| 56a63f57a22e550cb5ea | clusteredBarChart | fct_intermediacion_rm[perfil_ocupacional]; Calculos[Número Intermediaciones] |
| 59e8f5713b037474b0d7 | slicer | fct_ruta_mujer[Fecha Intermediación] |
| 6f90e8ee8d55d4c2cca0 | image |  |
| 83438805d30b2896b274 | donutChart | dim_vacantes_rm[sector_economico_empresa]; Calculos[Número Intermediaciones] |
| a7f92e9e527ecd6ca400 | slicer | dim_vacantes_rm[sector_economico_empresa] |
| af0a339f83b00ec812d2 | cardVisual | Calculos[Número Intermediaciones] |
| c19669de0090a1161a5a | slicer | fct_intermediacion_rm[estado] |
| d9326162b9b48c550b4e | cardVisual | Calculos[Personas Intermediadas] |
| e096865273b4e93e0049 | slicer | fct_intermediacion_rm[intermediador] |
| e9f233c1060874bd9330 | slicer | fct_intermediacion_rm[corte] |
| f9177d7f94036902848a | cardVisual | Calculos[Empresas Intermediadas] |
| feff43b478d68029450c | clusteredColumnChart | fct_intermediacion_rm[vacante]; Calculos[Número Intermediaciones] |

## Detalle Intermediaciones

| ID | Visual | Campos/medidas |
|---|---|---|
| 1446530200275530e17a | slicer | fct_ruta_mujer[Departamento de Nacimiento] |
| 237243c6d9b88b0a05c9 | slicer | fct_ruta_mujer[Tipo de Documento] |
| 36abd5e323350cdc837b | slicer | fct_ruta_mujer[Fecha Intermediación] |
| 37a022338199208a0d32 | slicer | fct_ruta_mujer[Documento] |
| 624eda782ab5975eee25 | image |  |
| 9e8d9e80a6422c02e113 | slicer | fct_ruta_mujer[corte_intermediacion] |
| c59605cf3e307ac1acbd | tableEx | fct_intermediacion_rm[Fecha intermediación]; fct_intermediacion_rm[documento]; fct_intermediacion_rm[primer_nombre]; fct_intermediacion_rm[segundo_nombre]; fct_intermediacion_rm[primer_apellido]; fct_intermediacion_rm[segundo_apellido]; fct_intermediacion_rm[Código vacante]; fct_intermediacion_rm[vacante]; fct_intermediacion_rm[nit_de_la_empresa]; fct_intermediacion_rm[empresa]; fct_intermediacion_rm[estado]; fct_intermediacion_rm[concepto_de_intermediaci_n]; fct_intermediacion_rm[novedad_intermediaci_n]; fct_intermediacion_rm[intermediador]; fct_intermediacion_rm[perfil_ocupacional]; fct_intermediacion_rm[corte] |
| d4589dbe95900c5670ca | cardVisual | Calculos[Personas Intermediadas] |
| 7a8d1bda035472000c30 | cardVisual | Calculos[Número Intermediaciones] |

## Agendamiento Empresarial

| ID | Visual | Campos/medidas |
|---|---|---|
| 08a91de75597182ad3e1 | slicer | fct_intermediacion_rm[corte] |
| 0e81041ac4197d16e7ce | donutChart | fct_agenda_comercial_rm[Estado]; Calculos[Citas Empresariales] |
| 1362db202379337ae950 | image |  |
| 172d0467069a4d8a3b91 | tableEx | fct_agenda_comercial_rm[Empresa]; fct_agenda_comercial_rm[Estado]; fct_agenda_comercial_rm[Observaciones del agendamiento] |
| 2b4346716c36b49e6c2e | cardVisual | Calculos[Citas Empresariales] |
| 2b507b8a3e85d524873e | tableEx | fct_agenda_comercial_rm[Empresa]; fct_agenda_comercial_rm[Fecha de Agenda]; fct_agenda_comercial_rm[Hora cita]; fct_agenda_comercial_rm[Estado]; fct_agenda_comercial_rm[Modalidad]; fct_agenda_comercial_rm[Municipio]; fct_agenda_comercial_rm[Dirección del lugar]; fct_agenda_comercial_rm[Enlace]; fct_agenda_comercial_rm[Asunto]; fct_agenda_comercial_rm[Persona de contacto]; fct_agenda_comercial_rm[Observaciones del agendamiento] |
| 344ca7f191d6e264485e | cardVisual | Calculos[Dias Agendados] |
| 36b706942b30021ca015 | cardVisual | Calculos[Citas Virtuales] |
| 6278c6e066e1887e05a6 | cardVisual | Calculos[Citas Presenciales] |
| 66e3811de700591222cd | slicer | fct_agenda_comercial_rm[Fecha de Agenda] |
| 7952805a7d1d51393349 | slicer | fct_agenda_comercial_rm[Empresa] |
| 9400219f17bb60dec807 | cardVisual | Calculos[Reuniones Unicas] |
| af9ce2fc6d562159ead4 | tableEx | fct_agenda_comercial_rm[Fecha de Agenda]; fct_agenda_comercial_rm[Empresa]; fct_agenda_comercial_rm[Estado] |
| cb655fbc1e59b67d8c95 | slicer | fct_agenda_comercial_rm[Estado] |

## Agendamiento Orientación

| ID | Visual | Campos/medidas |
|---|---|---|
| 0f0d8ba701bdcd5e0cae | slicer | fct_agenda_orientacion_rm[estado] |
| 1bbd7c1753dde0460bb3 | cardVisual | Calculos[Dias Agendados Orientacion] |
| 263da3f7aa16cb61668d | slicer | fct_intermediacion_rm[corte] |
| 286d5a23d8e73829098e | slicer | fct_agenda_orientacion_rm[fecha_cita] |
| 4ca54d7310b00c141167 | cardVisual | Calculos[Personas Agendadas] |
| 4fd8c57a0d8c282424b2 | cardVisual | Calculos[Citas Individuales] |
| 72a7985f718e7c776c20 | cardVisual | Calculos[Dias Agendados] |
| 7b9cf31e0570b01b1cc6 | tableEx | fct_agenda_orientacion_rm[documento]; fct_agenda_orientacion_rm[nombre_completo]; fct_agenda_orientacion_rm[celular]; fct_agenda_orientacion_rm[correo]; fct_agenda_orientacion_rm[fecha_cita]; fct_agenda_orientacion_rm[hora_cita]; fct_agenda_orientacion_rm[dia_semana]; fct_agenda_orientacion_rm[asunto]; fct_agenda_orientacion_rm[enlace] |
| b0dc6096b070a670494b | cardVisual | Calculos[Citas Presenciales] |
| c931d50667002e1d00b0 | donutChart | fct_agenda_orientacion_rm[estado]; Calculos[Citas Individuales] |
| ca971d181d7b102655b9 | image |  |
| ec71b4e8cd252952c280 | slicer | fct_agenda_comercial_rm[Responsable] |

## Análisis Metas

| ID | Visual | Campos/medidas |
|---|---|---|
| 1cd664950de9a6d4c055 | card | Calculos[Mujeres registradas] |
| 4c0ad010b9ac6403e309 | cardVisual | Calculos[Mujeres Orientadas] |
| 62452f8d0369e4da8373 | cardVisual | Calculos[Mujeres con Acompañamiento individual] |
| 767ef31079755c3d03da | cardVisual | Calculos[Número Intermediaciones] |
| 963da86c8a05677772a9 | Tachometer1474636471549 | Calculos[% Cumplimiento Colocados] |
| a0181f43ec1391b18785 | card | Calculos[Número Intermediaciones] |
| a5172781eaa87a7c2820 | card | Calculos[Meta Registros rm] |
| c30f5650cb207d91a132 | cardVisual | Calculos[Mujeres registradas] |
| c634b5408800652cb0a1 | cardVisual | Calculos[Mujeres colocadas] |
| c8dbe22c514073cd6727 | card | Calculos[Meta intermediación rm] |
| cd127a300161682d798d | Tachometer1474636471549 | Calculos[% Cumplimiento Registro] |
| cf1d9014b94778491134 | card | Calculos[Mujeres colocadas] |
| d60d747a2318e4e95840 | card | Calculos[Meta Colocados rm] |
| d8fe4ab223a78c8410b7 | image |  |
| dabb36051217101a5455 | Tachometer1474636471549 | Calculos[% Cumplimiento intermediación] |
| 83ef3e87d2eb3be6dc92 | card | Calculos[Mujeres Orientadas] |
| 9027efb7d42da394ae61 | Tachometer1474636471549 | Calculos[% Cumplimiento postvinculación] |
| 7a2028c8a0800c13ec34 | card | Calculos[Mujeres con Acompañamiento individual] |
| f18c6c89d48c17532c08 | card | Calculos[Meta Orientación rm] |
| 5bddd816020921124d63 | card | Calculos[Meta Psicosocial rm] |
| 776d855ea830dad6c0d8 | Tachometer1474636471549 | Calculos[% Cumplimiento Orientación] |
| 220b0fba288592780080 | card | Calculos[Mujeres posvinculadas] |
| 6b3dfb90362b0db5e7e3 | card | Calculos[Meta postvinculadas rm] |
| 3f2da1a0016c14594cab | Tachometer1474636471549 | Calculos[% Cumplimiento psicosocial] |

## Gestión Empresarial

| ID | Visual | Campos/medidas |
|---|---|---|
| 0a2d51680b90de4537c1 | slicer | fct_intermediacion_rm[corte] |
| 19a9663b51b851b878d6 | cardVisual | Calculos[Dias Agendados] |
| 33a1c52bc8e46dd1d5d0 | cardVisual | Calculos[Citas Virtuales] |
| 3b91bc5c3aad65191205 | slicer | fct_agenda_comercial_rm[Estado] |
| 5905d3100b6d6244070b | cardVisual | Calculos[Citas Empresariales] |
| 63aa7bdebd73064c629a | cardVisual | Calculos[Citas Presenciales] |
| 643fb8c1bea3c0e52109 | slicer | fct_agenda_comercial_rm[Fecha de Agenda] |
| 691a3a5042c77a33bc60 | clusteredColumnChart | fct_agenda_comercial_rm[Tipo de actividad]; Calculos[Citas Empresariales] |
| 7435e3b82219de92268e | donutChart | fct_agenda_comercial_rm[Estado]; Calculos[Citas Empresariales] |
| 976b56f0a1d88e79b139 | tableEx | fct_intermediacion_rm[empresa]; fct_intermediacion_rm[vacante]; fct_intermediacion_rm[Fecha intermediación]; fct_intermediacion_rm[estado]; dim_empresas_rm[Intermediaciones] |
| 9bfa5cd00405bd5636e5 | slicer | fct_agenda_comercial_rm[Empresa] |
| b7ba1086e6c7521a93c4 | slicer | fct_agenda_comercial_rm[Responsable] |
| cb94d20bc58206c5d0c3 | tableEx | dim_empresas_rm[nit]; dim_empresas_rm[empresa]; dim_empresas_rm[etapa]; dim_empresas_rm[Vacantes]; dim_empresas_rm[Intermediaciones]; dim_empresas_rm[Agendamientos] |
| d85c16bd77882260d1d6 | slicer | fct_agenda_comercial_rm[Sector economico] |
| e30f0b9730b033e60696 | cardVisual | Calculos[Reuniones Unicas] |
| 7c266d872638d097ac08 | image |  |

## Postvinculación

| ID | Visual | Campos/medidas |
|---|---|---|
| 08651a7e9cb5e0a70616 | slicer | fct_intermediacion_rm[Fecha intermediación] |
| 0b0120385ab558e70c27 | clusteredBarChart | fct_postvinculacion_rm[motivo_retiro]; Calculos[Total Posvinculaciones] |
| 419dcdf7cc0146bcb0a0 | clusteredColumnChart | fct_postvinculacion_rm[documento]; fct_postvinculacion_rm[tipo_novedad]; Calculos[Total Posvinculaciones] |
| 43e9656208ca000ec89d | slicer | fct_intermediacion_rm[estado] |
| 494427b3c4c1156b5ce4 | cardVisual | Calculos[Total Posvinculaciones] |
| 5af085e0755d43be6586 | tableEx | fct_postvinculacion_rm[documento]; fct_postvinculacion_rm[empresa]; fct_postvinculacion_rm[fecha_inicio_contrato]; fct_postvinculacion_rm[dias_transcurridos_contrato]; fct_postvinculacion_rm[fecha_llamada_seguimiento]; fct_postvinculacion_rm[estado_caso] |
| 8bc973a70c066a02c2dc | donutChart | fct_postvinculacion_rm[estado_post_calculado]; Calculos[Total Posvinculaciones] |
| 9d87c28360b62b0baec1 | cardVisual | Calculos[Total de Posvinculaciones pendientes] |
| 9dfc63dce53da0cd2bd3 | slicer | dim_vacantes_rm[sector_economico_empresa] |
| a632ee3de60a12ccba09 | cardVisual | Calculos[% Cobertura Posvinculacion] |
| c77db20361a3d5072c0e | slicer | fct_intermediacion_rm[intermediador] |
| d857d4cea4e064777a22 | donutChart | fct_postvinculacion_rm[permanencia_seguimiento]; Calculos[Total Posvinculaciones] |
| ec06787b4ceb3e028272 | image |  |
| f69585dd1046cb203014 | cardVisual | Calculos[Mujeres colocadas] |
| f7a16390c05b26006ab0 | cardVisual | Calculos[Posvinculadas sin gestionar] |
| 922210fc95bcde95695b | tableEx | fct_ruta_mujer[Documento]; fct_ruta_mujer[Primer Nombre]; fct_ruta_mujer[Segundo Nombre]; fct_ruta_mujer[Primer Apellido]; fct_ruta_mujer[Segundo Apellido]; fct_ruta_mujer[Fecha Colocación]; fct_ruta_mujer[Empresa Contratante] |

## Detalle Postvinculaciones

| ID | Visual | Campos/medidas |
|---|---|---|
| 8be02f12c237d6c03e04 | slicer | fct_ruta_mujer[Departamento de Nacimiento] |
| 23ce98bfc9dd04872447 | slicer | fct_ruta_mujer[Tipo de Documento] |
| bab0b59521cc03c44c4e | slicer | fct_ruta_mujer[Fecha Intermediación] |
| 2477fa1a8ab11e080302 | slicer | fct_ruta_mujer[Documento] |
| bb2dd05491a0397d15d4 | image |  |
| 5d7b7d2da66640725b00 | slicer | fct_ruta_mujer[corte] |
| 19e00d4797d3baa00d7a | tableEx | fct_postvinculacion_rm[documento]; fct_postvinculacion_rm[empresa]; fct_postvinculacion_rm[fecha_llamada_seguimiento]; fct_postvinculacion_rm[fecha_inicio_contrato]; fct_postvinculacion_rm[estado_post_calculado]; fct_postvinculacion_rm[dias_transcurridos_contrato] |
| 5b636b8e58ba03d11a4b | cardVisual | Calculos[Total Posvinculaciones] |

## Detalle Preregistro

| ID | Visual | Campos/medidas |
|---|---|---|
| b5dd61870ba5ab08a05e | slicer | fct_ruta_mujer[Departamento de Nacimiento] |
| 9a9d6c83b791d226d60a | slicer | fct_ruta_mujer[Tipo de Documento] |
| 081b2e7cb410e67b7520 | slicer | fct_preregistro_rm[created_time] |
| 04a8ea00957570e7db2e | slicer | fct_ruta_mujer[Documento] |
| 3a7cad80d00240668b50 | image |  |
| 330e470a16943d7c5003 | slicer | fct_ruta_mujer[corte] |
| 9574d97906080051cd57 | tableEx | fct_preregistro_rm[tipo_de_documento]; fct_preregistro_rm[documento]; fct_preregistro_rm[primer_nombre]; fct_preregistro_rm[segundo_nombre]; fct_preregistro_rm[primer_apellido]; fct_preregistro_rm[segundo_apellido]; fct_preregistro_rm[tipo_de_poblaci_n]; fct_preregistro_rm[municipio_de_residencia1]; fct_preregistro_rm[localidad]; fct_preregistro_rm[nivel_educativo_alcanzado]; fct_preregistro_rm[n_mero_de_tel_fono_celular]; fct_preregistro_rm[estado_inscripcion_final]; fct_preregistro_rm[preinscripci_n_completad]; fct_preregistro_rm[ha_tenido_empleo_con_caja_de_compensaci_n]; fct_preregistro_rm[d_nde_te_enteraste_de_esta_vacante] |
| 51003286e94ecd49131c | cardVisual | Calculos[Total Preregistros] |
