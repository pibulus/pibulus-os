#!/usr/bin/env python3
"""
Mary Poppins - Digital Sorting Agent
Cleans up messy filenames using AI (haiku or local claude)

Usage:
  python3 mary_poppins.py /path/to/messy/folder
  python3 mary_poppins.py /path/to/folder --dry-run
  python3 mary_poppins.py /path/to/folder --pattern "comics"
  python3 mary_poppins.py /path/to/folder --pattern "music"
  python3 mary_poppins.py /path/to/folder --depth 2

Patterns:
  comics  - "Series Name #001.ext" or "Series Name v01 #001.ext"
  music   - "Artist - Album (Year)/01 - Track Name.ext"
  movies  - "Movie Name (Year).ext"
  generic - Just clean up junk characters and normalize
"""

import os, sys, subprocess, json, argparse, re

PATTERNS = {
    "comics": """Clean these comic filenames. Target format: "Series Name #001.ext" or if volume info exists "Series Name v01 #001.ext".
Remove junk like scan info, group tags [brackets], resolution, file format indicators in the name (keep the actual extension).
Keep issue numbers. For collected editions use "Series Name - Volume Title.ext".""",

    "music": """Clean these music filenames. Target format: "01 - Track Name.ext" for files inside album folders.
For album folders: "Artist - Album Name (Year)". Remove bitrate info, codec info, catalog numbers, group tags.""",

    "movies": """Clean these movie/show filenames. Target format: "Title (Year).ext".
Remove quality tags (1080p, x264, etc), group names, source info. Keep the year.""",

    "generic": """Clean these filenames. Remove junk characters, normalize spacing, remove [brackets] with technical info,
keep meaningful content. Make them human-readable.""",
}

def get_files(path, depth=1):
    """List files and dirs at path, respecting depth"""
    entries = []
    for item in sorted(os.listdir(path)):
        full = os.path.join(path, item)
        is_dir = os.path.isdir(full)
        entries.append({
            "name": item,
            "is_dir": is_dir,
            "path": full,
        })
        if is_dir and depth > 1:
            for sub in sorted(os.listdir(full)):
                subfull = os.path.join(full, sub)
                entries.append({
                    "name": os.path.join(item, sub),
                    "is_dir": os.path.isdir(subfull),
                    "path": subfull,
                })
    return entries

def ask_ai(names, pattern_prompt):
    """Send filenames to claude haiku for cleaning"""
    prompt = f"""{pattern_prompt}

Return ONLY a JSON array of objects with "old" and "new" keys.
If a name is already clean, set "new" to the same as "old".
Do not change file extensions. Only rename, never delete.

Filenames to clean:
{json.dumps(names, indent=2)}

Return valid JSON only, no markdown, no explanation."""

    try:
        result = subprocess.run(
            ["claude", "-p", "--model", "haiku", prompt],
            capture_output=True, text=True, timeout=30
        )
        output = result.stdout.strip()
        # Extract JSON from response (haiku sometimes wraps it)
        match = re.search(r'\[.*\]', output, re.DOTALL)
        if match:
            return json.loads(match.group())
        return json.loads(output)
    except subprocess.TimeoutExpired:
        print("  AI timed out, skipping batch")
        return []
    except json.JSONDecodeError:
        print(f"  AI returned invalid JSON, skipping batch")
        print(f"  Raw output: {output[:200]}")
        return []
    except FileNotFoundError:
        print("  'claude' CLI not found. Install claude-code or use --manual mode")
        sys.exit(1)

def preview_renames(renames):
    """Show proposed renames"""
    changes = [(r["old"], r["new"]) for r in renames if r["old"] != r["new"]]
    if not changes:
        print("\n  Nothing to rename - all files look clean!")
        return []

    print(f"\n  {len(changes)} rename(s) proposed:\n")
    for old, new in changes:
        # Color: red for old, green for new
        print(f"    \033[31m- {old}\033[0m")
        print(f"    \033[32m+ {new}\033[0m")
        print()
    return changes

def execute_renames(base_path, changes, dry_run=False):
    """Actually rename the files"""
    done = 0
    for old, new in changes:
        old_path = os.path.join(base_path, old)
        new_path = os.path.join(base_path, new)

        if not os.path.exists(old_path):
            print(f"  SKIP (missing): {old}")
            continue
        if os.path.exists(new_path) and old_path != new_path:
            print(f"  SKIP (conflict): {new} already exists")
            continue

        if dry_run:
            print(f"  [DRY] {old} -> {new}")
        else:
            # Handle nested paths - create parent dirs if needed
            new_dir = os.path.dirname(new_path)
            if new_dir and not os.path.exists(new_dir):
                os.makedirs(new_dir)
            os.rename(old_path, new_path)
            print(f"  OK: {old} -> {new}")
        done += 1
    return done

def main():
    parser = argparse.ArgumentParser(
        description="Mary Poppins - Digital Sorting Agent",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="Practically perfect in every way."
    )
    parser.add_argument("path", help="Folder to clean up")
    parser.add_argument("--pattern", "-p", default="generic",
                        choices=list(PATTERNS.keys()),
                        help="Naming pattern to apply")
    parser.add_argument("--dry-run", "-n", action="store_true",
                        help="Preview only, don't rename")
    parser.add_argument("--yes", "-y", action="store_true",
                        help="Skip confirmation prompt")
    parser.add_argument("--depth", "-d", type=int, default=1,
                        help="How deep to scan (1=current dir, 2=one level of subdirs)")
    parser.add_argument("--batch-size", "-b", type=int, default=30,
                        help="Files per AI request (controls token usage)")
    args = parser.parse_args()

    path = os.path.abspath(args.path)
    if not os.path.isdir(path):
        print(f"Not a directory: {path}")
        sys.exit(1)

    print(f"\n  MARY POPPINS - Digital Sorting Agent")
    print(f"  ====================================")
    print(f"  Folder:  {path}")
    print(f"  Pattern: {args.pattern}")
    print(f"  Depth:   {args.depth}")
    if args.dry_run:
        print(f"  Mode:    DRY RUN")
    print()

    entries = get_files(path, args.depth)
    names = [e["name"] for e in entries]

    print(f"  Found {len(names)} items")

    if not names:
        print("  Nothing to clean!")
        return

    # Process in batches to keep token usage low
    all_changes = []
    batch_size = args.batch_size

    for i in range(0, len(names), batch_size):
        batch = names[i:i+batch_size]
        if len(names) > batch_size:
            print(f"\n  Processing batch {i//batch_size + 1}/{(len(names)-1)//batch_size + 1} ({len(batch)} items)...")

        renames = ask_ai(batch, PATTERNS[args.pattern])
        changes = preview_renames(renames)
        all_changes.extend(changes)

    if not all_changes:
        return

    if not args.yes and not args.dry_run:
        try:
            answer = input(f"\n  Apply {len(all_changes)} rename(s)? [y/N] ").strip().lower()
        except (EOFError, KeyboardInterrupt):
            answer = 'n'
        if answer != 'y':
            print("  Cancelled.")
            return

    done = execute_renames(path, all_changes, args.dry_run)
    print(f"\n  {'Would rename' if args.dry_run else 'Renamed'} {done}/{len(all_changes)} items")
    print(f"  Spit-spot! All tidy.")

if __name__ == "__main__":
    main()
