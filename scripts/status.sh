#!/bin/bash
# 📊 PIBULUS STATUS & POWER MONITOR

TEMP=$(vcgencmd measure_temp | grep -oP '[0-9.]+')
UPTIME=$(uptime -p | sed 's/up //; s/ days\?/d/g; s/ hours\?/h/g; s/ minutes\?/m/g; s/,//g')

# Power/Throttle check (0x0 means all good)
THROTTLED_HEX=$(vcgencmd get_throttled | cut -d'=' -f2)
POWER_STATUS="OK"
[[ "$THROTTLED_HEX" != "0x0" ]] && POWER_STATUS="⚠️ ISSUE"

DISK_PCT=$(df -h /media/pibulus/passport 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%')
[ -z "$DISK_PCT" ] && DISK_PCT="ERR"

cat > /media/pibulus/passport/www/html/status.json <<JSON
{
  "temp": "${TEMP}C",
  "uptime": "$UPTIME",
  "power": "$POWER_STATUS",
  "disk": "${DISK_PCT}%",
  "last_seen": "$(date '+%H:%M:%S')"
}
JSON
