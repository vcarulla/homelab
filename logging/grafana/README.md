## Proyecto Grafana con Docker Compose

Este proyecto despliega **Grafana** usando Docker Compose e integración con Traefik.

---

### ¿Qué es Grafana y para qué sirve?

**Grafana** es una plataforma de visualización y análisis de métricas y datos de series temporales. Permite crear dashboards interactivos para monitorear el estado y el rendimiento de sistemas, aplicaciones y servicios, integrándose fácilmente con Prometheus, Loki, y muchas otras fuentes de datos.

Grafana es ideal para:
- Visualizar métricas y logs de diferentes fuentes en un solo lugar
- Crear paneles personalizados y alertas para monitoreo proactivo
- Correlacionar eventos y métricas para análisis avanzados
- Compartir dashboards interactivos con tu equipo

---

### Estructura del repositorio

```bash
├── docker-compose.yml   # Definición del servicio Grafana
```

---

### Configuración

Ver `examples/` para plantillas de configuración con Traefik.

**Componentes principales:**
- **Image**: grafana/grafana
- **Port**: 3000
- **Volumes**: grafana_data para persistencia
- **Networks**: frontend para acceso via Traefik

---

### Despliegue

```bash
docker network create frontend
docker-compose up -d
```

### Acceso

- Puerto directo: http://localhost:3000
- Via Traefik: configurar router con tu dominio

### Credenciales por defecto

- Usuario: admin
- Password: admin (cambiar en primer login)
