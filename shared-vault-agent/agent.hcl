# 🏠 SHARED VAULT AGENT CONFIGURATION
# Configuración consolidada para todos los servicios del homelab
# Creado: 2025-09-09

pid_file = "/tmp/pidfile"

# Vault server configuration
vault {
  address = "http://vault:8200"
  retry {
    num_retries = 7
  }
}

# Auto-authentication using AppRole
# Credenciales se escriben a /tmp desde variables de entorno (ver docker-compose entrypoint)
auto_auth {
  method "approle" {
    mount_path = "auth/approle"
    config = {
      role_id_file_path   = "/tmp/role-id"
      secret_id_file_path = "/tmp/secret-id"
      remove_secret_id_file_after_reading = false
    }
  }
  
  # Token sink en /tmp (tmpfs privado del agente, lo usa solo el healthcheck).
  # NO en /vault/secrets: ese tmpfs lo montan todos los servicios y el token
  # tiene la homelab-policy completa.
  sink "file" {
    config = {
      path = "/tmp/token"
      mode = 0600
    }
  }
}

# Si una key no existe en Vault, fallar en vez de renderizar string vacío
template_config {
  error_on_missing_key = true
}

# Template for Linkding service  
template {
  source      = "/vault/config/templates/linkding.tpl"
  destination = "/vault/secrets/linkding.env"
  perms       = 0600
  command     = "echo '[$(date)] 🔗 Linkding secrets updated by Shared Vault Agent'"
}

# Template for Portainer service
template {
  source      = "/vault/config/templates/portainer.tpl"
  destination = "/vault/secrets/portainer.env"
  perms       = 0600
  command     = "echo '[$(date)] 🐳 Portainer secrets updated by Shared Vault Agent'"
}

# Template for Traefik service
template {
  source      = "/vault/config/templates/traefik.tpl"
  destination = "/vault/secrets/traefik.env"
  perms       = 0600
  command     = "echo '[$(date)] 🌐 Traefik secrets updated by Shared Vault Agent'"
}

# Template for SSL Certificates (with decoder)
template {
  source      = "/vault/config/templates/certificates-decoded.tpl"  
  destination = "/vault/secrets/certificates-setup.sh"
  perms       = 0700
  command     = "sh /vault/secrets/certificates-setup.sh && sh /vault/secrets/decode-certs.sh && echo '[$(date)] 🔐 SSL certificates decoded by Shared Vault Agent'"
}

# Template for Traefik Middlewares (auth credentials)
template {
  source      = "/vault/config/templates/middlewares.tpl"
  destination = "/vault/secrets/middlewares-setup.sh"
  perms       = 0700
  command     = "sh /vault/secrets/middlewares-setup.sh && echo '[$(date)] 🔐 Traefik middlewares updated by Shared Vault Agent'"
}

# Template for Glance dashboard service
template {
  source      = "/vault/config/templates/glance.tpl"
  destination = "/vault/secrets/glance.env"
  perms       = 0600
  command     = "echo '[$(date)] 🔭 Glance secrets updated by Shared Vault Agent'"
}

# Template for PostgreSQL service
template {
  source      = "/vault/config/templates/postgres.tpl"
  destination = "/vault/secrets/postgres.env"
  perms       = 0600
  command     = "echo '[$(date)] PostgreSQL secrets updated by Shared Vault Agent'"
}

# Template for Authentik service
template {
  source      = "/vault/config/templates/authentik.tpl"
  destination = "/vault/secrets/authentik.env"
  perms       = 0600
  command     = "echo '[$(date)] Authentik secrets updated by Shared Vault Agent'"
}

# Template for Speedtest Tracker (archivo en disco, no tmpfs - requerido por linuxserver s6)
# Permisos 0644 porque docker-compose lee el env_file como usuario no-root
template {
  source      = "/vault/config/templates/speedtest-tracker.tpl"
  destination = "/vault/speedtest-tracker/secrets.env"
  perms       = 0644
  command     = "echo '[$(date)] 🚀 Speedtest Tracker secrets updated by Shared Vault Agent'"
}