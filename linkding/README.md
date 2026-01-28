## Proyecto Linkding con Traefik y Docker Compose

Este proyecto despliega **Linkding** como gestor de marcadores autoalojado, integrado con Traefik para HTTPS automático.

---

### Estructura del repositorio

```bash
├── .env                     # Variables de entorno de configuración
├── docker-compose.yml       # Definición del servicio Linkding
└── data/                    # Directorio de datos persistentes
```

---

### 1. Archivo `.env`

Variables de configuración para Linkding:

```dotenv
# Configuración del contenedor
LD_CONTAINER_NAME=linkding
LD_HOST_DATA_DIR=./data

# Configuración de la aplicación
LD_SUPERUSER_NAME=admin
LD_SUPERUSER_PASSWORD=your_secure_password
LD_DEBUG=False
LD_DB_ENGINE=django.db.backends.sqlite3
LD_DISABLE_BACKGROUND_TASKS=False
LD_DISABLE_URL_VALIDATION=False
```

> **Importante:** No versionar este archivo. Añadir a `.gitignore`.

---

### 2. `docker-compose.yml`

Ver `examples/linkding/docker-compose.yml` para una plantilla de configuración.

**Descripción de componentes:**

* **`image`**: Linkding official image
* **`environment`**: configuración de zona horaria
* **`volumes`**: persistencia de datos en directorio local
* **`env_file`**: carga variables de configuración desde `.env`
* **`labels`**: configuración de Traefik para routing y TLS

---

## Despliegue y configuración

1. Configurar variables en `.env`:

   ```bash
   cp .env.example .env
   # Editar .env con tus valores
   ```

2. Crear la red `frontend` si no existe:

   ```bash
   docker network create frontend
   ```

3. Crear directorio de datos:

   ```bash
   mkdir -p ./data
   ```

4. Levantar Linkding:

   ```bash
   docker-compose up -d
   ```

5. Verificar el estado del contenedor:

   ```bash
   docker ps | grep linkding
   ```

---

### Configuración adicional

**Importar bookmarks existentes:**
```bash
docker exec -it linkding python manage.py import_bookmarks /path/to/bookmarks.html
```

**Crear usuario adicional:**
```bash
docker exec -it linkding python manage.py createsuperuser
```

**Backup de datos:**
```bash
docker exec linkding python manage.py export_bookmarks > bookmarks_backup.html
tar -czf linkding_backup_$(date +%Y%m%d).tar.gz ./data/
```

---

### Características principales

* **Gestión de bookmarks**: Agregar, editar, eliminar y organizar marcadores
* **Etiquetas**: Sistema de etiquetado flexible
* **Búsqueda**: Búsqueda full-text en títulos, URLs y descripciones
* **API REST**: Para integración con otras aplicaciones
* **Importación/Exportación**: Compatible con formatos estándar
* **Archivado**: Opcional snapshot de páginas web
* **Bookmarklet**: Para agregar marcadores desde el navegador

---

### Flujo de funcionamiento

```text
[Usuario] --HTTPS--> [Traefik] --HTTP--> [Linkding:9090]
                                              |
                                              v
                                         [SQLite DB]
                                         [/data/]
```
