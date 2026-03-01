#!/usr/bin/env python3
"""Generate KPAB.FM request catalog - fetches ALL pages from AzuraCast API"""
import json, urllib.request, time, sys

API = "http://localhost:8500/api/station/1/requests"
OUTFILE = "/media/pibulus/passport/www/html/kpab/catalog.json"

catalog = []
page = 1
total_pages = None
retries_left = 3

print(f"Fetching catalog from {API}...")

while True:
    url = f"{API}?per_page=25&page={page}"
    try:
        with urllib.request.urlopen(url, timeout=30) as resp:
            data = json.loads(resp.read())
    except Exception as e:
        print(f"  Page {page} failed: {e}", file=sys.stderr)
        retries_left -= 1
        if retries_left <= 0:
            print(f"  Too many failures, stopping at page {page}")
            break
        time.sleep(2)
        continue
    
    retries_left = 3  # reset on success
    
    if total_pages is None:
        total_pages = data.get("total_pages", 0)
        total = data.get("total", 0)
        print(f"  Total: {total} tracks across {total_pages} pages")
    
    rows = data.get("rows", [])
    if not rows:
        break
    
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
    
    if page % 50 == 0:
        print(f"  Page {page}/{total_pages} ({len(catalog)} tracks so far)")
    
    if page >= total_pages:
        break
    
    page += 1
    time.sleep(0.05)

print(f"Writing {len(catalog)} tracks to {OUTFILE}")
with open(OUTFILE, "w") as f:
    json.dump(catalog, f, separators=(",", ":"))

print(f"Done! {len(catalog)} tracks in catalog")
