# POSTGRESQL SERVICE SECRETS
# Auto-generado por Shared Vault Agent
# Generado: {{ timestamp }}

{{- with secret "secret/data/postgres" }}
{{- range $key, $value := .Data.data }}
{{ $key }}={{ $value }}
{{- end }}

VAULT_AGENT_SERVICE=postgres
VAULT_AGENT_GENERATED=true
VAULT_AGENT_TIMESTAMP={{ timestamp }}
VAULT_AGENT_TYPE=shared
{{- end }}
