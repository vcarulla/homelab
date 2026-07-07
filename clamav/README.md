# ClamAV - Antivirus del host

**ClamAV** escanea el filesystem del host icarus, montado read-only en `/scan` dentro del contenedor. Incluye un sidecar (`clamav-stats`) que expone estadísticas de los escaneos para Glance.

> **Estado: desactivado.** Ambos servicios están detrás de `profiles: disabled` y no arrancan con un `up -d` normal. Para activarlos:
>
> ```bash
> cd clamav && docker compose --env-file ../.env --profile disabled up -d
> ```

---

## Estructura

```
clamav/
├── docker-compose.yml     # clamav (daemon) + clamav-stats (sidecar)
├── scan-cron.sh           # Script de escaneo programado (cron del host)
├── clamav-stats.py        # Parser de logs → JSON
├── clamav-webserver.py    # Webserver HTTP que sirve las stats
└── config/
    ├── clamd.conf         # Configuración del daemon
    └── freshclam.conf     # Actualización de firmas
```

---

## Servicio `clamav`

- Monta **todo el host** en `/scan` read-only: `- /:/scan:ro`
- `cap_drop: ALL` + caps mínimas; **`DAC_READ_SEARCH`** es la clave: permite leer todo `/scan` sin ser dueño de los archivos (solo lectura, nunca escritura). `CHOWN/SETUID/SETGID/FOWNER` las usa el entrypoint para preparar `/var/lib/clamav` y bajar privilegios al usuario clamav.
- **Límite de 3G de RAM**: clamd carga la base de firmas completa en memoria.
- Red `backend` solo para que freshclam actualice firmas; no expone puertos.
- `read_only: true` con tmpfs en `/tmp` y `/run`; firmas persistidas en el volumen `clamav-data`.
- Healthcheck con `start_period: 5m` (la carga inicial de firmas es lenta).

---

## Escaneo programado: `scan-cron.sh`

Script pensado para cron del **host** (usa `docker exec`):

- Escanea por directorios con `clamdscan --multiscan --fdpass --infected`:
  - `--multiscan` paraleliza el escaneo dentro del daemon
  - `--fdpass` pasa file descriptors a clamd, evitando problemas de permisos
  - `--infected` loguea solo hallazgos y errores
- Directorios: `/scan/home` (en background, en paralelo), `/scan/tmp`, `/scan/opt`
- Logs en `/var/log/clamav-scans/clamav-scan-YYYYMMDD_HHMM.log`
- **Rotación**: borra logs con más de 30 días al inicio de cada corrida
- Cuenta `FOUND` y `ERROR` en el log y deja un resumen (notificación real pendiente, hoy solo log)

---

## Sidecar `clamav-stats`

Webserver Python minimalista (`python:alpine`, sin dependencias) que parsea el último log de `/var/log/clamav-scans` (montado `:ro`) y devuelve JSON en `/` o `/status`: amenazas encontradas, antigüedad del último escaneo, errores, duración.

- **Sin puerto publicado al host**: solo accesible dentro de la red `frontend` por nombre de contenedor (`clamav-stats:8080`). Lo consume el widget de Glance. (Antes publicaba 8081 y colisionaba con cadvisor.)
- Hardening completo: `read_only`, `cap_drop: ALL`, 128M de RAM.

---

## Operación

```bash
# Activar el stack (perfil disabled)
cd clamav && docker compose --env-file ../.env --profile disabled up -d

# Escaneo manual
./scan-cron.sh

# Ver último log
ls -t /var/log/clamav-scans/ | head -1

# Stats: http://clamav-stats:8080/status (solo desde contenedores en la red frontend)
```
