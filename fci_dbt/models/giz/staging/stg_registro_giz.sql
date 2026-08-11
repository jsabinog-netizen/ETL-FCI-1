select
    -- identificación
    id,
    Name                                            as documento,
    lower(trim(Tipo_de_documento))                  as tipo_documento,
    Documento_de_identidad                          as archivo_documento,
    Primer_Nombre                                   as primer_nombre,
    Primer_Apellido                                 as primer_apellido,
    Segundo_Nombre                                  as segundo_nombre,
    Segundo_apellido                                as segundo_apellido,
    Edad                                            as edad,
    

    -- variables de metas 
    lower(trim(G_nero))                             as genero,
    lower(trim(Tipo_de_participante))               as tipo_participante,
    lower(trim(Municipio_de_residencia))            as ciudad,
    lower(trim(Departamento_de_residencia))         as departamento,
    lower(trim(Nacionalidad))                       as nacionalidad,
    lower(trim(Pa_s_de_nacimiento))                 as pais_nacimiento,
    lower(trim(Ciudad_de_nacimiento))               as ciudad_nacimiento,

    -- análisis de población
    lower(trim(Etnia))                              as etnia,
    lower(trim(Tipo_de_discapacidad))               as tipo_discapacidad,
    lower(trim(V_ctima_del_conflicto_armado))       as victima_conflicto,
    lower(trim(Ultimo_nivel_educativo_alcanzado))   as nivel_educativo,
    lower(trim(Es_jefe_a_del_hogar))                as es_jefe_hogar,
    lower(trim(Zona_geogr_fica_de_residencia))      as zona_geografica,
    lower(trim(Se_reconoce_como_parte_de_la_poblaci_n_LGBTI_Q)) as lgbtiq,

    -- estado del registro
    lower(trim(Inscripci_n_Completada))             as inscripcion_completada,
    lower(trim(Validaci_n_inscripci_n))             as validacion_inscripcion,
    Observaci_n_Calidad                             as observacion_calidad,

    -- gestor
    coalesce(
        nullif(trim(json_value(Gestor_operativo, '$.name')), ''),
        'Sin gestor asignado'
    )                                               as gestor,

    -- Fechas
    DATE(safe_cast(Fecha_de_registro as timestamp))      as fecha_registro,

    -- plumbing
    DATE(safe_cast(Modified_Time as timestamp))           as modified_time,
    DATE(safe_cast(_loaded_at    as timestamp))           as _loaded_at

from {{ source('zoho_raw_giz', 'registro_giz') }}  