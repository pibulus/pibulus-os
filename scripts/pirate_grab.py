#!/usr/bin/env python3
"""
pirate-grab - TV show & movie grabber for legally owned media preservation
Searches 1337x for torrents, picks the best result, downloads via transmission-cli.

Usage:
  pirate-grab "Nirvana The Band The Show" --season 2
  pirate-grab "Succession" --season 4
  pirate-grab "The Simpsons" --season 33 --episode 6
  pirate-grab "Mad Max Fury Road" --movie
  pirate-grab "query" --dry-run                    # Preview without downloading
  pirate-grab "query" --quality 720                # Prefer 720p
  pirate-grab "query" --top 10                     # Show more results

Requires: requests, beautifulsoup4, transmission-cli
"""
import requests, re, sys, argparse, subprocess, time, os
from bs4 import BeautifulSoup
from urllib.parse import quote

SHOWS_DIR = "/media/pibulus/passport/Shows"
MOVIES_DIR = "/media/pibulus/passport/Movies"

HEADERS = {
    "User-Agent": "Mozilla/5.0 (X11; Linux aarch64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
}

# 1337x mirrors to try
MIRRORS = [
    "https://1337x.to",
    "https://1337x.st",
    "https://1337x.ws",
    "https://1337xx.to",
]


def search_1337x(query, category="TV"):
    """Search 1337x and return results with magnet links"""
    cat_path = {"TV": "TV", "Movies": "Movies", "": ""}
    search_path = f"/category-search/{quote(query)}/{cat_path.get(category, '')}/1/"

    for mirror in MIRRORS:
        try:
            url = mirror + search_path
            resp = requests.get(url, headers=HEADERS, timeout=15)
            if resp.status_code == 200 and "search-page" in resp.text:
                results = parse_search_results(resp.text, mirror)
                if results:
                    return results
        except requests.RequestException:
            continue

    # Fallback: regular search without category
    for mirror in MIRRORS:
        try:
            url = mirror + f"/search/{quote(query)}/1/"
            resp = requests.get(url, headers=HEADERS, timeout=15)
            if resp.status_code == 200:
                results = parse_search_results(resp.text, mirror)
                if results:
                    return results
        except requests.RequestException:
            continue

    return []


TPB_MIRRORS = [
    "https://tpb.party",
    "https://piratebay.live",
    "https://thehiddenbay.com",
    "https://thepiratebay.org",
]


def search_tpb(query, category="TV"):
    """Search The Pirate Bay as fallback"""
    # TPB categories: 200=Video, 205=TV, 201=Movies
    cat_id = {"TV": "205", "Movies": "201"}.get(category, "200")

    for mirror in TPB_MIRRORS:
        try:
            url = f"{mirror}/search/{quote(query)}/0/99/{cat_id}"
            resp = requests.get(url, headers=HEADERS, timeout=15)
            if resp.status_code != 200:
                continue

            soup = BeautifulSoup(resp.text, "html.parser")
            results = []

            # TPB uses table rows with magnet links inline
            for row in soup.select("#searchResult tr"):
                try:
                    name_cell = row.select_one("td .detName .detLink")
                    if not name_cell:
                        continue

                    name = name_cell.text.strip()
                    magnet_a = row.select_one('a[href^="magnet:"]')
                    magnet = magnet_a["href"] if magnet_a else None

                    # Parse seeds/leeches from last two tds
                    tds = row.select("td")
                    seeds = int(tds[-2].text.strip()) if len(tds) >= 4 else 0
                    leeches = int(tds[-1].text.strip()) if len(tds) >= 4 else 0

                    # Size from description
                    desc = row.select_one("td .detDesc")
                    size_text = ""
                    if desc:
                        m = re.search(r'Size\s+([\d.]+\s*[GMK]iB)', desc.text)
                        if m:
                            size_text = m.group(1)

                    results.append({
                        "name": name,
                        "link": None,  # TPB has inline magnets
                        "magnet": magnet,
                        "seeds": seeds,
                        "leeches": leeches,
                        "size": size_text,
                    })
                except (AttributeError, ValueError, IndexError):
                    continue

            if results:
                return results
        except requests.RequestException:
            continue

    return []


def parse_search_results(html, mirror):
    """Parse 1337x search results page"""
    soup = BeautifulSoup(html, "html.parser")
    results = []

    rows = soup.select("tbody tr")
    for row in rows:
        try:
            name_cell = row.select_one("td.name a:nth-of-type(2)")
            if not name_cell:
                continue

            name = name_cell.text.strip()
            link = mirror + name_cell["href"]

            seeds_cell = row.select_one("td.seeds")
            leech_cell = row.select_one("td.leeches")
            size_cell = row.select("td")

            seeds = int(seeds_cell.text.strip()) if seeds_cell else 0
            leeches = int(leech_cell.text.strip()) if leech_cell else 0

            # Size is usually the 5th td
            size_text = ""
            if len(size_cell) >= 5:
                size_text = size_cell[4].text.strip()
                # Clean up size text
                size_text = re.sub(r'\s+', ' ', size_text).strip()

            results.append({
                "name": name,
                "link": link,
                "seeds": seeds,
                "leeches": leeches,
                "size": size_text,
            })
        except (AttributeError, ValueError, IndexError):
            continue

    return results


def get_magnet(page_url):
    """Get magnet link from a 1337x detail page"""
    try:
        resp = requests.get(page_url, headers=HEADERS, timeout=15)
        soup = BeautifulSoup(resp.text, "html.parser")

        # Look for magnet link
        magnet_link = soup.select_one('a[href^="magnet:"]')
        if magnet_link:
            return magnet_link["href"]

        # Fallback: search in all links
        for a in soup.find_all("a", href=True):
            if a["href"].startswith("magnet:"):
                return a["href"]
    except requests.RequestException:
        pass
    return None


def score_result(result, query, quality_pref=None):
    """Score a torrent result for relevance and quality"""
    name = result["name"].lower()
    score = 0

    # Seeders are king
    seeds = result["seeds"]
    if seeds > 50:
        score += 40
    elif seeds > 20:
        score += 30
    elif seeds > 5:
        score += 20
    elif seeds > 0:
        score += 10

    # Quality scoring
    if "2160p" in name or "4k" in name:
        score += 15 if quality_pref == "2160" else 5
    elif "1080p" in name:
        score += 15 if quality_pref in (None, "1080") else 10
    elif "720p" in name:
        score += 12 if quality_pref == "720" else 8
    elif "480p" in name:
        score += 5

    # Codec preferences
    if "x265" in name or "hevc" in name:
        score += 8  # smaller files, good for Pi storage
    elif "x264" in name:
        score += 5

    # Penalize cam/ts/hdts
    if any(bad in name for bad in ["cam", "hdts", "telesync", "telecine"]):
        score -= 50

    # Prefer complete seasons
    if "complete" in name or "season" in name:
        score += 5

    # Penalize very large files (Pi storage)
    size = result.get("size", "").lower()
    if "gb" in size:
        try:
            gb = float(re.search(r'([\d.]+)\s*gb', size).group(1))
            if gb > 50:
                score -= 10  # very large
        except (AttributeError, ValueError):
            pass

    return score


def download_torrent(magnet, output_dir, dry_run=False):
    """Download torrent via transmission-cli"""
    if dry_run:
        print(f"  [DRY] Would download to {output_dir}")
        print(f"  [DRY] Magnet: {magnet[:80]}...")
        return True

    os.makedirs(output_dir, exist_ok=True)

    print(f"  Downloading to {output_dir}...")
    print(f"  This runs in the foreground. Ctrl+C to background it.\n")

    cmd = [
        "transmission-cli",
        magnet,
        "-w", output_dir,
        "--no-portmap",  # Don't try UPnP (Pi behind router)
    ]

    try:
        subprocess.run(cmd)
        return True
    except KeyboardInterrupt:
        print("\n  Download interrupted. Resume by running the same command.")
        return False


def build_query(args):
    """Build search query from args"""
    query = args.query
    if args.season and args.episode:
        query += f" S{args.season:02d}E{args.episode:02d}"
    elif args.season:
        query += f" Season {args.season}"
    if args.quality:
        query += f" {args.quality}p"
    return query


def main():
    parser = argparse.ArgumentParser(
        description="pirate-grab - TV & movie grabber for media preservation",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="For legally owned media preservation only. Arr!")
    parser.add_argument("query", help="Show/movie name to search")
    parser.add_argument("--season", "-s", type=int, help="Season number")
    parser.add_argument("--episode", "-e", type=int, help="Episode number")
    parser.add_argument("--movie", "-m", action="store_true", help="Search movies instead of TV")
    parser.add_argument("--quality", "-q", choices=["480", "720", "1080", "2160"],
                        help="Preferred quality")
    parser.add_argument("--dry-run", "-n", action="store_true", help="Preview only")
    parser.add_argument("--top", "-t", type=int, default=5, help="Show top N results")
    parser.add_argument("--pick", "-p", type=int, help="Pick result N (skip selection)")
    parser.add_argument("--dir", "-d", help="Custom output directory")
    parser.add_argument("--max-size", type=float, default=0,
                        help="Max size in GB (0 = no limit). Filters out results bigger than this.")
    args = parser.parse_args()

    category = "Movies" if args.movie else "TV"
    search_query = build_query(args)

    # Default output directory
    if args.dir:
        output_dir = args.dir
    elif args.movie:
        output_dir = MOVIES_DIR
    else:
        output_dir = SHOWS_DIR

    print(f"\n  PIRATE-GRAB")
    print(f"  {'='*45}")
    print(f"  Query:    {search_query}")
    print(f"  Category: {category}")
    print(f"  Output:   {output_dir}")
    if args.dry_run:
        print(f"  Mode:     DRY RUN")
    print()

    # Filter results to only include ones that actually match the query
    def filter_relevant(results, query):
        """Remove results that don't match any significant words from the query"""
        # Extract significant words (3+ chars, not common junk)
        skip = {"the", "and", "season", "complete", "episode"}
        words = [w.lower() for w in re.split(r'\W+', query) if len(w) >= 3 and w.lower() not in skip]
        if not words:
            return results
        # Require at least half the significant words to match
        threshold = max(1, len(words) // 2)
        filtered = []
        for r in results:
            name_lower = r["name"].lower()
            matches = sum(1 for w in words if w in name_lower)
            if matches >= threshold:
                filtered.append(r)
        return filtered

    # Search - try 1337x first, then TPB
    print(f"  Searching 1337x...")
    results = filter_relevant(search_1337x(search_query, category), args.query)
    source = "1337x"

    if not results:
        print(f"  Nothing relevant on 1337x. Trying Pirate Bay...")
        results = filter_relevant(search_tpb(search_query, category), args.query)
        source = "TPB"

    if not results:
        # Try without season/episode for broader results
        if args.season:
            print(f"  Trying broader search: {args.query}")
            results = filter_relevant(search_1337x(args.query, category), args.query)
            source = "1337x"
            if not results:
                results = filter_relevant(search_tpb(args.query, category), args.query)
                source = "TPB"

    if not results:
        # Last resort: TPB without category filter
        print(f"  Last resort: TPB all categories...")
        results = filter_relevant(search_tpb(args.query, ""), args.query)
        source = "TPB"

    if not results:
        print("  No results found anywhere. This might be too niche.")
        print("  Tips: try different search terms, check slskd, or search manually")
        sys.exit(1)

    print(f"  Source: {source}")

    # Filter by max size if specified
    if args.max_size > 0:
        def parse_size_gb(size_str):
            """Parse size string to GB"""
            s = size_str.lower().strip()
            try:
                if "gib" in s or "gb" in s:
                    return float(re.search(r'([\d.]+)', s).group(1))
                elif "mib" in s or "mb" in s:
                    return float(re.search(r'([\d.]+)', s).group(1)) / 1024
            except (AttributeError, ValueError):
                pass
            return 0  # unknown size, keep it

        before = len(results)
        results = [r for r in results if parse_size_gb(r.get("size", "")) <= args.max_size
                   or parse_size_gb(r.get("size", "")) == 0]  # keep unknown sizes
        if len(results) < before:
            print(f"  Filtered: {before - len(results)} results over {args.max_size}GB limit")

        if not results:
            print(f"  All results exceed {args.max_size}GB. Try --max-size with a higher value.")
            sys.exit(1)

    # Score and sort
    scored = []
    for r in results:
        s = score_result(r, search_query, args.quality)
        scored.append((s, r))
    scored.sort(key=lambda x: x[0], reverse=True)

    # Display results
    print(f"  Found {len(results)} results:\n")
    show_count = min(args.top, len(scored))
    for i, (score, r) in enumerate(scored[:show_count]):
        seeds_color = "\033[32m" if r["seeds"] > 10 else ("\033[33m" if r["seeds"] > 0 else "\033[31m")
        best = " <-- BEST" if i == 0 else ""
        print(f"  {i+1}. {r['name'][:80]}")
        print(f"     {seeds_color}S:{r['seeds']}\033[0m L:{r['leeches']} | {r['size']} | score={score}{best}")
        print()

    # Pick result
    if args.pick:
        pick_idx = args.pick - 1
    else:
        pick_idx = 0  # Default to best

    if pick_idx >= len(scored):
        print(f"  Pick #{args.pick} doesn't exist. Max is {len(scored)}.")
        sys.exit(1)

    chosen_score, chosen = scored[pick_idx]

    if chosen["seeds"] == 0 and not args.dry_run:
        print(f"  WARNING: No seeders! Download might not start.")
        print(f"  Try a different result with --pick N")

    # Get magnet link (TPB has inline magnets, 1337x needs page fetch)
    magnet = chosen.get("magnet")
    if not magnet and chosen.get("link"):
        print(f"  Getting magnet link for: {chosen['name'][:60]}...")
        magnet = get_magnet(chosen["link"])

    if not magnet:
        print("  Could not retrieve magnet link. Site might be blocking.")
        sys.exit(1)

    print(f"  Magnet acquired!\n")

    # Download
    download_torrent(magnet, output_dir, args.dry_run)

    if not args.dry_run:
        print(f"\n  Done! Check {output_dir} for your files.")
        print(f"  Run 'jellyfin-merge {SHOWS_DIR} --scan' if seasons need organizing.\n")
    else:
        print(f"\n  Run without --dry-run to download.\n")


if __name__ == "__main__":
    main()
