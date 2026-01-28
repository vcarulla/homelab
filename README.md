# Homelab Infrastructure - Docker + Traefik + Vault

> Modular home server infrastructure with enterprise-grade security patterns.
> Built with Docker containers, Traefik reverse proxy, and HashiCorp Vault.

---

## Architecture Overview

```
├── bind9/                 # Local DNS server (BIND9)
├── cloudflared/           # Cloudflare Zero Trust tunnel
├── traefik/               # Reverse proxy with ACME certificates
├── portainer/             # Container management UI
├── clamav/                # Open source antivirus
├── linkding/              # Self-hosted bookmark manager
├── glance/                # Dashboard with custom widgets
├── socket-proxy/          # Docker socket security proxy
├── vault/                 # Centralized secrets management
├── shared-vault-agent/    # Vault Agent sidecar (shared secrets)
├── speedtest-tracker/     # Internet speed monitoring
└── logging/               # Observability stack (paused)
    ├── prometheus/        # Metrics collection
    ├── grafana/           # Dashboards
    ├── loki/              # Log aggregation
    └── ...
```

---

## Security Stack

### Enterprise Pattern: HashiCorp Vault Agent Sidecar
Following Netflix/Uber/Airbnb patterns for secrets management.

**Key Features:**
- **Socket Proxy**: HAProxy-based granular Docker socket access
- **Encrypted tmpfs**: 50MB in-memory storage, secrets never on disk
- **SSL Centralized**: Vault KV → Template rendering → tmpfs → Traefik
- **Network Isolation**: frontend/backend network separation
- **Container Hardening**: read_only + no-privileges + cap_drop
- **Zero-Trust Credentials**: AppRole secrets only in RAM

### Bootstrap Flow (No Circular Dependencies)
1. Vault container starts (internal HTTP)
2. Shared Vault Agent → http://vault:8200
3. Agent renders certificates to shared tmpfs
4. Traefik reads certificates from tmpfs
5. Closed loop: HTTPS functional

---

## Quick Start

### Prerequisites
- Docker Engine ≥ 24.0
- Docker Compose ≥ 2.20
- Ubuntu 24.04+ / Debian 12+ (recommended)

### 1. Environment Setup

```bash
# Clone the repository
git clone <repository-url>
cd homelab

# Create shared Docker networks
docker network create frontend
docker network create backend

# Create global .env from template
cp public/.env.example .env
# Edit .env with your domains and timezone

# Copy and customize config files from public/
# See public/README.md for complete file mapping
cp public/traefik/config/*.yml traefik/config/
cp public/glance/config/glance.yml glance/config/
cp public/vault/config/*.hcl vault/config/
# Edit files and replace IPs (192.168.1.X) and domains (example.com)

# Add docker compose aliases (recommended)
cat >> ~/.bash_aliases << 'EOF'
alias dcu='docker compose --env-file ~/homelab/.env up -d'
alias dcd='docker compose --env-file ~/homelab/.env down'
alias dcc='docker compose --env-file ~/homelab/.env config'
alias dcl='docker compose --env-file ~/homelab/.env logs -f'
alias dcr='docker compose --env-file ~/homelab/.env restart'
EOF
source ~/.bashrc
```

### 2. Deployment Order

```bash
# 1. Security base
cd socket-proxy && dcu && cd ..

# 2. Secrets management
cd vault && dcu && cd ..
# IMPORTANT: Initialize Vault before continuing
# See public/vault/VAULT-SETUP.md for complete instructions
cd shared-vault-agent && dcu && cd ..

# 3. Local DNS
cd bind9 && dcu && cd ..

# 4. Reverse proxy
cd traefik && dcu && cd ..

# 5. Management
cd portainer && dcu && cd ..

# 6. Services
cd glance && dcu && cd ..
cd linkding && dcu && cd ..
cd speedtest-tracker && dcu && cd ..
```

### 3. Verification

```bash
# Check all containers
docker ps --format "table {{.Names}}\t{{.Status}}"

# Check critical logs
docker logs traefik
docker logs vault
docker logs homelab-vault-agent
```

---

## Configuration Templates

The `public/` folder contains sanitized configuration templates. Copy them to their respective locations and replace placeholders:

| Placeholder | Example | Description |
|-------------|---------|-------------|
| `192.168.1.X` | `10.0.0.10` | Your server IPs |
| `example.com` | `yourdomain.com` | Your domain |
| `server.example.com` | `server.yourdomain.com` | Server subdomain |

See `public/README.md` for complete file mapping and setup instructions.

---

## Network Architecture

```
                    [Internet]
                        |
               [Cloudflare Zero Trust]
                        |
                [cloudflared tunnel]
                        |
    ┌───────────────────────────────────────────────┐
    │               Traefik (443/80)                │
    │          (reverse proxy + ACME)               │
    └─────────────────────┬─────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
    [frontend]        [backend]         [docker.sock]
        │                 │                 │
   ┌────┴─────┐       ┌───┴───────┐       ┌─┴───────┐
   │ glance   │       │ bind9     │       │ socket- │
   │ portainer│       │ loki      │       │ proxy   │
   │ grafana  │       │ prometheus│       └─────────┘
   │ linkding │       │ clamav    │
   │ vault    │       └───────────┘
   └──────────┘
```

---

## Secrets Management with Vault

### AppRole Authentication
- **Pattern**: Vault Agent sidecar with AppRole
- **Security**: Credentials only in environment variables → tmpfs
- **Templates**: Go templates render secrets to tmpfs volume
- **Rotation**: Automatic token renewal

### Managed Secrets
- SSL certificates (fullchain, private key, CA)
- Traefik basic auth credentials
- Service API tokens (Portainer, Proxmox, etc.)
- Dashboard configurations

---

## Security Layers

- **Network**: Docker frontend/backend segmentation
- **Socket**: Read-only proxy for controlled daemon access
- **TLS**: Automatic Let's Encrypt via DNS Challenge
- **Antivirus**: ClamAV with automatic host scanning
- **Access**: IP whitelisting in Traefik middlewares
- **Secrets**: Vault with centralized credential management

### Hardening Applied
- Containers without privileges (except ClamAV and node_exporter)
- Least privilege principle in socket-proxy
- Automatic HTTP security headers
- Centralized audit logs
- Rate limiting on public endpoints
- Automatic rotation of sensitive tokens

---

## Maintenance

### SSL Certificate Update
```bash
# Update in Vault
docker exec vault vault kv put secret/certificates/traefik \
    fullchain="$(cat new-chain.crt)" \
    private_key="$(cat new-key.key)" \
    ca_cert="$(cat new-ca.crt)"

# Restart Traefik
cd traefik && docker compose down && docker compose up -d
```

### Configuration Backup
```bash
tar -czf backup-$(date +%Y%m%d).tar.gz */docker-compose.yml */config/
```

---

## Troubleshooting

### Traefik Middleware Errors
Always use `down/up` (NOT restart):
```bash
cd traefik && docker compose down && docker compose up -d
```

### SSL Not Working
```bash
# Verify certificates in tmpfs
docker exec homelab-vault-agent ls -la /vault/secrets/certs/
docker exec traefik ls -la /vault/secrets/certs/
```

### DNS Not Resolving
```bash
cd bind9 && docker compose restart
```

### Vault Issues
```bash
docker exec vault vault status
docker logs vault
```

---

## Technology Stack

- **Virtualization**: Proxmox VE 8.x
- **Containers**: Docker Engine 24.x + Docker Compose 2.x
- **Proxy**: Traefik v3 with automatic ACME
- **DNS**: BIND9
- **Secrets**: HashiCorp Vault + Agent
- **Dashboard**: Glance with custom widgets
- **Antivirus**: ClamAV
- **Observability**: Prometheus + Grafana + Loki (optional)

---

## License

MIT License - See individual service documentation for specific configurations.

---

**Enterprise-grade security patterns adapted for home server use.**
