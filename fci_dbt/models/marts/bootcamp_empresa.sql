-- Grano: una fila por empresa en bootcamp.
-- Deriva el estado del bootcamp a partir de los estados de las dos sesiones.
-- Una sesión cuenta como REALIZADA solo si está 'ejecutada'.

with inscripcion as (
    select * from {{ ref('stg_agenda_inscripcion') }}
),

final as (
    select
        nit,
        razon_social,
        fecha_sesion_1,
        fecha_sesion_2,
        estado_sesion_1,
        estado_sesion_2,

        -- Banderas de sesión realizada (1 = ejecutada, 0 = no).
        case when estado_sesion_1 = 'ejecutada' then 1 else 0 end as hizo_sesion_1,
        case when estado_sesion_2 = 'ejecutada' then 1 else 0 end as hizo_sesion_2,

        -- Estado del bootcamp DERIVADO (no campo manual):
        --   completado  = ambas sesiones ejecutadas
        --   en proceso  = una ejecutada, la otra no
        --   sin iniciar = ninguna ejecutada (registrada pero sin empezar)
        case
            when estado_sesion_1 = 'ejecutada' and estado_sesion_2 = 'ejecutada'
                then 'completado'
            when estado_sesion_1 = 'ejecutada' or  estado_sesion_2 = 'ejecutada'
                then 'en proceso'
            else 'sin iniciar'
        end as estado_bootcamp

    from inscripcion
)

select * from final