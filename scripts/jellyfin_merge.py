#!/usr/bin/env python3
"""
Jellyfin Season Merger (Spit-Spot Edition)
Auto-detects and merges split-season show folders into proper Jellyfin structure.

Usage:
  jellyfin-merge /path/to/Shows --scan              # Find problems
  jellyfin-merge /path/to/Shows --scan --dry-run     # Preview fixes
  jellyfin-merge /path/to/Shows --scan               # Execute fixes (confirms first)
  jellyfin-merge /path/to/Shows --eject "Skate vids" # Move folder out to ../Misc Videos/

Jellyfin expects: Show Name/Season 01/episodes...
This script finds folders that look like separate seasons of the same show
and merges them. Zero AI calls, pure pattern matching.

Can also be imported and used with manual rules (see MERGE_RULES dict format).
"""
import os, sys, re, shutil, argparse
from collections import defaultdict

def detect_season(name):
    """Extract season number from folder name"""
    for p in [r'[Ss]eason\s*(\d+)', r'\.S(\d{2})', r'[Ss](\d{1,2})[\s\.\)\-]', r'[Ss](\d{1,2})$']:
        m = re.search(p, name)
        if m:
            return int(m.group(1))
    return None

def extract_show_name(folder_name):
    """Try to extract the base show name from a messy folder name"""
    name = folder_name
    # Remove year + season + quality junk
    name = re.sub(r'\s*\(?\d{4}\)?\s*[Ss](eason)?\s*\d+.*', '', name)
    name = re.sub(r'\s*[Ss](eason)?\s*\d+.*', '', name)
    name = re.sub(r'\s*\.S\d{2}.*', '', name)
    name = re.sub(r'\s*S\d{2}E?\d*.*', '', name)
    # Clean dots to spaces
    name = name.replace('.', ' ').strip()
    # Remove trailing junk
    name = re.sub(r'\s*[-_]\s*$', '', name)
    return name.strip()

def scan_for_splits(base_path):
    """Auto-detect shows with multiple season folders"""
    folders = sorted([f for f in os.listdir(base_path)
                     if os.path.isdir(os.path.join(base_path, f))])

    # Group by extracted show name
    groups = defaultdict(list)
    for f in folders:
        show = extract_show_name(f)
        if show and detect_season(f) is not None:
            groups[show].append(f)

    # Only return groups with 2+ folders (actual splits)
    splits = {k: v for k, v in groups.items() if len(v) >= 2}
    return splits

def merge_folders(base_path, target_name, source_folders, dry_run=True):
    """Merge source folders into target/Season XX structure"""
    target_path = os.path.join(base_path, target_name)
    count = 0

    if not os.path.exists(target_path):
        print(f"    MKDIR  {target_name}")
        if not dry_run:
            os.makedirs(target_path, exist_ok=True)
        count += 1

    for folder in source_folders:
        source_path = os.path.join(base_path, folder)
        if not os.path.exists(source_path):
            continue
        # Skip if this IS the target
        if os.path.abspath(source_path) == os.path.abspath(target_path):
            continue

        season_num = detect_season(folder)
        if season_num is None:
            print(f"    WARN: Can't detect season from '{folder}'")
            continue

        season_dir = f"Season {season_num:02d}"
        season_path = os.path.join(target_path, season_dir)

        print(f"    SEASON {folder} -> {target_name}/{season_dir}")
        if not dry_run:
            if os.path.exists(season_path):
                # Merge contents
                for item in os.listdir(source_path):
                    shutil.move(os.path.join(source_path, item),
                              os.path.join(season_path, item))
                try:
                    os.rmdir(source_path)
                except OSError:
                    pass
            else:
                os.rename(source_path, season_path)
        count += 1

    return count

def eject_folder(base_path, folder_name, dry_run=True):
    """Move a folder out of Shows into ../Misc Videos/"""
    src = os.path.join(base_path, folder_name)
    misc = os.path.join(os.path.dirname(base_path), "Misc Videos")
    dst = os.path.join(misc, folder_name)
    if not os.path.exists(src):
        print(f"  Not found: {folder_name}")
        return
    print(f"  EJECT: {folder_name} -> ../Misc Videos/")
    if not dry_run:
        os.makedirs(misc, exist_ok=True)
        shutil.move(src, dst)

def main():
    parser = argparse.ArgumentParser(
        description="Jellyfin Season Merger - Spit-Spot Edition",
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("path", help="Shows directory")
    parser.add_argument("--scan", action="store_true",
                        help="Auto-detect split seasons and merge them")
    parser.add_argument("--eject", nargs="+",
                        help="Move folder(s) out to ../Misc Videos/")
    parser.add_argument("--dry-run", "-n", action="store_true")
    parser.add_argument("--yes", "-y", action="store_true",
                        help="Skip confirmation")
    args = parser.parse_args()

    base = os.path.abspath(args.path)
    mode = "DRY RUN" if args.dry_run else "LIVE"

    print(f"\n  JELLYFIN SEASON MERGER [{mode}]")
    print(f"  {'='*45}")
    print(f"  Path: {base}\n")

    if args.eject:
        for folder in args.eject:
            eject_folder(base, folder, args.dry_run)
        print()

    if args.scan:
        splits = scan_for_splits(base)
        if not splits:
            print("  No split-season folders detected. Library looks clean!")
            return

        print(f"  Found {len(splits)} shows with split seasons:\n")
        for show, folders in sorted(splits.items()):
            # Pick a clean target name: show name + year if available
            year_match = re.search(r'(\d{4})', folders[0])
            year = f" ({year_match.group(1)})" if year_match else ""
            target = f"{show}{year}"
            print(f"  {target}:")
            for f in folders:
                s = detect_season(f)
                print(f"    S{s:02d} <- {f}")
            print()

        if args.dry_run:
            print("  Run without --dry-run to merge these.\n")
            return

        if not args.yes:
            try:
                answer = input(f"  Merge {len(splits)} shows? [y/N] ").strip().lower()
            except (EOFError, KeyboardInterrupt):
                print("\n  Cancelled.")
                return
            if answer != 'y':
                print("  Cancelled.")
                return

        total = 0
        for show, folders in sorted(splits.items()):
            year_match = re.search(r'(\d{4})', folders[0])
            year = f" ({year_match.group(1)})" if year_match else ""
            target = f"{show}{year}"
            print(f"\n  {target}:")
            total += merge_folders(base, target, folders, dry_run=False)

        print(f"\n  Done! {total} actions. Rescan Jellyfin.\n")

    if not args.scan and not args.eject:
        parser.print_help()

if __name__ == "__main__":
    main()
