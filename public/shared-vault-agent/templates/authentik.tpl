# AUTHENTIK SERVICE SECRETS
# Auto-generado por Shared Vault Agent
# Generado: {{ timestamp }}

{{- with secret "secret/data/authentik" }}
# Authentik core secrets
{{- range $key, $value := .Data.data }}
{{ $key }}={{ $value }}
{{- end }}
{{- end }}

{{- with secret "secret/data/postgres" }}
# PostgreSQL connection (formato Authentik)
AUTHENTIK_POSTGRESQL__USER={{ .Data.data.POSTGRES_USER }}
AUTHENTIK_POSTGRESQL__PASSWORD={{ .Data.data.POSTGRES_PASSWORD }}
AUTHENTIK_POSTGRESQL__NAME={{ .Data.data.POSTGRES_DB }}
{{- end }}

VAULT_AGENT_SERVICE=authentik
VAULT_AGENT_GENERATED=true
VAULT_AGENT_TIMESTAMP={{ timestamp }}
VAULT_AGENT_TYPE=shared
