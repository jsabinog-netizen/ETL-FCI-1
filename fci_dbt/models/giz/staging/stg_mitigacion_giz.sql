select
    id,
    Primer_nombre                                           as primer_nombre,
    Primer_apellido                                         as primer_apellido,
    lower(trim(Tipo_de_documento))                          as tipo_documento,
    Name                                                    as documento,

    lower(trim(Enfrenta_alg_n_tipo_de_barrera))             as enfrenta_barrera,
    lower(trim(Seleccione_el_tipo_de_barrera_individual))   as tipo_barrera,
    lower(trim(Tipo_de_mitigaci_n))                         as tipo_mitigacion,
    lower(trim(Es_micromitigaci_n))                         as es_micromitigacion,
    coalesce(nullif(lower(trim(Estado_de_mitigaci_n)), ''), 'Cargado en CRM') as estado_mitigacion,
    lower(trim(Qu_servicio_recibi_para_superar_la_barrera)) as servicio_recibido,
    safe_cast(Qu_valor_recibi_para_superar_la_barrera as numeric) as valor_recibido,
    coalesce(nullif(trim(Nombre_de_encargado), ''), 'Sin encargado') as encargado_mitigacion,
    lower(trim(Gestor_Mitigaci_n))                          as gestor_mitigacion,
    lower(trim(Municipio))                                  as ciudad,
    lower(trim(Departamento))                               as departamento,

    DATE(safe_cast(Fecha_de_pago_de_la_mitigaci_n as timestamp)) as fecha_mitigacion,
    DATE(safe_cast(Modified_Time as timestamp))              as modified_time,
    DATE(safe_cast(Created_Time as timestamp))               as _loaded_at

from {{ source('zoho_raw_giz', 'mitigaci_n_giz') }}