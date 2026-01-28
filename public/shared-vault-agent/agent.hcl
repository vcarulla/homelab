# Shared Vault Agent Configuration
# Copy to: shared-vault-agent/agent.hcl
# This agent fetches secrets from Vault and renders them to tmpfs

pid_file = "/tmp/pidfile"

# Vault server configuration
vault {
  address = "http://vault:8200"
}

# Auto-authentication using AppRole
# Credentials are written to /tmp from environment variables (see docker-compose entrypoint)
auto_auth {
  method "approle" {
    mount_path = "auth/approle"
    config = {
      role_id_file_path   = "/tmp/role-id"
      secret_id_file_path = "/tmp/secret-id"
      remove_secret_id_file_after_reading = false
    }
  }

  # Token sink - where authenticated token is stored
  sink "file" {
    config = {
      path = "/vault/secrets/token"
      mode = 0600
    }
  }
}

# Template for Linkding service
template {
  source      = "/vault/config/templates/linkding.tpl"
  destination = "/vault/secrets/linkding.env"
  perms       = 0600
  command     = "echo '[$(date)] Linkding secrets updated'"
}

# Template for Portainer service
template {
  source      = "/vault/config/templates/portainer.tpl"
  destination = "/vault/secrets/portainer.env"
  perms       = 0600
  command     = "echo '[$(date)] Portainer secrets updated'"
}

# Template for Traefik service
template {
  source      = "/vault/config/templates/traefik.tpl"
  destination = "/vault/secrets/traefik.env"
  perms       = 0600
  command     = "echo '[$(date)] Traefik secrets updated'"
}

# Template for SSL Certificates
template {
  source      = "/vault/config/templates/certificates-decoded.tpl"
  destination = "/vault/secrets/certificates-setup.sh"
  perms       = 0700
  command     = "sh /vault/secrets/certificates-setup.sh && echo '[$(date)] SSL certificates decoded'"
}

# Template for Traefik Middlewares (auth credentials)
template {
  source      = "/vault/config/templates/middlewares.tpl"
  destination = "/vault/secrets/middlewares-setup.sh"
  perms       = 0700
  command     = "sh /vault/secrets/middlewares-setup.sh && echo '[$(date)] Traefik middlewares updated'"
}

# Template for Glance dashboard service
template {
  source      = "/vault/config/templates/glance.tpl"
  destination = "/vault/secrets/glance.env"
  perms       = 0600
  command     = "echo '[$(date)] Glance secrets updated'"
}

# Template for Speedtest Tracker
template {
  source      = "/vault/config/templates/speedtest-tracker.tpl"
  destination = "/vault/speedtest-tracker/secrets.env"
  perms       = 0644
  command     = "echo '[$(date)] Speedtest Tracker secrets updated'"
}
