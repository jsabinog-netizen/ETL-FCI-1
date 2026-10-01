-- Grano: un registro del modulo Zoho (id).
-- Name conserva el documento como texto; los eventos no se deduplican por persona.
select
    id,
    nullif(trim(Name), '') as documento,
    safe_cast(`Created_Time` as timestamp) as created_time,
    json_value(`Inscripci_n`, '$.id') as inscripci_n_id,
    json_value(`Inscripci_n`, '$.name') as inscripci_n_nombre,
    trim(`Primer_nombre`) as primer_nombre,
    trim(`Segundo_nombre`) as segundo_nombre,
    trim(`Primer_apellido`) as primer_apellido,
    trim(`Segundo_apellido`) as segundo_apellido,
    date(safe_cast(`Fecha_de_orientaci_n` as timestamp)) as fecha_de_orientaci_n,
    lower(trim(`Orientaci_n_sociocupacion_Completada`)) as orientaci_n_sociocupacion_completada,
    trim(`Concepto_de_Orientaci_n`) as concepto_de_orientaci_n,
    trim(`Concepto_de_orientaci_n_colsubsidio`) as concepto_de_orientaci_n_colsubsidio,
    lower(trim(`Modalidad_Orientacion`)) as modalidad_orientacion,
    trim(`Gestor_operativo`) as gestor_operativo,
    trim(`Perfil_Ocupacional`) as perfil_ocupacional,
    `Grupos_poblacionales` as grupos_poblacionales_json,
    lower(trim(json_value(`Grupos_poblacionales`, '$[0]'))) as grupos_poblacionales,
    lower(trim(`Nivel_de_necesidad_de_acompa_amiento_psicosocial`)) as nivel_de_necesidad_de_acompa_amiento_psicosocial,
    trim(`Sientes_que_actualmente_necesitas_apoyo_adicional`) as sientes_que_actualmente_necesitas_apoyo_adicional,
    trim(`N_mero_de_celular_Principal`) as n_mero_de_celular_principal,
    lower(trim(`Municipio_de_residencia`)) as municipio_de_residencia,
    lower(trim(`rea_de_Experiencia_Laboral_experiencia_2`)) as area_experiencia_2,
    lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)) as area_experiencia,
    case
        when nullif(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`), '') is null or lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)) in ('nan', '') 
            then 'Sin información'
        when lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)) in ('n/a', 'no aplica') 
            then 'No aplica / Sin experiencia'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'¿otro\?|otra$|^otro$') 
            then 'Otro / Por clasificar'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'comercio|venta|comercial|tienda|cajer|impulsador|recaudo|caja|retail|cliente|papeler[íi]a') 
            then 'Comercio y Ventas'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'administra|secretari|recepci|digitador|archivo|archivista|facturaci|documentaci|asistente|reclutamiento|informaci|investigaci') 
            then 'Servicios Administrativos y Oficina'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'alimento|bebida|comida|helader|restaurante|ec[óo]nomo|alimentaci') 
            then 'Alimentos y Gastronomía'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'manufactur|producci|operari|operativ|metalmec|carpinter|empaque|icopor') 
            then 'Industria y Manufactura'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'contact center|call center|bpo|teleoperad') 
            then 'Contact Center y BPO'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'domestico|doméstico|limpieza|aseador|conserje|jardiner|servicios generales') 
            then 'Servicios Generales y Limpieza'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'transporte|logistic|logístic|almacen|almacén|bodega|conductor|mensajer') 
            then 'Transporte y Logística'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'financier|finanza|contab|auditor|credit|crédit|tesorer|poliza|cobranza') 
            then 'Finanzas y Contabilidad'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'salud|farmac|medicamento|hospital|droger|laborat') 
            then 'Salud y Farmacia'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'textil|confecci|moda|prenda|tapete') 
            then 'Textil y Confección'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'tecnolog|software|sofware|sistema|telecomunicac|tic|soporte') 
            then 'Tecnología y Telecomunicaciones'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'seguridad|vigilanc') 
            then 'Seguridad y Vigilancia'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'arte|diseño|diseñ|comunicaci|publicidad') 
            then 'Artes, Diseño y Comunicación'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'belleza|estilista|esteticista|cosmetic') 
            then 'Belleza y Cuidado Personal'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'educaci|social|psicolog|antropolog|infancia|empleabilidad|cuidador|sena') 
            then 'Educación y Social'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'agropecuari|agricola|agrícola|verde|ambiental|flor') 
            then 'Agropecuario y Ambiental'
        when regexp_contains(lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)), r'construcci|mantenimiento|reparaci|mecanic|mecánic|repuesto|ingenier') 
            then 'Construcción y Mantenimiento'
        when lower(trim(`Sector_o_Area_del_cargo_que_desempe_o_1`)) = 'servicios temporales' 
            then 'Servicios Temporales'
        else 'Otro / Por clasificar'
    end as area_experiencia_normalizada,
    trim(`Tiempo_de_experiencia_Laboral`) as tiempo_de_experiencia_laboral,
    lower(trim(`Localidad`)) as localidad,
    lower(trim(`Actitud_y_disposici_n`)) as actitud_y_disposici_n,
    lower(trim(`actualmente_cu_l_es_su_ocupaci_n`)) as ocupacion_actual,
    lower(trim(`Inter_s_Laboral`)) as inter_s_laboral,
    lower(trim(`Corte`)) as corte,
    safe_cast(_loaded_at as timestamp) as _loaded_at,
    safe_cast(Modified_Time as timestamp) as modified_time
from {{ source('zoho_raw_ruta_mujer', 'orientaci_n_colsubsidios') }}
