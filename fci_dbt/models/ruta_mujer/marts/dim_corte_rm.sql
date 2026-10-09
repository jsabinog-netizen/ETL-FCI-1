-- Grano: un corte del programa.
-- Dimension del unico slicer de corte en Power BI. Se relaciona solo con
-- fct_actividad_rm; las demas tablas se filtran con TREATAS en las medidas.
select 'corte 1' as corte, 'Corte 1' as corte_nombre, 1 as corte_orden
union all
select 'corte 2', 'Corte 2', 2
union all
select 'sin corte', 'Sin corte', 3
