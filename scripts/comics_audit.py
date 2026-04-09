#!/usr/bin/env python3
"""
comics_audit.py — Kavita comics library diagnostic tool
Scans /media/pibulus/passport/Comics and reports:
  1. Top-level series folders with suspicious duplicates
  2. Folders with file-level duplicates (same issue, multiple variants)
  3. Folders whose internal files span multiple apparent series (Frazetta problem)
  4. Files with junk prefixes
No changes are made — report only.
"""

import os
import re
from collections import defaultdict
from pathlib import Path

COMICS_ROOT = Path("/media/pibulus/passport/Comics")
COMIC_EXTS = {".cbr", ".cbz", ".pdf", ".epub", ".rar", ".zip"}

# ── helpers ─────────────────────────────────────────────────────────────────

def is_comic(path: Path) -> bool:
    return path.suffix.lower() in COMIC_EXTS

def strip_noise(name: str) -> str:
    """Remove year, scanner tags, edition noise for fuzzy comparison."""
    name = re.sub(r'\(\d{4}[-–]\d{4}\)', '', name)   # (1990-1993)
    name = re.sub(r'\(\d{4}\)', '', name)             # (2012)
    name = re.sub(r'\(of \d+\)', '', name, flags=re.I)
    name = re.sub(r'\(digital\)', '', name, flags=re.I)
    name = re.sub(r'\([^)]*empire[^)]*\)', '', name, flags=re.I)
    name = re.sub(r'\([^)]*DCP[^)]*\)', '', name, flags=re.I)
    name = re.sub(r'\([^)]*scan[^)]*\)', '', name, flags=re.I)
    name = re.sub(r'\([^)]*cover[^)]*\)', '', name, flags=re.I)
    name = re.sub(r'\s+', ' ', name)
    return name.strip().lower()

def extract_series_from_filename(fname: str) -> str:
    """Best-effort: strip issue number and noise to get series name."""
    name = Path(fname).stem
    # Remove trailing issue numbers like " 01", " #001", " v1 01"
    name = re.sub(r'\s*[#v]?\d+\s*$', '', name)
    name = re.sub(r'\s*(vol|volume|book|part|issue)\s*\d+\s*$', '', name, flags=re.I)
    return strip_noise(name)

def junk_prefix(name: str) -> bool:
    """Detect filenames/folders with obvious garbage prefixes."""
    return bool(re.match(r'^[0-9a-fA-F]{6,}[_\s]', name) or
                re.match(r'^\[.+\]', name))

# ── section 1: top-level folder duplicate detection ─────────────────────────

def audit_toplevel():
    print("=" * 70)
    print("SECTION 1 — Top-level series folders: suspected duplicates")
    print("=" * 70)

    folders = [f for f in COMICS_ROOT.iterdir() if f.is_dir()]
    # Group folders by their stripped name
    groups = defaultdict(list)
    for f in sorted(folders):
        key = strip_noise(f.name)
        groups[key].append(f.name)

    dupes = {k: v for k, v in groups.items() if len(v) > 1}
    if not dupes:
        print("  None found.\n")
        return

    for key, names in sorted(dupes.items()):
        print(f"\n  ⚠  Possible duplicates (normalised: '{key}'):")
        for n in names:
            prefix = "  [JUNK PREFIX]" if junk_prefix(n) else ""
            size = _folder_size(COMICS_ROOT / n)
            print(f"       {n}  ({size}){prefix}")

    # Also flag obvious junk-prefix folders even if no dupe
    print()
    for f in sorted(folders):
        if junk_prefix(f.name) and strip_noise(f.name) not in dupes:
            size = _folder_size(f)
            print(f"  ⚠  Junk-prefix folder (no dupe detected): {f.name}  ({size})")
    print()

def _folder_size(path: Path) -> str:
    total = 0
    try:
        for root, _, files in os.walk(path):
            for f in files:
                try:
                    total += os.path.getsize(os.path.join(root, f))
                except OSError:
                    pass
    except PermissionError:
        return "?"
    if total < 1024**2:
        return f"{total//1024} KB"
    elif total < 1024**3:
        return f"{total//1024//1024} MB"
    else:
        return f"{total/1024/1024/1024:.1f} GB"

# ── section 2: file-level duplicates within a series folder ─────────────────

def audit_file_dupes():
    print("=" * 70)
    print("SECTION 2 — File-level duplicates (same issue, multiple files)")
    print("=" * 70)

    any_found = False
    for series_dir in sorted(COMICS_ROOT.iterdir()):
        if not series_dir.is_dir():
            continue
        _check_dir_for_dupes(series_dir, prefix=series_dir.name)

    if not any_found:
        print("  None found.\n")

_any_file_dupe = False

def _check_dir_for_dupes(folder: Path, prefix: str, depth: int = 0):
    global _any_file_dupe
    if depth > 3:
        return

    # Group files in THIS folder by stripped name
    comic_files = [f for f in folder.iterdir() if f.is_file() and is_comic(f)]
    groups = defaultdict(list)
    for f in comic_files:
        key = strip_noise(f.stem)
        groups[key].append(f.name)

    reported_this = False
    for key, names in groups.items():
        if len(names) > 1:
            if not reported_this:
                print(f"\n  📁 {prefix}/")
                reported_this = True
                _any_file_dupe = True
            print(f"    Dupe group '{key}':")
            for n in sorted(names):
                sz = os.path.getsize(folder / n)
                print(f"      {n}  ({sz//1024} KB)")

    # Recurse into sub-folders
    for sub in sorted(folder.iterdir()):
        if sub.is_dir():
            _check_dir_for_dupes(sub, prefix=f"{prefix}/{sub.name}", depth=depth+1)

# ── section 3: mixed-series folders (Frazetta problem) ─────────────────────

def audit_mixed_series():
    print("=" * 70)
    print("SECTION 3 — Folders whose files span multiple apparent series")
    print("           (these show up as separate series in Kavita)")
    print("=" * 70)

    any_found = False
    for series_dir in sorted(COMICS_ROOT.iterdir()):
        if not series_dir.is_dir():
            continue
        comic_files = [f for f in series_dir.iterdir() if f.is_file() and is_comic(f)]
        if len(comic_files) < 3:
            continue

        series_names = defaultdict(list)
        for f in comic_files:
            s = extract_series_from_filename(f.name)
            series_names[s].append(f.name)

        if len(series_names) > 2:
            any_found = True
            print(f"\n  📁 {series_dir.name}/  — {len(series_names)} apparent sub-series:")
            for sname, files in sorted(series_names.items()):
                print(f"    '{sname}'  ({len(files)} file{'s' if len(files)>1 else ''})")

    if not any_found:
        print("  None found.\n")
    print()

# ── section 4: junk-prefix files ────────────────────────────────────────────

def audit_junk_files():
    print("=" * 70)
    print("SECTION 4 — Files with junk prefixes")
    print("=" * 70)

    found = []
    for root, dirs, files in os.walk(COMICS_ROOT):
        # Only go 2 levels deep to keep it manageable
        depth = Path(root).relative_to(COMICS_ROOT).parts
        if len(depth) > 2:
            dirs.clear()
            continue
        for f in files:
            if is_comic(Path(f)) and junk_prefix(f):
                rel = Path(root).relative_to(COMICS_ROOT) / f
                found.append(str(rel))

    if not found:
        print("  None found.\n")
    else:
        for f in sorted(found):
            print(f"  ⚠  {f}")
    print()

# ── main ─────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    print(f"\nKavita Comics Audit — {COMICS_ROOT}\n")
    audit_toplevel()
    audit_file_dupes()
    audit_mixed_series()
    audit_junk_files()
    print("Done. No files were modified.")
