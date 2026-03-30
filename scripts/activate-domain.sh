#!/bin/bash
# 🌐 ACTIVATE-DOMAIN — Add any domain to Cloudflare + point to Pi tunnel
# Usage: bash activate-domain.sh <domain>
#
# Does everything: Cloudflare zone creation, Porkbun NS update, CNAME to tunnel
# Run this ONCE per domain. After that, ship-to-pi.sh handles deployments.

set -e
source ~/.secrets/porkbun_keys 2>/dev/null

DOMAIN="$1"
CF_TOKEN="$CLOUDFLARE_API_TOKEN"
CF_ACCOUNT="${CLOUDFLARE_ACCOUNT_ID:-c5a72aa2df2ddaa73fe129888a3d3402}"
TUNNEL_ID="c79eb8a2-9791-4ece-8b54-bc9d0e6d01cd"

if [ -z "$DOMAIN" ]; then
  echo "Usage: activate-domain.sh <domain>"
  echo "Example: activate-domain.sh talktype.app"
  exit 1
fi

if [ -z "$CF_TOKEN" ]; then
  echo "ERROR: No CLOUDFLARE_API_TOKEN in ~/.config/api_keys"
  exit 1
fi

echo ""
echo "=== ACTIVATE DOMAIN: $DOMAIN ==="
echo ""

# 1. Check if zone already exists
echo "[1/3] Checking Cloudflare zones..."
EXISTING=$(curl -s -H "Authorization: Bearer $CF_TOKEN" \
  "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN&account.id=$CF_ACCOUNT" | \
  python3 -c "import json,sys; d=json.load(sys.stdin); r=d.get('result',[]); print(r[0]['id'] if r else '')" 2>/dev/null)

if [ -n "$EXISTING" ]; then
  echo "       Zone exists: $EXISTING"
  ZONE_ID="$EXISTING"
else
  echo "       Creating zone..."
  RESULT=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones" \
    -H "Authorization: Bearer $CF_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"$DOMAIN\",\"account\":{\"id\":\"$CF_ACCOUNT\"},\"type\":\"full\"}")

  ZONE_ID=$(echo "$RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('result',{}).get('id',''))" 2>/dev/null)
  NS=$(echo "$RESULT" | python3 -c "import json,sys; print(' '.join(json.load(sys.stdin).get('result',{}).get('name_servers',[])))" 2>/dev/null)

  if [ -z "$ZONE_ID" ]; then
    echo "       FAILED: $(echo "$RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('errors',[{}])[0].get('message','unknown'))" 2>/dev/null)"
    exit 1
  fi
  echo "       Zone created: $ZONE_ID"
  echo "       Nameservers: $NS"

  # 2. Update Porkbun nameservers
  echo "[2/3] Updating Porkbun nameservers..."
  NS_ARRAY=$(echo "$NS" | python3 -c "import sys; ns=sys.stdin.read().split(); print(','.join(['\"'+n+'\"' for n in ns]))")

  PB_RESULT=$(curl -s -X POST "https://api.porkbun.com/api/json/v3/domain/updateNs/$DOMAIN" \
    -H "Content-Type: application/json" \
    -d "{
      \"apikey\":\"$PORKBUN_API_KEY\",
      \"secretapikey\":\"$PORKBUN_SECRET_KEY\",
      \"ns\":[$NS_ARRAY]
    }")

  if echo "$PB_RESULT" | grep -q "SUCCESS"; then
    echo "       Nameservers updated at Porkbun."
  else
    echo "       WARNING: Porkbun NS update failed. Update manually:"
    echo "       $NS"
  fi
fi

# 3. Add CNAME to tunnel (if not already set)
echo "[3/3] Setting CNAME to tunnel..."
CNAME_EXISTS=$(curl -s -H "Authorization: Bearer $CF_TOKEN" \
  "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=CNAME&name=$DOMAIN" | \
  python3 -c "import json,sys; r=json.load(sys.stdin).get('result',[]); print('yes' if r else 'no')" 2>/dev/null)

if [ "$CNAME_EXISTS" = "yes" ]; then
  echo "       CNAME already exists."
else
  DNS_RESULT=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
    -H "Authorization: Bearer $CF_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"type\":\"CNAME\",
      \"name\":\"@\",
      \"content\":\"$TUNNEL_ID.cfargotunnel.com\",
      \"proxied\":true,
      \"ttl\":1
    }")

  if echo "$DNS_RESULT" | grep -q '"success":true'; then
    echo "       CNAME → tunnel (proxied)"
  else
    echo "       CNAME creation failed."
  fi
fi

echo ""
echo "=== DOMAIN ACTIVATED: $DOMAIN ==="
echo "    Zone: $ZONE_ID"
echo "    CNAME: $DOMAIN → tunnel (proxied, SSL auto)"
echo "    NS propagation: may take up to 24h (usually ~30min)"
echo ""
echo "    Next: bash ship-to-pi.sh <app-path> $DOMAIN <app-name>"
echo ""
