#!/usr/bin/env python3
"""
Mary Poppins - Digital Sorting Agent

Practical filename cleanup with deterministic rules first, optional AI second.

Usage:
  python3 mary_poppins.py /path/to/folder --pattern roms --dry-run
  python3 mary_poppins.py /path/to/folder --pattern comics --engine deterministic
  python3 mary_poppins.py /path/to/folder --pattern generic --engine ai
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path

PATTERNS = {
    "comics": """Clean these comic filenames. Target format: "Series Name #001.ext" or if volume info exists "Series Name v01 #001.ext".
Remove junk like scan info, group tags [brackets], resolution, file format indicators in the name (keep the actual extension).
Keep issue numbers. For collected editions use "Series Name - Volume Title.ext".""",
    "music": """Clean these music filenames. Target format: "01 - Track Name.ext" for files inside album folders.
For album folders: "Artist - Album Name (Year)". Remove bitrate info, codec info, catalog numbers, group tags.""",
    "movies": """Clean these movie/show filenames. Target format: "Title (Year).ext".
Remove quality tags (1080p, x264, etc), group names, source info. Keep the year.""",
    "roms": """Clean these ROM filenames for library scanners.
Keep the real title and useful region/disc info. Remove patcher credits, translation tags, scene junk, revision spam, and technical clutter.
Prefer "Title (Region).ext" or "Title (Region) (Disc X).ext" when relevant.""",
    "generic": """Clean these filenames. Remove junk characters, normalize spacing, remove [brackets] with technical info,
keep meaningful content. Make them human-readable.""",
}

TRASH_BRACKETS = re.compile(r"\[(?:[^\]]*?(?:by|v\d|\bn\b|\bi\b|beta|proto|patch|hack|fix|english|translation)[^\]]*?)\]", re.I)
TRASH_PARENS = re.compile(r"\((?:[^\)]*?(?:rev(?:ision)?|beta|proto|demo|sample|track|cue|bin|patched?|translation)[^\)]*?)\)", re.I)
MULTISPACE_RE = re.compile(r"\s+")
REGION_RE = re.compile(r"\((USA|Europe|Japan|World|Australia|US|EU|JP)\)", re.I)
DISC_RE = re.compile(r"\((Disc\s*\d+)\)", re.I)
TITLE_ALIAS_MAP = {
    "Akumajou Dracula X - Gekka no Yasoukyoku": "Castlevania - Symphony of the Night",
    "Castlevania- Rondo of Blood": "Castlevania - Rondo of Blood",
    "MegaMan X4": "Mega Man X4",
    "MegaMan X6": "Mega Man X6",
    "Persona 2 - Tsumi - Innocent Sin": "Persona 2 - Innocent Sin",
}
ROM_EXTS = {
    ".7z", ".bin", ".chd", ".cue", ".gba", ".gb", ".gbc", ".gen", ".iso",
    ".n64", ".nes", ".pbp", ".pce", ".sfc", ".smc", ".v64", ".z64", ".zip",
}


def normalize_spaces(text: str) -> str:
    text = text.replace("_", " ")
    text = text.replace(" - ", " - ")
    text = text.replace(" :", ":")
    text = text.replace(" -.", ".")
    # Only normalize separator hyphens that already have whitespace on one side.
    # This preserves real title compounds like "Vib-Ribbon" and "Butt-Head".
    text = re.sub(r"\s+-\s*", " - ", text)
    text = re.sub(r"\s*-\s+", " - ", text)
    return MULTISPACE_RE.sub(" ", text).strip(" .-_")


def normalize_region(text: str) -> str:
    def repl(match: re.Match[str]) -> str:
        region = match.group(1).upper()
        mapping = {"US": "USA", "EU": "Europe", "JP": "Japan"}
        return f"({mapping.get(region, region.title() if region not in {'USA', 'EU'} else region)})"

    return REGION_RE.sub(repl, text)


def pull_first(pattern: re.Pattern[str], text: str) -> str | None:
    match = pattern.search(text)
    return match.group(1) if match else None


def clean_generic_name(stem: str) -> str:
    stem = TRASH_BRACKETS.sub("", stem)
    stem = TRASH_PARENS.sub("", stem)
    stem = re.sub(r"[【】]", "", stem)
    stem = re.sub(r"\s{2,}", " ", stem)
    return normalize_spaces(stem)


def clean_rom_name(stem: str) -> str:
    region = pull_first(REGION_RE, stem)
    disc = pull_first(DISC_RE, stem)

    title = re.sub(r"\[[^\]]+\]", "", stem)
    title = TRASH_PARENS.sub("", title)
    title = REGION_RE.sub("", title)
    title = DISC_RE.sub("", title)
    title = title.replace("’", "'")
    title = normalize_spaces(title)
    title = TITLE_ALIAS_MAP.get(title, title)

    if region and f"({region})" not in title:
        norm_region = normalize_region(f"({region})")
        title = f"{title} {norm_region}"
    if disc and f"({disc})" not in title:
        title = f"{title} ({disc})"

    title = normalize_region(title)
    title = re.sub(r"\s+\((Disc\s*\d+)\)\s+\(([^)]+)\)", r" (\2) (\1)", title, flags=re.I)
    return normalize_spaces(title)


def clean_music_name(stem: str) -> str:
    stem = re.sub(r"\[(?:FLAC|MP3|320kbps|V0|WEB|CD|vinyl)[^\]]*\]", "", stem, flags=re.I)
    return normalize_spaces(stem)


def clean_movie_name(stem: str) -> str:
    stem = re.sub(r"\b(480p|720p|1080p|2160p|x264|x265|bluray|webrip|web-dl|dvdrip|brrip)\b", "", stem, flags=re.I)
    stem = TRASH_BRACKETS.sub("", stem)
    return normalize_spaces(stem)


def deterministic_rename(name: str, pattern: str) -> str:
    path = Path(name)
    suffix = path.suffix if path.suffix else ""
    stem = path.name[:-len(suffix)] if suffix else path.name

    if path.name.startswith("."):
        return name
    if pattern == "roms" and (not path.suffix or path.suffix.lower() not in ROM_EXTS):
        return name

    if pattern == "roms":
        cleaned = clean_rom_name(stem)
    elif pattern == "music":
        cleaned = clean_music_name(stem)
    elif pattern == "movies":
        cleaned = clean_movie_name(stem)
    else:
        cleaned = clean_generic_name(stem)

    if path.parent.as_posix() == ".":
        return f"{cleaned}{suffix}"
    return str(path.parent / f"{cleaned}{suffix}")


def get_entries(path: Path, depth: int) -> list[dict[str, object]]:
    entries: list[dict[str, object]] = []
    for item in sorted(path.iterdir()):
        entries.append({"name": item.name, "path": item, "is_dir": item.is_dir()})
        if item.is_dir() and depth > 1:
            for sub in sorted(item.iterdir()):
                rel = str(sub.relative_to(path))
                entries.append({"name": rel, "path": sub, "is_dir": sub.is_dir()})
    return entries


def ask_ai(names: list[str], pattern_prompt: str) -> list[dict[str, str]]:
    prompt = f"""{pattern_prompt}

Return ONLY a JSON array of objects with "old" and "new" keys.
If a name is already clean, set "new" to the same as "old".
Do not change file extensions. Only rename, never delete.

Filenames to clean:
{json.dumps(names, indent=2)}

Return valid JSON only, no markdown, no explanation."""

    result = subprocess.run(
        ["claude", "-p", "--model", "haiku", prompt],
        capture_output=True,
        text=True,
        timeout=30,
    )
    output = result.stdout.strip()
    match = re.search(r"\[.*\]", output, re.DOTALL)
    payload = match.group() if match else output
    return json.loads(payload)


def build_plan(names: list[str], pattern: str, engine: str) -> list[dict[str, str]]:
    if engine in {"deterministic", "auto"}:
        plan = [{"old": name, "new": deterministic_rename(name, pattern)} for name in names]
        if engine == "deterministic":
            return plan

        changed = [item for item in plan if item["old"] != item["new"]]
        if changed:
            return plan

    try:
        return ask_ai(names, PATTERNS[pattern])
    except subprocess.TimeoutExpired:
        print("  AI timed out, falling back to deterministic cleanup")
    except (FileNotFoundError, json.JSONDecodeError) as exc:
        print(f"  AI cleanup unavailable ({exc}), falling back to deterministic cleanup")

    return [{"old": name, "new": deterministic_rename(name, pattern)} for name in names]


def preview_renames(renames: list[dict[str, str]]) -> list[tuple[str, str]]:
    changes = [(r["old"], r["new"]) for r in renames if r["old"] != r["new"]]
    if not changes:
        print("\n  Nothing to rename - all files look clean!")
        return []

    print(f"\n  {len(changes)} rename(s) proposed:\n")
    for old, new in changes:
        print(f"    \033[31m- {old}\033[0m")
        print(f"    \033[32m+ {new}\033[0m\n")
    return changes


def execute_renames(base_path: Path, changes: list[tuple[str, str]], dry_run: bool = False) -> int:
    done = 0
    for old, new in changes:
        old_path = base_path / old
        new_path = base_path / new

        if not old_path.exists():
            print(f"  SKIP (missing): {old}")
            continue
        if new_path.exists() and old_path != new_path:
            print(f"  SKIP (conflict): {new} already exists")
            continue

        if dry_run:
            print(f"  [DRY] {old} -> {new}")
        else:
            new_path.parent.mkdir(parents=True, exist_ok=True)
            old_path.rename(new_path)
            print(f"  OK: {old} -> {new}")
        done += 1
    return done


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Mary Poppins - Digital Sorting Agent",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="Practically perfect in every way.",
    )
    parser.add_argument("path", help="Folder to clean up")
    parser.add_argument("--pattern", "-p", default="generic", choices=list(PATTERNS.keys()))
    parser.add_argument("--engine", choices=["auto", "deterministic", "ai"], default="auto")
    parser.add_argument("--dry-run", "-n", action="store_true", help="Preview only, don't rename")
    parser.add_argument("--yes", "-y", action="store_true", help="Skip confirmation prompt")
    parser.add_argument("--depth", "-d", type=int, default=1, help="How deep to scan")
    parser.add_argument("--batch-size", "-b", type=int, default=30, help="Files per AI request")
    args = parser.parse_args()

    path = Path(args.path).expanduser().resolve()
    if not path.is_dir():
        print(f"Not a directory: {path}")
        sys.exit(1)

    print("\n  MARY POPPINS - Digital Sorting Agent")
    print("  ====================================")
    print(f"  Folder:  {path}")
    print(f"  Pattern: {args.pattern}")
    print(f"  Engine:  {args.engine}")
    print(f"  Depth:   {args.depth}")
    if args.dry_run:
        print("  Mode:    DRY RUN")
    print()

    entries = get_entries(path, args.depth)
    names = [str(entry["name"]) for entry in entries]
    print(f"  Found {len(names)} items")
    if not names:
        print("  Nothing to clean!")
        return

    all_changes: list[tuple[str, str]] = []
    for i in range(0, len(names), args.batch_size):
        batch = names[i:i + args.batch_size]
        if len(names) > args.batch_size:
            total_batches = (len(names) - 1) // args.batch_size + 1
            print(f"\n  Processing batch {i // args.batch_size + 1}/{total_batches} ({len(batch)} items)...")
        renames = build_plan(batch, args.pattern, args.engine)
        all_changes.extend(preview_renames(renames))

    if not all_changes:
        return

    if not args.yes and not args.dry_run:
        try:
            answer = input(f"\n  Apply {len(all_changes)} rename(s)? [y/N] ").strip().lower()
        except (EOFError, KeyboardInterrupt):
            answer = "n"
        if answer != "y":
            print("  Cancelled.")
            return

    done = execute_renames(path, all_changes, args.dry_run)
    print(f"\n  {'Would rename' if args.dry_run else 'Renamed'} {done}/{len(all_changes)} items")
    print("  Spit-spot! All tidy.")


if __name__ == "__main__":
    main()
