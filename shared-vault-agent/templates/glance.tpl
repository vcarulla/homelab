# 🔭 GLANCE SERVICE SECRETS
# Auto-generado por Shared Vault Agent - 🔄 Rotación automática
# Generado: {{ timestamp }}

{{- with secret "secret/data/glance" }}
# Variables de Glance desde Vault
{{- range $key, $value := .Data.data }}
{{ $key }}={{ $value }}
{{- end }}

# Metadatos del Shared Vault Agent
VAULT_AGENT_SERVICE=glance
VAULT_AGENT_GENERATED=true
VAULT_AGENT_TIMESTAMP={{ timestamp }}
VAULT_AGENT_TYPE=shared
{{- end }}
