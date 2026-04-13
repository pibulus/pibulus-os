#!/usr/bin/env python3
"""
Build a clean Artist/Album hardlink mirror for Soulseek downloads.

Default mode is dry-run. Use --apply to create hardlinks under:
  /media/pibulus/passport/Music/Soulseek Organized

The raw Soulseek downloads are never moved, renamed, or retagged.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
from collections import Counter
from pathlib import Path

SOURCE = Path("/media/pibulus/passport/Soulseek")
DEST = Path("/media/pibulus/passport/Music/Soulseek Organized")
AUDIO_EXTS = {".mp3", ".flac", ".m4a", ".ogg", ".opus", ".wav", ".aiff", ".aif"}
BAD_CHARS = re.compile(r'[<>:"/\\|?*\x00-\x1f]')
SPACE_RE = re.compile(r"\s+")


def clean_part(value: object, fallback: str) -> str:
    text = str(value or "").strip()
    if not text:
        text = fallback
    text = BAD_CHARS.sub("_", text)
    text = SPACE_RE.sub(" ", text)
    return text.strip(" ._")[:160] or fallback


def track_prefix(value: object, disc: object = None) -> str:
    try:
        track = int(str(value).split("/")[0])
    except (TypeError, ValueError):
        return ""
    try:
        disc_num = int(str(disc).split("/")[0])
    except (TypeError, ValueError):
        disc_num = 0
    if disc_num and disc_num > 1:
        return f"{disc_num}-{track:02d} - "
    return f"{track:02d} - "


def tag_with_mediafile(path: Path) -> dict[str, object] | None:
    try:
        from mediafile import MediaFile
    except Exception:
        return None

    try:
        media = MediaFile(str(path))
    except Exception:
        return None

    return {
        "artist": media.artist,
        "albumartist": media.albumartist,
        "album": media.album,
        "title": media.title,
        "track": media.track,
        "disc": media.disc,
        "year": media.year,
    }


def tag_with_ffprobe(path: Path) -> dict[str, object]:
    try:
        proc = subprocess.run(
            [
                "ffprobe",
                "-v",
                "quiet",
                "-print_format",
                "json",
                "-show_entries",
                "format_tags",
                str(path),
            ],
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )
        data = json.loads(proc.stdout or "{}")
    except Exception:
        data = {}
    tags = {k.lower(): v for k, v in (data.get("format", {}).get("tags") or {}).items()}
    return {
        "artist": tags.get("artist"),
        "albumartist": tags.get("albumartist") or tags.get("album_artist"),
        "album": tags.get("album"),
        "title": tags.get("title"),
        "track": tags.get("track"),
        "disc": tags.get("disc") or tags.get("discnumber"),
        "year": tags.get("date") or tags.get("year"),
    }


def read_tags(path: Path) -> dict[str, object]:
    return tag_with_mediafile(path) or tag_with_ffprobe(path)


def audio_files(source: Path) -> list[Path]:
    files: list[Path] = []
    for path in source.rglob("*"):
        if path.is_relative_to(DEST) or path.name.startswith("."):
            continue
        if path.is_file() and path.suffix.lower() in AUDIO_EXTS:
            files.append(path)
    return sorted(files)


def target_for(path: Path) -> tuple[Path | None, str, dict[str, object]]:
    tags = read_tags(path)
    artist = tags.get("albumartist") or tags.get("artist")
    album = tags.get("album")
    title = tags.get("title") or path.stem
    if not artist or not album:
        return None, "missing artist/album tags", tags

    album_part = clean_part(album, "Unknown Album")

    filename = clean_part(track_prefix(tags.get("track"), tags.get("disc")) + str(title), path.stem) + path.suffix.lower()
    target = DEST / clean_part(artist, "Unknown Artist") / album_part / filename
    return target, "ok", tags


def unique_target(target: Path, source: Path) -> Path:
    if not target.exists() and not target.is_symlink():
        return target
    try:
        if target.samefile(source):
            return target
    except FileNotFoundError:
        pass
    stem = target.stem
    suffix = target.suffix
    for idx in range(2, 1000):
        candidate = target.with_name(f"{stem} [{idx}]{suffix}")
        if not candidate.exists() and not candidate.is_symlink():
            return candidate
    raise RuntimeError(f"could not pick unique target for {target}")


def link_file(source: Path, target: Path, mode: str) -> str:
    target.parent.mkdir(parents=True, exist_ok=True)
    target = unique_target(target, source)
    try:
        if target.exists() and target.samefile(source):
            return "exists"
    except FileNotFoundError:
        pass
    if mode == "symlink":
        rel = os.path.relpath(source, target.parent)
        target.symlink_to(rel)
    else:
        os.link(source, target)
    return "linked"


def main() -> int:
    global SOURCE, DEST

    parser = argparse.ArgumentParser(description="Build a clean Soulseek Artist/Album hardlink mirror")
    parser.add_argument("--source", type=Path, default=SOURCE)
    parser.add_argument("--dest", type=Path, default=DEST)
    parser.add_argument("--apply", action="store_true", help="create links; default is dry-run")
    parser.add_argument("--mode", choices=("hardlink", "symlink"), default="hardlink", help="link type to create with --apply")
    parser.add_argument("--limit", type=int, default=0, help="only inspect the first N audio files")
    parser.add_argument("--album", help="only inspect source paths containing this text")
    args = parser.parse_args()

    SOURCE = args.source
    DEST = args.dest

    files = audio_files(SOURCE)
    if args.album:
        needle = args.album.lower()
        files = [p for p in files if needle in str(p.relative_to(SOURCE)).lower()]
    if args.limit:
        files = files[: args.limit]

    stats: Counter[str] = Counter()
    preview: list[dict[str, str]] = []
    for source in files:
        target, reason, tags = target_for(source)
        stats[reason] += 1
        if not target:
            if len(preview) < 20:
                preview.append({"status": reason, "source": str(source.relative_to(SOURCE))})
            continue
        status = link_file(source, target, args.mode) if args.apply else f"would_{args.mode}"
        stats[status] += 1
        if len(preview) < 40:
            preview.append({
                "status": status,
                "source": str(source.relative_to(SOURCE)),
                "target": str(target.relative_to(DEST)),
                "artist": str(tags.get("albumartist") or tags.get("artist") or ""),
                "album": str(tags.get("album") or ""),
            })

    report = {"source": str(SOURCE), "dest": str(DEST), "mode": args.mode, "apply": args.apply, "stats": dict(stats), "preview": preview}
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
