## Proyecto Loki con Docker Compose

Este proyecto despliega **Loki** usando Docker Compose e integración con Traefik.

---

### ¿Qué es Loki y para qué sirve?

**Loki** es un sistema de almacenamiento y consulta de logs desarrollado por Grafana Labs, diseñado específicamente para ser eficiente, escalable y fácil de integrar con otros sistemas de monitoreo como Prometheus y Grafana.

A diferencia de otros sistemas de logs, Loki indexa solo las etiquetas (labels) de los logs y no el contenido completo, lo que permite almacenar grandes volúmenes de logs de manera económica y rápida.

Loki es ideal para:
- Centralizar los logs de múltiples servicios y contenedores Docker
- Consultar y analizar logs históricos desde una interfaz web (Grafana) o mediante su API
- Correlacionar eventos de logs con métricas de Prometheus para un monitoreo integral
- Mantener un stack de observabilidad moderno, eficiente y fácil de mantener

---

### Estructura del repositorio

```bash
├── docker-compose.yml   # Definición del servicio Loki
└── config/
    └── config.yml       # Configuración de Loki
```

---

### Configuración

Ver `config/config.yml` para la configuración de Loki.

**Componentes principales:**
- **Image**: grafana/loki
- **Port**: 3100
- **Volumes**: data_loki para persistencia
- **Networks**: frontend y backend

---

### ¿Cómo se usa Loki en este stack?

- Los logs de los contenedores Docker se recolectan mediante **Promtail** (otro servicio del stack), que los envía a Loki
- Desde **Grafana** puedes consultar, filtrar y visualizar los logs almacenados en Loki, correlacionando eventos con métricas y alertas
- Loki puede integrarse con alertas y dashboards personalizados para una observabilidad avanzada
