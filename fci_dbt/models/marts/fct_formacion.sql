select
    'Estrategias comerciales' as curso,
    id,
    nombre,
    cedula,
    sesiones_asistidas,
    porcentaje_asistencia,
    evaluacion_1,
    'No aplica' as evaluacion_2,
    estado_curso
from {{ ref( 'stg_formacion_comercial') }}

union all

select
    'Intermediación laboral' as curso,
    id,
    nombre,
    cedula,
    sesiones_asistidas,
    porcentaje_asistencia,
    evaluacion_1,
    'No aplica' as evaluacion_2,
    estado_curso
from {{ ref('stg_formacion_intermediacion') }}

union all

select
    'Lengua de Señas' as curso,
    id,
    nombre,
    cedula,
    sesiones_asistidas,
    porcentaje_asistencia,
    evaluacion_1,
    evaluacion_2,
    estado_curso

from {{ ref('stg_formacion_lenguaje') }}