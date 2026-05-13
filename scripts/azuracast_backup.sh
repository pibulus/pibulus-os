#!/bin/bash
# Daily AzuraCast DB backup to Passport
# Keeps last 7 days
set -e

FALLBACK_LOG="/tmp/azuracast_backup.log"
if ! mountpoint -q /media/pibulus/passport; then
    echo "[$(date "+%F %T")] ERROR: Passport not mounted, aborting" >> "$FALLBACK_LOG"
    exit 1
fi

BACKUP_DIR="/media/pibulus/passport/Backups/azuracast"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/azuracast_${DATE}.zip"
BACKUP_VOLUME="/var/lib/docker/volumes/azuracast_backups/_data"
LOG_DIR="/media/pibulus/passport/Backups/pi-system/logs"
LOG="$LOG_DIR/azuracast-backup.log"

mkdir -p "$BACKUP_DIR" "$LOG_DIR"
exec >> "$LOG" 2>&1
echo "=== AzuraCast backup $(date) ==="

docker exec azuracast azuracast_cli azuracast:backup "/var/azuracast/backups/azuracast_${DATE}.zip" --exclude-media

sudo cp "$BACKUP_VOLUME/azuracast_${DATE}.zip" "$BACKUP_FILE"
sudo rm -f "$BACKUP_VOLUME/azuracast_${DATE}.zip"

# Keep last 7
ls -t "$BACKUP_DIR"/azuracast_*.zip 2>/dev/null | tail -n +8 | xargs rm -f 2>/dev/null || true

echo "Backup complete: $BACKUP_FILE"
