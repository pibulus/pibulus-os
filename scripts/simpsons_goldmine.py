#!/usr/bin/env python3
"""
Simpsons Goldmine - Find the gems in post-golden-age Simpsons
Uses IMDb's free public dataset to find highly-rated episodes.

Usage:
  simpsons-goldmine                          # Default: S20+, rating 7.0+
  simpsons-goldmine --min-season 15          # From season 15
  simpsons-goldmine --min-rating 7.5         # Higher bar
  simpsons-goldmine --format torrent         # Output torrent search strings
  simpsons-goldmine --format list            # Just episode list
  simpsons-goldmine --format kpab-grab       # Output as download commands

Data source: IMDb public datasets (no API key needed)
"""
import urllib.request, gzip, csv, io, sys, argparse, json, os

CACHE_DIR = os.path.expanduser("~/.cache/simpsons-goldmine")
SIMPSONS_ID = "tt0096697"  # IMDb ID for The Simpsons

RATINGS_URL = "https://datasets.imdbws.com/title.ratings.tsv.gz"
EPISODES_URL = "https://datasets.imdbws.com/title.episode.tsv.gz"
BASICS_URL = "https://datasets.imdbws.com/title.basics.tsv.gz"

def download_gz(url, cache_name):
    """Download and cache gzipped TSV"""
    os.makedirs(CACHE_DIR, exist_ok=True)
    cache_path = os.path.join(CACHE_DIR, cache_name)

    # Use cache if less than 7 days old
    if os.path.exists(cache_path):
        age = os.time() - os.path.getmtime(cache_path) if hasattr(os, 'time') else 999999
        import time
        age = time.time() - os.path.getmtime(cache_path)
        if age < 7 * 86400:
            with open(cache_path, 'r') as f:
                return f.read()

    print(f"  Downloading {cache_name}... (this is ~30MB, cached for 7 days)")
    req = urllib.request.Request(url, headers={"User-Agent": "simpsons-goldmine/1.0"})
    response = urllib.request.urlopen(req, timeout=120)
    data = gzip.decompress(response.read()).decode('utf-8')

    with open(cache_path, 'w') as f:
        f.write(data)
    return data

def load_simpsons_episodes():
    """Load episode data for The Simpsons"""
    # Step 1: Get all episode IDs for The Simpsons
    print("  Loading episode index...")
    episodes_data = download_gz(EPISODES_URL, "episodes.tsv")
    reader = csv.DictReader(io.StringIO(episodes_data), delimiter='\t')

    simpsons_eps = {}  # tconst -> {season, episode}
    for row in reader:
        if row["parentTconst"] == SIMPSONS_ID:
            try:
                s = int(row["seasonNumber"]) if row["seasonNumber"] != "\\N" else None
                e = int(row["episodeNumber"]) if row["episodeNumber"] != "\\N" else None
                if s and e:
                    simpsons_eps[row["tconst"]] = {"season": s, "episode": e}
            except (ValueError, KeyError):
                pass

    print(f"  Found {len(simpsons_eps)} Simpsons episodes in index")

    # Step 2: Get ratings
    print("  Loading ratings...")
    ratings_data = download_gz(RATINGS_URL, "ratings.tsv")
    reader = csv.DictReader(io.StringIO(ratings_data), delimiter='\t')

    for row in reader:
        if row["tconst"] in simpsons_eps:
            try:
                simpsons_eps[row["tconst"]]["rating"] = float(row["averageRating"])
                simpsons_eps[row["tconst"]]["votes"] = int(row["numVotes"])
            except (ValueError, KeyError):
                pass

    # Step 3: Get episode titles
    print("  Loading titles...")
    basics_data = download_gz(BASICS_URL, "basics.tsv")
    reader = csv.DictReader(io.StringIO(basics_data), delimiter='\t')

    for row in reader:
        if row["tconst"] in simpsons_eps:
            simpsons_eps[row["tconst"]]["title"] = row.get("primaryTitle", "?")

    return simpsons_eps

def main():
    parser = argparse.ArgumentParser(
        description="Simpsons Goldmine - Find gems in later seasons")
    parser.add_argument("--min-season", type=int, default=20,
                        help="Minimum season (default: 20)")
    parser.add_argument("--min-rating", type=float, default=7.0,
                        help="Minimum IMDb rating (default: 7.0)")
    parser.add_argument("--format", choices=["table", "list", "torrent", "json"],
                        default="table", help="Output format")
    parser.add_argument("--refresh", action="store_true",
                        help="Force re-download of IMDb data")
    args = parser.parse_args()

    print(f"\n  SIMPSONS GOLDMINE")
    print(f"  {'='*45}")
    print(f"  Filter: Season {args.min_season}+ with IMDb {args.min_rating}+\n")

    if args.refresh:
        import shutil
        shutil.rmtree(CACHE_DIR, ignore_errors=True)

    episodes = load_simpsons_episodes()

    # Filter
    gems = []
    for eid, ep in episodes.items():
        if (ep.get("season", 0) >= args.min_season and
            ep.get("rating", 0) >= args.min_rating and
            ep.get("title")):
            gems.append(ep)

    gems.sort(key=lambda x: (x["season"], x["episode"]))

    total_in_range = sum(1 for ep in episodes.values()
                        if ep.get("season", 0) >= args.min_season)

    print(f"\n  {len(gems)} gems out of {total_in_range} episodes "
          f"(Season {args.min_season}+, {args.min_rating}+ rating)\n")

    if args.format == "table":
        print(f"  {'S':>3}{'E':>4}  {'Rating':>6}  {'Votes':>6}  Title")
        print(f"  {'─'*3}{'─'*4}  {'─'*6}  {'─'*6}  {'─'*30}")
        for ep in gems:
            r = ep.get("rating", 0)
            star = " *" if r >= 8.0 else ""
            print(f"  {ep['season']:>3}{ep['episode']:>4}  {r:>6.1f}  {ep.get('votes',0):>6}  {ep['title']}{star}")

    elif args.format == "list":
        for ep in gems:
            print(f"The Simpsons S{ep['season']:02d}E{ep['episode']:02d} - {ep['title']}")

    elif args.format == "torrent":
        print("  Torrent search strings:\n")
        # Group by season for batch searching
        from collections import defaultdict
        by_season = defaultdict(list)
        for ep in gems:
            by_season[ep["season"]].append(ep)

        for s in sorted(by_season):
            eps = by_season[s]
            if len(eps) > 5:
                # If most of the season is good, grab the whole thing
                print(f"  The Simpsons Season {s} 1080p")
            else:
                for ep in eps:
                    print(f"  The Simpsons S{s:02d}E{ep['episode']:02d}")

    elif args.format == "json":
        out = []
        for ep in gems:
            out.append({
                "season": ep["season"],
                "episode": ep["episode"],
                "title": ep["title"],
                "rating": ep.get("rating", 0),
                "votes": ep.get("votes", 0),
                "search": f"The Simpsons S{ep['season']:02d}E{ep['episode']:02d}"
            })
        print(json.dumps(out, indent=2))

    print()

if __name__ == "__main__":
    main()
