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

# Verificar que ClamAV esté ejecutándose
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "❌ ERROR: ClamAV container no está ejecutándose" | tee -a "$SCAN_LOG"
    exit 1
fi

# Escaneo efectivo del sistema como antivirus profesional  
echo "📁 Escaneando archivos críticos en /home..." | tee -a "$SCAN_LOG"
# Usar find para localizar y escanear archivos específicos
docker exec "$CONTAINER_NAME" find /scan/home -type f \( -name "*.exe" -o -name "*.zip" -o -name "*.rar" -o -name "*.tar.gz" -o -name "*.deb" -o -name "*.pdf" -o -name "*.doc*" -o -name "*.xls*" \) 2>/dev/null | head -100 | xargs -I {} docker exec "$CONTAINER_NAME" clamdscan "{}" >> "$SCAN_LOG" 2>&1

echo "📁 Escaneando Downloads..." | tee -a "$SCAN_LOG"
# Escanear todo en directorios de descarga
docker exec "$CONTAINER_NAME" find /scan/home -path "*/Downloads/*" -type f 2>/dev/null | head -50 | xargs -I {} docker exec "$CONTAINER_NAME" clamdscan "{}" >> "$SCAN_LOG" 2>&1

echo "📁 Escaneando archivos temporales..." | tee -a "$SCAN_LOG"
# Archivos temporales recientes
docker exec "$CONTAINER_NAME" find /scan/tmp -type f -mtime -1 -size +1k 2>/dev/null | head -30 | xargs -I {} docker exec "$CONTAINER_NAME" clamdscan "{}" >> "$SCAN_LOG" 2>&1

echo "📁 Escaneando aplicaciones..." | tee -a "$SCAN_LOG"
# Solo ejecutables en /opt
docker exec "$CONTAINER_NAME" find /scan/opt -type f -executable 2>/dev/null | head -20 | xargs -I {} docker exec "$CONTAINER_NAME" clamdscan "{}" >> "$SCAN_LOG" 2>&1

# Resumen final
echo "✅ Escaneo completado: $(date)" | tee -a "$SCAN_LOG"
INFECTED_COUNT=$(grep -c "FOUND" "$SCAN_LOG" 2>/dev/null | head -1)
ERROR_COUNT=$(grep -c "ERROR" "$SCAN_LOG" 2>/dev/null | head -1)
SCANNED_COUNT=$(grep -c ": OK" "$SCAN_LOG" 2>/dev/null | head -1)

# Asegurar valores numéricos
INFECTED_COUNT=${INFECTED_COUNT:-0}
ERROR_COUNT=${ERROR_COUNT:-0}
SCANNED_COUNT=${SCANNED_COUNT:-0}

echo "📊 Archivos escaneados: $SCANNED_COUNT" | tee -a "$SCAN_LOG"
echo "📊 Archivos infectados encontrados: $INFECTED_COUNT" | tee -a "$SCAN_LOG"
echo "⚠️ Errores de acceso: $ERROR_COUNT" | tee -a "$SCAN_LOG"

# Notificar si hay infecciones
if [ "$INFECTED_COUNT" -gt 0 ]; then
    echo "🚨 ALERTA: Se encontraron $INFECTED_COUNT archivos infectados" | tee -a "$SCAN_LOG"
    # Aquí podrías agregar notificación (email, webhook, etc.)
fi

echo "📄 Log guardado en: $SCAN_LOG"