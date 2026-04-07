#!/bin/bash
# Re-apply AzuraCast performance patches after container recreate
# These patches live inside the container and are lost on docker pull/recreate
# Run after: docker compose pull, docker recreate, or any AzuraCast update

set -e

log() { echo "[azuracast-patch] $1"; }

if ! docker ps --format '{{.Names}}' | grep -qx azuracast; then
    log "AzuraCast not running — start it first"
    exit 1
fi

# Patch CheckMediaTask: every 5min -> daily 3:30am
# This is the big one — scans entire NTFS media library, murders Pi I/O
docker exec azuracast sed -i \
    "s|return '1-59/5 \* \* \* \*';|return '30 3 * * *'; // PATCHED: daily 3:30am (Pi I/O)|" \
    /var/azuracast/www/backend/src/Sync/Task/CheckMediaTask.php

log "CheckMediaTask -> daily 3:30am"

# CheckUpdatesTask uses its own timing (not cron), runs infrequently — leave it alone
# ENABLE_WEB_UPDATER=false in azuracast.env handles the update check

log "Done. Restart AzuraCast to apply: docker restart azuracast"
