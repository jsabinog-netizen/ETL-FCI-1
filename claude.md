# ETL FCI — Reglas y Contexto para Agentes de Código

> Lee este archivo completo antes de planificar o editar código.
> Fuente canónica de arquitectura y convenciones para Colsubsidio, GIZ y Ruta Mujer.

---

## 1. Modo de Operación y Restricciones
- **Rol:** Asistente técnico ejecutor. Propón cambios atómicos y concisos.
- **Protocolo de cambios:** 1 cambio lógico = 1 commit (Conventional Commits). Build verde obligatorio antes de cerrar tarea.
- **Producción congelada:** Colsubsidio, GIZ y Ruta Mujer están en producción. NO modificar su lógica ni tablas sin orden explícita.
- **PROHIBIDO inventar nombres:** Usa estrictamente los `api_name` de Zoho y nombres de modelos documentados. Si un campo no existe, repórtalo inmediatamente.
- **Formato de respuesta:** Muestra únicamente diffs o bloques específicos modificados. No reescribas archivos completos salvo que sea indispensable.

---

## 2. Stack y Entorno
- **Pipeline:** Zoho CRM v8 (OAuth2) → Python 3.11 → Google BigQuery → dbt → Power BI
- **GCP Project:** `zoho-bq-pipeline-492116` (Región: `US` multi-region)
- **Repo:** `github.com/jsabinog-netizen/ETL-FCI-1`
- **dbt:** `1.11.12` | **dbt-bigquery:** `1.11.3` (Fijo; versiones 1.12+ rompen compatibilidad binaria)
- **Orquestación:** GitHub Actions vía `python main.py <proyecto>`

| Proyecto | Grano Base | Dataset BigQuery | Prefijo ENV Zoho | Argumento CLI |
|---|---|---|---|---|
| **Colsubsidio** | Empresa | `colsubsidio_ruta_empresas` | `ZOHO` | `colsubsidio` |
| **GIZ** | Persona | `proyecto_giz` | `ZOHO_GIZ` | `giz` |
| **Ruta Mujer** | Persona | `proyecto_ruta_mujer` | `ZOHO` | `ruta_mujer` |

---

## 3. Protocolo Obligatorio para Agregar o Modificar Campos
Para evitar errores de compilación en dbt (`Unrecognized name: ...`), sigue este orden estricto:
1. **Verificar:** Confirmar el `api_name` exacto contra Zoho CRM (`getFields`).
2. **Extraer:** Agregar el campo en `config.py` (`MODULES_<PROYECTO>`). Respetar el límite de 50 campos por módulo en Zoho.
3. **Poblar Raw:** Ejecutar re-extracción y carga del módulo específico hacia BigQuery.
4. **Validar Raw:** Comprobar en `INFORMATION_SCHEMA.COLUMNS` que la columna existe en BigQuery.
5. **Modelar dbt:** Agregar la columna a `stg_*.sql`, propagar al mart (`fct_*.sql`) y ejecutar `dbt build --select <modelo>`.

---

## 4. Reglas Críticas de Arquitectura

### dbt & Modelado
- **Contrato con BI:** Power BI consume **exclusivamente** marts (`fct_*` / `dim_*`). NUNCA conectar Power BI a stagings.
- **Materialización:** `staging/` = `view` | `marts/` = `table`.
- **División de lógica:**
  - `staging`: `lower`, `trim`, `safe_cast`, `coalesce`, desempaquetar JSON simples (`json_value`).
  - `marts`: JOINs, agregaciones, `UNION ALL`, flags cruzados, deduplicaciones.
  - `Power BI`: Medidas DAX dinámicas (agregaciones según filtro). No mover lógica de negocio a DAX.
- **Tests dbt:** Siempre con `severity: warn`. Sintaxis dbt 1.11:
  ```yaml
  - accepted_values:
      arguments:
        values: ['val1', 'val2']
      config:
        severity: warn