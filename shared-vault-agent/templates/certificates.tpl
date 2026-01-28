# 🔐 TRAEFIK SSL CERTIFICATES
# Auto-generado por Shared Vault Agent - 🔄 Gestión centralizada
# Generado: {{ timestamp }}

{{- with secret "secret/data/certificates/traefik" }}
# Certificate files content (base64 encoded for safe storage)
TRAEFIK_FULLCHAIN_CERT={{ .Data.data.fullchain | base64Encode }}
TRAEFIK_PRIVATE_KEY={{ .Data.data.private_key | base64Encode }}
TRAEFIK_CA_CERT={{ .Data.data.ca_cert | base64Encode }}

# Certificate metadata
TRAEFIK_CERT_EXPIRES={{ .Data.data.expires }}
TRAEFIK_CERT_ISSUER={{ .Data.data.issuer }}

# Metadatos del Shared Vault Agent
VAULT_AGENT_SERVICE=traefik-certificates
VAULT_AGENT_GENERATED=true
VAULT_AGENT_TIMESTAMP={{ timestamp }}
VAULT_AGENT_TYPE=shared
{{- end }}