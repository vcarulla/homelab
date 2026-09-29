#!/bin/sh
# Espera a que PostgreSQL acepte conexiones antes de arrancar Authentik.
#
# Por que: authentik y postgres viven en proyectos compose distintos
# (homelab/authentik y homelab/postgres), asi que depends_on no los alcanza.
# Sin esta espera, con postgres caido authentik entra en crash-loop y cada
# reinicio crea y destruye una interfaz veth; el flood de eventos del kernel
# satura el journal y degrada el host entero. Paso el 2026-08-23: dejo a
# sshd sin atender y tumbo el login OIDC de Proxmox.
#
# Espera indefinida a proposito: mantiene el contenedor vivo sin reiniciar,
# que es justamente lo que evita el flapping.
HOST="${AUTHENTIK_POSTGRESQL__HOST:-homelab-postgres}"
PORT="${AUTHENTIK_POSTGRESQL__PORT:-5432}"
PY=/ak-root/.venv/bin/python3

i=0
until "$PY" -c "import socket,sys; socket.create_connection((sys.argv[1], int(sys.argv[2])), 3).close()" "$HOST" "$PORT" 2>/dev/null; do
    i=$((i+1))
    # Log espaciado (~1 min) para no inundar el journal mientras espera.
    [ $((i % 30)) -eq 1 ] && echo "Esperando a PostgreSQL en $HOST:$PORT (intento $i)..."
    sleep 2
done
echo "PostgreSQL disponible en $HOST:$PORT"
