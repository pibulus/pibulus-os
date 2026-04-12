#!/bin/bash
# nightly-backup.sh — Back up Pi configs and databases to Passport
# Runs daily at 3am via crontab. Protects against config corruption and
# provides a restore source for EliteDesk migration.
#
# What gets backed up:
#   configs/     — app config dirs (rsync, incremental)
#   docker-db/   — database dumps (AzuraCast MariaDB, Memos SQLite)
#   volumes/     — Docker/app state that is awkward to recreate
#   system/      — crontab, fstab, cloudflared, docker service list
#   pibulus-os/  — scripts, compose files, www (excludes secrets)

BACKUP_DIR="/media/pibulus/passport/Backups/pi-system"
DATE=$(date +%Y-%m-%d)
LOG="/tmp/nightly-backup.log"

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; }

# Check Passport is mounted
if ! mountpoint -q /media/pibulus/passport; then
    echo "[ERROR] Passport not mounted, aborting" >> "$LOG"
    exit 1
fi

echo "=== Nightly backup $(date) ===" > "$LOG"

mkdir -p "$BACKUP_DIR/configs"
mkdir -p "$BACKUP_DIR/docker-db"
mkdir -p "$BACKUP_DIR/volumes"
mkdir -p "$BACKUP_DIR/system"

# ── 1. Service configs (rsync, incremental) ───────────────────────────────────

log "[configs] Syncing service configs..."

# Jellyfin: exclude transcodes, logs, cache (all rebuildable)
rsync -a --delete \
  --exclude 'cache/' \
  --exclude 'log/' \
  --exclude 'logs/' \
  --exclude 'transcodes/' \
  /home/pibulus/.config/jellyfin/ "$BACKUP_DIR/configs/jellyfin/" >> "$LOG" 2>&1
log "  jellyfin: OK"

rsync -a --delete \
  --exclude 'cache/' \
  /home/pibulus/.config/navidrome/ "$BACKUP_DIR/configs/navidrome/" >> "$LOG" 2>&1
log "  navidrome: OK"

rsync -a --delete \
  --exclude 'cache/' \
  --exclude 'cache-long/' \
  --exclude 'logs/' \
  /home/pibulus/.config/kavita/ "$BACKUP_DIR/configs/kavita/" >> "$LOG" 2>&1
log "  kavita: OK"

rsync -a --delete \
  /home/pibulus/.config/calibre-web/ "$BACKUP_DIR/configs/calibre-web/" >> "$LOG" 2>&1
log "  calibre-web: OK"

if [ -d /home/pibulus/.config/audiobookshelf ]; then
    rsync -a --delete \
      /home/pibulus/.config/audiobookshelf/ "$BACKUP_DIR/configs/audiobookshelf/" >> "$LOG" 2>&1
    log "  audiobookshelf: OK"
else
    log "  audiobookshelf: SKIP (not found)"
fi

rsync -a --delete \
  /home/pibulus/.config/memos/ "$BACKUP_DIR/configs/memos/" >> "$LOG" 2>&1
log "  memos: OK"

if [ -d /home/pibulus/.config/thelounge ]; then
    rsync -a --delete \
      --exclude 'logs/' \
      /home/pibulus/.config/thelounge/ "$BACKUP_DIR/configs/thelounge/" >> "$LOG" 2>&1
    log "  thelounge: OK"
else
    log "  thelounge: SKIP (not found)"
fi

rsync -a --delete \
  --exclude 'logs/' \
  /home/pibulus/.config/qbittorrent/ "$BACKUP_DIR/configs/qbittorrent/" >> "$LOG" 2>&1
log "  qbittorrent: OK"

rsync -a --delete \
  /home/pibulus/filebrowser-db/ "$BACKUP_DIR/configs/filebrowser/" >> "$LOG" 2>&1
log "  filebrowser: OK"

if [ -d /home/pibulus/.config/pibulus-youtube-archive ]; then
    rsync -a --delete \
      /home/pibulus/.config/pibulus-youtube-archive/ "$BACKUP_DIR/configs/pibulus-youtube-archive/" >> "$LOG" 2>&1
    log "  youtube-archive: OK"
else
    log "  youtube-archive: SKIP (not found)"
fi

mkdir -p "$BACKUP_DIR/configs/curator"
cp /home/pibulus/pibulus-os/data/curator_list.json "$BACKUP_DIR/configs/curator/curator_list.json" 2>> "$LOG" || true
cp /home/pibulus/pibulus-os/data/curator_log.txt "$BACKUP_DIR/configs/curator/curator_log.txt" 2>> "$LOG" || true
log "  curator-state: OK"

# ── 2. AzuraCast MariaDB dump ─────────────────────────────────────────────────

log "[db] Dumping AzuraCast database..."
MYSQL_PWD=$(grep ^MYSQL_PASSWORD ~/azuracast/azuracast.env | cut -d= -f2)
if docker exec -e MYSQL_PWD="$MYSQL_PWD" azuracast \
    sh -c 'mariadb-dump --single-transaction -u azuracast -p"$MYSQL_PWD" azuracast' 2>/dev/null \
    | gzip > "$BACKUP_DIR/docker-db/azuracast-$DATE.sql.gz"; then
    SIZE=$(ls -lh "$BACKUP_DIR/docker-db/azuracast-$DATE.sql.gz" | awk '{print $5}')
    log "  azuracast-db: OK ($SIZE)"
else
    log "  azuracast-db: FAILED"
fi
# Keep 14 days
ls -t "$BACKUP_DIR/docker-db/azuracast-"*.sql.gz 2>/dev/null | tail -n +15 | xargs rm -f 2>/dev/null

log "[db] Dumping RomM database..."
if docker exec romm-db \
    sh -c 'mariadb-dump --single-transaction -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" "$MARIADB_DATABASE"' 2>/dev/null \
    | gzip > "$BACKUP_DIR/docker-db/romm-$DATE.sql.gz"; then
    SIZE=$(ls -lh "$BACKUP_DIR/docker-db/romm-$DATE.sql.gz" | awk '{print $5}')
    log "  romm-db: OK ($SIZE)"
else
    log "  romm-db: FAILED"
fi
# Keep 14 days
ls -t "$BACKUP_DIR/docker-db/romm-"*.sql.gz 2>/dev/null | tail -n +15 | xargs rm -f 2>/dev/null

# ── 3. Docker/app state ───────────────────────────────────────────────────────
# Contains playlists, station config, media metadata, and presentation assets.

log "[volumes] Backing up AzuraCast station_data..."
if docker run --rm \
    -v azuracast_station_data:/source:ro \
    -v "$BACKUP_DIR/volumes":/backup \
    alpine tar -czf /backup/azuracast-station_data.tar.gz -C /source . >> "$LOG" 2>&1; then
    SIZE=$(ls -lh "$BACKUP_DIR/volumes/azuracast-station_data.tar.gz" | awk '{print $5}')
    log "  station_data: OK ($SIZE)"
else
    log "  station_data: FAILED"
fi

if [ -d /media/pibulus/passport/app-data/romm/config ]; then
    rsync -a --delete \
      /media/pibulus/passport/app-data/romm/config/ "$BACKUP_DIR/volumes/romm-config/" >> "$LOG" 2>&1
    log "  romm-config: OK"
else
    log "  romm-config: SKIP (not found)"
fi

if [ -d /media/pibulus/passport/app-data/romm/assets ]; then
    rsync -a --delete \
      /media/pibulus/passport/app-data/romm/assets/ "$BACKUP_DIR/volumes/romm-assets/" >> "$LOG" 2>&1
    log "  romm-assets: OK"
else
    log "  romm-assets: SKIP (not found)"
fi

# ── 4. Key system files ───────────────────────────────────────────────────────

log "[system] Backing up system configs..."
cp /etc/fstab "$BACKUP_DIR/system/fstab" 2>> "$LOG"
sudo cp /etc/cloudflared/config.yml "$BACKUP_DIR/system/cloudflared-config.yml" 2>> "$LOG"
crontab -l > "$BACKUP_DIR/system/crontab.txt" 2>> "$LOG"
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' \
    > "$BACKUP_DIR/system/docker-services.txt" 2>> "$LOG"
log "  system: OK"

# ── 5. Pibulus-OS (scripts, compose files, www) ───────────────────────────────

log "[pibulus-os] Syncing pibulus-os repo..."
rsync -a --delete \
  --exclude '.git/' \
  --exclude '.cloudflared/' \
  --exclude '.env' \
  --exclude '.env.*' \
  --exclude 'config/nginx/.htpasswd*' \
  --exclude 'azuracast/.env' \
  --exclude 'azuracast/azuracast.env' \
  --exclude 'pibulus-os.env' \
  --exclude 'config/user-accounts.txt' \
  --exclude 'config/stacks/icloudpd_config/*.session' \
  --exclude 'config/stacks/icloudpd_config/*.json' \
  --exclude 'data/' \
  --exclude '*.log' \
  --exclude '*.bak' \
  --exclude '*.backup' \
  /home/pibulus/pibulus-os/ "$BACKUP_DIR/pibulus-os/" >> "$LOG" 2>&1
log "  pibulus-os: OK"

# ── Done ──────────────────────────────────────────────────────────────────────

TOTAL=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
log "=== Backup complete. Total: $TOTAL ==="
