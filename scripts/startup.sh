#!/bin/bash
# PIBULUS OS — Staggered Docker Startup v2
# Runs automatically on boot via systemd, or manually: ~/pibulus-os/scripts/startup.sh
# Why: 19 containers starting at once OOM-kills sshd on 4GB Pi
#
# Now containers have restart=no, so ONLY this script starts them.
# Priority order:
#   1. Infrastructure (nginx) — gateway for everything
#   2. Core services (AzuraCast, Jellyfin, Navidrome) — the essentials
#   3. Secondary services (Calibre, Kavita, Memos, etc.)
#   4. Heavy/optional services (RomM, slskd, qBittorrent)
#   5. Skip: Immich, ScummVM (start manually if needed)

set -e

log() { echo "[$(date "+%H:%M:%S")] $1"; }

FAILED_STARTS=()

wait_for_calm() {
    local target="${1:-6}"
    local max_wait="${2:-60}"
    local waited=0
    local load
    while [ $waited -lt $max_wait ]; do
        load=$(cut -d" " -f1 /proc/loadavg)
        if awk "BEGIN{exit !($load < $target)}"; then
            return 0
        fi
        log "  Load $load (target <$target) — waiting..."
        sleep 5
        waited=$((waited + 5))
    done
    log "  Load still high after ${max_wait}s — continuing anyway"
}

start_containers() {
    local name
    for name in "$@"; do
        if docker start "$name" >/dev/null 2>&1; then
            log "  Started $name"
        else
            log "  FAILED to start $name"
            FAILED_STARTS+=("$name")
        fi
    done
}

require_docker_ready() {
    local attempts="${1:-30}"
    local delay="${2:-2}"
    local i
    for i in $(seq 1 "$attempts"); do
        if docker info >/dev/null 2>&1; then
            return 0
        fi
        sleep "$delay"
    done
    log "Docker never became ready — aborting startup run"
    exit 1
}

log "=== PIBULUS OS Staggered Startup v2 ==="
log "Memory: $(free -h | awk '/Mem:/{print $3"/"$2" used"}')"
log "Load: $(cat /proc/loadavg)"

# Wait for Docker to be fully ready
log "Waiting for Docker..."
require_docker_ready 30 2

# Tier 1: Infrastructure (nginx gateway)
log "[Tier 1] Infrastructure"
start_containers web_host
sleep 3

# Tier 2: Core entertainment — KPAB is the priority
log "[Tier 2] Core services"
wait_for_calm 6 45
start_containers azuracast
log "  AzuraCast started — waiting for it to settle..."
sleep 20

wait_for_calm 5 45
start_containers jellyfin navidrome
sleep 8

# Tier 3: Secondary services (lightweight)
log "[Tier 3] Secondary services"
wait_for_calm 5 45
start_containers calibre-web kavita
sleep 8
start_containers memos filebrowser kiwix
sleep 5

# Tier 4: Heavy/optional
log "[Tier 4] Heavy services"
wait_for_calm 4 60
start_containers romm-db romm-redis
sleep 8
start_containers romm
sleep 8
wait_for_calm 4 60
log "  slskd: SKIP manual-only after overload/corruption incidents"
start_containers qbittorrent

log "=== Startup pass complete ==="
log "Load: $(cat /proc/loadavg)"
log "Memory: $(free -h | awk '/Mem:/{print $3"/"$2" used"}')"
if [ ${#FAILED_STARTS[@]} -gt 0 ]; then
    log ""
    log "Containers that failed to start: ${FAILED_STARTS[*]}"
else
    log "All requested containers started cleanly."
fi
log ""
log "Skipped (start manually if needed):"
log "  docker start slskd"
log "  docker start immich_server immich_postgres immich_redis"
log "  docker start scummvm"
