{% macro rm_post_vencida(dias, llamada) -%}
coalesce({{ dias }} >= 15 and {{ llamada }} is null, false)
{%- endmacro %}
