select
    id,
    Primer_nombre                                   as primer_nombre,
    Primer_apellido                                 as primer_apellido,
    Name                                            as documento,
    Perfil_ocupacional                              as perfil_ocupacional,
    lower(trim(Estado))                             as estado,
    CASE 
        WHEN lower(trim(Estado)) IN (
            'contratado', 
            'aprobó proceso/pendiente firma del contrato'
        ) THEN 'Exitosa'
        
        WHEN lower(trim(Estado)) IN (
            'envío de hoja de vida',
            'citado para proceso de selección en la empresa',
            'asistió/está en proceso',
            'en proceso de exámenes médicos',
            'interesado citado',
            'activo',
            'en proceso',
            'proceso aplazado/volver a llamar'
        ) THEN 'En proceso'
        
        WHEN lower(trim(Estado)) IN (
            'asistió/ no le interesa la vacante',
            'asistió/no superó el proceso',
            'no asistió a la citación',
            'no interesado en la vacante',
            'no contesta no se pudo contactar',
            'retirado',
            'no interesado por otro motivo ¿cual?',
            'no interesado en continuar con el programa',
            'la asignación salarial no se ajusta a sus necesidades',
            'ingresó a estudiar',
            'se va de la ciudad',
            'ya consiguió trabajo formal',
            'ya consiguió trabajo informal',
            'problemas de salud',
            'estado de salud no permite su labor',
            'participante debe mejorar competencias socioemocionales',
            'participante debe mejorar competencias técnicas',
            'participante desertó en etapas avanzadas del proceso',
            'participante no se acopla a los horarios de trabajo',
            'participante no aprobó exámenes médicos',
            'participante presenta novedad familiar',
            'no se presentó a entrevista'
        ) THEN 'No continuó'
        
        WHEN lower(trim(Estado)) IN (
            'no cuenta con los requisitos sugeridos por la empresa',
            'no cuenta con la documentación requerida',
            'el candidato presenta información falsa en la hoja de vida',
            'no cumple con el perfil requerido',
            'no cumple con documentación',
            'no cumple con perfil requerido en estudio',
            'no cumple con perfil requerido en experiencia',
            'el candidato no cumple con los requisitos sugeridos por la empresa'
        ) THEN 'No calificó'
    
        ELSE 'Otro'
    END AS estado_intermediacion_grupo,
    Nombre_de_la_vacante                            as vacante,
    Nit_de_la_empresa                               as nit_empresa,
    coalesce(nullif(trim(json_value(Empresa, '$.name')), ''), 'SIN_EMPRESA') as empresa,
    coalesce(nullif(trim(json_value(Responsable_de_la_Intermediaci_n, '$.name')), ''), 'Sin intermediador') as intermediador,
    safe_cast(Fecha_de_intermediaci_n as timestamp) as fecha_intermediacion,
    lower(trim(Desea_hacer_otra_intermediaci_n))    as desea_otra,

    safe_cast(Modified_Time as timestamp)           as modified_time
from {{ source('zoho_raw_giz', 'intermediaci_n_giz') }}