select
    id,
    -- persona
    Name                                            as documento,
    lower(trim(Tipo_de_documento))                  as tipo_documento,
    Primer_Nombre                                   as primer_nombre,
    Primer_Apellido                                 as primer_apellido,
    Segundo_apellido                                as segundo_apellido,

    -- link a registro: el lookup trae {name, id}; el id es la PK del registro
    json_value(Registro_Giz, '$.id')                as registro_id,

    -- variables de meta (redundantes con registro, pero útiles si orientación es más fresca)
    lower(trim(G_nero))                             as genero,
    lower(trim(Tipo_de_participante))               as tipo_participante,
    lower(trim(Municipio_de_residencia))            as ciudad,
    lower(trim(Departamento_de_residencia))         as departamento,

    -- perfil ocupacional
    Perfil_ocupacional                              as perfil_ocupacional,
    lower(trim(Ocupaci_n_Actual))                   as ocupacion_actual,
    lower(trim(rea_de_formaci_n))                   as area_formacion,
    lower(trim(rea_de_desempe_o))                   as area_desempeno,
    lower(trim(Cuenta_con_experiencia_laboral_formal)) as experiencia_formal,

    -- barreras
    lower(trim(Presenta_barreras_de_pre_vinculaci_n)) as presenta_barreras,
    Barreras_interna_de_previnculaci_n              as barrera_interna,
    Barrera_externa_de_pre_vinculaci_n              as barrera_externa,
    lower(trim(Remisi_n_atenci_n_psic_social))      as remision_psicosocial,

    -- resultado de la etapa
    coalesce(nullif(trim(json_value(Orientador, '$.name')), ''), 'Sin orientador') as orientador,
    lower(trim(Orientaci_n_Completada))             as orientacion_completada,
    Recomendado_para_una_vacante_de                 as recomendado_vacante,
    safe_cast(Fecha_de_orientaci_n as timestamp)    as fecha_orientacion,

    -- plumbing
    safe_cast(Modified_Time as timestamp)           as modified_time
from {{ source('zoho_raw_giz', 'orientaci_n_giz') }}