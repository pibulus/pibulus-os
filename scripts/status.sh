#!/bin/bash
# 📊 PIBULUS STATUS v2 — feeds the deck dashboard

TEMP=$(vcgencmd measure_temp | grep -oP '[0-9.]+')
UPTIME=$(uptime -p | sed 's/up //; s/ days\?/d/g; s/ hours\?/h/g; s/ minutes\?/m/g; s/,//g')

# Power/Throttle check
THROTTLED_HEX=$(vcgencmd get_throttled | cut -d'=' -f2)
POWER_STATUS="OK"
[[ "$THROTTLED_HEX" != "0x0" ]] && POWER_STATUS="THROTTLED"

# Disk
DISK_PCT=$(df -h /media/pibulus/passport 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%')
DISK_USED=$(df -h /media/pibulus/passport 2>/dev/null | awk 'NR==2 {print $3}')
DISK_TOTAL=$(df -h /media/pibulus/passport 2>/dev/null | awk 'NR==2 {print $2}')
ROOT_PCT=$(df -h / 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%')

# RAM
RAM_USED=$(free -m | awk '/Mem:/ {print $3}')
RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
RAM_PCT=$((RAM_USED * 100 / RAM_TOTAL))

# Containers
CONTAINERS=$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')

# Now playing (AzuraCast)
NP_JSON=$(curl -s --max-time 3 http://localhost:8500/api/nowplaying 2>/dev/null)
NP_ARTIST=$(echo "$NP_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['now_playing']['song']['artist'])" 2>/dev/null || echo "")
NP_TITLE=$(echo "$NP_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['now_playing']['song']['title'])" 2>/dev/null || echo "")
NP_LISTENERS=$(echo "$NP_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['listeners']['current'])" 2>/dev/null || echo "0")

# Load average
LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | tr -d ' ')

# Connected users — unique real IPs from nginx logs in last 10 minutes
# X-Forwarded-For is the last quoted field in combined+proxy log format
USERS_ONLINE=$(docker logs web_host --since 10m 2>/dev/null | \
  grep -oP '"\d+\.\d+\.\d+\.\d+"$' | tr -d '"' | \
  grep -v '^-$' | sort -u | wc -l | tr -d ' ')

cat > /media/pibulus/passport/www/html/status.json <<JSON
{
  "temp": "${TEMP}",
  "uptime": "$UPTIME",
  "power": "$POWER_STATUS",
  "disk_pct": ${DISK_PCT:-0},
  "disk_used": "${DISK_USED:-?}",
  "disk_total": "${DISK_TOTAL:-?}",
  "root_pct": ${ROOT_PCT:-0},
  "ram_used": ${RAM_USED:-0},
  "ram_total": ${RAM_TOTAL:-0},
  "ram_pct": ${RAM_PCT:-0},
  "containers": ${CONTAINERS:-0},
  "load": "${LOAD:-?}",
  "np_artist": "$(echo "$NP_ARTIST" | sed 's/"/\\"/g')",
  "np_title": "$(echo "$NP_TITLE" | sed 's/"/\\"/g')",
  "np_listeners": ${NP_LISTENERS:-0},
  "users_online": ${USERS_ONLINE:-0},
  "ts": "$(date '+%H:%M:%S')",
  "date": "$(date '+%Y-%m-%d')"
}
JSON
