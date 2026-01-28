## Proyecto Traefik v3.4.0 con Docker Compose 🌊

Este proyecto despliega **Traefik v3.4.0** como proxy inverso en Docker Compose, integrado con DNS de Cloudflare para emitir certificados ACME automáticamente. Ideal para enrutar tráfico HTTP/HTTPS a los servicios internos.

---

### Estructura del repositorio 🗂️

```
├── .env                   # Variables de entorno (Cloudflare API Token)
├── certs                  # Directorio para almacenamiento ACME (cloudflare-acme.json y certs)
├── config
│   └── traefik.yml        # Configuración principal de Traefik
└── docker-compose.yml     # Definición del servicio Traefik
```

---

### 1. Archivo `.env`

Definir las credenciales sensibles para administración de DNS:

```dotenv
# Token de API de Cloudflare con permisos DNS
CLOUDFLARE_DNS_API_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

> **Importante:** No versionar este archivo. Añadir a `.gitignore`.

---

### 2. `docker-compose.yml`

Describe el servicio **traefik**:

```yaml
version: '3.8'
services:
  traefik:
    container_name: traefik
    image: traefik:v3.4.0
    env_file:
      - ./.env
    environment:
      - CF_DNS_API_TOKEN=${CLOUDFLARE_DNS_API_TOKEN}
    ports:
      - 80:80        # HTTP
      - 443:443      # HTTPS
      - 8080:8080    # Dashboard
    volumes:
      - /run/docker.sock:/run/docker.sock:ro    # Acceso a la API de Docker
      - ./config/:/etc/traefik/:ro              # Configuración estática
      - ./certs/:/var/traefik/certs/:rw         # Almacenamiento de certificados
    networks:
      - frontend                                # Red expuesta
    restart: unless-stopped

networks:
  frontend:
    external: true
```

* **env\_file**: carga de variables de entorno.
* **CF\_DNS\_API\_TOKEN**: utilizado por `dnsChallenge`.
* **volumes**: montajes para configuración, certs y acceso a Docker.

---

### 3. `config/traefik.yml` (Configuración estática)

```yaml
# Habilita comprobaciones y logs
global:
  checkNewVersion: true
  sendAnonymousUsage: false
log:
  level: DEBUG

# Panel de control
api:
  dashboard: true
  insecure: true

# EntryPoints para HTTP/HTTPS
entryPoints:
  web:
    address: :80
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
  websecure:
    address: :443

# Emisión de certificados ACME con DNS Challenge
certificatesResolvers:
  cloudflare:
    acme:
      email: YOUR_EMAIL@domain.com
      storage: /var/traefik/certs/cloudflare-acme.json
      caServer: "https://acme-v02.api.letsencrypt.org/directory"
      dnsChallenge:
        provider: cloudflare
        delayBeforeCheck: "30"
        resolvers:
          - "1.1.1.1:53"
          - "8.8.8.8:53"

# Proveedores de rutas
providers:
  docker:
    exposedByDefault: false    # Solo servicios etiquetados
    network: frontend          # Red de descubrimiento
  file:
    directory: /etc/traefik    # Archivos dinámicos si se requieren
    watch: true
```

* **entryPoints**: define redireccionamiento HTTP → HTTPS.
* **certificatesResolvers**: configuración ACME con Cloudflare DNS Challenge.
* **providers**: detecta contenedores Docker en la red `frontend`, y opcionalmente archivos estáticos.

---

## Despliegue y comprobación 🛠️

1. Crear o asegurar la existencia de la red Docker `frontend`:

   ```bash
   docker network create frontend
   ```
2. Copiar el token de Cloudflare en `.env`.
3. Levantar Traefik:

   ```bash
   docker-compose up -d
   ```
4. Verificar los logs:

   ```bash
   docker logs -f traefik
   ```
5. Acceder al **Dashboard** en: http\://\<IP-servidor>:8080/dashboard/

---

### Flujo de enrutamiento

```text
[Internet]
   |
   v  (80/443)
[Traefik]
   |
   +--> servicios en la red 'frontend' según etiquetas y reglas
   |
   +--> ACME (Let's Encrypt) via Cloudflare DNS Challenge → `certs/cloudflare-acme.json`
```
