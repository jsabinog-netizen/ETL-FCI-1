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

Cree una cuenta en https://cron-job.org. En **Settings**, ponga la zona horaria **America/Bogota**.

Luego, **Cronjobs → Create cronjob** con esta configuración común:

| Campo | Valor |
|---|---|
| **URL** | `https://api.github.com/repos/jsabinog-netizen/ETL-FCI-1/actions/workflows/ARCHIVO/dispatches` |
| **Execution schedule** | *Custom* (ver la tabla de abajo) |
| **Advanced → Request method** | `POST` |
| **Advanced → Request body** | `{"ref":"main"}` |
| **Advanced → Headers** | `Accept` = `application/vnd.github+json` |
| | `Authorization` = `Bearer EL_TOKEN` |
| | `X-GitHub-Api-Version` = `2022-11-28` |
| | `Content-Type` = `application/json` |
| **Notifications** | Activar "Notify me when execution fails" |
| **Time zone** (si el cronjob la pide) | America/Bogota |

Reemplace `ARCHIVO` y `EL_TOKEN`. Los 6 cronjobs son:

| # | Nombre | ARCHIVO | Minuto | Horas |
|---|---|---|---|---|
| 1 | Colsubsidio | `pipeline.yml` | 40 | 8, 11, 13, 15, 17, 19 |
| 2 | Colsubsidio 10:10 | `pipeline.yml` | 10 | 10 |
| 3 | Ruta Mujer | `pipeline_ruta_mujer.yml` | 50 | 8, 11, 13, 15, 17, 19 |
| 4 | Ruta Mujer 10:20 | `pipeline_ruta_mujer.yml` | 20 | 10 |
| 5 | GIZ | `pipeline_giz.yml` | 50 | 8, 11, 13, 15, 17, 19 |
| 6 | GIZ 10:20 | `pipeline_giz.yml` | 20 | 10 |

Días: todos. Si quiere que no corra el fin de semana, desmarque sábado y domingo.

**Por qué esas horas:**
- Cada corrida dura ~4 min, así que los datos quedan listos antes de las 09:00, 10:30, 12:00, 14:00, 16:00, 18:00 y 20:00.
- Colsubsidio va 10 min antes que Ruta Mujer porque comparten la cuenta de Zoho y su cuota de API.
- GIZ usa otra cuenta, así que puede ir a la misma hora que Ruta Mujer.

## 3. Probar

1. En el cronjob de Ruta Mujer → **Test run**.
   - **204** = correcto.
   - **401 / 403**: el token está mal, venció o no tiene el permiso "Actions: Read and write".
   - **404**: el nombre del archivo o del repo en la URL está mal.
   - **422**: el body no es exactamente `{"ref":"main"}`.
2. GitHub → **Actions → Pipeline ELT Ruta Mujer**: debe aparecer una corrida con evento `workflow_dispatch`, iniciada en segundos y que termina en verde.

## 4. Respaldo

Cada workflow conserva un `schedule:` de madrugada (Colsubsidio 01:00, Ruta Mujer 01:20, GIZ 01:40, hora Colombia). Si cron-job.org falla o el token vence, los datos se ponen al día al menos una vez al día. El pipeline es incremental (MERGE por watermark), así que una corrida extra no duplica datos.

Para una actualización inmediata: GitHub → Actions → el pipeline → **Run workflow**.

## 5. Mantenimiento

- **Renovar el token antes de que venza:** GitHub → Fine-grained tokens → Regenerate. Luego actualice el header `Authorization` en los 6 cronjobs.
- Si un día no se actualizó el tablero, revise primero el historial de cron-job.org ("History") y después GitHub Actions.
