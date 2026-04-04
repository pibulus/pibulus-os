#!/bin/bash
# qb_unstick.sh — pause torrents stuck in metaDL or stalledDL for too long
# Runs via cron every 10 minutes

QB_URL="http://localhost:8888"
COOKIE_JAR="/tmp/qb_unstick_cookies.txt"
STALL_LIMIT=600  # seconds — pause if stuck longer than this

# Login
curl -s -c "$COOKIE_JAR" \
  -X POST "$QB_URL/api/v2/auth/login" \
  -d "username=admin&password=meringue" \
  -H "Referer: $QB_URL" > /dev/null

# Find torrents stuck in metaDL or stalledDL beyond the time limit
HASHES=$(curl -s -b "$COOKIE_JAR" "$QB_URL/api/v2/torrents/info" \
  -H "Referer: $QB_URL" | python3 -c "
import json, sys, time
data = json.load(sys.stdin)
now = time.time()
stuck = []
for t in data:
    if t['state'] in ('metaDL', 'stalledDL'):
        # time_active is how long the torrent has been active in seconds
        # last_activity is epoch of last data received
        last = t.get('last_activity', 0)
        time_active = t.get('time_active', 0)
        # stalled if last activity was more than STALL_LIMIT seconds ago
        if last > 0 and (now - last) > $STALL_LIMIT:
            stuck.append(t['hash'])
            print(f'Pausing stuck torrent: {t[\"name\"][:60]} (state={t[\"state\"]}, idle={int(now-last)}s)', file=sys.stderr)
        elif last == 0 and time_active > $STALL_LIMIT:
            stuck.append(t['hash'])
            print(f'Pausing stuck torrent: {t[\"name\"][:60]} (state={t[\"state\"]}, no activity)', file=sys.stderr)
print('|'.join(stuck))
")

if [ -n "$HASHES" ] && [ "$HASHES" != "|" ]; then
  curl -s -b "$COOKIE_JAR" \
    -X POST "$QB_URL/api/v2/torrents/stop" \
    -H "Referer: $QB_URL" \
    -d "hashes=$HASHES" > /dev/null
fi
