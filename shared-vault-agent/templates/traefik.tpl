# 🌐 TRAEFIK SERVICE SECRETS
# Auto-generado por Shared Vault Agent - 🔄 Rotación automática
# Generado: {{ timestamp }}

{{- with secret "secret/data/traefik" }}
# Variables de Traefik desde Vault  
{{- range $key, $value := .Data.data }}
{{ $key }}={{ $value }}
{{- end }}

# Metadatos del Shared Vault Agent
VAULT_AGENT_SERVICE=traefik
VAULT_AGENT_GENERATED=true
VAULT_AGENT_TIMESTAMP={{ timestamp }}
VAULT_AGENT_TYPE=shared
{{- end }}