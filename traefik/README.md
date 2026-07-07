# Traefik v3 - Reverse Proxy del Homelab

Este proyecto despliega **Traefik v3** como proxy inverso en Docker Compose. A diferencia del setup clásico con ACME, aquí los **certificados TLS vienen de Vault** (renderizados por el Shared Vault Agent a un tmpfs compartido) y el acceso a la API de Docker pasa por **socket-proxy**, nunca montando `docker.sock` directamente.

---

## Estructura del repositorio

```
traefik/
├── config/
│   ├── traefik.yml        # Configuración estática
│   ├── middlewares.yml    # Middlewares dinámicos (auth-basic, rate-limit, internal-access, authentik-forward-auth, security-headers...)
│   ├── tls.yml            # Certificados desde el tmpfs de Vault Agent
│   ├── traefik-api.yml    # Config dinámica adicional
│   └── *.yml              # Routers file-provider para hosts externos (proxmox, homeassistant, pulse, openclaw, n8n...)
├── logs/                  # Access logs (volumen traefik_logs)
└── docker-compose.yml     # Definición del servicio Traefik
```

El file provider observa `/etc/traefik` (`watch: true`): los cambios en los `.yml` dinámicos se recargan solos. Los cambios en **labels Docker** requieren `docker compose down && up -d`.

---

## Certificados TLS (sin ACME)

No hay `certificatesResolvers` activos. El flujo es:

1. Los certificados viven en Vault (`secret/certificates/...`).
2. El Shared Vault Agent los renderiza al tmpfs compartido (`/vault/secrets/certs/`).
3. Traefik monta ese tmpfs **read-only** y los carga vía `config/tls.yml`:

```yaml
tls:
  options:
    default:
      minVersion: VersionTLS12
      sniStrict: true
  certificates:
    - certFile: /vault/secrets/certs/fullchain.crt
      keyFile: /vault/secrets/certs/server.key
  stores:
    default:
      defaultCertificate:
        certFile: /vault/secrets/certs/fullchain.crt
        keyFile: /vault/secrets/certs/server.key
```

- **TLS mínimo 1.2** + `sniStrict: true`.
- Los certificados nunca tocan disco: viven en memoria (tmpfs).

Para rotar certificados: actualizar el secret en Vault, el agente re-renderiza; luego `cd traefik && docker compose down && docker compose up -d`.

---

## Configuración estática (`config/traefik.yml`)

Puntos clave (leer el archivo para el detalle completo):

```yaml
log:
  level: INFO
  format: json

accesslog:
  filePath: "/var/log/traefik/access.log"
  format: json
  filters:
    statusCodes: ["400-499", "500-599"]   # solo errores

api:
  dashboard: true
  insecure: false        # dashboard SOLO via router HTTPS con middlewares

entryPoints:
  web:                   # :80 → redirect a websecure
  websecure:             # :443
  metrics:               # :9090, NO publicado al host

providers:
  docker:
    endpoint: "tcp://socket-proxy:2375"   # API Docker via socket-proxy
    exposedByDefault: false
    network: frontend
  file:
    directory: /etc/traefik
    watch: true

ping:
  entryPoint: metrics    # /ping fuera del entrypoint público

metrics:
  prometheus:
    entryPoint: metrics
```

- **`api.insecure: false`**: no hay puerto 8080. El dashboard se sirve por HTTPS (ver abajo).
- **`ping` en `metrics` (:9090)**: el healthcheck del contenedor (`traefik healthcheck --ping`) no pasa por el redirect 308 de web→websecure. El puerto 9090 no está publicado al host.
- **socket-proxy**: Traefik habla con la API de Docker por TCP contra `socket-proxy:2375` (red backend), con permisos mínimos.

---

## Dashboard

El dashboard va detrás de HTTPS con cadena de middlewares, definido por labels en `docker-compose.yml`:

```yaml
- "traefik.http.routers.dashboard.rule=Host(`traefik.${DOMAIN_ICARUS}`) && (PathPrefix(`/api`) || PathPrefix(`/dashboard`))"
- "traefik.http.routers.dashboard.entrypoints=websecure"
- "traefik.http.routers.dashboard.tls=true"
- "traefik.http.routers.dashboard.middlewares=internal-access@file,rate-limit@file,auth-basic@file,security-headers@file"
- "traefik.http.routers.dashboard.service=api@internal"
```

Middlewares aplicados (definidos en `config/middlewares.yml`):

| Middleware | Función |
|---|---|
| `internal-access@file` | Whitelist de IPs internas |
| `rate-limit@file` | Rate limiting |
| `auth-basic@file` | Basic auth (credenciales desde Vault) |
| `security-headers@file` | Headers de seguridad HTTP |

Acceso: `https://traefik.${DOMAIN_ICARUS}/dashboard/` (solo desde red interna).

> `security-headers@file` se aplica **por router**, no globalmente en el entrypoint (permite excepciones como OpenClaw sin frameDeny).

---

## Hardening del contenedor

Del `docker-compose.yml`:

- `read_only: true` + tmpfs en `/tmp`
- `cap_drop: ALL` + solo `NET_BIND_SERVICE` (puertos 80/443)
- `no-new-privileges:true`
- Límites de recursos (1 CPU / 512M)
- Certificados montados `:ro` desde el volumen externo `shared-vault-agent_vault_secrets_tmpfs`

---

## Despliegue y comprobación

```bash
# Prerequisitos: redes frontend/backend, vault + shared-vault-agent corriendo
docker network create frontend
docker network create backend

cd traefik && docker compose --env-file ../.env up -d

# Logs
docker logs -f traefik

# Verificar que los certificados están en el tmpfs
docker exec traefik ls -la /vault/secrets/certs/
```

Ante cambios en labels o middlewares: **siempre `down && up -d`**, nunca `restart`.

---

## Flujo de enrutamiento

```text
[Cliente]
   |
   v  (80 → redirect 443)
[Traefik :443]  ← certificados desde /vault/secrets/certs (tmpfs de Vault Agent)
   |
   +--> servicios Docker en red 'frontend' (labels, via socket-proxy)
   +--> hosts externos via file provider (proxmox, homeassistant, pulse, ...)
   +--> forward-auth a Authentik (authentik-forward-auth@file) donde aplica
```
