#!/usr/bin/env bash
# wire-app.sh APP — make a deployed app reachable: DNS (CF CNAME→tunnel) +
# tunnel ingress + verify. Reads port/domain from apps-registry.json.
# Idempotent: safe to re-run. The "once and for all" glue.
#
#   bash wire-app.sh cryptkeep
set -euo pipefail
APP="${1:?usage: wire-app.sh APP}"
REG="$HOME/pibulus-os/apps-registry.json"
CFG="/etc/cloudflared/config.yml"
source "$HOME/.config/api_keys" 2>/dev/null || true
TOK="${CLOUDFLARE_API_TOKEN:?CLOUDFLARE_API_TOKEN missing}"

read PORT DOMAIN TUNNEL < <(python3 - "$REG" "$APP" <<'PY'
import json,sys
d=json.load(open(sys.argv[1])); a=d["apps"].get(sys.argv[2])
if not a or not a.get("domain"): print("ERR"); sys.exit(1)
print(a["port"], a["domain"], d["tunnel"])
PY
)
[ "$PORT" = "ERR" ] && { echo "no registry entry/domain for $APP"; exit 1; }
TUNNEL_CNAME="$TUNNEL.cfargotunnel.com"
echo "→ wiring $APP : $DOMAIN → :$PORT"

api(){ curl -s -H "Authorization: Bearer $TOK" -H "Content-Type: application/json" "$@"; }

# 1. DNS — apex + www as proxied CNAME to the tunnel (clear conflicts first)
ZID=$(api "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" | python3 -c "import sys,json;r=json.load(sys.stdin)['result'];print(r[0]['id'] if r else '')")
[ -z "$ZID" ] && { echo "  ! $DOMAIN not a CF zone — skipping DNS"; } || {
  for host in "$DOMAIN" "www.$DOMAIN"; do
    cur=$(api "https://api.cloudflare.com/client/v4/zones/$ZID/dns_records?name=$host")
    # already a CNAME to our tunnel? leave it
    if echo "$cur" | grep -q "$TUNNEL_CNAME"; then echo "  = DNS $host ok"; continue; fi
    for id in $(echo "$cur" | python3 -c "import sys,json;[print(r['id']) for r in json.load(sys.stdin)['result']]"); do
      api -X DELETE "https://api.cloudflare.com/client/v4/zones/$ZID/dns_records/$id" >/dev/null
    done
    ok=$(api -X POST "https://api.cloudflare.com/client/v4/zones/$ZID/dns_records" -d "{\"type\":\"CNAME\",\"name\":\"$host\",\"content\":\"$TUNNEL_CNAME\",\"proxied\":true}" | python3 -c "import sys,json;print(json.load(sys.stdin)['success'])")
    echo "  + DNS $host → tunnel ($ok)"
  done
}

# 2. Ingress — add rule before the catch-all (idempotent)
if sudo grep -q "hostname: $DOMAIN\$" "$CFG"; then
  echo "  = ingress $DOMAIN already present"
else
  sudo cp "$CFG" "$CFG.bak.$(date +%s)"
  sudo python3 - "$CFG" "$DOMAIN" "$PORT" <<'PY'
import sys
cfg,host,port=sys.argv[1],sys.argv[2],sys.argv[3]
L=open(cfg).read().splitlines()
ins=[f"- hostname: {host}",f"  service: http://localhost:{port}",
     f"- hostname: www.{host}",f"  service: http://localhost:{port}"]
i=next(k for k,l in enumerate(L) if l.strip().startswith("- service: http_status"))
L[i:i]=ins; open(cfg,"w").write("\n".join(L)+"\n")
PY
  sudo cloudflared tunnel --config "$CFG" ingress validate >/dev/null 2>&1 && echo "  + ingress added (valid)" || { echo "  ! ingress invalid — check $CFG"; exit 1; }
  sudo systemctl restart cloudflared; sleep 4
  echo "  ↻ cloudflared restarted"
fi

# 3. Verify
sleep 3
code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 "https://$DOMAIN/" 2>/dev/null)
echo "✓ https://$DOMAIN → $code"
[ "$code" = "200" ] && python3 - "$REG" "$APP" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d["apps"][sys.argv[2]]["status"]="live"
json.dump(d,open(p,"w"),indent=2)
PY
