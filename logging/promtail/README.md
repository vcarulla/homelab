## Proyecto Promtail con Docker Compose 📑

Este proyecto despliega **Promtail** usando Docker Compose para recolectar y enviar logs a Loki.

---

### ¿Qué es Promtail y para qué sirve?

**Promtail** es un agente desarrollado por Grafana Labs que se encarga de recolectar logs de archivos y contenedores, procesarlos y enviarlos a Loki para su almacenamiento y consulta centralizada. Está diseñado para integrarse fácilmente con entornos Docker y Kubernetes.

Promtail es ideal para:
- Centralizar los logs de todos los contenedores y servicios en un solo lugar.
- Enviar logs a Loki para su análisis y visualización en Grafana.
- Filtrar, etiquetar y transformar logs antes de almacenarlos.
- Mantener un stack de observabilidad moderno y eficiente.

---

### Estructura del repositorio 📁

```bash
├── docker-compose.yml         # Definición del servicio Promtail
└── config/
    └── config.yml             # Configuración de Promtail
```

---

### 1. `docker-compose.yml`

```yaml
services:
  promtail:
    image: grafana/promtail:3.5.0
    container_name: promtail
    volumes:
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /var/log:/var/log:ro
      - ./config/config.yml:/etc/promtail/config.yml:ro

    networks:
      - frontend
      - backend
    command:
      - -config.file=/etc/promtail/config.yml
    restart: unless-stopped

networks:
  frontend:
    external: true
  backend:
    external: true
```
