#!/bin/bash
# PIBULUS OS — Staggered Docker Startup
# Runs automatically on boot via systemd, or manually: ~/pibulus-os/scripts/startup.sh
# Why: 19 containers starting at once OOM-kills sshd on 4GB Pi
#
# Priority order:
#   1. Infrastructure (nginx, cloudflared) — everything depends on these
#   2. Core services (AzuraCast, Jellyfin, Navidrome) — the essentials
#   3. Secondary services (Calibre, Kavita, Memos, etc.)
#   4. Heavy/optional services (RomM, slskd, qBittorrent)
#   5. Skip: Immich (too RAM-heavy for 4GB Pi)

set -e

log() { echo "[$(date '+%H:%M:%S')] $1"; }

wait_for_calm() {
    local target="${1:-5}"
    local tries=0
    while [ $tries -lt 30 ]; do
        load=$(cut -d' ' -f1 /proc/loadavg)
        if awk "BEGIN{exit !($load < $target)}"; then
            return
        fi
        log "  Load $load — waiting..."
        sleep 5
        tries=$((tries + 1))
    done
    log "  Load still high after 150s — continuing anyway"
}

log "=== PIBULUS OS Staggered Startup ==="

# Start Docker if not running
if ! systemctl is-active --quiet docker; then
    log "Starting Docker..."
    sudo systemctl start docker
    sleep 8
fi

# Tier 1: Infrastructure
log "[Tier 1] Infrastructure"
docker start web_host 2>/dev/null || true
sleep 3

# Tier 2: Core entertainment
log "[Tier 2] Core services"
wait_for_calm 5
docker start azuracast 2>/dev/null || true
sleep 15

# Apply AzuraCast performance patches (sync throttling)
if [ -x ~/pibulus-os/scripts/azuracast-patch.sh ]; then
    log "Applying AzuraCast patches..."
    bash ~/pibulus-os/scripts/azuracast-patch.sh 2>/dev/null || true
    docker restart azuracast 2>/dev/null || true
    sleep 10
fi

wait_for_calm 5
docker start jellyfin 2>/dev/null || true
sleep 5
docker start navidrome 2>/dev/null || true
sleep 3

# Tier 3: Secondary services
log "[Tier 3] Secondary services"
wait_for_calm 5
docker start calibre-web kavita 2>/dev/null || true
sleep 5
docker start memos shortener filebrowser kiwix 2>/dev/null || true
sleep 3

# Tier 4: Heavy/optional
log "[Tier 4] Heavy services"
wait_for_calm 4
docker start romm-db romm-redis 2>/dev/null || true
sleep 5
docker start romm 2>/dev/null || true
sleep 5
wait_for_calm 4
docker start slskd 2>/dev/null || true
docker start qbittorrent 2>/dev/null || true
sleep 3

log "=== All services started ==="
log "Load: $(cat /proc/loadavg)"
log "Memory: $(free -h | awk '/Mem:/{print $3"/"$2" used"}')"
log ""
log "Skipped (start manually if needed):"
log "  docker start immich_server immich_postgres immich_redis"
log "  docker start scummvm"
log "  docker start tunarr television-simulator"
