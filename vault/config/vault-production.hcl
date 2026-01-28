# HashiCorp Vault - Configuración de Producción
# Para homelab con persistencia y seguridad mejorada

# Storage persistente en filesystem
storage "file" {
  path = "/vault/data"
}

# Listener HTTP (TLS manejado por Traefik)
listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_disable   = true  # Traefik maneja TLS
}

# Configuración de UI
ui = true

# Configuración de logging
log_level = "INFO"
log_format = "json"

# Configuración de API y cluster
api_addr = "http://0.0.0.0:8200"
cluster_addr = "http://127.0.0.1:8201"

# TTL para tokens
default_lease_ttl = "168h"    # 7 días
max_lease_ttl = "720h"        # 30 días

# Configuración de PID
pid_file = "/vault/vault.pid"

# Configuración de telemetría (opcional)
telemetry {
  prometheus_retention_time = "30s"
  disable_hostname = true
}