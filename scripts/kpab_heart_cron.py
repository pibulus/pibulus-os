#!/usr/bin/env python3
"""KPAB Heart Cron — Auto-request hearted tracks weighted by love count.
Run every 2h via cron.
"""

import json, os, random, time, fcntl
from urllib.request import Request, urlopen

AZURACAST_URL = "http://localhost:8500"
STATION_ID = 1
HEARTS_FILE = "/home/pibulus/pibulus-os/data/hearts.json"
SECRETS_FILE = "/home/pibulus/.secrets/azuracast_key"
MIN_HEARTS = 2
MAX_WEIGHT = 10  # cap weight to prevent rich-get-richer
REQUEST_COOLDOWN = 7200  # 2 hours


def get_api_key():
    try:
        return open(SECRETS_FILE).read().strip()
    except FileNotFoundError:
        print(f"[HEART-CRON] API key not found at {SECRETS_FILE}")
        raise SystemExit(1)


def load_hearts():
    try:
        with open(HEARTS_FILE, "r") as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def save_hearts(data):
    lock_path = HEARTS_FILE + ".lock"
    with open(lock_path, "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        tmp = HEARTS_FILE + ".tmp"
        with open(tmp, "w") as f:
            json.dump(data, f, indent=2)
        os.replace(tmp, HEARTS_FILE)


def api_post(path, api_key):
    req = Request(f"{AZURACAST_URL}{path}", data=b"", method="POST")
    req.add_header("X-API-Key", api_key)
    with urlopen(req, timeout=10) as r:
        return json.loads(r.read())


def get_requestable_map():
    req = Request(f"{AZURACAST_URL}/api/station/{STATION_ID}/requests")
    with urlopen(req, timeout=60) as r:
        data = json.loads(r.read())
    return {item["song"]["id"]: item["request_id"] for item in data if item.get("song", {}).get("id")}


def main():
    api_key = get_api_key()
    hearts = load_hearts()
    now = time.time()

    eligible = []
    for song_id, entry in hearts.items():
        if entry.get("hearts", 0) < MIN_HEARTS:
            continue
        last_req = entry.get("last_requested", 0)
        if now - last_req < REQUEST_COOLDOWN:
            continue
        eligible.append((song_id, entry))

    if not eligible:
        print("[HEART-CRON] No eligible tracks to request")
        return

    # Weighted random with cap to prevent runaway favorites
    weights = [min(e[1]["hearts"], MAX_WEIGHT) for e in eligible]
    total = sum(weights)
    roll = random.uniform(0, total)
    cumulative = 0
    chosen = eligible[-1]  # guaranteed catch-all
    for i, item in enumerate(eligible):
        cumulative += weights[i]
        if roll <= cumulative:
            chosen = item
            break

    song_id, entry = chosen
    print(f"[HEART-CRON] Selected: '{entry['text']}' ({entry['hearts']} hearts)")

    try:
        req_map = get_requestable_map()
    except Exception as e:
        print(f"[HEART-CRON] Failed to fetch requestable list: {e}")
        return

    request_id = req_map.get(song_id)
    if not request_id:
        print(f"[HEART-CRON] Song {song_id} not in requestable list, skipping")
        return

    try:
        result = api_post(f"/api/station/{STATION_ID}/request/{request_id}", api_key)
        print(f"[HEART-CRON] Requested! {result}")
        entry["last_requested"] = now
        save_hearts(hearts)
    except Exception as e:
        print(f"[HEART-CRON] Request failed: {e}")


if __name__ == "__main__":
    main()
