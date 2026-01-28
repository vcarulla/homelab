# 🚀 SPEEDTEST TRACKER SECRETS
# Auto-generado por Shared Vault Agent
# Generado: {{ timestamp }}
# NO COMMITEAR ESTE ARCHIVO

{{- with secret "secret/data/speedtest-tracker" }}
APP_KEY={{ .Data.data.app_key }}
{{- end }}
