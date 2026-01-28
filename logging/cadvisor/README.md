## Proyecto cAdvisor con Docker Compose

Este proyecto despliega **cAdvisor** (Container Advisor) de Google para monitoreo de contenedores Docker en tiempo real. Proporciona métricas de uso de CPU, memoria, red y almacenamiento de todos los contenedores del sistema.

---

### Estructura del repositorio

```bash
├── docker-compose.yml       # Definición del servicio cAdvisor
```

---

### Configuración

**Descripción de componentes:**

* **`image`**: última versión de cAdvisor desde Google Container Registry
* **`ports`**: expone la interfaz web en puerto 8081 del host
* **`volumes`**: montajes esenciales para monitoreo:
  * **`/:/rootfs:ro`**: acceso de solo lectura al sistema de archivos raíz
  * **`/var/run:/var/run:ro`**: acceso a sockets y PIDs del sistema
  * **`/sys:/sys:ro`**: acceso al sistema de archivos virtual del kernel
  * **`/var/lib/docker/:/var/lib/docker:ro`**: acceso a metadatos de Docker
* **`networks`**: conectado a ambas redes para monitoreo completo
* **`pid: host`**: necesario para ver procesos del host

---

## Despliegue y configuración

1. Crear las redes necesarias si no existen:

   ```bash
   docker network create frontend
   docker network create backend
   ```

2. Levantar cAdvisor:

   ```bash
   docker-compose up -d
   ```

3. Verificar el estado del contenedor:

   ```bash
   docker ps | grep cadvisor
   ```

4. Acceder a la interfaz web:
   - URL: http://localhost:8081

---

### Métricas disponibles

cAdvisor proporciona las siguientes métricas:

* **CPU**: uso por contenedor y total del sistema
* **Memoria**: consumo, límites y swap
* **Red**: tráfico de entrada/salida por interfaz
* **Almacenamiento**: uso de disco por contenedor
* **Procesos**: número de procesos y threads

### Endpoints importantes

* **`/`**: Interfaz web principal
* **`/metrics`**: Métricas en formato Prometheus
* **`/api/v1.3/docker/`**: API REST para consultas programáticas

---

### Integración con sistemas de monitoreo

**Prometheus**:
```yaml
scrape_configs:
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
```

**Grafana**: Importar dashboard ID 893 (Docker Dashboard for cAdvisor)

---

### Flujo de monitoreo

```text
[Docker Containers] --> [cAdvisor] --> [Métricas]
                                         |
                                         +--> [Interfaz Web :8081]
                                         +--> [Prometheus /metrics]
                                         +--> [API REST /api/*]
```
