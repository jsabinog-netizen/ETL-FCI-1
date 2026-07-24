with fuente as (
    select * from {{ source('zoho_raw', 'agenda_inscripci_n') }}
),

limpio as (
    select
        -- NIT: en este módulo viene en Name, ya SIN puntos ni guion.
        Name as nit,

        Raz_n_social_de_la_empresa as razon_social,

        -- Fechas de cada sesión (STRING en raw → date).
        safe_cast(Seleccione_fecha   as date) as fecha_sesion_1,
        safe_cast(Seleccione_fecha_2 as date) as fecha_sesion_2,

        -- Estados de sesión normalizados a minúscula/sin espacios.
        -- Valores reales: ejecutada / pendiente / programada.
        lower(trim(Sesi_n_1)) as estado_sesion_1,
        lower(trim(Sesi_n_2)) as estado_sesion_2,

        _loaded_at
    from fuente
)

select * from limpio