# Disparar los pipelines desde cron-job.org

> Oct-2026. GitHub Actions trata `schedule:` como "mejor esfuerzo" y en este repo
> descartaba casi todas las corridas de la mañana (Colsubsidio, programado entre
> 08:10 y 19:10, corría entre 16:40 y 01:40). Ahora cron-job.org llama a la API de
> GitHub a la hora exacta y el workflow arranca en segundos.

## 1. Crear el token en GitHub (una sola vez)

1. GitHub → foto de perfil → **Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token**.
2. **Token name:** `cron-job-org-etl`. **Expiration:** 1 año. Anote la fecha de vencimiento en el calendario.
3. **Repository access:** *Only select repositories* → `jsabinog-netizen/ETL-FCI-1`.
4. **Permissions → Repository permissions → Actions: Read and write.** Ningún otro permiso.
5. **Generate token** y cópielo. GitHub no lo vuelve a mostrar.

No lo pegue en el repo, en chats ni en archivos: solo en los headers de cron-job.org.

## 2. Crear los cronjobs en cron-job.org

Cree una cuenta en https://cron-job.org → **Panel → Cronjobs → Crear cronjob**.
Repita este paso 6 veces, uno por fila de la tabla de la sección 2.5.

### 2.1 Pestaña principal

| Campo en pantalla | Qué poner |
|---|---|
| **Título** | El nombre de la tabla 2.5, por ejemplo `Ruta Mujer` |
| **URL** | `https://api.github.com/repos/jsabinog-netizen/ETL-FCI-1/actions/workflows/ARCHIVO/dispatches`, reemplazando `ARCHIVO` según la tabla 2.5 |
| **Habilitar job** | Activado |
| **Guardar respuestas en el historial de jobs** | Activado (sirve para ver el error si falla) |

### 2.2 Horario de ejecución

1. Marque **Personalizado**.
2. En **Expresión Crontab** borre `*/15 * * * *` y pegue la expresión de la tabla 2.5.
3. Revise **Próximas ejecuciones**: deben salir las horas esperadas "(America/Bogota)". Si salen otras horas, la zona horaria está mal (ver 2.4).
4. **El horario expira:** desactivado.

### 2.3 Notificarme cuando…

| Opción | Estado |
|---|---|
| cuando la ejecución del cronjob falle | **Activado**, notificar después de **1** fallo |
| cuando la ejecución del cronjob tenga éxito después de haber fallado antes | **Activado** |
| cuando el cronjob se deshabilite por demasiados fallos | Activado (ya viene así) |
| el certificado TLS del servidor está a punto de expirar | Desactivado |

**Notificar mediante:** todos los canales de notificación.

### 2.4 Pestaña Avanzado

| Campo en pantalla | Qué poner |
|---|---|
| **Requiere autenticación HTTP** | Desactivado (el token va en los encabezados) |
| **Encabezados** → Clave / Valor (botón **+ AÑADIR** por cada uno) | `Accept` → `application/vnd.github+json` |
| | `Authorization` → `Bearer EL_TOKEN` (la palabra Bearer, un espacio y el token) |
| | `X-GitHub-Api-Version` → `2022-11-28` |
| | `Content-Type` → `application/json` |
| **Zona horaria** | `America/Bogota` |
| **Método de solicitud** | **POST** (viene en GET: cámbielo, si no GitHub responde 404) |
| **Cuerpo de la solicitud** | `{"ref":"main"}` |
| **Tiempo de espera agotado** | 30 segundos (dejar así; GitHub responde en ~1 s) |
| **Tratar las redirecciones 3xx como exitosas** | Desactivado |

**Atajo:** el botón **IMPORT FROM CURL** llena URL, método, encabezados y cuerpo de una vez. Pegue esto, con su token y el archivo correcto, y después solo ajuste título y horario:

```
curl -X POST "https://api.github.com/repos/jsabinog-netizen/ETL-FCI-1/actions/workflows/pipeline_ruta_mujer.yml/dispatches" -H "Accept: application/vnd.github+json" -H "Authorization: Bearer EL_TOKEN" -H "X-GitHub-Api-Version: 2022-11-28" -H "Content-Type: application/json" -d "{\"ref\":\"main\"}"
```

### 2.5 Los 6 cronjobs

| # | Título | ARCHIVO (en la URL) | Expresión Crontab | Corre a las (COL) |
|---|---|---|---|---|
| 1 | Colsubsidio | `pipeline.yml` | `40 8,11,13,15,17,19 * * *` | 08:40, 11:40, 13:40, 15:40, 17:40, 19:40 |
| 2 | Colsubsidio 10:10 | `pipeline.yml` | `10 10 * * *` | 10:10 |
| 3 | Ruta Mujer | `pipeline_ruta_mujer.yml` | `50 8,11,13,15,17,19 * * *` | 08:50, 11:50, 13:50, 15:50, 17:50, 19:50 |
| 4 | Ruta Mujer 10:20 | `pipeline_ruta_mujer.yml` | `20 10 * * *` | 10:20 |
| 5 | GIZ | `pipeline_giz.yml` | `50 8,11,13,15,17,19 * * *` | 08:50, 11:50, 13:50, 15:50, 17:50, 19:50 |
| 6 | GIZ 10:20 | `pipeline_giz.yml` | `20 10 * * *` | 10:20 |

Para no correr sábados ni domingos, cambie el último `*` por `1-5`. Ejemplo: `40 8,11,13,15,17,19 * * 1-5`.

**Por qué esas horas:**
- Cada corrida dura ~4 min, así que los datos quedan listos antes de las 09:00, 10:30, 12:00, 14:00, 16:00, 18:00 y 20:00.
- Colsubsidio va 10 min antes que Ruta Mujer porque comparten la cuenta de Zoho y su cuota de API.
- GIZ usa otra cuenta, así que puede ir a la misma hora que Ruta Mujer.

## 3. Probar

1. Antes de **CREAR**, pulse **EJECUCIÓN DE PRUEBA**.
   - **204** = correcto. GitHub no devuelve cuerpo; es normal.
   - **401 / 403**: el token está mal, venció o no tiene el permiso "Actions: Read and write". Revise que diga `Bearer ` con el espacio.
   - **404**: el método quedó en GET, o el nombre del archivo o del repo en la URL está mal.
   - **422**: el cuerpo no es exactamente `{"ref":"main"}`.
2. GitHub → **Actions → Pipeline ELT ...**: debe aparecer una corrida con evento `workflow_dispatch`, iniciada en segundos y que termina en verde.
3. Pulse **CREAR**.

Ojo: cada "Ejecución de prueba" dispara una corrida real del pipeline. No pasa nada porque el pipeline es incremental, pero no la repita muchas veces seguidas en Colsubsidio y Ruta Mujer, que comparten la cuota de Zoho.

## 4. Respaldo

Cada workflow conserva un `schedule:` de madrugada (Colsubsidio 01:00, Ruta Mujer 01:20, GIZ 01:40, hora Colombia). Si cron-job.org falla o el token vence, los datos se ponen al día al menos una vez al día. El pipeline es incremental (MERGE por watermark), así que una corrida extra no duplica datos.

Para una actualización inmediata: GitHub → Actions → el pipeline → **Run workflow**.

## 5. Mantenimiento

- **Renovar el token antes de que venza:** GitHub → Fine-grained tokens → Regenerate. Luego actualice el header `Authorization` en los 6 cronjobs.
- Si un día no se actualizó el tablero, revise primero el historial del job en cron-job.org (por eso se activa "Guardar respuestas en el historial de jobs") y después GitHub Actions.
