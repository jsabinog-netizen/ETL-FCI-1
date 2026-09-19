-- Fuente: Metas_Convenio_RutaMujer_BI (1).docx, entregado por Jorge.
-- Metas de convenio completo: el documento no distribuye cuotas por corte ni sede.
with metas as (
select 'C1_DIAGNOSTICO' as indicador_id, 1 as componente, 'Diagnóstico de madurez empresarial' as indicador, 'empresas' as unidad, 120 as meta, 'objetivo' as tipo_meta, 'Instrumento de diagnóstico empresarial estándar' as fuente_oficial, 'Sin fuente vinculada' as estado_fuente
union all
select 'C1_ASESORIA' as indicador_id, 1 as componente, 'Asesoría individual especializada' as indicador, 'empresas' as unidad, 80 as meta, 'objetivo' as tipo_meta, 'Ficha técnica de acciones priorizadas' as fuente_oficial, 'Sin fuente vinculada' as estado_fuente
union all
select 'C1_VACANTES_GENERO' as indicador_id, 1 as componente, 'Vacantes con enfoque de género ajustadas' as indicador, 'vacantes' as unidad, 250 as meta, 'objetivo' as tipo_meta, 'Formato de vacante cargado en SAE' as fuente_oficial, 'Proxy CRM; confirmar ajuste y carga SAE' as estado_fuente
union all
select 'C2_REGISTRO' as indicador_id, 2 as componente, 'Registro' as indicador, 'mujeres' as unidad, 1000 as meta, 'objetivo' as tipo_meta, 'Protocolo de registro SAE' as fuente_oficial, 'Proxy CRM; conciliar con SAE' as estado_fuente
union all
select 'C2_ORIENTACION' as indicador_id, 2 as componente, 'Orientación laboral' as indicador, 'mujeres' as unidad, 1000 as meta, 'objetivo' as tipo_meta, 'Formulario de plan de orientación SAE' as fuente_oficial, 'Proxy CRM; conciliar con SAE' as estado_fuente
union all
select 'C2_INTERMEDIACION' as indicador_id, 2 as componente, 'Intermediación laboral' as indicador, 'remisiones' as unidad, 1000 as meta, 'objetivo' as tipo_meta, 'Protocolo de intermediación SAE' as fuente_oficial, 'Proxy CRM; conciliar con SAE' as estado_fuente
union all
select 'C2_COLOCACION' as indicador_id, 2 as componente, 'Colocación' as indicador, 'mujeres' as unidad, 240 as meta, 'objetivo' as tipo_meta, 'Colocación cargada en SAE' as fuente_oficial, 'Proxy CRM; conciliar con SAE' as estado_fuente
union all
select 'C2_MASCULINIZADOS' as indicador_id, 2 as componente, 'Colocaciones en sectores masculinizados' as indicador, 'proporcion' as unidad, 0.25 as meta, 'objetivo' as tipo_meta, 'Colocaciones confirmadas y soportes de mitigación' as fuente_oficial, 'Sin catálogo completo ni soportes validados' as estado_fuente
union all
select 'C2_PSICO_INDIVIDUAL' as indicador_id, 2 as componente, 'Acompañamiento psicosocial individual' as indicador, 'sesiones_minimo_60_minutos' as unidad, 600 as meta, 'objetivo' as tipo_meta, 'Informe de barreras individuales por mujer' as fuente_oficial, 'Sin eventos de sesión y duración validados' as estado_fuente
union all
select 'C2_PSICO_GRUPAL' as indicador_id, 2 as componente, 'Acompañamiento psicosocial grupal' as indicador, 'talleres_webinars' as unidad, 30 as meta, 'objetivo' as tipo_meta, 'Registro de espacios grupales de salud emocional' as fuente_oficial, 'Sin fuente vinculada' as estado_fuente
union all
select 'C2_CAPSULAS' as indicador_id, 2 as componente, 'Cápsulas motivacionales' as indicador, 'capsulas' as unidad, 16 as meta, 'objetivo' as tipo_meta, 'Envíos por WhatsApp y redes sociales' as fuente_oficial, 'Sin fuente vinculada' as estado_fuente
union all
select 'C3_DIAGNOSTICOS' as indicador_id, 3 as componente, 'Diagnósticos generales con enfoque de género' as indicador, 'diagnosticos' as unidad, 4 as meta, 'objetivo' as tipo_meta, 'Informe con benchmarking por servicio' as fuente_oficial, 'Sin fuente vinculada' as estado_fuente
union all
select 'C3_HOJAS_RUTA' as indicador_id, 3 as componente, 'Hojas de ruta validadas por Alta Gerencia' as indicador, 'documentos' as unidad, 4 as meta, 'objetivo' as tipo_meta, 'Documento con plan de acción por servicio' as fuente_oficial, 'Sin fuente vinculada' as estado_fuente
union all
select 'C3_ACCIONES' as indicador_id, 3 as componente, 'Acciones priorizadas implementadas' as indicador, 'acciones' as unidad, 4 as meta, 'minimo' as tipo_meta, 'Informe de acciones por servicio' as fuente_oficial, 'Sin fuente vinculada' as estado_fuente
union all
select 'C4_GUIA' as indicador_id, 4 as componente, 'Guía de mensajes clave' as indicador, 'documentos' as unidad, 1 as meta, 'objetivo' as tipo_meta, 'Documento de mensajería unificada' as fuente_oficial, 'Sin fuente vinculada' as estado_fuente
union all
select 'C4_TESTIMONIOS' as indicador_id, 4 as componente, 'Videos testimoniales' as indicador, 'videos' as unidad, 10 as meta, 'objetivo' as tipo_meta, 'Producción con empresas y beneficiarias' as fuente_oficial, 'Sin fuente vinculada' as estado_fuente
union all
select 'C4_HERO' as indicador_id, 4 as componente, 'Hero video' as indicador, 'videos' as unidad, 1 as meta, 'objetivo' as tipo_meta, 'Pieza audiovisual central' as fuente_oficial, 'Sin fuente vinculada' as estado_fuente
union all
select 'C4_PIEZAS' as indicador_id, 4 as componente, 'Piezas gráficas y digitales' as indicador, 'piezas' as unidad, 20 as meta, 'maximo' as tipo_meta, 'Piezas bajo lineamientos de marca' as fuente_oficial, 'Sin fuente vinculada' as estado_fuente
)
select *, 'Convenio completo' as alcance, cast(null as string) as corte_meta from metas
