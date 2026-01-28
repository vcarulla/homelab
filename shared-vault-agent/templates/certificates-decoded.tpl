# 🔐 TRAEFIK SSL CERTIFICATES - DECODED FILES
# Auto-generado por Shared Vault Agent - 🔄 Gestión centralizada  
# Generado: {{ timestamp }}

{{- with secret "secret/data/certificates/traefik" }}
# Este template genera archivos de certificados decodificados
# Los archivos se crearán en /vault/secrets/certs/

# Script para decodificar certificados
cat > /vault/secrets/decode-certs.sh << 'DECODE_SCRIPT'
#!/bin/sh
echo "🔐 Decodificando certificados desde Vault Agent..."

# Crear directorio de certificados
mkdir -p /vault/secrets/certs

# Escribir fullchain (ya decodificado por Vault)
cat > /vault/secrets/certs/fullchain.crt << 'EOF'
{{ .Data.data.fullchain }}
EOF
echo "✅ fullchain.crt escrito"

# Escribir private key (ya decodificado por Vault)
cat > /vault/secrets/certs/server.key << 'EOF'
{{ .Data.data.private_key }}
EOF
echo "✅ server.key escrito"

# Escribir CA cert (ya decodificado por Vault)
cat > /vault/secrets/certs/ca.crt << 'EOF'
{{ .Data.data.ca_cert }}
EOF
echo "✅ ca.crt escrito"

# Establecer permisos correctos
chmod 600 /vault/secrets/certs/server.key
chmod 644 /vault/secrets/certs/fullchain.crt
chmod 644 /vault/secrets/certs/ca.crt

# Los certificados ya están listos para Traefik en /vault/secrets/certs/
echo "📋 Certificados disponibles para Traefik en volumen compartido..."
echo "  - /vault/secrets/certs/fullchain.crt"
echo "  - /vault/secrets/certs/server.key" 
echo "  - /vault/secrets/certs/ca.crt"

echo "🎉 Certificados decodificados y listos en /vault/secrets/certs/"
DECODE_SCRIPT

chmod +x /vault/secrets/decode-certs.sh
{{- end }}