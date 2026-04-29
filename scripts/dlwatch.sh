#!/bin/bash
# dlwatch — live download progress viewer
# Usage: dlwatch [filter]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
[ -f "$SCRIPT_DIR/load_pibulus_env.sh" ] && . "$SCRIPT_DIR/load_pibulus_env.sh"

FILTER="${1:-}"
QB_URL="${QB_WEBUI_URL:-http://localhost:8888}"

while true; do
  clear
  echo "  :: qbittorrent downloads :: $(date '+%H:%M:%S')"
  echo "  ─────────────────────────────────────────────────────────────────────"

  curl -s --max-time 3 -c /tmp/qb-watch.txt \
    --data-urlencode "username=${QB_WEBUI_USERNAME:-admin}" \
    --data-urlencode "password=${QB_WEBUI_PASSWORD:?QB_WEBUI_PASSWORD not set}" \
    "$QB_URL/api/v2/auth/login" > /dev/null 2>&1

  curl -s --max-time 5 -b /tmp/qb-watch.txt \
    "$QB_URL/api/v2/torrents/info" 2>/dev/null > /tmp/qb-info.json

  python3 - "$FILTER" << 'EOF'
import json, sys, os

try:
    torrents = json.load(open('/tmp/qb-info.json'))
except Exception:
    print("  (no data)")
    sys.exit()

filt = sys.argv[1].lower() if len(sys.argv) > 1 else ""

active    = [t for t in torrents if t["state"] in ("downloading","metaDL","stalledDL") and (not filt or filt in t["name"].lower())]
queued    = [t for t in torrents if t["state"] in ("queuedDL",) and (not filt or filt in t["name"].lower())]
done      = [t for t in torrents if t["state"] in ("uploading","stalledUP","queuedUP") and (not filt or filt in t["name"].lower())]

total_dl  = sum(t.get("dlspeed",0) for t in active) // 1024

print(f"  active: {len(active)}  queued: {len(queued)}  done: {len(done)}  speed: {total_dl}KB/s")
print()

if active:
    print("  DOWNLOADING:")
    for t in sorted(active, key=lambda x: x["progress"], reverse=True):
        prog  = t["progress"] * 100
        speed = t.get("dlspeed", 0) // 1024
        eta   = t.get("eta", -1)
        eta_s = f"{eta//3600}h{(eta%3600)//60}m" if 0 < eta < 86400 else "∞"
        bar   = "█" * int(prog/5) + "░" * (20 - int(prog/5))
        name  = t["name"][:45]
        print(f"  {bar} {prog:>5.1f}%  {speed:>5}KB/s  eta:{eta_s:<8}  {name}")
    print()

if queued[:5]:
    print(f"  QUEUED (next {min(5,len(queued))} of {len(queued)}):")
    for t in queued[:5]:
        size = t.get("total_size", t.get("size", 0)) // 1024 // 1024
        print(f"  {'░'*20}   0.0%          {size:>5}MB  {t['name'][:45]}")
    print()
EOF

  sleep 3
done
