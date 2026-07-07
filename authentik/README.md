# Authentik - SSO / Identity Provider

**Authentik** es el proveedor de identidad (IdP) del homelab: SSO centralizado para los servicios via forward-auth y OAuth2/OIDC.

Acceso: `https://auth.${DOMAIN_ICARUS}` (router Traefik por labels, middleware `security-headers@file`).

---

## Arquitectura

Dos contenedores con la misma imagen (`ghcr.io/goauthentik/server`):

| Contenedor | Comando | Redes | Función |
|---|---|---|---|
| `authentik-server` | `server` | frontend, database | UI + API + outpost embebido (puerto 9000, detrás de Traefik) |
| `authentik-worker` | `worker` | database | Tareas en background (sync, tokens, certs) |

Dependencias (deben estar corriendo antes):

- **PostgreSQL** (`homelab-postgres`, red database) — base de datos
- **Redis** (`homelab-redis`, red database) — cache y broker de tareas
- **Shared Vault Agent** — secrets
- **Traefik** — exposición HTTPS

---

## Secrets via Shared Vault Agent

No hay `.env` con credenciales: el Shared Vault Agent renderiza `authentik.env` al tmpfs compartido, que ambos contenedores montan en `/run/secrets` (read-only). El entrypoint carga las variables antes de arrancar:

```sh
export $(grep -v '^#' /run/secrets/authentik.env | grep -v '^$' | grep -v '^VAULT_' | xargs)
exec /lifecycle/ak server   # o worker
```

Si el archivo no existe (agente caído / Vault sealed), el contenedor **falla explícitamente** en vez de arrancar sin secrets.

> **`user: root` es obligatorio**: el tmpfs `vault_secrets_tmpfs` tiene `mode=0700 uid=0`, y la imagen de Authentik corre por defecto como uid 1000 (usuario `authentik`), que no puede leerlo.

---

## Capabilities y hardening

Ambos contenedores: `no-new-privileges:true` + `cap_drop: ALL` + caps mínimas:

- **server**: `CHOWN`, `FOWNER`, `SETUID`, `SETGID`, `DAC_OVERRIDE`
- **worker**: las mismas + **`KILL`** — el healthcheck `ak healthcheck` la necesita

Otras particularidades de la imagen:

- **Healthchecks con `curl`**: la imagen no trae `wget` (el server usa `curl -sf http://localhost:9000/-/health/live/`).
- **`AUTHENTIK_OUTPOSTS__DISCOVER=false`** en el worker: evita errores de discovery de Kubernetes (no hay k8s acá).
- **Sin `read_only`** (decisión consciente): la imagen escribe en varios paths internos y el riesgo de romper el SSO de todo el homelab no compensa el beneficio. Es la excepción documentada al estándar de hardening del repo.

---

## Bootstrap

Las credenciales iniciales (usuario akadmin) están en `private/authentik-bootstrap.txt` (fuera del repo público).

---

## Integraciones

Dos patrones conviven:

### 1. Forward Auth (Traefik)

Para apps sin soporte nativo de SSO. Middleware definido en `traefik/config/middlewares.yml`:

```yaml
- "traefik.http.routers.<svc>.middlewares=authentik-forward-auth@file"
```

Apunta al outpost embebido: `http://authentik-server:9000/outpost.goauthentik.io/auth/traefik`.

### 2. OAuth2 / OIDC

Para apps con soporte nativo (Portainer, Proxmox VE, Home Assistant, etc.): se configura un Provider OAuth2/OIDC en Authentik y las credenciales en la app. No requiere cambios en Traefik.

---

## Operación

```bash
# Levantar (con postgres, redis, traefik y vault-agent ya arriba)
cd authentik && docker compose --env-file ../.env up -d

# Logs
docker logs -f authentik-server
docker logs -f authentik-worker

# Verificar secrets disponibles
docker exec authentik-server ls -la /run/secrets/
```
