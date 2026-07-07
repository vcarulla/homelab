# PLAYBOOK DE HARDENING — Docker Compose + Traefik + Vault

> Receta destilada de la revisión integral del homelab (2026-07-07).
> Pensada para replicar en otros stacks (mediacli, etc.). Cada regla lleva su
> **por qué**: si no aplica el motivo, no apliques la regla a ciegas.

---

## 1. Baseline de todo contenedor

Todo servicio arranca con este esqueleto y se le agrega solo lo que necesita:

```yaml
services:
  servicio:
    image: imagen:1.2.3          # SIEMPRE pineada (ver §1.1)
    security_opt:
      - no-new-privileges:true   # bloquea escalación via binarios setuid
    cap_drop:
      - ALL                      # deny-by-default; agregar caps una a una (§2)
    read_only: true              # rootfs inmutable; escribir solo en volúmenes/tmpfs
    tmpfs:
      - /tmp:rw,noexec,nosuid,size=10m
    deploy:
      resources:
        limits:                  # un servicio comprometido/con leak no tumba el host
          memory: 256M
          cpus: '0.5'
    healthcheck:                 # honesto: falla cuando el servicio NO sirve (§1.2)
      test: ["CMD", "..."]
    restart: unless-stopped
```

**Por qué**: un contenedor comprometido con caps default + rootfs escribible +
sin límites es casi un root en el host. Cada línea recorta una vía de escape
concreta: caps (syscalls privilegiadas), no-new-privileges (setuid), read_only
(persistencia del atacante), limits (DoS).

### 1.1 Pin de imágenes

- Tag exacto (`postgres:18.3-alpine`), nunca `:latest`.
- Si el registry solo publica `:latest` (ej. `ubuntu/bind9`), pinear **por digest**:

```yaml
image: ubuntu/bind9@sha256:45d541e9...
# Para actualizar: docker pull ubuntu/bind9:latest && docker inspect --format '{{.RepoDigests}}'
```

**Por qué**: `:latest` convierte cada `up -d` en una actualización sorpresa sin
changelog ni rollback claro.

### 1.2 Healthchecks honestos

- **Comillas en URLs con `&` dentro de `sh -c`**: sin comillas, el shell
  backgroundea el comando y el check devuelve siempre 0. Nos pasó con Vault:
  reportó *healthy* durante meses incluso estando sealed.

```yaml
# MAL:  wget ... http://x/health?a=1&b=2 || exit 1    ← & backgroundea, siempre OK
# BIEN: wget ... 'http://x/health?a=1' || exit 1
```

- Un estado degradado (Vault sealed, DB caída) **debe** verse como unhealthy.
  Señal honesta > dashboard verde.
- Verificar qué binarios trae la imagen (authentik no tiene `wget`, usar `curl`;
  alpine tiene `wget` de busybox).

---

## 2. Capabilities mínimas por tipo de servicio

`cap_drop: ALL` rompe cosas no obvias. Tabla de recetas probadas:

| Tipo de servicio | cap_add necesarias | Por qué |
|---|---|---|
| App simple no-root o root que solo escribe en su volumen (portainer, redis, glance, cloudflared, loki, grafana) | *(ninguna)* | No hacen syscalls privilegiadas |
| Proceso root que escribe archivos de **otro uid** (linkding con `./data` de uid 1000) | `DAC_OVERRIDE` | Sin ella, root NO bypasea permisos de archivo (sqlite: "readonly database") |
| Lector de archivos ajenos **solo lectura** (promtail, clamav, cadvisor) | `DAC_READ_SEARCH` | Como DAC_OVERRIDE pero sin permitir escritura — preferirla siempre que alcance |
| Entrypoint root que baja privilegios (vault, bind9) | `SETUID`, `SETGID` (+ `CHOWN` si el entrypoint chownea dirs) | su-exec/setuid() para dropear a usuario de servicio |
| linuxserver.io / s6-overlay (speedtest-tracker, \*arr) | `CHOWN`, `SETUID`, `SETGID`, `FOWNER`, `DAC_OVERRIDE` | s6 ajusta ownership a PUID/PGID en el arranque. **read_only NO es viable** con s6 |
| Bind a puerto <1024 como no-root (traefik) | `NET_BIND_SERVICE` | Puertos 80/443 |
| Vault (server y agent) con mlock | `IPC_LOCK` + `ulimits: memlock: {soft: -1, hard: -1}` | Secretos fuera de swap; 2.0.3+ necesita el ulimit o crashea |
| Healthcheck que manda señales a otro proceso (authentik worker `ak healthcheck`) | `KILL` | kill() a proceso de otro uid dentro del contenedor |

**Método**: arrancar con `cap_drop: ALL` pelado, mirar los logs del arranque, y
agregar la cap que pida el error concreto. Documentar cada `cap_add` con un
comentario de por qué (el próximo que lea el compose no tiene el contexto).

### Casos especiales verificados

- **Vault server con `read_only`**: además de caps, necesita
  `SKIP_SETCAP=true` (el entrypoint intenta `setcap` sobre el binario y falla
  en rootfs ro; el binario ya trae `cap_ipc_lock` de fábrica) y `pid_file`
  apuntando a tmpfs (`/tmp/vault.pid`).
- **bind9**: `read_only: true` funciona con tmpfs en `/tmp`, `/var/run`,
  `/var/cache/bind`. Y **no** necesita `apparmor:unconfined` — si un
  `security_opt` relajante no tiene un motivo verificado, probá sacarlo.
- **Authentik**: decisión consciente de NO usar `read_only` (escribe en varios
  paths y romper el SSO afecta a todo el stack). Documentar las excepciones
  vale tanto como aplicar la regla.

---

## 3. Socket de Docker: nunca directo

**Regla**: ningún servicio monta `/var/run/docker.sock`, ni siquiera `:ro`.
Todo pasa por un socket-proxy (tecnativa/docker-socket-proxy) con permisos
explícitos y `POST=0`.

**Por qué**: el `:ro` del mount protege el *archivo*, no la API — con acceso al
socket se crean contenedores privilegiados = root en el host. El proxy expone
solo los endpoints GET necesarios (`CONTAINERS=1`, `INFO=1`, etc.).

Trampas detectadas:
- **Mounts que cuelan el socket**: montar `/var/run:/var/run:ro` (cadvisor) te
  regala el socket entero sin que se note. Montar paths específicos.
- Los clientes suelen soportar endpoint TCP: Traefik
  (`endpoint: tcp://socket-proxy:2375`), Portainer (`--host=...`), Glance
  (`sock-path: tcp://socket-proxy:2375`), cadvisor (`--docker=tcp://...`),
  promtail (`docker_sd_configs.host`).

---

## 4. Traefik

```yaml
# tls.yml — sin esto, TLS 1.0/1.1 quedan aceptados por defecto
tls:
  options:
    default:
      minVersion: VersionTLS12
      sniStrict: true        # rechaza conexiones sin SNI (escaneos por IP)
```

- **`log.level: INFO`** en producción (DEBUG filtra detalle de requests y llena disco).
- **`ipAllowList`**, no `ipWhiteList` (deprecado en v3, se va en v4).
- **Headers**: `sslRedirect` (redundante con el redirect del entrypoint) y
  `browserXssFilter` (X-XSS-Protection, obsoleto y potencialmente dañino)
  se quitan; agregar `referrerPolicy: "strict-origin-when-cross-origin"`.
- **Capas por sensibilidad del servicio**:
  - Público con auth propia fuerte → `security-headers`
  - Sin auth propia robusta (indexers, torrent, paneles) → `internal-access`
    (ipAllowList de LAN/VPN) + `security-headers`
  - Administrativo (dashboard, vault) → `internal-access` + `rate-limit` +
    `auth-basic`/SSO + `security-headers`
- **`ping` en un entrypoint no publicado** (ej. el de metrics): saca el
  healthcheck del puerto público y evita el 308 del redirect global.
- Un middleware definido pero no referenciado (nuestro `rate-limit`) es
  seguridad imaginaria: griparlo a los routers o borrarlo.
- Labels de Docker requieren `docker compose down && up -d` (no `restart`);
  el file provider recarga solo.

---

## 5. Vault y Vault Agent

### Agent

```hcl
vault {
  address = "http://vault:8200"
  retry { num_retries = 7 }          # aguanta la ventana sealed tras reinicio
}

template_config {
  error_on_missing_key = true        # typo en una key => error visible,
}                                    # NO string vacío silencioso
```

- **Token sink en tmpfs PRIVADO del agente** (`/tmp/token`), nunca en el tmpfs
  compartido que montan los servicios: ese token lleva la policy completa del
  agente; cualquier servicio que monte el volumen podría leerlo y pedir los
  secretos de todos los demás.
- Credenciales AppRole solo en RAM (env vars → archivos en `/tmp` del
  contenedor). **Gotcha**: si el compose interpola `${ROLE_ID}` desde el
  entorno, un `docker compose up -d` desde una shell sin esas vars **recrea el
  contenedor sin credenciales** (el hash de config cambia). Regenerar
  secret-id y exportar antes de cualquier recreate, o usar el bootstrap script.

### Server

- Hardening completo de §1/§2 + `SKIP_SETCAP` + pid_file en tmpfs.
- `api_addr` es la URL **anunciada** a los clientes, no un bind:
  `http://vault:8200`, jamás `0.0.0.0`.
- Sealed ⇒ unhealthy (ver §1.2).

### Policies como código

- **Una sola fuente de verdad** para cada policy (un archivo, un path), sin
  copias sueltas. Nuestro caso: la policy viva en Vault tenía 2 servicios más
  que cualquier copia commiteada — el repo mentía sobre sí mismo y una
  restauración desde el repo hubiera roto servicios.
- Al agregar un servicio al agente (template nuevo), actualizar la policy
  **en el mismo cambio**.

---

## 6. Higiene de repo

- **Sanitizado de verdad**: en los archivos "ejemplo" no van IPs reales (ni
  como ejemplo de placeholder), ni hostnames reales, ni usernames en rutas
  (`/home/usuario/...` → `~/proyecto/...`), ni timezone si no hace falta.
  Grep de control: `grep -rn 'IP_REAL\|hostname_real\|usuario' public/`.
- Duplicados de config divergen siempre: consolidar y borrar (git guarda la
  historia).
- Reglas de `.gitignore` de servicios muertos: borrarlas (ruido que confunde).
- Symlink `.env` en cada dir de servicio: `env_file` carga vars al contenedor,
  pero la interpolación `${VAR}` en labels/compose necesita el `.env` en el
  directorio del proyecto.
- Comentarios/labels que referencian cosas inexistentes (un `certresolver` no
  configurado) fallan silenciosamente el día que se activan: corregirlos en frío.

---

## 7. Procedimiento de rollout (por servicio)

1. `docker compose config -q` — valida sintaxis e interpolación.
2. `docker compose up -d --force-recreate` (down/up si cambiaste labels de Traefik).
3. Esperar `healthy` (loop sobre `docker inspect -f '{{.State.Health.Status}}'`).
4. **Verificación funcional real**, no solo healthy: pegarle al endpoint via
   proxy, revisar logs por errores nuevos, probar la feature que tocaste
   (ej.: widget de Glance renderizando tras migrar a socket-proxy).
5. Si algo falla, el error dice qué cap/mount falta — agregar SOLO eso y repetir.
6. Servicios `profiles: disabled`: se pueden probar en vivo igual
   (`--profile disabled up -d`, verificar, `down`) antes de commitear.

Gotchas de verificación:
- curl desde el host a un router con ipAllowList puede dar 403 legítimo: el
  origen es el gateway de la red docker, no tu IP LAN. Probar desde un
  contenedor en la red permitida o desde otra máquina de la LAN.
- Recrear Vault ⇒ arranca sealed ⇒ unseal manual y ventana de 503 en el agent
  (con `retry` configurado se recupera solo).

---

## 8. Orden sugerido para aplicar en un repo nuevo

1. **Inventario**: contenedores corriendo vs. composes; imágenes `:latest`;
   quién monta docker.sock; qué healthchecks mienten.
2. **Lo que guarda secretos primero** (vault/agent): §5.
3. **Cerrar el socket de Docker**: §3.
4. **Proxy/TLS**: §4.
5. **Baseline por servicio** (§1 + §2), de a uno, verificando entre cada uno.
6. **Servicios apagados/disabled**: fixes en frío + prueba efímera.
7. **Higiene de repo y docs**: §6.
8. Commitear por bloques lógicos con el porqué en el mensaje.

---

## Apéndice: chequeos rápidos

```bash
# Imágenes sin pinear
docker ps --format '{{.Image}}' | grep ':latest'

# Quién monta el socket real
docker ps -q | xargs docker inspect -f '{{.Name}} {{range .Mounts}}{{.Source}} {{end}}' | grep docker.sock

# Contenedores sin límite de memoria
docker ps -q | xargs docker inspect -f '{{.Name}} {{.HostConfig.Memory}}' | grep ' 0$'

# Caps efectivas de un contenedor
docker inspect -f '{{.HostConfig.CapAdd}} {{.HostConfig.CapDrop}}' <nombre>

# TLS mínimo aceptado por el proxy
curl -sk --tls-max 1.1 https://servicio.dominio/   # debe fallar

# Healthchecks: ¿alguno miente? — matar la dependencia y ver si se entera
```
