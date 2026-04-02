#!/bin/bash
# Generate KPAB.FM request catalog as static JSON
# Run periodically via cron to keep fresh

OUTFILE="/home/pibulus/pibulus-os/www/html/kpab/catalog.json"
API="http://localhost:8500/api/station/1/requests"
TMPFILE="/tmp/kpab_catalog_build.json"

echo "[" > "$TMPFILE"
page=1
total=0
first=true

while true; do
    data=$(curl -sf "${API}?per_page=25&page=${page}" 2>/dev/null)
    [ -z "$data" ] && break
    
    rows=$(echo "$data" | python3 -c "
import sys, json
d = json.load(sys.stdin)
rows = d.get(\"rows\", [])
for r in rows:
    s = r.get(\"song\", {})
    print(json.dumps({
        \"id\": r.get(\"request_id\", \"\"),
        \"url\": r.get(\"request_url\", \"\"),
        \"t\": s.get(\"title\", \"\"),
        \"a\": s.get(\"artist\", \"\"),
        \"b\": s.get(\"album\", \"\"),
        \"art\": s.get(\"art\", \"\")
    }, separators=(\",\", \":\")))
" 2>/dev/null)
    
    count=$(echo "$rows" | grep -c "^{" 2>/dev/null || echo 0)
    
    if [ "$count" -eq 0 ]; then
        break
    fi
    
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        if [ "$first" = true ]; then
            first=false
        else
            echo "," >> "$TMPFILE"
        fi
        printf "%s" "$line" >> "$TMPFILE"
        total=$((total + 1))
    done <<< "$rows"
    
    page_total=$(echo "$data" | python3 -c "import sys,json; print(json.load(sys.stdin).get(\"total_pages\",0))" 2>/dev/null)
    
    if [ "$page" -ge "$page_total" ]; then
        break
    fi
    
    page=$((page + 1))
    sleep 0.1
done

echo "]" >> "$TMPFILE"

# Validate and move
if python3 -c "import json; d=json.load(open(\"$TMPFILE\")); print(f\"Valid: {len(d)} songs\")" 2>/dev/null; then
    mv "$TMPFILE" "$OUTFILE"
    echo "Catalog written: $total songs → $OUTFILE"
else
    echo "ERROR: Invalid JSON, keeping old catalog"
    rm -f "$TMPFILE"
fi
