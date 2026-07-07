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
# api_addr es la URL que se anuncia a los clientes (no un bind): debe ser alcanzable
api_addr = "http://vault:8200"
cluster_addr = "http://127.0.0.1:8201"

# TTL para tokens
default_lease_ttl = "168h"    # 7 días
max_lease_ttl = "720h"        # 30 días

# Configuración de PID (en /tmp: el rootfs es read_only, /tmp es tmpfs)
pid_file = "/tmp/vault.pid"

# Configuración de telemetría (opcional)
telemetry {
  prometheus_retention_time = "30s"
  disable_hostname = true
}