#!/usr/bin/env python3
"""
simpsons-grab - Download the post-golden-age Simpsons gems
Reads simpsons-goldmine data and queues downloads via pirate-grab.

Strategy: If 5+ gems in a season, grab the whole season (cheaper/easier).
Otherwise grab individual episodes.

Usage:
  simpsons-grab                          # Dry run, show the plan
  simpsons-grab --go                     # Actually download
  simpsons-grab --min-rating 7.5         # Higher bar
  simpsons-grab --seasons 23,27,33       # Only specific seasons
"""
import json, os, sys, subprocess, argparse
from collections import defaultdict

CACHE = os.path.expanduser("~/.cache/simpsons-goldmine/gems.json")
PIRATE_GRAB = os.path.expanduser("~/pibulus-os/scripts/pirate_grab.py")

def main():
    parser = argparse.ArgumentParser(description="Simpsons Grab - Download the gems")
    parser.add_argument("--go", action="store_true", help="Actually download (default is dry run)")
    parser.add_argument("--min-rating", type=float, default=7.0, help="Min rating (default 7.0)")
    parser.add_argument("--seasons", help="Comma-separated season numbers to grab")
    parser.add_argument("--quality", "-q", default="720", help="Quality pref (default 720)")
    args = parser.parse_args()

    if not os.path.exists(CACHE):
        print("  No gems data found. Run simpsons-goldmine on Mac first and SCP the cache.")
        sys.exit(1)

    gems = json.load(open(CACHE))
    gems = [g for g in gems if g.get("rating", 0) >= args.min_rating]

    if args.seasons:
        allowed = set(int(s) for s in args.seasons.split(","))
        gems = [g for g in gems if g["season"] in allowed]

    # Group by season
    by_season = defaultdict(list)
    for g in gems:
        by_season[g["season"]].append(g)

    mode = "LIVE" if args.go else "DRY RUN"
    print(f"\n  SIMPSONS GRAB [{mode}]")
    print(f"  {'='*45}")
    print(f"  Rating: >= {args.min_rating}")
    print(f"  Quality: {args.quality}p")
    print(f"  Episodes: {len(gems)} across {len(by_season)} seasons\n")

    # Strategy display
    full_seasons = []
    individual_eps = []

    for s in sorted(by_season):
        eps = by_season[s]
        if len(eps) >= 5:
            full_seasons.append(s)
            print(f"  S{s:02d}: {len(eps)} gems -> FULL SEASON")
        else:
            for ep in eps:
                individual_eps.append(ep)
                print(f"  S{s:02d}E{ep['episode']:02d}: {ep['title']} ({ep['rating']})")

    print(f"\n  Plan: {len(full_seasons)} full seasons + {len(individual_eps)} individual episodes")

    if not args.go:
        print(f"\n  Run with --go to start downloading.\n")
        return

    # Execute
    print(f"\n  Starting downloads...\n")

    for s in full_seasons:
        print(f"\n  --- Season {s} (full) ---")
        cmd = ["python3", PIRATE_GRAB, "The Simpsons", "--season", str(s)]
        if args.quality:
            cmd.extend(["--quality", args.quality])
        subprocess.run(cmd)

    for ep in individual_eps:
        print(f"\n  --- S{ep['season']:02d}E{ep['episode']:02d}: {ep['title']} ---")
        cmd = ["python3", PIRATE_GRAB, "The Simpsons",
               "--season", str(ep["season"]),
               "--episode", str(ep["episode"])]
        if args.quality:
            cmd.extend(["--quality", args.quality])
        subprocess.run(cmd)

    print(f"\n  All queued! Run 'jellyfin-merge --scan' to organize.\n")

if __name__ == "__main__":
    main()
