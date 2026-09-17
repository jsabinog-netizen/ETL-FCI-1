-- Grano: UNA INSCRIPCIÓN A CURSO por fila.
--
-- CAMBIO DE GRANO (tanda 2): antes este mart era `select *` del staging,
-- así que su grano era un registro de Zoho (≈ una mujer) y COUNTROWS no
-- contaba cursos. El módulo Formaci_n_Colsubsidios está en formato ancho:
-- un registro con hasta 6 cursos en columnas separadas. Acá se desanida
-- con UNION ALL para que cada curso sea una fila.
--
-- Consecuencia: COUNTROWS aumenta respecto a la versión anterior. No es
-- un bug — el número viejo contaba registros, no inscripciones.
--
-- Para contar personas: DISTINCTCOUNT(documento) en DAX.
--
-- LIMITACIÓN CONOCIDA: formaci_n_completada es un flag a nivel de
-- REGISTRO, no de curso. Una mujer con 3 cursos tiene un solo flag, así
-- que no se puede saber cuál curso completó. El flag se replica en las
-- 6 filas. Es un límite del dato en Zoho, no del modelo.

with fuente as (
    select * from {{ ref('stg_formaci_n_colsubsidios') }}
),

slot_1 as (
    select
        concat(id, ':1') as id_curso, id as id_registro, 1 as slot,
        'técnica' as tipo_curso,
        fortalecimiento_de_habilidades_t_cnica as curso,
        fecha_curso as fecha_curso, modalidad as modalidad, jornada as jornada
    from fuente where fortalecimiento_de_habilidades_t_cnica is not null
),
slot_2 as (
    select
        concat(id, ':2'), id, 2, 'técnica',
        fortalecimiento_de_habilidades_t_cnicas_2,
        fecha_curso_2, modalidad_2, jornada_2
    from fuente where fortalecimiento_de_habilidades_t_cnicas_2 is not null
),
slot_3 as (
    select
        concat(id, ':3'), id, 3, 'técnica',
        fortalecimiento_de_habilidades_t_cnicas_3,
        fecha_curso_3, modalidad_3, jornada_3
    from fuente where fortalecimiento_de_habilidades_t_cnicas_3 is not null
),
slot_4 as (
    select
        concat(id, ':4'), id, 4, 'técnica',
        fortalecimiento_de_habilidades_t_cnicas_4,
        fecha_curso_4, modalidad_4, jornada_4
    from fuente where fortalecimiento_de_habilidades_t_cnicas_4 is not null
),
slot_5 as (
    select
        concat(id, ':5'), id, 5, 'blandas',
        fortalecimiento_de_habilidades_blandas,
        fecha_curso_blandas, modalidad_blandas, jornada_blandas
    from fuente where fortalecimiento_de_habilidades_blandas is not null
),
slot_6 as (
    select
        concat(id, ':6'), id, 6, 'blandas',
        fortalecimiento_de_habilidades_blandas_2,
        fecha_curso_blandas_2, modalidad_blandas_2, jornada_blandas_2
    from fuente where fortalecimiento_de_habilidades_blandas_2 is not null
),

cursos as (
    select * from slot_1
    union all select * from slot_2
    union all select * from slot_3
    union all select * from slot_4
    union all select * from slot_5
    union all select * from slot_6
)

select
    c.id_curso,
    c.id_registro,
    c.slot,
    c.tipo_curso,
    c.curso,
    c.fecha_curso,
    c.modalidad,
    c.jornada,
    -- Atributos del registro padre, repetidos en cada curso
    f.documento,
    f.corte,
    case
        when coalesce(c.fecha_curso, f.fecha_formaci_n, date(f.created_time)) >= '2026-09-01' then 'corte 2'
        else 'corte 1'
    end as corte_evento,
    f.primer_nombre, f.segundo_nombre, f.primer_apellido, f.segundo_apellido,
    f.n_mero_de_celular,
    f.municipio, f.localidad,
    f.profesional_de_orientaci_n,
    f.fecha_formaci_n,
    f.formaci_n_completada,
    case when f.formaci_n_completada in ('si', 'sí', 'true')
         then 'Completada' else 'Pendiente'
    end as estado_formacion,
    date(f.created_time) as created_time,
    date(f.modified_time) as modified_time,
    date(f._loaded_at) as _loaded_at
from cursos c
join fuente f on c.id_registro = f.id
