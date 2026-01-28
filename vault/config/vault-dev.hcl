# HashiCorp Vault - Configuración de Desarrollo
# Para uso en homelab durante testing y validación inicial

# Storage en archivo (persistente)
storage "file" {
  path = "/vault/data"
}

# Listener HTTP (TLS manejado por Traefik)
listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_disable   = true
}

# Configuración de UI
ui = true

# Configuración de logging
log_level = "INFO"
log_format = "json"

# Configuración de API
api_addr = "http://0.0.0.0:8200"

# TTL por defecto para tokens
default_lease_ttl = "168h"    # 7 días
max_lease_ttl = "720h"        # 30 días

# Configuración de cluster (single node)
cluster_addr = "http://127.0.0.1:8201"

# Configuración de PID
pid_file = "/vault/vault.pid"