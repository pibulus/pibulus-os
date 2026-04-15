#!/usr/bin/env bash
# Cloudflare zone watchdog — detects "moved" status and re-triggers activation check
# Runs every 30 minutes via cron. Alerts via KPAB shoutbox if it has to fix things.

CF_TOKEN="${CF_WATCHDOG_TOKEN:?CF_WATCHDOG_TOKEN not set in pibulus-os.env}"
ZONE_ID="${CF_ZONE_ID:?CF_ZONE_ID not set in pibulus-os.env}"
LOGFILE="/var/log/cloudflare-watchdog.log"

log() { echo "[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] $*" | tee -a "$LOGFILE"; }

STATUS=$(curl -s "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}" \
  -H "Authorization: Bearer ${CF_TOKEN}" | python3 -c "import sys,json; print(json.load(sys.stdin)['result']['status'])" 2>/dev/null)

if [ "$STATUS" = "active" ]; then
  # All good, silent exit
  exit 0
fi

log "ALERT: quickcat.club zone status is '${STATUS}' — triggering activation check"

RESULT=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/activation_check" \
  -H "Authorization: Bearer ${CF_TOKEN}" \
  -H "Content-Type: application/json")

SUCCESS=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['success'])" 2>/dev/null)

if [ "$SUCCESS" = "True" ]; then
  log "Activation check triggered successfully. Zone was '${STATUS}', re-checking now."
else
  log "ERROR: Activation check failed. Response: $RESULT"
fi
