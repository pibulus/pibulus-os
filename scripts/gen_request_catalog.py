#!/usr/bin/env python3
"""Generate KPAB.FM request catalog - fetches ALL pages from AzuraCast API"""
import json, urllib.request, time, sys, os

API = "http://localhost:8500/api/station/1/requests"
OUTFILE = "/home/pibulus/pibulus-os/www/html/kpab/catalog.json"
TEMP_FILE = OUTFILE + ".tmp"

catalog = []
page = 1
total_pages = None
retries_left = 3

print(f"Fetching catalog from {API}...")

while True:
    url = f"{API}?per_page=50&page={page}"
    try:
        with urllib.request.urlopen(url, timeout=30) as resp:
            data = json.loads(resp.read())
    except Exception as e:
        print(f"  Page {page} failed: {e}", file=sys.stderr)
        retries_left -= 1
        if retries_left <= 0:
            print(f"  FATAL: Too many failures. Aborting to protect existing catalog.")
            sys.exit(1)
        time.sleep(2)
        continue
    
    retries_left = 3
    if total_pages is None:
        total_pages = data.get("total_pages", 0)
        print(f"  Total: {data.get('total', 0)} tracks across {total_pages} pages")
    
    rows = data.get("rows", [])
    if not rows: break
    
    for r in rows:
        s = r.get("song", {})
        catalog.append({
            "id": r.get("request_id", ""),
            "url": r.get("request_url", ""),
            "t": s.get("title", ""),
            "a": s.get("artist", ""),
            "b": s.get("album", ""),
            "art": s.get("art", "")
        })
    
    if page >= total_pages: break
    page += 1
    time.sleep(0.05)

if len(catalog) > 0:
    print(f"Writing {len(catalog)} tracks to {OUTFILE}")
    with open(TEMP_FILE, "w") as f:
        json.dump(catalog, f, separators=(",", ":"))
    os.replace(TEMP_FILE, OUTFILE)
    print("Done!")
else:
    print("Error: Catalog is empty. Not overwriting.")
    sys.exit(1)
