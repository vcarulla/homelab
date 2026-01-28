# 🔐 ADMIN POLICY - ADMINISTRATOR PERMISSIONS
# Política para administrador del homelab
# Creado: 2025-09-09

# Full access to secrets engine
path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Manage authentication methods
path "auth/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage policies
path "sys/policies/acl/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List policies
path "sys/policies/acl" {
  capabilities = ["list"]
}

# Manage AppRoles
path "auth/approle/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Manage userpass users
path "auth/userpass/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# System info and health
path "sys/health" {
  capabilities = ["read", "sudo"]
}

path "sys/capabilities-self" {
  capabilities = ["update"]
}

# Token management
path "auth/token/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Mount/unmount engines  
path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List mounts
path "sys/mounts" {
  capabilities = ["read"]
}

# Additional permissions for Web UI
path "sys/auth" {
  capabilities = ["read"]
}

path "sys/auth/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Audit devices
path "sys/audit" {
  capabilities = ["read", "list"]
}

path "sys/audit/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# System configuration
path "sys/config/*" {
  capabilities = ["read", "list"]
}

# Capabilities
path "sys/capabilities" {
  capabilities = ["create", "update"]
}

# Lease management
path "sys/leases/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Namespaces (if using Enterprise)
path "sys/namespaces" {
  capabilities = ["read", "list"]
}

# Seal/unseal status
path "sys/seal-status" {
  capabilities = ["read"]
}

# Key status
path "sys/key-status" {
  capabilities = ["read"]
}

# Leader status  
path "sys/leader" {
  capabilities = ["read"]
}

# Metrics
path "sys/metrics" {
  capabilities = ["read"]
}

# Internal UI paths
path "sys/internal/ui/mounts" {
  capabilities = ["read"]
}

path "sys/internal/ui/mounts/*" {
  capabilities = ["read"]
}