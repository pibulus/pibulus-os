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
NP_JSON=$(curl -s --max-time 3 http://localhost:8500/api/nowplaying/kpab.fm 2>/dev/null)
NP_ARTIST=$(echo "$NP_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('now_playing',{}).get('song',{}).get('artist',''))" 2>/dev/null || echo "")
NP_TITLE=$(echo "$NP_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('now_playing',{}).get('song',{}).get('title',''))" 2>/dev/null || echo "")
NP_NEXT_ARTIST=$(echo "$NP_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('playing_next',{}).get('song',{}).get('artist',''))" 2>/dev/null || echo "")
NP_NEXT_TITLE=$(echo "$NP_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('playing_next',{}).get('song',{}).get('title',''))" 2>/dev/null || echo "")
NP_LISTENERS_CURRENT=$(echo "$NP_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('listeners',{}).get('current',0))" 2>/dev/null || echo "0")
NP_LISTENERS_UNIQUE=$(echo "$NP_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('listeners',{}).get('unique',0))" 2>/dev/null || echo "0")
NP_LISTENERS_TOTAL=$(echo "$NP_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('listeners',{}).get('total',0))" 2>/dev/null || echo "0")

# Active Jellyfin streams (watching now)
WATCHING=$(curl -s --max-time 3 "http://localhost:8096/Sessions?api_key=1980cdafcfec43b58b04b89c4d1f5b99" 2>/dev/null | \
  python3 -c "import sys,json; s=json.load(sys.stdin); print(len([x for x in s if x.get('NowPlayingItem')]))" 2>/dev/null || echo "0")

# Load average
LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | tr -d ' ')

# Connected web visitors — unique IPs seen by web_host in the last 10 minutes.
# This is intentionally narrower than "everyone using the Pi" because services
# that bypass nginx (radio, Kavita, Jellyfin, etc.) will not appear here.
# X-Forwarded-For is the last quoted field in the combined+proxy log format.
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
  "np_next_artist": "$(echo "$NP_NEXT_ARTIST" | sed 's/"/\\"/g')",
  "np_next_title": "$(echo "$NP_NEXT_TITLE" | sed 's/"/\\"/g')",
  "np_listeners": ${NP_LISTENERS_CURRENT:-0},
  "np_listeners_unique": ${NP_LISTENERS_UNIQUE:-0},
  "np_listeners_total": ${NP_LISTENERS_TOTAL:-0},
  "watching": ${WATCHING:-0},
  "users_online": ${USERS_ONLINE:-0},
  "ts": "$(date '+%H:%M:%S')",
  "date": "$(date '+%Y-%m-%d')"
}
JSON
