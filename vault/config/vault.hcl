# vault/config/vault.hcl
# Configuración de producción para Vault

# Configuración de storage (filesystem para homelab)
storage "file" {
  path = "/vault/data"
}

# Listener HTTPS (con certificados de Traefik)
listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_disable   = "true"  # Traefik maneja TLS
  # Para TLS directo (opcional):
  # tls_cert_file = "/vault/certs/vault.crt"
  # tls_key_file  = "/vault/certs/vault.key"
}

# Configuración del cluster (single node para homelab)
cluster_addr  = "http://127.0.0.1:8201"
api_addr      = "http://127.0.0.1:8200"

# Configuración de UI
ui = true

# Configuración de logging
log_level = "INFO"
log_format = "json"

# Configuración de telemetría (opcional)
telemetry {
  prometheus_retention_time = "30s"
  disable_hostname = true
}

# Configuración de timeouts
default_lease_ttl = "168h"    # 7 días
max_lease_ttl = "720h"        # 30 días

# Configuración de PID file
pid_file = "/vault/vault.pid"

# Configuración de plugins (homelab básico)
plugin_directory = "/vault/plugins"