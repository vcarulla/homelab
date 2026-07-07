#!/bin/bash
# 🦠 CLAMAV AUTOMATED SCANNING SCRIPT
# Genera: $(date)
# Uso: Escaneo programado con reportes cada 90 minutos
# Logs: /var/log/clamav-scans/ con rotación automática

SCAN_LOG="/var/log/clamav-scans/clamav-scan-$(date +%Y%m%d_%H%M).log"
CONTAINER_NAME="clamav"
LOG_DIR="/var/log/clamav-scans"

# Rotación de logs: Mantener solo últimos 30 días
find "$LOG_DIR" -name "clamav-scan-*.log" -mtime +30 -delete 2>/dev/null

echo "🦠 Iniciando escaneo ClamAV: $(date)" | tee "$SCAN_LOG"

# Verificar que ClamAV esté ejecutándose (match exacto por nombre, no substring)
if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    echo "❌ ERROR: ClamAV container no está ejecutándose" | tee -a "$SCAN_LOG"
    exit 1
fi

# Escaneo por directorios completos con clamd (--multiscan paraleliza,
# --fdpass evita problemas de permisos pasando file descriptors al daemon).
# Un solo docker exec por directorio, sin límites arbitrarios de head.
scan_dir() {
    local dir="$1" label="$2"
    echo "📁 Escaneando ${label}..." | tee -a "$SCAN_LOG"
    docker exec "$CONTAINER_NAME" clamdscan --multiscan --fdpass --infected "$dir" >> "$SCAN_LOG" 2>&1
}

scan_dir /scan/home "/home completo" &
SCAN_PID=$!
scan_dir /scan/tmp "archivos temporales"
scan_dir /scan/opt "aplicaciones en /opt"
wait "$SCAN_PID"

# Resumen final (con --infected solo se loguean hallazgos y errores)
echo "✅ Escaneo completado: $(date)" | tee -a "$SCAN_LOG"
INFECTED_COUNT=$(grep -c "FOUND" "$SCAN_LOG" 2>/dev/null || echo 0)
ERROR_COUNT=$(grep -c "ERROR" "$SCAN_LOG" 2>/dev/null || echo 0)

echo "📊 Archivos infectados encontrados: $INFECTED_COUNT" | tee -a "$SCAN_LOG"
echo "⚠️ Errores de acceso: $ERROR_COUNT" | tee -a "$SCAN_LOG"

# Notificar si hay infecciones
if [ "$INFECTED_COUNT" -gt 0 ]; then
    echo "🚨 ALERTA: Se encontraron $INFECTED_COUNT archivos infectados" | tee -a "$SCAN_LOG"
    # TODO: enganchar notificación real (ntfy/Telegram); por ahora solo log
fi

echo "📄 Log guardado en: $SCAN_LOG"