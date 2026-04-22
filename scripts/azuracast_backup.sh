#!/bin/bash
# Daily AzuraCast DB backup to Passport
# Keeps last 7 days
set -e

BACKUP_DIR="/media/pibulus/passport/Backups/azuracast"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/azuracast_${DATE}.zip"
BACKUP_VOLUME="/var/lib/docker/volumes/azuracast_backups/_data"

mkdir -p "$BACKUP_DIR"

docker exec azuracast azuracast_cli azuracast:backup "/var/azuracast/backups/azuracast_${DATE}.zip" --exclude-media

sudo cp "$BACKUP_VOLUME/azuracast_${DATE}.zip" "$BACKUP_FILE"
sudo rm -f "$BACKUP_VOLUME/azuracast_${DATE}.zip"

# Keep last 7
ls -t "$BACKUP_DIR"/azuracast_*.zip 2>/dev/null | tail -n +8 | xargs rm -f 2>/dev/null || true

echo "Backup complete: $BACKUP_FILE"
