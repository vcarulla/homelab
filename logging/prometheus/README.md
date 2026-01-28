## Proyecto Prometheus con Docker Compose

Este proyecto despliega **Prometheus** usando Docker Compose e integración con Traefik para monitoreo y recolección de métricas.

---

### ¿Qué es Prometheus y para qué sirve?

**Prometheus** es un sistema de monitoreo y base de datos de series temporales open source, diseñado para recolectar, almacenar y consultar métricas de sistemas, aplicaciones y servicios. Utiliza un modelo de datos basado en etiquetas y un potente lenguaje de consultas (PromQL).

Prometheus es ideal para:
- Monitorear infraestructura, aplicaciones y servicios en tiempo real
- Generar alertas automáticas ante condiciones anómalas
- Almacenar métricas históricas para análisis y capacity planning
- Integrar con Grafana para visualización avanzada de datos

---

### Estructura del repositorio

```bash
├── docker-compose.yml         # Definición del servicio Prometheus
└── config/
    └── prometheus.yml         # Configuración de Prometheus
```

---

### Configuración

Ver `examples/logging/prometheus/config/prometheus.yml` para una plantilla de configuración.

**Componentes principales:**
- **Image**: prom/prometheus
- **Port**: 9090
- **Volumes**: prometheus_data para persistencia, config para configuración
- **Networks**: frontend y backend

---

### Despliegue

```bash
docker network create frontend
docker network create backend
docker-compose up -d
```

### Acceso

- Puerto directo: http://localhost:9090
- Via Traefik: configurar router con tu dominio
