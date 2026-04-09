#!/usr/bin/env python3
"""
grab_movie.py — torrent grabber for movies via The Pirate Bay API.

Usage:
  python3 grab_movie.py "tommy boy"
  python3 grab_movie.py "tommy boy 1995"
  python3 grab_movie.py "tommy boy" --dry-run
  python3 grab_movie.py "tommy boy" --list

Finds the best available version and queues it to qBittorrent.
"""

import argparse
import json
import re
import sys
import time
import urllib.parse
import urllib.request
from http.cookiejar import CookieJar

QB_URL  = "http://localhost:8888"
QB_USER = "admin"
QB_PASS = "meringue"
QB_SAVE = "/movies/"   # inside container = /media/pibulus/passport/Movies/

# Size limits (bytes)
MAX_MOVIE_SIZE   = 8 * 1024 ** 3    # 8GB max
MIN_MOVIE_SIZE   = 200 * 1024 ** 2  # 200MB — skip obvious trash
SWEET_SPOT_MIN   = 1 * 1024 ** 3    # 1GB — prefer this range
SWEET_SPOT_MAX   = 3 * 1024 ** 3    # 3GB — prefer this range

# These in the name mean skip
SKIP_KEYWORDS = ["2160p", "4k", "uhd", "hevc-d3g", "remux", "bluray.remux", "sample", "cam", "camrip", "hdcam", "ts."]

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
    "bluray": 5, "bdrip": 4, "brrip": 4,
    "hdtv": 3, "x264": 2, "xvid": 1, "480p": 0, "mp4": 0,
}


def search_tpb(query, cat=207):
    """cat 207 = HD Movies, 200 = all movies. Returns list of result dicts."""
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


def in_sweet_spot(size):
    return SWEET_SPOT_MIN <= size <= SWEET_SPOT_MAX


def is_acceptable(r):
    name_lower = r["name"].lower()
    size = int(r.get("size", 0))
    if any(kw in name_lower for kw in SKIP_KEYWORDS):
        return False, f"skip keyword in name"
    if size > MAX_MOVIE_SIZE:
        return False, f"too large ({size//1024//1024}MB > {MAX_MOVIE_SIZE//1024//1024}MB limit)"
    if size < MIN_MOVIE_SIZE and size > 0:
        return False, f"suspiciously small ({size//1024//1024}MB)"
    return True, "ok"


def make_magnet(info_hash, name):
    dn = urllib.parse.quote(name)
    tr = "&".join(f"tr={urllib.parse.quote(t)}" for t in TRACKERS)
    return f"magnet:?xt=urn:btih:{info_hash}&dn={dn}&{tr}"


def pick_best(results):
    """
    Pick the best movie result.
    Priority: sweet-spot size (1-3GB) > seeders > quality score.
    Filters 4K, cam, remux, and oversized first.
    """
    acceptable = [r for r in results if is_acceptable(r)[0]]
    pool = acceptable if acceptable else results

    def sort_key(r):
        seeders = int(r.get("seeders", 0))
        q = quality_score(r["name"])
        size = int(r.get("size", 0))
        sweet = 1 if in_sweet_spot(size) else 0
        return (sweet, seeders, q, size)

    return sorted(pool, key=sort_key, reverse=True)[0]


def gum_pick(candidates):
    """Present candidates via gum choose and return the selected result."""
    import subprocess
    pool = sorted(candidates, key=lambda r: int(r.get("seeders", 0)), reverse=True)
    lines = []
    for r in pool:
        seeders = int(r.get("seeders", 0))
        size = int(r.get("size", 0)) // 1024 // 1024
        ok, _ = is_acceptable(r)
        flag = "  " if ok else "✗ "
        spot = "*" if in_sweet_spot(int(r.get("size", 0))) else " "
        lines.append(f"{flag}{spot} S:{seeders:>4}  {size:>5}MB  {r['name'][:70]}")
    try:
        result = subprocess.run(
            ["gum", "choose", "--height", "20"],
            input="\n".join(lines),
            capture_output=True,
            text=True,
        )
        chosen = result.stdout.strip()
        if not chosen:
            return None
        for i, line in enumerate(lines):
            if line == chosen:
                return pool[i]
    except FileNotFoundError:
        pass
    return pick_best(candidates)


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
        "category": "movies",
    }).encode()
    req = urllib.request.Request(f"{QB_URL}/api/v2/torrents/add", data=data)
    with opener.open(req, timeout=10) as r:
        return r.read().decode()


def main():
    ap = argparse.ArgumentParser(description="Grab a movie from TPB → qBittorrent")
    ap.add_argument("movie", help="Movie title to search for")
    ap.add_argument("--dry-run", action="store_true", help="Show what would be added, don't add")
    ap.add_argument("--list", action="store_true", help="List all found results without picking")
    ap.add_argument("--pick", action="store_true", help="Interactively choose from results with gum")
    args = ap.parse_args()

    print(f"  searching TPB for: {args.movie!r} ...")
    results = search_tpb(args.movie, cat=207)
    if not results:
        results = search_tpb(args.movie, cat=201)  # all movies fallback
    if not results:
        print("  no results found.")
        sys.exit(1)

    print(f"  {len(results)} results found.\n")

    if args.list:
        for r in sorted(results, key=lambda x: int(x.get('seeders', 0)), reverse=True):
            se = r.get('seeders', '?')
            size = int(r.get('size', 0)) // 1024 // 1024
            spot = "*" if in_sweet_spot(int(r.get('size', 0))) else " "
            ok, reason = is_acceptable(r)
            flag = "  " if ok else "✗ "
            print(f"  {flag}{spot} S:{se:>4}  {size:>5}MB  {r['name'][:65]}")
        return

    # Filter by search words appearing in name
    search_words = args.movie.lower().split()
    # Strip year if present (e.g. "1995")
    keywords = [w for w in search_words if not re.match(r'^\d{4}$', w)]

    candidates = []
    for r in results:
        name_lower = r["name"].lower()
        if all(w in name_lower for w in keywords[:3]):
            candidates.append(r)

    if not candidates:
        # Relax: try just first 2 words
        for r in results:
            name_lower = r["name"].lower()
            if all(w in name_lower for w in keywords[:2]):
                candidates.append(r)

    if not candidates:
        print("  no matching results (try --list to see raw results)")
        sys.exit(1)

    if args.pick:
        best = gum_pick(candidates)
        if best is None:
            print("  cancelled.")
            sys.exit(0)
    else:
        best = pick_best(candidates)
    seeders = int(best.get("seeders", 0))
    size = int(best.get("size", 0)) // 1024 // 1024
    ok, reason = is_acceptable(best)

    print(f"  best match:")
    print(f"    {best['name']}")
    print(f"    seeders: {seeders}  size: {size}MB  quality: {quality_score(best['name'])}")
    if not ok:
        print(f"    warning: {reason} (no acceptable alternatives found)")
    if seeders == 0:
        print(f"    warning: no seeders — download may be slow/stuck")

    if args.dry_run:
        print("\n  dry run — nothing added.")
        return

    print("\n  logging into qBittorrent...")
    try:
        opener = qb_login()
    except Exception as ex:
        print(f"  qBittorrent login failed: {ex}")
        sys.exit(1)

    magnet = make_magnet(best["info_hash"], best["name"])
    try:
        qb_add(opener, magnet, QB_SAVE, best["name"])
        print(f"  + queued: {best['name'][:70]}")
        print(f"  files will land in: /media/pibulus/passport/The_Bucket/Movies/")
    except Exception as ex:
        print(f"  failed to add: {ex}")
        sys.exit(1)


if __name__ == "__main__":
    main()
