# Vault Initialization Guide

Complete guide to initialize HashiCorp Vault for the homelab stack.

## 1. Start Vault Container

```bash
cd vault
docker compose --env-file ../.env up -d
```

## 2. Initialize Vault

```bash
# Initialize with 5 key shares, 3 required to unseal
docker exec vault vault operator init -key-shares=5 -key-threshold=3
```

**IMPORTANT**: Save the output securely! You'll get:
- 5 Unseal Keys
- 1 Root Token

Store these in a secure location (password manager, encrypted file, etc.)

## 3. Unseal Vault

You need 3 of the 5 keys to unseal:

```bash
docker exec -it vault vault operator unseal
# Enter key 1
docker exec -it vault vault operator unseal
# Enter key 2
docker exec -it vault vault operator unseal
# Enter key 3
```

## 4. Login and Enable Secrets Engine

```bash
# Login with root token
docker exec -it vault vault login
# Enter root token

# Enable KV secrets engine v2
docker exec vault vault secrets enable -path=secret kv-v2
```

## 5. Create Policy

```bash
# Copy policy file to container
docker cp vault/config/homelab-policy.hcl vault:/tmp/

# Create the policy
docker exec vault vault policy write homelab-policy /tmp/homelab-policy.hcl
```

## 6. Enable AppRole Authentication

```bash
# Enable AppRole
docker exec vault vault auth enable approle

# Create role for homelab
docker exec vault vault write auth/approle/role/homelab-role \
    token_policies="homelab-policy" \
    token_ttl=1h \
    token_max_ttl=4h \
    secret_id_ttl=0
```

## 7. Get AppRole Credentials

```bash
# Get Role ID
docker exec vault vault read auth/approle/role/homelab-role/role-id
# Save the role_id value

# Generate Secret ID
docker exec vault vault write -f auth/approle/role/homelab-role/secret-id
# Save the secret_id value
```

## 8. Store Credentials for Vault Agent

Create files that Vault Agent will use (these are in .gitignore):

```bash
# In shared-vault-agent directory
echo "YOUR_ROLE_ID" > shared-vault-agent/role-id
echo "YOUR_SECRET_ID" > shared-vault-agent/secret-id
```

## 9. Add Secrets to Vault

Example secrets for each service:

```bash
# Traefik basic auth (generate with: htpasswd -nb admin password)
docker exec vault vault kv put secret/traefik \
    basic_auth_user="admin" \
    basic_auth_hash='$apr1$...'

# Linkding
docker exec vault vault kv put secret/linkding \
    superuser_name="admin" \
    superuser_password="your-password"

# Glance API keys
docker exec vault vault kv put secret/glance \
    PROXMOXVE_URL="192.168.1.10:8006" \
    PROXMOXVE_KEY="user@pam!token=uuid" \
    PORTAINER_URL="https://portainer.server.example.com" \
    PORTAINER_API_KEY="your-api-key" \
    SPEEDTEST_URL="https://speedtest.server.example.com" \
    SPEEDTEST_TRACKER_API_TOKEN="your-token"

# Speedtest Tracker
docker exec vault vault kv put secret/speedtest-tracker \
    APP_KEY="base64:$(openssl rand -base64 32)"

# SSL Certificates (if using custom certs)
docker exec vault vault kv put secret/certificates/traefik \
    fullchain="$(cat /path/to/fullchain.pem)" \
    private_key="$(cat /path/to/privkey.pem)" \
    ca_cert="$(cat /path/to/ca.pem)"
```

## 10. Start Vault Agent

```bash
cd shared-vault-agent
docker compose --env-file ../.env up -d
```

## 11. Verify

```bash
# Check Vault Agent logs
docker logs homelab-vault-agent

# Verify secrets are rendered
docker exec homelab-vault-agent ls -la /vault/secrets/
```

## Daily Operations

### Unseal After Reboot

Vault seals itself on container restart. Create a bootstrap script:

```bash
#!/bin/bash
# vault-bootstrap.sh
docker exec vault vault operator unseal YOUR_KEY_1
docker exec vault vault operator unseal YOUR_KEY_2
docker exec vault vault operator unseal YOUR_KEY_3
docker restart homelab-vault-agent
```

### Check Vault Status

```bash
docker exec vault vault status
```

### Rotate Secret ID (periodic security)

```bash
# Generate new Secret ID
docker exec vault vault write -f auth/approle/role/homelab-role/secret-id

# Update the file
echo "NEW_SECRET_ID" > shared-vault-agent/secret-id

# Restart agent
docker restart homelab-vault-agent
```
