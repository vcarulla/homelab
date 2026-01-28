# HashiCorp Vault - Production Configuration
# Copy to: vault/config/vault-production.hcl

# Persistent storage on filesystem
storage "file" {
  path = "/vault/data"
}

# HTTP Listener (TLS handled by Traefik)
listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_disable   = true  # Traefik handles TLS termination
}

# UI configuration
ui = true

# Logging configuration
log_level = "INFO"
log_format = "json"

# API and cluster configuration
api_addr = "http://0.0.0.0:8200"
cluster_addr = "http://127.0.0.1:8201"

# Token TTL
default_lease_ttl = "168h"    # 7 days
max_lease_ttl = "720h"        # 30 days

# PID file
pid_file = "/vault/vault.pid"

# Telemetry (optional - for Prometheus)
telemetry {
  prometheus_retention_time = "30s"
  disable_hostname = true
}
