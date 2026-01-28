## Proyecto Portainer CE con Traefik y Docker Compose

Este proyecto despliega **Portainer CE** en Docker Compose, protegido por Traefik con HTTPS.

---

### Estructura del repositorio

```bash
├── docker-compose.yml       # Definición del servicio Portainer
└── volumes
    └── portainer_data       # Persistencia de datos de Portainer
```

---

### 1. `docker-compose.yml`

Ver `examples/portainer/docker-compose.yml` para una plantilla de configuración.

**Descripción de componentes:**

* **`image`**: Portainer CE official image
* **`ports`**: expone el contenedor en el puerto 9000 para acceso directo (opcional)
* **`volumes`**: monta el socket Docker para administrar contenedores y persiste la configuración
* **`labels`**: configuración de Traefik para routing y TLS

---

## Despliegue y pruebas

1. Asegurarse de que **Traefik** esté en ejecución y conectado a la red `frontend`.
2. Crear la red `frontend` si no existe:

   ```bash
   docker network create frontend
   ```
3. Levantar Portainer:

   ```bash
   docker-compose up -d
   ```
4. Verificar el estado del contenedor:

   ```bash
   docker ps | grep portainer
   ```

---

### Flujo de enrutamiento

```text
[Cliente] -- HTTPS --> [Traefik] --portainer--> [Portainer (9000)]
```
