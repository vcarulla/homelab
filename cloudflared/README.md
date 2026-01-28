## Proyecto Cloudflared Tunnel con Docker Compose

Este proyecto despliega un **Cloudflare Tunnel** (`cloudflared`) en Docker Compose para exponer servicios internos de forma segura mediante la infraestructura de Cloudflare. Incluye configuración de variables de entorno (.env) y red de Docker.

---

### Estructura del repositorio

```bash
├── .env                    # Variables de entorno (TUNNEL_TOKEN)
├── docker-compose.yml      # Definición del servicio cloudflared
```

---

### 1. Archivo `.env`

Definir las variables sensibles que no se deben versionar en el repositorio:

```dotenv
# Token de túnel generado en Cloudflare
TUNNEL_TOKEN=tu_token_de_tunel_aqui
```

> **Importante**: nunca compartir este archivo públicamente. Agregar `.env` a tu `.gitignore` para mantener la seguridad.

---

### 2. `docker-compose.yml`

Describe el servicio `cloudflaredtunnel`:

```yaml
version: '3.8'
services:
  cloudflaredtunnel:
    container_name: cloudflaredtunnel
    image: cloudflare/cloudflared:2025.4.2
    env_file:       # carga variables de .env
      - ./.env
    environment:
      - TUNNEL_TOKEN=${TUNNEL_TOKEN}
    command: tunnel --no-autoupdate run --token ${TUNNEL_TOKEN}
    networks:
      - frontend    # red para tráfico HTTP/HTTPS
      - backend     # red con servicios internos
    restart: unless-stopped

networks:
  frontend:
    external: true
  backend:
    external: true
```

**Explicación de secciones**:

* `image`: versión específica de `cloudflared` para mayor estabilidad.
* `env_file` y `environment`: carga del token de túnel desde `.env`.
* `command`: ejecuta el túnel sin actualizaciones automáticas.
* `networks`: conecta el túnel tanto a la red expuesta (`frontend`) como a la red interna (`backend`).
* `restart`: mantiene el contenedor activo ante fallos.

---

## Despliegue y uso

1. **Cloudflare Zero Trust**: acceder al panel de Cloudflare Zero Trust → **Networks** → **Tunnels**, hacer clic en **Create tunnel**, seguir el asistente y copia el **Tunnel Token**. 🔑

2. Generar el túnel en el panel de Cloudflare y copiar el **Tunnel Token**.

3. Crear el archivo `.env` en la raíz del proyecto y agregar:

   ```dotenv
   TUNNEL_TOKEN=tu_token_de_tunel_aqui
   ```

4. Asegúrase de que las redes `frontend` y `backend` existan en Docker:

   ```bash
   docker network create frontend
   docker network create backend
   ```

5. Levantar el servicio:

   ```bash
   docker-compose up -d
   ```

6. Verificar el estado del túnel:

   ```bash
   docker logs -f cloudflaredtunnel
   ```

Una vez en ejecución, **Cloudflare Tunnel** enruta el tráfico externo a los servicios internos a través del túnel seguro, sin exponer puertos directamente.

---

### Diagrama de flujo

```text
[Internet] ⇄ Cloudflare Edge ⇄ tunnel.cloudflared
                         ↕
                     Docker
                ┌────────────┐
                │  frontend  │
                │  backend   │
                └────────────┘
```
