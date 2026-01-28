# Public Templates

This folder contains sanitized configuration templates for deploying the homelab stack.

## Quick Setup

```bash
# 1. Create the global .env file
cp public/.env.example .env
# Edit .env with your domains

# 2. Copy and customize each service config
# (see detailed instructions below)
```

## File Mapping

Copy files from `public/` to their destinations and customize values.

### Global Environment

| Source | Destination | Description |
|--------|-------------|-------------|
| `.env.example` | `/.env` | Global environment variables (domains, timezone) |

### Traefik (Reverse Proxy)

| Source | Destination | Description |
|--------|-------------|-------------|
| `traefik/config/traefik.yml` | `traefik/config/traefik.yml` | Main Traefik configuration |
| `traefik/config/tls.yml` | `traefik/config/tls.yml` | TLS/SSL certificate paths |
| `traefik/config/middlewares.yml` | `traefik/config/middlewares.yml` | Auth and security middlewares |
| `traefik/config/traefik-api.yml` | `traefik/config/traefik-api.yml` | API access for dashboards |
| `traefik/config/homeassistant.yml` | `traefik/config/homeassistant.yml` | Home Assistant routing |
| `traefik/config/proxmox.yml` | `traefik/config/proxmox.yml` | Proxmox routing |
| `traefik/config/n8n.yml` | `traefik/config/n8n.yml` | n8n automation routing |
| `traefik/config/pulse.yml` | `traefik/config/pulse.yml` | Pulse routing |
| `traefik/config/mediacli.yml` | `traefik/config/mediacli.yml` | Media stack (*arr, Plex, etc.) |
| `traefik/config/dispatcharr.yml` | `traefik/config/dispatcharr.yml` | Dispatcharr routing |

### Vault (Secrets Management)

| Source | Destination | Description |
|--------|-------------|-------------|
| `vault/config/vault-production.hcl` | `vault/config/vault-production.hcl` | Vault server config |
| `vault/config/homelab-policy.hcl` | `vault/config/homelab-policy.hcl` | Access policies |

### Shared Vault Agent

| Source | Destination | Description |
|--------|-------------|-------------|
| `shared-vault-agent/agent.hcl` | `shared-vault-agent/agent.hcl` | Agent configuration |
| `shared-vault-agent/templates/middlewares.tpl` | `shared-vault-agent/templates/middlewares.tpl` | Traefik auth template |
| `shared-vault-agent/templates/linkding.tpl` | `shared-vault-agent/templates/linkding.tpl` | Linkding secrets |
| `shared-vault-agent/templates/portainer.tpl` | `shared-vault-agent/templates/portainer.tpl` | Portainer secrets |
| `shared-vault-agent/templates/traefik.tpl` | `shared-vault-agent/templates/traefik.tpl` | Traefik secrets |
| `shared-vault-agent/templates/glance.tpl` | `shared-vault-agent/templates/glance.tpl` | Glance API keys |
| `shared-vault-agent/templates/speedtest-tracker.tpl` | `shared-vault-agent/templates/speedtest-tracker.tpl` | Speedtest APP_KEY |
| `shared-vault-agent/templates/certificates.tpl` | `shared-vault-agent/templates/certificates.tpl` | SSL certs (base64) |
| `shared-vault-agent/templates/certificates-decoded.tpl` | `shared-vault-agent/templates/certificates-decoded.tpl` | SSL certs decoder |

### DNS (Bind9)

| Source | Destination | Description |
|--------|-------------|-------------|
| `bind9/config/named.conf` | `bind9/config/named.conf` | DNS server config |
| `bind9/config/db.example.com.zone` | `bind9/config/db.yourdomain.com.zone` | Forward zone |
| `bind9/config/db.example.com-reverse.zone` | `bind9/config/db.yourdomain.com-reverse.zone` | Reverse zone |

### Glance (Dashboard)

| Source | Destination | Description |
|--------|-------------|-------------|
| `glance/config/glance.yml` | `glance/config/glance.yml` | Dashboard widgets config |

### Logging Stack

| Source | Destination | Description |
|--------|-------------|-------------|
| `logging/prometheus/config/prometheus.yml` | `logging/prometheus/config/prometheus.yml` | Metrics scraping |
| `logging/promtail/config/config.yml` | `logging/promtail/config/config.yml` | Log collection |

### Speedtest Tracker

| Source | Destination | Description |
|--------|-------------|-------------|
| `speedtest-tracker/secrets.env.example` | `speedtest-tracker/secrets.env` | APP_KEY secret |

## Placeholders to Replace

| Placeholder | Example | Description |
|-------------|---------|-------------|
| `192.168.1.X` | `10.10.1.77` | Your server IPs |
| `example.com` | `yourdomain.com` | Your domain |
| `server.example.com` | `icarus.yourdomain.com` | Server subdomain |
| `media.example.com` | `orfeo.yourdomain.com` | Media server subdomain |

## Deployment Order

After copying and customizing all files:

```bash
# Add aliases to your shell (optional but recommended)
echo 'alias dcu="docker compose --env-file /path/to/homelab/.env up -d"' >> ~/.bash_aliases
echo 'alias dcd="docker compose --env-file /path/to/homelab/.env down"' >> ~/.bash_aliases
source ~/.bashrc

# Create networks
docker network create frontend
docker network create backend

# Deploy in order
cd socket-proxy && dcu && cd ..
cd vault && dcu && cd ..
# Initialize Vault (see VAULT-SETUP.md)
cd shared-vault-agent && dcu && cd ..
cd bind9 && dcu && cd ..
cd traefik && dcu && cd ..
cd portainer && dcu && cd ..
cd glance && dcu && cd ..
cd linkding && dcu && cd ..
cd speedtest-tracker && dcu && cd ..
```

## Vault Initialization

See `public/vault/VAULT-SETUP.md` for complete Vault initialization instructions.
