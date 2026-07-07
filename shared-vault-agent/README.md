# Shared Vault Agent - Agente consolidado de secrets

Un único **Vault Agent** (`homelab-vault-agent`) sirve los secrets de todos los servicios de icarus: Traefik, Glance, Linkding, Portainer, PostgreSQL, Authentik, Speedtest Tracker y los certificados TLS. Patrón consolidado en lugar de un sidecar por servicio.

---

## Estructura

```
shared-vault-agent/
├── agent.hcl              # Configuración del agente (auto_auth + templates)
├── docker-compose.yml     # Servicio + volumen tmpfs compartido
└── templates/             # Templates Go (*.tpl), uno por servicio
```

---

## Flujo

```
[Vault :8200] ←── AppRole auth ──┐
                                 │
                    [homelab-vault-agent]
                                 │ renderiza templates
                                 v
            vault_secrets_tmpfs (/vault/secrets, tmpfs 0700 uid=0)
                                 │ montado :ro por cada servicio
                                 v
        traefik, glance, linkding, portainer, postgres, authentik...
```

- Los secrets **nunca tocan disco**: el volumen `vault_secrets_tmpfs` es tmpfs (50MB, `mode=0700 uid=0 noexec nosuid`).
- Como el tmpfs es `0700 uid=0`, los servicios que corren como no-root necesitan `user: root` para leer sus secrets.

---

## Autenticación: AppRole solo en RAM

Las credenciales AppRole llegan por **variables de entorno** (`VAULT_SHARED_ROLE_ID` / `VAULT_SHARED_SECRET_ID`) y el entrypoint las escribe a `/tmp` del contenedor (tmpfs privado, `chmod 600`) antes de arrancar el agente:

```sh
echo "$VAULT_ROLE_ID"   > /tmp/role-id
echo "$VAULT_SECRET_ID" > /tmp/secret-id
exec vault agent -config=/vault/config/agent.hcl
```

Nada persiste: tras un reinicio del host las credenciales no existen y hay que regenerarlas con el bootstrap (script privado):

```bash
/home/bittor/homelab/scripts/vault-bootstrap.sh
```

El script hace unseal de Vault, regenera el secret-id del AppRole y reinicia el agente.

---

## Token sink en /tmp (no en el tmpfs compartido)

```hcl
sink "file" {
  config = {
    path = "/tmp/token"
    mode = 0600
  }
}
```

El token de Vault se escribe en `/tmp` del agente (tmpfs **privado** del contenedor), y solo lo usa el healthcheck. **Deliberadamente NO va en `/vault/secrets`**: ese tmpfs lo montan todos los servicios, y el token tiene la `homelab-policy` completa — cualquier contenedor comprometido podría leer todos los secrets del homelab con él.

---

## Configuración clave (`agent.hcl`)

- **`error_on_missing_key = true`**: si una key no existe en Vault, el template falla explícito en vez de renderizar un string vacío (evita servicios arrancando con secrets en blanco).
- **`retry { num_retries = 7 }`**: reintenta contra Vault mientras está sealed o arrancando; junto con el `start_period: 90s` del healthcheck cubre el arranque ordenado tras reboot.
- Templates → `/vault/secrets/*.env` con `perms 0600`; los de certificados y middlewares generan scripts (`certificates-setup.sh`, `middlewares-setup.sh`) que se ejecutan al renderizar.

El healthcheck del contenedor verifica que exista el token y los `.env` principales renderizados.

---

## Excepción: Speedtest Tracker

Es el único secret que va a **disco** en vez de tmpfs:

```hcl
template {
  source      = "/vault/config/templates/speedtest-tracker.tpl"
  destination = "/vault/speedtest-tracker/secrets.env"
  perms       = 0644
}
```

Motivo: la imagen de linuxserver usa s6-overlay, que necesita el `env_file` presente antes de crear el contenedor (docker-compose lo lee del host), así que no puede consumirlo del tmpfs. Se monta `../speedtest-tracker` en el agente y el archivo se escribe ahí con `0644` (compose lo lee como usuario no-root).

---

## Hardening del contenedor

- `read_only: true`, `cap_drop: ALL` + solo `SETGID`, `SETUID`, `IPC_LOCK` (Vault 2.x necesita `IPC_LOCK` con `no-new-privileges`)
- `init: true`, `no-new-privileges:true`
- Config montada `:ro`, límites 256M / 0.5 CPU

---

## Operación

```bash
# Levantar
cd shared-vault-agent && docker compose --env-file ../.env up -d

# Estado y logs
docker logs -f homelab-vault-agent

# Ver secrets renderizados
docker exec homelab-vault-agent ls -la /vault/secrets/

# Tras reboot del host (Vault sealed + sin credenciales AppRole)
/home/bittor/homelab/scripts/vault-bootstrap.sh
```

Para agregar un servicio nuevo: crear el template en `templates/`, añadir el bloque `template {}` en `agent.hcl`, verificar que `homelab-policy` tiene acceso de lectura al path del secret, y montar el volumen `shared-vault-agent_vault_secrets_tmpfs` (`:ro`) en el servicio.
