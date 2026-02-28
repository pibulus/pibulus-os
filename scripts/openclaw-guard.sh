#!/bin/bash
# OpenClaw Guard - smart start/stop with RAM awareness
# Usage: openclaw-guard.sh [start|stop|status|check]

MIN_FREE_MB=800  # Don't start if less than 800MB available
SERVICE="openclaw.service"

case "${1:-status}" in
  start)
    AVAIL=$(free -m | awk '/^Mem:/{print $7}')
    if [ "$AVAIL" -lt "$MIN_FREE_MB" ]; then
      echo "⚠️  Only ${AVAIL}MB available (need ${MIN_FREE_MB}MB). OpenClaw not started."
      echo "   Free up RAM first: docker stop immich_server immich_postgres"
      exit 1
    fi
    sudo systemctl start "$SERVICE"
    sleep 2
    if systemctl is-active --quiet "$SERVICE"; then
      echo "✅ OpenClaw gateway started (${AVAIL}MB was available)"
    else
      echo "❌ OpenClaw failed to start. Check: journalctl -u openclaw -n 20"
      exit 1
    fi
    ;;
  stop)
    sudo systemctl stop "$SERVICE"
    echo "✅ OpenClaw gateway stopped"
    ;;
  status)
    if systemctl is-active --quiet "$SERVICE"; then
      PID=$(systemctl show "$SERVICE" --property=MainPID --value)
      MEM=$(ps -p "$PID" -o rss= 2>/dev/null | awk '{printf "%.0f", $1/1024}')
      echo "✅ OpenClaw running (PID $PID, ${MEM}MB RAM)"
    else
      echo "⏸️  OpenClaw not running"
    fi
    ;;
  check)
    # Called by cron - auto-heal if needed
    if ! systemctl is-active --quiet "$SERVICE"; then
      exit 0  # Not running, that's fine - don't auto-start
    fi
    # If running, check if it's healthy (port responding)
    if ! ss -tlnp | grep -q ":18789 "; then
      echo "$(date): OpenClaw running but port 18789 not listening - restarting"
      sudo systemctl restart "$SERVICE"
    fi
    ;;
esac
