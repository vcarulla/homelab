# Vault Policy for mediacli services
# Read-only access to mediacli secrets

# Allow reading all mediacli secrets
path "secret/data/mediacli/*" {
  capabilities = ["read", "list"]
}

# Allow listing mediacli secret paths
path "secret/metadata/mediacli/*" {
  capabilities = ["read", "list"]
}

# Allow token renewal
path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Allow token lookup
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
