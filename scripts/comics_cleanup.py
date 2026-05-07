#!/usr/bin/env python3
"""
comics_cleanup.py — Kavita comics library cleanup
Dry-run by default. Pass --execute to actually make changes.

Actions performed:
  1. Delete confirmed small variant-cover dupes (Locke & Key)
  2. Delete Saga #003 778MB cbz (keep the 24MB cbr)
  3. Delete Sandman #001 cbz (keep the cbr)
  4. Rename Swamp Thing files (underscores → spaces, clean up noise)
  5. Rename Predator Omnibus URL-encoded filenames
  6. Rename Metabarons omnibus file (strip junk 15Z8I46q_ prefix)
  7. Move Metabarons omnibus into the Metabarons/ folder
  8. Create sub-folders in Frank Frazetta collection per series
  9. Merge Y: The Last Man two folders into one
 10. Report items needing manual review (Robotech dupes, Italian Berserk)
"""

import sys
import os
import re
import shutil
from pathlib import Path
from urllib.parse import unquote

COMICS = Path("/media/pibulus/passport/Comics")
DRY = "--execute" not in sys.argv
actions = []   # (verb, src, dst_or_None, description)

# ── logging ──────────────────────────────────────────────────────────────────

def log(verb, src, dst=None, note=""):
    tag = "[DRY]" if DRY else "[DO ]"
    if dst:
        print(f"{tag} {verb:8s}  {src}  →  {dst}  {note}")
    else:
        print(f"{tag} {verb:8s}  {src}  {note}")
    actions.append((verb, src, dst, note))

def do_delete(path: Path, reason: str):
    log("DELETE", path, note=f"({reason})")
    if not DRY:
        path.unlink()

def do_rename(src: Path, dst: Path):
    log("RENAME", src.name, dst.name)
    if not DRY:
        src.rename(dst)

def do_move(src: Path, dst_dir: Path, new_name: str = None):
    dst = dst_dir / (new_name or src.name)
    log("MOVE", src, dst)
    if not DRY:
        dst_dir.mkdir(parents=True, exist_ok=True)
        shutil.move(str(src), str(dst))

def do_mkdir(path: Path):
    log("MKDIR", path)
    if not DRY:
        path.mkdir(parents=True, exist_ok=True)

# ── 1. Locke & Key variant-cover dupes ───────────────────────────────────────

def clean_locke_and_key():
    print("\n── Locke & Key: variant-cover dupes ──")
    base = COMICS / "Locke & Key"

    # Each tuple: (folder, small_file_to_delete, reason)
    dupes = [
        (
            base,
            "Locke & Key - Guide to the Known Keys (2011) (#comicmarket Variant Cover) (Mao&Art-DCP).cbz",
            "522 KB variant; 32 MB proper scan kept"
        ),
        (
            base / "02 Locke & Key - Head Games",
            "Locke & Key - Head Games 01 (2009) (Jetpack Comics Exclusive Variant Cover) (Mao&Art-DCP).cbz",
            "477 KB variant; 13 MB proper scan kept"
        ),
        (
            base / "03 Locke & Key - Crown of Shadows",
            "Locke & Key - Crown of Shadows 01 (2009) (Jetpack Comics Exclusive Variant Cover) (Mao&Art-DCP).cbz",
            "422 KB variant; 13 MB proper scan kept"
        ),
    ]
    for folder, fname, reason in dupes:
        p = folder / fname
        if p.exists():
            do_delete(p, reason)
        else:
            print(f"  [SKIP] not found: {p.name}")

# ── 2. Saga #003 giant cbz ────────────────────────────────────────────────────

def clean_saga():
    print("\n── Saga: #003 duplicate ──")
    saga = COMICS / "Saga"
    cbz = saga / "Saga #003.cbz"
    cbr = saga / "Saga #003.cbr"
    if cbz.exists() and cbr.exists():
        do_delete(cbz, f"778 MB cbz dupe; {cbr.stat().st_size//1024//1024} MB cbr kept")
    else:
        print(f"  [SKIP] one or both files missing")

# ── 3. Sandman #001 cbz ───────────────────────────────────────────────────────

def clean_sandman():
    print("\n── Sandman: #001 duplicate ──")
    sandman = COMICS / "The Sandman"
    cbz = sandman / "The Sandman #001.cbz"
    cbr = sandman / "The Sandman #001.cbr"
    if cbz.exists() and cbr.exists():
        do_delete(cbz, f"15 MB cbz dupe; {cbr.stat().st_size//1024//1024} MB cbr kept")
    else:
        print(f"  [SKIP] one or both files missing")

# ── 4. Swamp Thing: underscore filenames ──────────────────────────────────────

def clean_swamp_thing():
    print("\n── Swamp Thing: fix underscore filenames ──")
    folder = COMICS / "Swamp Thing"
    for f in sorted(folder.iterdir()):
        if not f.is_file():
            continue
        # Replace underscores with spaces, collapse multiple spaces
        new_name = f.name.replace("_", " ").strip()
        # Clean up double spaces
        new_name = re.sub(r"  +", " ", new_name)
        # Fix spacing around parens: " ( " → " ("
        new_name = re.sub(r"\s+\(", " (", new_name)
        new_name = re.sub(r"\(\s+", "(", new_name)
        if new_name != f.name:
            do_rename(f, folder / new_name)
        else:
            print(f"  [OK]   {f.name}")

# ── 5. Predator Omnibus: URL-encoded filenames ────────────────────────────────

PREDATOR_RENAMES = {
    "Predator_Omnibus_01_%282007%29_%28Pudgy_-_DCP%29.cbr":          "Predator Omnibus 01 (2007) (Pudgy-DCP).cbr",
    "Predator_Omnibus_02_282008_29_28Pudgy_DCP_29.cbr":              "Predator Omnibus 02 (2008) (Pudgy-DCP).cbr",
    "Predator_Omnibus_03_282008_29_28Pudgy_DCP_29.cbr":              "Predator Omnibus 03 (2008) (Pudgy-DCP).cbr",
    "Predator_Omnibus_04_282008_29_28Pudgy_DCP_29.cbr":              "Predator Omnibus 04 (2008) (Pudgy-DCP).cbr",
    "Aliens_vs._Predator_Duel_281995_29_28Digital_29_28Bean_Empire_29.cbz":
        "Aliens vs. Predator - Duel (1995) (Digital) (Bean-Empire).cbz",
    "Aliens_vs._Predator_Eternal_Old_Secrets_281999_29_28Digital_29_28Bean_Empire_29.cbz":
        "Aliens vs. Predator - Eternal-Old Secrets (1999) (Digital) (Bean-Empire).cbz",
}

def clean_predator_omnibus():
    print("\n── Predator Omnibus: fix encoded filenames ──")
    folder = COMICS / "Predator Omnibus"
    if not folder.exists():
        print("  [SKIP] folder not found")
        return
    for old_name, new_name in PREDATOR_RENAMES.items():
        src = folder / old_name
        dst = folder / new_name
        if src.exists():
            if dst.exists():
                print(f"  [SKIP] target already exists: {new_name}")
            else:
                do_rename(src, dst)
        else:
            print(f"  [SKIP] not found: {old_name}")

# ── 6+7. Metabarons: strip junk prefix + merge folders ───────────────────────

def clean_metabarons():
    print("\n── Metabarons: strip junk prefix + merge folders ──")
    src_folder = COMICS / "Jodorowsky & Gimenez - The Metabarons"
    dst_folder = COMICS / "Metabarons"

    junk_file = src_folder / "15Z8I46q_Jodorowsky & Gimenez - The Metabarons -  complete - (v1-17).cbr"
    clean_name = "Jodorowsky & Gimenez - The Metabarons - complete (v1-17).cbr"

    if junk_file.exists():
        # Step 1: rename to clean name inside source folder
        clean_path = src_folder / clean_name
        do_rename(junk_file, clean_path)
        # Step 2: move into Metabarons/
        do_move(clean_path, dst_folder)
    else:
        # Maybe already renamed
        maybe = src_folder / clean_name
        if maybe.exists():
            do_move(maybe, dst_folder)
        else:
            print(f"  [SKIP] source file not found in {src_folder.name}/")

    # If source folder is now empty, flag it
    if not DRY:
        remaining = list(src_folder.iterdir()) if src_folder.exists() else []
        if not remaining:
            log("RMDIR", src_folder, note="(now empty)")
            src_folder.rmdir()
        else:
            print(f"  [NOTE] {src_folder.name}/ still has {len(remaining)} items — check manually")

# ── 8. Frank Frazetta: create sub-folders per series ─────────────────────────

FRAZETTA_SERIES = {
    "Frank Frazetta's Death Dealer": [
        "Frank Frazetta's Death Dealer 01 (3 Covers) (2007) (TheRedStar-DCP).cbr",
        "Frank Frazetta's Death Dealer 01 - Black White Special Edition.cbr",
        "Frank Frazetta's Death Dealer 02 (of 6) (2007) (Whitewolf-DCP).cbr",
        "Frank Frazetta's Death Dealer 03 (of 6) (2007) (Whitewolf-DCP).cbr",
        "Frank Frazetta's Death Dealer 04 (of 6) (2007) (c2c) (Whitewolf-DCP).cbr",
        "Frank Frazetta's Death Dealer 05 (of 6) (2007) (SnackAttack-DCP).cbr",
        "Frank Frazetta's Death Dealer 06 (of 6) (2008) (Whitewolf-DCP).cbr",
    ],
    "Death Dealer (Verotik)": [
        "Death Dealer v1 01 (Verotik).cbr",
        "Death Dealer v1 02 (Verotik).cbr",
        "Death Dealer v1 03 (Verotik).cbr",
        "Death Dealer v1 04 (Verotik).cbr",
    ],
    "Frank Frazetta's Dark Kingdom": [
        "Frank Frazetta's Dark Kingdom 01 (2008) (2 covers) (Minutemen-LockeZone).cbr",
        "Frank Frazetta's Dark Kingdom 02 (2009) (Image) (YZ1).cbr",
        "Frank Frazetta's Dark Kingdom 03 (2009) (Image) (YZ1).cbr",
        "Frank Frazetta's Dark Kingdom 04 (Image)(2010)(YZ1).cbr",
    ],
    # One-shots stay flat in parent folder — no sub-folder needed
}

def clean_frazetta():
    print("\n── Frank Frazetta: create sub-folders per series ──")
    base = COMICS / "Frank Frazetta Image Comics Collection"
    for series_name, files in FRAZETTA_SERIES.items():
        series_dir = base / series_name
        do_mkdir(series_dir)
        for fname in files:
            src = base / fname
            if src.exists():
                do_move(src, series_dir)
            else:
                print(f"  [SKIP] not found: {fname}")

# ── 9. Y: The Last Man — merge two folders ────────────────────────────────────

def clean_y_last_man():
    print("\n── Y: The Last Man — merge folders ──")
    # Keep: "Y - The Last Man" (Books 01-05, cleaner name)
    # Absorb: "Y - THE LAST MAN (DC Vertigo) Volumes 01-10 (2003-2008) Complete"
    keep = COMICS / "Y - The Last Man"
    absorb = COMICS / "Y - THE LAST MAN (DC Vertigo) Volumes 01-10 (2003-2008) Complete"
    if not absorb.exists():
        print("  [SKIP] source folder not found")
        return
    for f in sorted(absorb.iterdir()):
        if f.is_file():
            dst = keep / f.name
            if dst.exists():
                print(f"  [SKIP] already exists in dest: {f.name}")
            else:
                do_move(f, keep)
    if not DRY:
        remaining = list(absorb.iterdir())
        if not remaining:
            log("RMDIR", absorb, note="(now empty)")
            absorb.rmdir()
        else:
            print(f"  [NOTE] {absorb.name}/ still has {len(remaining)} items")

# ── 10. Confirmed deletions from manual review ───────────────────────────────

def clean_confirmed():
    print("\n── Confirmed deletions ──")

    # Italian Berserk — nuke the whole folder
    ita = COMICS / "[tntvillage_org][ebook-manga-ita]Berserk"
    if ita.exists():
        log("RMDIR", ita, note="(Italian Berserk — 662 MB, unwanted)")
        if not DRY:
            shutil.rmtree(str(ita))
    else:
        print(f"  [SKIP] Italian Berserk not found")

    # Robotech Sentinels Vol 1 — keep Limited Edition Hardcover, delete plain scan
    r_plain = COMICS / "Robotech/Robotech II-The Sentinels Volume 1 (1989)/Robotech II-The Sentinels Volume 1 (1989) - A New Beginning.cbr"
    if r_plain.exists():
        do_delete(r_plain, "plain scan dupe; Limited Edition Hardcover kept")
    else:
        print(f"  [SKIP] Robotech plain scan not found")

    # Saga collected books — keep individual issues, ditch the two omnibus books
    for fname in [
        "Saga Book 1 (2014) GetComics.INFO.cbr",
        "Saga Book 2 (2015) GetComics.INFO.cbr",
    ]:
        p = COMICS / "Saga" / fname
        if p.exists():
            do_delete(p, "collected book — individual issues kept")
        else:
            print(f"  [SKIP] not found: {fname}")

# ── 11. Remaining manual review items ────────────────────────────────────────

def report_manual():
    print("\n── Items needing manual review ──")

    # Robotech Sentinels Vol 1 dupe
    r1a = COMICS / "Robotech/Robotech II-The Sentinels Volume 1 (1989)/Robotech II-The Sentinels Volume 1 (1989) - A New Beginning.cbr"
    r1b = COMICS / "Robotech/Robotech II-The Sentinels Volume 1 (1989)/Robotech II-The Sentinels Volume 1 (1989) - A New Beginning (Limited Edition Hardcover).cbr"
    if r1a.exists() and r1b.exists():
        print(f"  ⚠  Robotech Sentinels Vol 1: two scans of same book")
        print(f"       {r1a.stat().st_size//1024//1024} MB — {r1a.name}")
        print(f"       {r1b.stat().st_size//1024//1024} MB — {r1b.name}")
        print(f"     → Keep whichever you prefer, delete the other")

    # Italian Berserk
    ita = COMICS / "[tntvillage_org][ebook-manga-ita]Berserk"
    if ita.exists():
        size = sum(f.stat().st_size for f in ita.rglob("*") if f.is_file())
        print(f"\n  ⚠  Italian Berserk: {ita.name}")
        print(f"       {size//1024//1024} MB total — Italian RARs, probably unwanted")
        print(f"     → Delete with: rm -rf '{ita}'")

    # Robotech Book 3 duplicate folders
    rb3a = COMICS / "Robotech/Robotech II-The Sentinels Book 3 (1993-1994)"
    rb3b = COMICS / "Robotech/Robotech II-The Sentinels Book 3 (1994-1995)"
    if rb3a.exists() and rb3b.exists():
        print(f"\n  ⚠  Robotech Sentinels Book 3: two folders with different date ranges")
        print(f"       {rb3a.name}/ — {sum(1 for f in rb3a.rglob('*') if f.is_file())} files")
        print(f"       {rb3b.name}/ — {sum(1 for f in rb3b.rglob('*') if f.is_file())} files")
        print(f"     → Check contents and merge manually")

    # Saga Book omnibus dupes
    saga_book1 = COMICS / "Saga/saga book 1 getcomics.info.cbr"  # approximate
    for f in (COMICS / "Saga").iterdir():
        if "book" in f.name.lower() and f.is_file():
            print(f"\n  ⚠  Saga has individual issues AND collected books: {f.name}")
            print(f"     → Decide if you want to keep both or just the issues")
            break

# ── main ──────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    mode = "DRY RUN (no changes)" if DRY else "EXECUTE MODE"
    print(f"\nKavita Comics Cleanup — {mode}")
    if DRY:
        print("Pass --execute to apply changes.\n")

    clean_locke_and_key()
    clean_saga()
    clean_sandman()
    clean_swamp_thing()
    clean_predator_omnibus()
    clean_metabarons()
    clean_frazetta()
    clean_y_last_man()
    clean_confirmed()
    report_manual()

    print(f"\n── Summary: {len(actions)} actions {'planned' if DRY else 'taken'} ──")
