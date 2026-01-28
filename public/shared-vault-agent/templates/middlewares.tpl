# =============================================================================
# TRAEFIK MIDDLEWARES TEMPLATE - VAULT AGENT
# =============================================================================

# 🔐 TRAEFIK MIDDLEWARES CONFIG
# Auto-generado por Shared Vault Agent - 🔄 Rotación automática
# Generado: {{ timestamp }}

{{- with secret "secret/data/traefik" }}
# Generar archivo de usuarios para Traefik (formato htpasswd)
cat > /vault/secrets/traefik-users.txt << 'USERS_EOF'
{{ .Data.data.admin_user_hash }}
USERS_EOF

# También generar el middlewares.yml completo como referencia
cat > /vault/secrets/middlewares-gen.yml << 'MIDDLEWARE_EOF'
---
http:
  middlewares:
    # Autenticación básica para dashboard - DESDE VAULT
    auth-basic:
      basicAuth:
        users:
          - "{{ .Data.data.admin_user_hash }}"

    # Rate limiting
    rate-limit:
      rateLimit:
        burst: 10
        period: 1m
        average: 30

    # Headers de seguridad
    security-headers:
      headers:
        frameDeny: true
        sslRedirect: true
        browserXssFilter: true
        contentTypeNosniff: true
        forceSTSHeader: true
        stsIncludeSubdomains: true
        stsPreload: true
        stsSeconds: 31536000
        customRequestHeaders:
          X-Forwarded-Proto: "https"

    # Middleware para servicios internos - CONFIGURAR TUS SUBNETS
    internal-access:
      ipWhiteList:
        sourceRange:
          - "YOUR_SUBNET"        # Main LAN
          - "YOUR_IOT_SUBNET"    # IoT LAN (optional)
          - "YOUR_GUEST_SUBNET"  # Guest LAN (optional)
          - "127.0.0.1/32"       # Localhost
          - "172.18.0.0/16"      # Docker network

    # Middleware para redirect HTTP to HTTPS
    redirect-to-https:
      redirectScheme:
        scheme: "https"
        permanent: true
MIDDLEWARE_EOF

# Establecer permisos correctos
chmod 644 /vault/secrets/traefik-users.txt
chmod 644 /vault/secrets/middlewares-gen.yml

echo "[$(date)] 🔐 Traefik auth files generados desde Vault Agent"
echo "📁 Users file: /vault/secrets/traefik-users.txt"
echo "📁 Middlewares: /vault/secrets/middlewares-gen.yml"
{{- end }}
