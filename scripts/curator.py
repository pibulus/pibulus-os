#!/usr/bin/env python3
"""
curator.py — weekly themed media acquisition system for the Quick Cat Club cyberdeck.

Modes:
  --generate    Scan the library, call Claude API, write themed weekly batches to
                ~/pibulus-os/data/curator_list.json

  (default)     Load the list, find the next unfinished batch, grab everything,
                mark it done. Run this weekly via cron.

  --status      Show all batches and completion state.
  --batch N     Run a specific batch number (1-indexed) instead of the next one.
  --dry-run     Show what would be grabbed, don't actually queue anything.

Usage:
  python3 curator.py --generate
  python3 curator.py
  python3 curator.py --status
  python3 curator.py --dry-run
  python3 curator.py --batch 3
"""

import argparse
import json
import os
import re
import subprocess
import sys
import time
import urllib.parse
import urllib.request
from datetime import datetime
from http.cookiejar import CookieJar
from pathlib import Path

# ── Paths ────────────────────────────────────────────────────────────────────
MOVIES_DIR   = Path("/media/pibulus/passport/Movies")
SHOWS_DIR    = Path("/media/pibulus/passport/Shows")
DATA_DIR     = Path("/home/pibulus/pibulus-os/data")
LIST_FILE    = DATA_DIR / "curator_list.json"
LOG_FILE     = DATA_DIR / "curator_log.txt"
SCRIPTS_DIR  = Path("/home/pibulus/pibulus-os/scripts")

# ── qBittorrent ───────────────────────────────────────────────────────────────
QB_URL       = "http://localhost:8888"
QB_USER      = "admin"
QB_PASS      = "meringue"
QB_MOVIES    = "/downloads/Movies/"
QB_SHOWS     = "/downloads/"

# ── Claude API ────────────────────────────────────────────────────────────────
CLAUDE_MODEL = "claude-opus-4-6"
CLAUDE_API   = "https://api.anthropic.com/v1/messages"

# ── Acquisition settings (mirrors grab_show.py / grab_movie.py) ───────────────
MAX_MOVIE_SIZE   = 8  * 1024 ** 3
MIN_MOVIE_SIZE   = 200 * 1024 ** 2
SWEET_SPOT_MIN   = 1  * 1024 ** 3
SWEET_SPOT_MAX   = 3  * 1024 ** 3
MAX_EP_SIZE      = 2  * 1024 ** 3
MIN_EP_SIZE      = 50 * 1024 ** 2

SKIP_KEYWORDS = ["2160p", "4k", "uhd", "hevc-d3g", "remux", "bluray.remux", "sample", "cam", "camrip", "hdcam"]

QUALITY_RANK = {
    "webrip": 5, "web-dl": 5, "webdl": 5, "web": 4,
    "bluray": 5, "bdrip": 4, "brrip": 4,
    "hdtv": 3, "x264": 2, "xvid": 1, "480p": 0, "mp4": 0,
}

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


# ── Library scanning ──────────────────────────────────────────────────────────

def scan_library():
    movies = sorted([p.name for p in MOVIES_DIR.iterdir() if not p.name.startswith('$')]) if MOVIES_DIR.exists() else []
    shows  = sorted([p.name for p in SHOWS_DIR.iterdir()  if not p.name.startswith('$')]) if SHOWS_DIR.exists() else []
    return movies, shows


# ── Claude API call ───────────────────────────────────────────────────────────

def get_api_key():
    key = os.environ.get("ANTHROPIC_API_KEY", "")
    if not key:
        key_file = Path.home() / ".config" / "anthropic-api-key"
        if key_file.exists():
            key = key_file.read_text().strip()
    if not key:
        raise RuntimeError("No Anthropic API key found. Set ANTHROPIC_API_KEY env var.")
    return key


def call_claude(prompt):
    api_key = get_api_key()
    payload = json.dumps({
        "model": CLAUDE_MODEL,
        "max_tokens": 4096,
        "messages": [{"role": "user", "content": prompt}],
    }).encode()
    req = urllib.request.Request(
        CLAUDE_API,
        data=payload,
        headers={
            "x-api-key": api_key,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json",
        }
    )
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read())


def generate_list(movies, shows):
    """Call Claude to generate 12 themed weekly batches."""

    library_block = f"""CURRENT MOVIES ({len(movies)} total):
{chr(10).join(f'  {m}' for m in movies[:150])}
{'  ... and more' if len(movies) > 150 else ''}

CURRENT SHOWS ({len(shows)} total):
{chr(10).join(f'  {s}' for s in shows[:150])}
{'  ... and more' if len(shows) > 150 else ''}"""

    prompt = f"""You are the curator for the Quick Cat Club — a personal media server run on a Raspberry Pi cyberdeck by a music-lover, film enthusiast, and general weirdo in the best possible way.

The vibe: indie music, cult films, documentary, comedy classics, DIY/underground culture. The person running this knows Mac DeMarco, is friends with Amyl and the Sniffers, loves King Gizzard and the Lizard Wizard, is into Joe Pera, has connections to the Pervirella underground film world (Josh Collins), and their band Mesa Cosa plays noisy, fun music.

Your job: generate 12 themed weekly batches of media to acquire, filling gaps in the library and adding things that fit the vibe. Each batch has:
- A theme name (short, evocative — e.g. "australian chaos", "deadpan comedy", "documentary weirdos")
- A theme note (1-2 sentences on the vibe — casual, no jargon)
- 5 movies (exact titles with year — things likely to be on The Pirate Bay)
- 2 shows (exact show titles — full series, cult or indie preferred)

Rules:
- Skip anything already in the library (listed below)
- Prefer things with some cult or underground pedigree — not just mainstream blockbusters
- Comedy, documentary, horror, indie drama, cult classics all welcome
- Avoid 4K-only releases — aim for 1080p territory
- Mix eras, don't cluster everything in one decade
- Shows: prefer series that are complete or at least several seasons in
- Be realistic — choose things actually available as torrents, not super obscure

{library_block}

Return ONLY valid JSON, no markdown, no explanation. Format:
{{
  "generated": "YYYY-MM-DD",
  "batches": [
    {{
      "batch": 1,
      "theme": "theme name",
      "note": "theme note",
      "done": false,
      "grabbed_at": null,
      "movies": ["Movie Title (Year)", ...],
      "shows": ["Show Title", ...]
    }},
    ...
  ]
}}

Generate all 12 batches now."""

    print("  calling Claude API...")
    response = call_claude(prompt)
    text = response["content"][0]["text"].strip()

    # Strip markdown fences if present
    if text.startswith("```"):
        text = re.sub(r'^```[a-z]*\n?', '', text)
        text = re.sub(r'\n?```$', '', text)

    return json.loads(text)


# ── TPB acquisition (inline — no subprocess dependency) ───────────────────────

def search_tpb(query, cat):
    url = f"https://apibay.org/q.php?q={urllib.parse.quote(query)}&cat={cat}"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=12) as r:
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


def is_acceptable_movie(r):
    name_lower = r["name"].lower()
    size = int(r.get("size", 0))
    if any(kw in name_lower for kw in SKIP_KEYWORDS):
        return False
    if size > MAX_MOVIE_SIZE or (size < MIN_MOVIE_SIZE and size > 0):
        return False
    return True


def is_acceptable_ep(r):
    name_lower = r["name"].lower()
    size = int(r.get("size", 0))
    if any(kw in name_lower for kw in SKIP_KEYWORDS):
        return False
    if size > MAX_EP_SIZE or (size < MIN_EP_SIZE and size > 0):
        return False
    return True


def in_sweet_spot(size):
    return SWEET_SPOT_MIN <= size <= SWEET_SPOT_MAX


def make_magnet(info_hash, name):
    dn = urllib.parse.quote(name)
    tr = "&".join(f"tr={urllib.parse.quote(t)}" for t in TRACKERS)
    return f"magnet:?xt=urn:btih:{info_hash}&dn={dn}&{tr}"


def parse_episode(name):
    m = re.search(r'[Ss](\d{1,2})[Ee](\d{1,2})', name)
    if m:
        return int(m.group(1)), int(m.group(2))
    return None


def pick_best_movie(results):
    pool = [r for r in results if is_acceptable_movie(r)] or results

    def key(r):
        seeders = int(r.get("seeders", 0))
        q = quality_score(r["name"])
        size = int(r.get("size", 0))
        sweet = 1 if in_sweet_spot(size) else 0
        return (sweet, seeders, q, size)

    return sorted(pool, key=key, reverse=True)[0]


def pick_best_ep(results):
    pool = [r for r in results if is_acceptable_ep(r)] or results

    def key(r):
        seeders = int(r.get("seeders", 0))
        q = quality_score(r["name"])
        size = int(r.get("size", 0))
        return (seeders, q, size)

    return sorted(pool, key=key, reverse=True)[0]


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


def qb_add(opener, magnet, save_path, category):
    data = urllib.parse.urlencode({
        "urls": magnet,
        "savepath": save_path,
        "category": category,
    }).encode()
    req = urllib.request.Request(f"{QB_URL}/api/v2/torrents/add", data=data)
    with opener.open(req, timeout=10) as r:
        return r.read().decode()


def resolve_movie(title):
    """Search TPB and return the best result dict, or None."""
    search_query = re.sub(r'\s*\(\d{4}\)\s*$', '', title).strip()
    keywords = [w.lower() for w in search_query.split() if not re.match(r'^\d{4}$', w.lower())]

    results = search_tpb(search_query, cat=207)
    if not results:
        results = search_tpb(search_query, cat=201)
    if not results:
        return None

    candidates = [r for r in results if all(w in r["name"].lower() for w in keywords[:3])]
    if not candidates:
        candidates = [r for r in results if all(w in r["name"].lower() for w in keywords[:2])]
    if not candidates:
        return None

    return pick_best_movie(candidates)


def grab_movie(opener, title, dry_run=False, prefetched=None):
    """Queue a single movie. Uses prefetched result if available. Returns (success, name, size_mb, note)."""
    best = prefetched or resolve_movie(title)
    if not best:
        return False, None, 0, "no results"

    size_mb = int(best.get("size", 0)) // 1024 // 1024
    seeders = int(best.get("seeders", 0))

    if dry_run:
        return True, best["name"], size_mb, f"S:{seeders}"

    magnet = make_magnet(best["info_hash"], best["name"])
    qb_add(opener, magnet, QB_MOVIES, "movies")
    return True, best["name"], size_mb, f"S:{seeders}"


def resolve_show(show_title):
    """Search TPB and return dict of {(s,e): best_result} for a show, or {}."""
    show_words = show_title.lower().split()

    results = search_tpb(show_title, cat=200)
    if not results:
        results = search_tpb(show_title, cat=0)
    if not results:
        return {}

    episodes = {}
    for r in results:
        name_lower = r["name"].lower()
        if not all(w in name_lower for w in show_words[:3]):
            continue
        ep = parse_episode(r["name"])
        if not ep:
            continue
        episodes.setdefault(ep, []).append(r)

    return {k: pick_best_ep(v) for k, v in episodes.items()}


def grab_show(opener, show_title, dry_run=False, prefetched=None):
    """Queue all episodes of a show. Uses prefetched results if available. Returns (count, episodes_queued, note)."""
    if prefetched is not None:
        picks = prefetched
    else:
        picks = resolve_show(show_title)

    if not picks:
        return 0, [], "no episodes matched"

    if dry_run:
        return len(picks), list(picks.keys()), f"{len(picks)} eps"

    save_path = QB_SHOWS + show_title.title().replace("  ", " ") + "/"
    queued = []
    for (s, e), r in sorted(picks.items()):
        magnet = make_magnet(r["info_hash"], r["name"])
        try:
            qb_add(opener, magnet, save_path, "shows")
            queued.append((s, e))
            time.sleep(0.3)
        except Exception:
            pass

    return len(queued), queued, f"{len(queued)}/{len(picks)} eps"


def log(msg):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M")
    line = f"[{timestamp}] {msg}"
    print(line)
    with open(LOG_FILE, "a") as f:
        f.write(line + "\n")


# ── Main ──────────────────────────────────────────────────────────────────────

def cmd_generate(args):
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    print("  scanning library...")
    movies, shows = scan_library()
    print(f"  found {len(movies)} movies, {len(shows)} shows")

    data = generate_list(movies, shows)
    data["generated"] = datetime.now().strftime("%Y-%m-%d")

    LIST_FILE.write_text(json.dumps(data, indent=2))
    print(f"\n  saved {len(data['batches'])} batches → {LIST_FILE}")
    print()
    for b in data["batches"]:
        print(f"  batch {b['batch']:>2}: {b['theme']}")
        print(f"           {b['note']}")
        for m in b["movies"]:
            print(f"             movie: {m}")
        for s in b["shows"]:
            print(f"              show: {s}")
        print()


def cmd_status(args):
    if not LIST_FILE.exists():
        print("  no curator list found — run with --generate first")
        return
    data = json.load(open(LIST_FILE))
    print(f"  generated: {data.get('generated', '?')}")
    print()
    for b in data["batches"]:
        done = b.get("done", False)
        grabbed = b.get("grabbed_at", "")
        status = f"done {grabbed}" if done else "pending"
        print(f"  [{b['batch']:>2}] {'✓' if done else '·'} {b['theme']:<30}  {status}")


def cmd_prefetch(args):
    """Search TPB for all pending batches and store magnet links in the JSON."""
    if not LIST_FILE.exists():
        print("  no curator list found — run with --generate first")
        sys.exit(1)

    data = json.load(open(LIST_FILE))
    batches = [b for b in data["batches"] if not b.get("done", False)]

    if not batches:
        print("  all batches already done")
        return

    print(f"  prefetching torrents for {len(batches)} pending batches...\n")

    for batch in batches:
        print(f"  batch {batch['batch']}: {batch['theme']}")
        batch.setdefault("prefetched_movies", {})
        batch.setdefault("prefetched_shows", {})

        for title in batch["movies"]:
            if title in batch["prefetched_movies"]:
                print(f"    · {title[:50]}  (already cached)")
                continue
            result = resolve_movie(title)
            if result:
                batch["prefetched_movies"][title] = {
                    "info_hash": result["info_hash"],
                    "name": result["name"],
                    "size": result.get("size", 0),
                    "seeders": result.get("seeders", 0),
                }
                size_mb = int(result.get("size", 0)) // 1024 // 1024
                print(f"    + {result['name'][:55]}  ({size_mb}MB  S:{result.get('seeders',0)})")
            else:
                print(f"    ✗ {title[:55]}  (not found)")
            time.sleep(0.5)

        for show in batch["shows"]:
            if show in batch["prefetched_shows"]:
                print(f"    · {show}  (already cached)")
                continue
            picks = resolve_show(show)
            if picks:
                batch["prefetched_shows"][show] = {
                    ep_key: {"info_hash": r["info_hash"], "name": r["name"],
                             "size": r.get("size", 0), "seeders": r.get("seeders", 0)}
                    for ep_key, r in picks.items()
                    for ep_key in [f"{ep_key[0]}x{ep_key[1]:02d}"]
                }
                print(f"    + {show}  ({len(picks)} eps)")
            else:
                print(f"    ✗ {show}  (not found)")
            time.sleep(0.5)

        print()

    LIST_FILE.write_text(json.dumps(data, indent=2))
    print("  prefetch complete — magnets cached in curator_list.json")


def cmd_run(args):
    if not LIST_FILE.exists():
        print("  no curator list found — run with --generate first")
        sys.exit(1)

    data = json.load(open(LIST_FILE))
    batches = data["batches"]

    if args.batch:
        idx = next((i for i, b in enumerate(batches) if b["batch"] == args.batch), None)
        if idx is None:
            print(f"  batch {args.batch} not found")
            sys.exit(1)
        batch = batches[idx]
    else:
        batch = next((b for b in batches if not b.get("done", False)), None)
        if not batch:
            print("  all batches complete — run --generate for a fresh list")
            return
        idx = batches.index(batch)

    print(f"\n  batch {batch['batch']}: {batch['theme']}")
    print(f"  {batch['note']}\n")

    opener = None
    if not args.dry_run:
        print("  logging into qBittorrent...")
        try:
            opener = qb_login()
        except Exception as ex:
            print(f"  qBittorrent login failed: {ex}")
            sys.exit(1)

    results = {"movies": [], "shows": []}

    prefetched_movies = batch.get("prefetched_movies", {})
    prefetched_shows  = batch.get("prefetched_shows", {})

    print("  movies:")
    for title in batch["movies"]:
        pre = prefetched_movies.get(title)
        ok, name, size_mb, note = grab_movie(opener, title, dry_run=args.dry_run, prefetched=pre)
        marker = "+" if ok else "✗"
        display = name[:60] if name else title
        cached = " (cached)" if pre else ""
        print(f"    {marker} {display}  ({size_mb}MB  {note}){cached}")
        results["movies"].append({"title": title, "ok": ok, "note": note})
        time.sleep(0.5 if pre else 1)

    print("\n  shows:")
    for show in batch["shows"]:
        pre_raw = prefetched_shows.get(show)
        # Reconstruct picks dict from stored format
        if pre_raw:
            pre = {}
            for ep_key, r in pre_raw.items():
                s, e = ep_key.split("x")
                pre[(int(s), int(e))] = r
        else:
            pre = None
        count, eps, note = grab_show(opener, show, dry_run=args.dry_run, prefetched=pre)
        marker = "+" if count > 0 else "✗"
        cached = " (cached)" if pre_raw else ""
        print(f"    {marker} {show}  ({note}){cached}")
        results["shows"].append({"title": show, "ok": count > 0, "note": note})
        time.sleep(0.5 if pre_raw else 1)

    if not args.dry_run:
        batches[idx]["done"] = True
        batches[idx]["grabbed_at"] = datetime.now().strftime("%Y-%m-%d")
        LIST_FILE.write_text(json.dumps(data, indent=2))
        log(f"batch {batch['batch']} '{batch['theme']}' — {len(batch['movies'])} movies, {len(batch['shows'])} shows")
        print(f"\n  batch {batch['batch']} marked done.")
    else:
        print("\n  dry run — nothing queued.")


def main():
    ap = argparse.ArgumentParser(description="Weekly themed media curator")
    ap.add_argument("--generate", action="store_true", help="Generate a fresh batch list via Claude")
    ap.add_argument("--prefetch", action="store_true", help="Pre-search TPB and cache magnets for all pending batches")
    ap.add_argument("--status",   action="store_true", help="Show batch completion status")
    ap.add_argument("--dry-run",  action="store_true", help="Preview what would be grabbed")
    ap.add_argument("--batch",    type=int, default=None, help="Run a specific batch number")
    args = ap.parse_args()

    if args.generate:
        cmd_generate(args)
    elif args.prefetch:
        cmd_prefetch(args)
    elif args.status:
        cmd_status(args)
    else:
        cmd_run(args)


if __name__ == "__main__":
    main()
