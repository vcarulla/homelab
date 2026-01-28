## Proyecto Node Exporter con Docker Compose 🖥️

Este proyecto despliega **Node Exporter** usando Docker Compose para exponer métricas del sistema operativo del host.

---

### ¿Qué es Node Exporter y para qué sirve?

**Node Exporter** es un agente desarrollado por el equipo de Prometheus que recolecta y expone métricas del sistema operativo, como uso de CPU, memoria, disco, red, procesos y más. Estas métricas pueden ser recolectadas por Prometheus para monitoreo, alertas y análisis de rendimiento.

Node Exporter es ideal para:
- Monitorear el estado y la salud de servidores físicos o virtuales.
- Obtener métricas detalladas del sistema operativo en tiempo real.
- Integrar con Prometheus y Grafana para visualización y alertas.
- Detectar problemas de recursos y planificar capacidad.

---

### Estructura del repositorio 📁

```bash
├── docker-compose.yml   # Definición del servicio Node Exporter
```

---

### 1. `docker-compose.yml`

```yaml
services:
  node_exporter:
    image: quay.io/prometheus/node-exporter:v1.9.1
    container_name: node_exporter
    environment:
      - TZ="America/Argentina/Buenos_Aires"
    volumes:
      - /:/host:ro,rslave
    network_mode: host
    pid: host
    command:
      - --path.rootfs=/host
    restart: unless-stopped
```
