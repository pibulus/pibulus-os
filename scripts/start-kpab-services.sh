#!/usr/bin/env bash
# Quick Cat Club microservices launcher.
# Starts: shoutbox (8087), wall (8086), hearts (8092), public deck (7683), admin shell (7684).

set -u

SCRIPTS=${PIBULUS_OS_ROOT:-/home/pibulus/pibulus-os}
ENV_FILE=${PIBULUS_OS_ENV:-$SCRIPTS/pibulus-os.env}

if [ -r "$ENV_FILE" ]; then
  # Local-only credentials and overrides. This file is gitignored.
  # shellcheck disable=SC1090
  . "$ENV_FILE"
fi

log() {
  printf '[%s] %s\n' "$(date)" "$*"
}

start_python_service() {
  local label=$1
  local script=$2
  local port=$3

  python3 "$SCRIPTS/scripts/$script" &
  log "$label ($port) PID: $!"
}

log 'Cleaning up any existing aggregate microservice processes...'
pkill -f 'kpab_shoutbox.py' 2>/dev/null || true
pkill -f 'wall_server.py' 2>/dev/null || true
pkill -f 'kpab_hearts.py' 2>/dev/null || true
pkill -f 'ttyd.*768[34]' 2>/dev/null || true
sleep 2

# Give Docker services a moment to settle after boot.
sleep "${KPAB_STARTUP_DELAY:-10}"

log 'Starting Quick Cat Club microservices...'

start_python_service 'Shoutbox' 'kpab_shoutbox.py' '8087'
start_python_service 'Wall Server' 'wall_server.py' '8086'
start_python_service 'Hearts' 'kpab_hearts.py' '8092'

# Public Cyberdeck: no auth, sandboxed to the textworld launcher.
/usr/local/bin/ttyd --writable -p 7683 \
  -t fontSize=16 \
  -t fontFamily=monospace \
  -t cursorBlink=true \
  -t 'theme={"background":"#020402","foreground":"#d8f3dc","cursor":"#ffb000","selection":"#244c2f"}' \
  --max-clients 5 \
  "$SCRIPTS/public-deck.sh" &
log "Public Deck (7683) PID: $!"

if [ -n "${TTYD_ADMIN_AUTH:-}" ]; then
  /usr/local/bin/ttyd --writable -b /shell/ -p 7684 \
    -c "$TTYD_ADMIN_AUTH" \
    -t fontSize=16 \
    -t fontFamily=monospace \
    -t 'theme={"background":"#0D0F14","foreground":"#C8D8E8","cursor":"#E040FB"}' \
    /bin/bash -l &
  log "Admin Shell (7684) PID: $!"
else
  log 'TTYD_ADMIN_AUTH is not set; admin shell (7684) was not started.'
fi

log 'All aggregate microservices started'
wait
