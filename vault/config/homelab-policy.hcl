# 🏠 HOMELAB CONSOLIDATED POLICY
# Política unificada para todos los servicios del homelab via Shared Vault Agent
# Creado: 2025-09-09

# Linkding service secrets
path "secret/data/linkding" {
  capabilities = ["read"]
}
path "secret/metadata/linkding" {
  capabilities = ["read"]
}

# Portainer service secrets
path "secret/data/portainer" {
  capabilities = ["read"]
}
path "secret/metadata/portainer" {
  capabilities = ["read"]
}

# Traefik service secrets
path "secret/data/traefik" {
  capabilities = ["read"]
}
path "secret/metadata/traefik" {
  capabilities = ["read"]
}

# Glance dashboard secrets
path "secret/data/glance" {
  capabilities = ["read"]
}
path "secret/metadata/glance" {
  capabilities = ["read"]
}

# Speedtest Tracker secrets
path "secret/data/speedtest-tracker" {
  capabilities = ["read"]
}
path "secret/metadata/speedtest-tracker" {
  capabilities = ["read"]
}

# PostgreSQL secrets
path "secret/data/postgres" {
  capabilities = ["read"]
}
path "secret/metadata/postgres" {
  capabilities = ["read"]
}

# Authentik secrets
path "secret/data/authentik" {
  capabilities = ["read"]
}
path "secret/metadata/authentik" {
  capabilities = ["read"]
}

# Token renewal capabilities (required for auto-renewal)
path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Token lookup (for health checks)
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

# Certificate access for SSL/TLS
path "secret/data/certificates/*" {
  capabilities = ["read"]
}
path "secret/metadata/certificates/*" {
  capabilities = ["read"]
}
