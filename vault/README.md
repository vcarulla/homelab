# HashiCorp Vault - Gestión Centralizada de Secrets

Este proyecto despliega **HashiCorp Vault** como solución centralizada de gestión de secrets para el homelab.

---

## ¿Qué es Vault y para qué sirve?

**HashiCorp Vault** es una herramienta de gestión de secrets que permite:

- **Almacenamiento seguro**: Cifrado de secrets en reposo y en tránsito
- **Acceso controlado**: Políticas granulares de autorización
- **Rotación automática**: TTL configurable para tokens y credenciales
- **Auditoría completa**: Logs detallados de todos los accesos
- **Integración nativa**: APIs REST para automatización

**Casos de uso en el homelab:**
- Gestión centralizada de API tokens
- Almacenamiento seguro de credenciales de servicios
- Rotación automática de tokens con TTL
- Auditoría de accesos a secrets sensibles

---

## Estructura del repositorio

```bash
vault/
├── docker-compose.yml          # Servicio Vault en Docker
├── README.md                   # Esta documentación
├── config/
│   ├── vault.hcl              # Configuración de Vault
│   ├── homelab-policy.hcl     # Política para servicios
│   └── admin-policy.hcl       # Política de administrador
└── data/                      # Datos persistentes (auto-creado)
```

---

## Configuración

Ver `examples/vault/docker-compose.yml` para una plantilla de configuración.

### Archivo de configuración `vault.hcl`

```hcl
storage "file" {
  path = "/vault/data"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_disable   = "true"  # Traefik maneja TLS
}

ui = true
log_level = "INFO"
log_format = "json"

default_lease_ttl = "168h"
max_lease_ttl = "720h"
```

---

## Despliegue

```bash
# Crear las redes necesarias
docker network create frontend
docker network create backend

# Levantar Vault
docker compose up -d

# Verificar estado
docker logs vault
```

---

## Comandos útiles

### Operaciones básicas

```bash
# Verificar estado de Vault
docker exec vault vault status

# Listar secrets
docker exec vault vault kv list secret/

# Leer secret específico
docker exec vault vault kv get secret/myservice

# Escribir nuevo secret
docker exec vault vault kv put secret/nuevo-servicio \
  api_key="valor_secreto" \
  username="usuario"
```

### Gestión de tokens

```bash
# Listar tokens activos
docker exec vault vault list auth/token/accessors

# Renovar token
docker exec vault vault token renew $TOKEN

# Crear token con política específica
docker exec vault vault write auth/token/create \
  policies="myservice-policy" \
  ttl="168h" \
  display_name="nuevo-servicio"
```

### Gestión de políticas

```bash
# Listar políticas
docker exec vault vault policy list

# Leer política específica
docker exec vault vault policy read myservice-policy
```

---

## Seguridad y Buenas Prácticas

1. **Nunca commitear** el token de root o unseal keys
2. **Usar políticas granulares** para cada servicio
3. **Configurar TTL** apropiados para tokens
4. **Habilitar auditoría** para tracking de accesos
5. **Backup regular** de los datos de Vault

---

## Integración con Vault Agent

Para integración automática de secrets con servicios, ver la configuración en `shared-vault-agent/`.

El Vault Agent patrón sidecar permite:
- Autenticación automática con AppRole
- Renderizado de templates con secrets
- Rotación automática de credenciales
- Secrets en memoria (tmpfs) sin persistir en disco
