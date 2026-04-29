#!/usr/bin/env python3
"""
grab_show.py — batch torrent grabber for TV shows via The Pirate Bay API.

Usage:
  python3 grab_show.py "joe pera talks with you"
  python3 grab_show.py "joe pera talks with you" --season 2
  python3 grab_show.py "joe pera talks with you" --dry-run
  python3 grab_show.py "joe pera talks with you" --list

Grabs the best available version of each episode, deduplicates,
and queues them all to qBittorrent in one shot.
"""

import argparse
import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request
from http.cookiejar import CookieJar

from env_utils import load_local_env, require_env

load_local_env()

QB_URL  = os.environ.get("QB_WEBUI_URL", "http://localhost:8888")
QB_USER = os.environ.get("QB_WEBUI_USERNAME", "admin")
QB_PASS = require_env("QB_WEBUI_PASSWORD")
QB_SAVE = "/shows/"   # inside container = /media/pibulus/passport/Shows/

# Size limits (bytes)
MAX_EPISODE_SIZE = 2 * 1024 ** 3    # 2GB per episode — 1080p should never need more
MAX_MOVIE_SIZE   = 8 * 1024 ** 3    # 8GB per movie
MIN_EPISODE_SIZE = 50 * 1024 ** 2   # 50MB — skip obvious trash/samples

# These in the name mean skip — too big, wrong format, or junk
SKIP_KEYWORDS = ["2160p", "4k", "uhd", "hevc-d3g", "remux", "bluray.remux", "sample"]

TRACKERS = [
    "udp://tracker.opentrackr.org:1337/announce",
    "udp://open.tracker.cl:1337/announce",
    "udp://tracker.openbittorrent.com:6969/announce",
    "udp://opentracker.io:6969/announce",
    "udp://tracker.torrent.eu.org:451/announce",
    "udp://open.stealth.si:80/announce",
    "udp://exodus.desync.com:6969/announce",
    "udp://tracker.tiny-vps.com:6969/announce",
]

QUALITY_RANK = {
    "webrip": 5, "web-dl": 5, "webdl": 5, "web": 4,
    "hdtv": 3, "x264": 2, "xvid": 1, "480p": 0, "mp4": 0,
}


def search_tpb(query, cat=205):
    """cat 205 = TV HD, 200 = all TV. Returns list of result dicts."""
    url = f"https://apibay.org/q.php?q={urllib.parse.quote(query)}&cat={cat}"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=10) as r:
        data = json.loads(r.read())
    if not data or data[0].get("name") == "No results returned":
        return []
    return data


def quality_score(name):
    name_lower = name.lower()
    score = 0
    for kw, val in QUALITY_RANK.items():
        if kw in name_lower:
            score = max(score, val)
    return score


def is_acceptable(r, max_size=MAX_EPISODE_SIZE):
    name_lower = r["name"].lower()
    size = int(r.get("size", 0))
    if any(kw in name_lower for kw in SKIP_KEYWORDS):
        return False, f"skip keyword in name"
    if size > max_size:
        return False, f"too large ({size//1024//1024}MB > {max_size//1024//1024}MB limit)"
    if size < MIN_EPISODE_SIZE and size > 0:
        return False, f"suspiciously small ({size//1024//1024}MB)"
    return True, "ok"


def parse_episode(name):
    """Extract (season, episode) from torrent name. Returns (int,int) or None."""
    m = re.search(r'[Ss](\d{1,2})[Ee](\d{1,2})', name)
    if m:
        return int(m.group(1)), int(m.group(2))
    return None


def make_magnet(info_hash, name):
    dn = urllib.parse.quote(name)
    tr = "&".join(f"tr={urllib.parse.quote(t)}" for t in TRACKERS)
    return f"magnet:?xt=urn:btih:{info_hash}&dn={dn}&{tr}"


def pick_best(results, max_size=MAX_EPISODE_SIZE):
    """
    Given a list of results for the same episode, pick the best acceptable one.
    Priority: seeders > quality score > size (bigger = better for same quality).
    Filters out 4K, remuxes, and oversized files first.
    """
    acceptable = [r for r in results if is_acceptable(r, max_size)[0]]
    pool = acceptable if acceptable else results  # fallback to anything if all filtered

    def sort_key(r):
        seeders = int(r.get("seeders", 0))
        q = quality_score(r["name"])
        size = int(r.get("size", 0))
        return (seeders, q, size)
    return sorted(pool, key=sort_key, reverse=True)[0]


def qb_login():
    cj = CookieJar()
    opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj))
    data = urllib.parse.urlencode({"username": QB_USER, "password": QB_PASS}).encode()
    req = urllib.request.Request(f"{QB_URL}/api/v2/auth/login", data=data)
    with opener.open(req, timeout=10) as r:
        body = r.read().decode()
    if body.strip() != "Ok.":
        raise RuntimeError(f"qBittorrent login failed: {body}")
    return opener


def qb_add(opener, magnet, save_path, name):
    data = urllib.parse.urlencode({
        "urls": magnet,
        "savepath": save_path,
        "category": "shows",
    }).encode()
    req = urllib.request.Request(f"{QB_URL}/api/v2/torrents/add", data=data)
    with opener.open(req, timeout=10) as r:
        return r.read().decode()


def main():
    ap = argparse.ArgumentParser(description="Batch-grab a TV show from TPB → qBittorrent")
    ap.add_argument("show", help="Show name to search for")
    ap.add_argument("--season", type=int, default=None, help="Grab only this season")
    ap.add_argument("--dry-run", action="store_true", help="Show what would be added, don't add")
    ap.add_argument("--list", action="store_true", help="List all found results without dedup")
    args = ap.parse_args()

    print(f"  searching TPB for: {args.show!r} ...")
    results = search_tpb(args.show, cat=200)
    if not results:
        # Broaden search - try without cat filter
        results = search_tpb(args.show, cat=0)
    if not results:
        print("  no results found.")
        sys.exit(1)

    print(f"  {len(results)} results found.\n")

    if args.list:
        for r in sorted(results, key=lambda x: (parse_episode(x['name']) or (99,99))):
            ep = parse_episode(r['name'])
            ep_str = f"S{ep[0]:02d}E{ep[1]:02d}" if ep else "?????"
            se = r.get('seeders', '?')
            size = int(r.get('size', 0)) // 1024 // 1024
            print(f"  {ep_str}  S:{se:>3}  {size:>4}MB  {r['name'][:65]}")
        return

    # Group by (season, episode), filter to show name matches
    show_words = args.show.lower().split()
    episodes = {}
    skipped = []
    for r in results:
        name_lower = r["name"].lower()
        if not all(w in name_lower for w in show_words[:3]):
            skipped.append(r["name"])
            continue
        ep = parse_episode(r["name"])
        if not ep:
            continue
        season, episode = ep
        if args.season and season != args.season:
            continue
        key = (season, episode)
        episodes.setdefault(key, []).append(r)

    if not episodes:
        print("  no matching episodes found (try --list to see raw results)")
        sys.exit(1)

    # Pick best for each episode
    picks = {}
    for key in sorted(episodes):
        picks[key] = pick_best(episodes[key])

    print(f"  episodes to grab: {len(picks)}\n")
    total_mb = 0
    for (s, e), r in picks.items():
        seeders = int(r.get("seeders", 0))
        size = int(r.get("size", 0)) // 1024 // 1024
        total_mb += size
        seed_warn = "  ⚠ no seeders" if seeders == 0 else ""
        print(f"  S{s:02d}E{e:02d}  S:{seeders:>3}  {size:>4}MB  {r['name'][:55]}{seed_warn}")

    print(f"\n  total: ~{total_mb}MB across {len(picks)} episodes")

    if args.dry_run:
        print("\n  dry run — nothing added.")
        return

    print("\n  logging into qBittorrent...")
    try:
        opener = qb_login()
    except Exception as ex:
        print(f"  qBittorrent login failed: {ex}")
        sys.exit(1)

    # Build save path from show name
    show_folder = args.show.title().replace("  ", " ")
    save_path = QB_SAVE + show_folder + "/"

    print(f"  save path: {save_path}")
    print(f"  adding {len(picks)} torrents...\n")

    added = 0
    for (s, e), r in picks.items():
        magnet = make_magnet(r["info_hash"], r["name"])
        try:
            qb_add(opener, magnet, save_path, r["name"])
            print(f"  + S{s:02d}E{e:02d}  {r['name'][:60]}")
            added += 1
            time.sleep(0.3)   # be gentle with the API
        except Exception as ex:
            print(f"  ✗ S{s:02d}E{e:02d}  failed: {ex}")

    print(f"\n  done. {added}/{len(picks)} queued in qBittorrent.")
    print(f"  files will land in: /media/pibulus/passport/The_Bucket/{show_folder}/")


if __name__ == "__main__":
    main()
