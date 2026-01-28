## Proyecto Socket Proxy con Docker Compose 🔒

Este proyecto despliega **Docker Socket Proxy v0.3.0** usando tecnativa/docker-socket-proxy como capa de seguridad entre Traefik y el socket de Docker. Proporciona acceso controlado y de solo lectura al daemon de Docker para service discovery.

---

### Estructura del repositorio 📁

```bash
├── docker-compose.yml       # Definición del servicio Socket Proxy
```

---

### 1. `docker-compose.yml`

```yaml
services:
  socket-proxy:
    container_name: socket-proxy
    image: tecnativa/docker-socket-proxy:0.3.0
    environment:
      # --- PERMISOS DE SOLO LECTURA ---
      # 1 = Habilitado, 0 = Deshabilitado (por defecto)
      # Habilitar acceso a eventos de Docker (necesario para service discovery)
      - EVENTS=1
      # Habilitar acceso para listar contenedores (necesario para service discovery)
      - CONTAINERS=1
      # Habilitar acceso a la info general del sistema
      - INFO=1
      # Habilitar acceso al ping (usado por muchos servicios para ver si está vivo)
      - PING=1
      # Habilitar acceso a la versión de Docker
      - VERSION=1
      # Habilitar acceso a las redes de Docker (necesario para service discovery)
      - NETWORKS=1
      # --- VERIFICACIÓN DE SEGURIDAD ---
      # Asegurarse de que todas las demás llamadas (crear, borrar, ejecutar) están deshabilitadas.
      # La imagen lo hace por defecto, pero ser explícito no está de más.
      - POST=0 # Bloquea la mayoría de las acciones de escritura
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - backend
    healthcheck:
      test: ["CMD-SHELL", "pgrep haproxy || exit 1"]
      interval: 1m
      timeout: 10s
      retries: 3
      start_period: 30s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
        labels: "service={{.Name}}"
    restart: unless-stopped

networks:
  backend:
    external: true
```

**Descripción de componentes:**

* **`image`**: versión 0.3.0 del proxy de socket de Docker de Tecnativa.
* **`environment`**: configuración granular de permisos:
  * **EVENTS=1**: permite escuchar eventos de Docker para service discovery.
  * **CONTAINERS=1**: permite listar contenedores.
  * **INFO/PING/VERSION=1**: información básica del sistema.
  * **NETWORKS=1**: acceso a redes de Docker.
  * **POST=0**: bloquea operaciones de escritura explícitamente.
* **`volumes`**: monta el socket Docker en modo solo lectura.
* **`networks`**: conectado a la red `backend` para comunicación interna.
* **`healthcheck`**: verifica que HAProxy esté funcionando.

---

## Despliegue y configuración 🚀

1. Crear la red `backend` si no existe:

   ```bash
   docker network create backend
   ```

2. Levantar Socket Proxy:

   ```bash
   docker-compose up -d
   ```

3. Verificar el estado del contenedor:

   ```bash
   docker ps | grep socket-proxy
   ```

4. Comprobar logs para verificar funcionamiento:

   ```bash
   docker logs -f socket-proxy
   ```

---

### Integración con Traefik

Para usar Socket Proxy con Traefik, modificar la configuración de Traefik para usar el proxy en lugar del socket directo:

```yaml
# En docker-compose.yml de Traefik, cambiar:
# - /var/run/docker.sock:/var/run/docker.sock:ro

# Por una conexión TCP al socket-proxy:
environment:
  - DOCKER_HOST=tcp://socket-proxy:2375
```

Y en `traefik.yml`:

```yaml
providers:
  docker:
    endpoint: "tcp://socket-proxy:2375"
    exposedByDefault: false
    network: frontend
```

---

### Flujo de seguridad

```text
[Traefik] --TCP:2375--> [Socket Proxy] --socket:ro--> [Docker Daemon]
                           |
                           +--> Filtra solo operaciones de lectura
                           +--> Bloquea comandos destructivos
                           +--> Logs de auditoría
```

**Beneficios de seguridad:**
- Acceso granular al socket de Docker
- Previene operaciones destructivas accidentales
- Auditoría de accesos al daemon
- Aislamiento de red entre frontend y backend