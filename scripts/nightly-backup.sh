#!/bin/bash
# nightly-backup.sh — Back up Pi configs and databases
# Backs up to Passport drive (same drive, different folder — not ideal 
# but protects against config corruption, not drive failure)

BACKUP_DIR="/media/pibulus/passport/Backups/pi-system"
DATE=$(date +%Y-%m-%d)
LOG="/tmp/backup-$DATE.log"

echo "[$(date)] Nightly backup starting" > "$LOG"

# Check Passport is mounted
if ! mountpoint -q /media/pibulus/passport; then
    echo "[ERROR] Passport not mounted, aborting" >> "$LOG"
    exit 1
fi

mkdir -p "$BACKUP_DIR/configs"
mkdir -p "$BACKUP_DIR/docker-db"
mkdir -p "$BACKUP_DIR/system"

# 1. Service configs (small, critical)
echo "[configs] Syncing service configs..." >> "$LOG"
rsync -a /home/pibulus/.config/jellyfin/ "$BACKUP_DIR/configs/jellyfin/" 2>> "$LOG"
rsync -a /home/pibulus/.config/navidrome/ "$BACKUP_DIR/configs/navidrome/" 2>> "$LOG"
rsync -a /home/pibulus/.config/kavita/ "$BACKUP_DIR/configs/kavita/" 2>> "$LOG"
rsync -a /home/pibulus/.config/calibre-web/ "$BACKUP_DIR/configs/calibre-web/" 2>> "$LOG"

# 2. AzuraCast MariaDB dump
echo "[db] Dumping AzuraCast database..." >> "$LOG"
docker exec azuracast mysqldump --single-transaction -u azuracast azuracast 2>/dev/null | gzip > "$BACKUP_DIR/docker-db/azuracast-$DATE.sql.gz" 2>> "$LOG"
ls -t "$BACKUP_DIR/docker-db/azuracast-"*.sql.gz 2>/dev/null | tail -n +8 | xargs rm -f 2>/dev/null

# 3. Memos database
echo "[db] Copying Memos database..." >> "$LOG"
docker cp memos:/var/opt/memos/memos_prod.db "$BACKUP_DIR/docker-db/memos-$DATE.db" 2>> "$LOG"
ls -t "$BACKUP_DIR/docker-db/memos-"*.db 2>/dev/null | tail -n +8 | xargs rm -f 2>/dev/null

# 4. Key system files
echo "[system] Backing up system configs..." >> "$LOG"
cp /etc/fstab "$BACKUP_DIR/system/fstab" 2>> "$LOG"
sudo cp /etc/cloudflared/config.yml "$BACKUP_DIR/system/cloudflared-config.yml" 2>> "$LOG"
crontab -l > "$BACKUP_DIR/system/crontab.txt" 2>> "$LOG"
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' > "$BACKUP_DIR/system/docker-services.txt" 2>> "$LOG"

# 5. Pibulus-OS scripts and www
echo "[scripts] Syncing pibulus-os..." >> "$LOG"
rsync -a /home/pibulus/pibulus-os/ "$BACKUP_DIR/pibulus-os/" 2>> "$LOG"

# Summary
TOTAL=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
echo "[$(date)] Backup complete. Total size: $TOTAL" >> "$LOG"
cat "$LOG"
