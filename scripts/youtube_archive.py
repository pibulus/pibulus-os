#!/usr/bin/env python3
"""
Small yt-dlp archive/subscription helper for PIBULUS media folders.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

CONFIG_DIR = Path.home() / ".config" / "pibulus-youtube-archive"
CONFIG_FILE = CONFIG_DIR / "subscriptions.json"
TMP_DIR = Path("/media/pibulus/passport/.tmp/yt-dlp")

DEST_ROOTS = {
    "conspiracy": Path("/media/pibulus/passport/Conspiracy/YouTube Channels"),
    "palestine": Path("/media/pibulus/passport/Palestine/YouTube Channels"),
    "bucket": Path("/media/pibulus/passport/The_Bucket/YouTube"),
}

MODE_PLAYLIST_FLAG = {
    "video": "--no-playlist",
    "playlist": "--yes-playlist",
    "channel": "--yes-playlist",
}


def load_config() -> dict[str, Any]:
    if not CONFIG_FILE.exists():
        return {"version": 1, "subscriptions": []}
    with CONFIG_FILE.open() as fh:
        data = json.load(fh)
    data.setdefault("version", 1)
    data.setdefault("subscriptions", [])
    return data


def save_config(data: dict[str, Any]) -> None:
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    tmp = CONFIG_FILE.with_suffix(".tmp")
    with tmp.open("w") as fh:
        json.dump(data, fh, indent=2, sort_keys=True)
        fh.write("\n")
    tmp.replace(CONFIG_FILE)


def slugify(value: str) -> str:
    slug = re.sub(r"[^A-Za-z0-9._ -]+", "", value).strip(" ._-")
    slug = re.sub(r"\s+", " ", slug)
    return slug[:120] or "YouTube Pull"


def fetch_title(url: str) -> str:
    cmd = [
        "yt-dlp",
        "--dump-single-json",
        "--flat-playlist",
        "--skip-download",
        url,
    ]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=60, check=False)
    except subprocess.TimeoutExpired:
        return "YouTube Pull"

    if result.returncode != 0 or not result.stdout.strip():
        return "YouTube Pull"

    try:
        info = json.loads(result.stdout)
    except json.JSONDecodeError:
        return "YouTube Pull"

    return str(info.get("title") or info.get("uploader") or "YouTube Pull")


def archive_for(dest: Path) -> Path:
    old_archive = dest / "done.txt"
    if old_archive.exists():
        return old_archive
    return dest / ".yt-dlp-archive.txt"


def download(url: str, dest: Path, mode: str, archive: Path, dry_run: bool = False, sync: bool = False) -> int:
    dest.mkdir(parents=True, exist_ok=True)
    TMP_DIR.mkdir(parents=True, exist_ok=True)
    archive.touch(exist_ok=True)

    cmd = [
        "yt-dlp",
        "--ignore-errors",
        "--download-archive",
        str(archive),
        "--write-sub",
        "--write-auto-sub",
        "--sub-lang",
        "en",
        "--convert-subs",
        "srt",
        "--embed-metadata",
        "--write-info-json",
        "-f",
        "bestvideo[height<=1080]+bestaudio/best[height<=1080]/best[height<=1080]/best",
        "--merge-output-format",
        "mkv",
        MODE_PLAYLIST_FLAG[mode],
        "-P",
        f"home:{dest}",
        "-P",
        f"temp:{TMP_DIR}",
        "-o",
        "%(upload_date|00000000)s - %(title).180B [%(id)s].%(ext)s",
    ]
    if sync and mode != "video":
        cmd.append("--break-on-existing")
    cmd.append(url)

    if dry_run:
        print(" ".join(quote_part(part) for part in cmd))
        return 0

    print(f"\nArchive: {dest}")
    print(f"URL: {url}\n")
    return subprocess.run(cmd).returncode


def quote_part(part: str) -> str:
    if re.search(r"[^A-Za-z0-9_./:=@%+,-]", part):
        return "'" + part.replace("'", "'\\''") + "'"
    return part


def upsert_subscription(data: dict[str, Any], entry: dict[str, Any]) -> None:
    subs = data["subscriptions"]
    for index, existing in enumerate(subs):
        if existing.get("url") == entry["url"] and existing.get("section") == entry["section"]:
            subs[index] = {**existing, **entry}
            return
    subs.append(entry)


def add(args: argparse.Namespace) -> int:
    root = DEST_ROOTS[args.section]
    name = slugify(args.name or fetch_title(args.url))
    dest = root / name
    archive = archive_for(dest)

    if args.subscribe:
        data = load_config()
        upsert_subscription(
            data,
            {
                "name": name,
                "url": args.url,
                "section": args.section,
                "mode": args.mode,
                "dest": str(dest),
                "archive": str(archive),
            },
        )
        save_config(data)
        print(f"Subscribed: {name}")

    return download(args.url, dest, args.mode, archive, args.dry_run)


def sync(args: argparse.Namespace) -> int:
    data = load_config()
    subs = data.get("subscriptions", [])
    if not subs:
        print("No YouTube subscriptions yet.")
        return 0

    failures = 0
    for sub in subs:
        name = sub.get("name", sub.get("url", "untitled"))
        print(f"\n=== {name} ===")
        code = download(
            sub["url"],
            Path(sub["dest"]),
            sub.get("mode", "channel"),
            Path(sub["archive"]),
            args.dry_run,
            sync=True,
        )
        if code != 0:
            failures += 1
            print(f"FAILED: {name} exited {code}", file=sys.stderr)
    return 1 if failures else 0


def list_subs(_: argparse.Namespace) -> int:
    data = load_config()
    subs = data.get("subscriptions", [])
    if not subs:
        print("No YouTube subscriptions yet.")
        return 0

    for sub in subs:
        print(f"{sub['name']} [{sub['section']} / {sub.get('mode', 'channel')}]")
        print(f"  {sub['url']}")
        print(f"  {sub['dest']}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Manage PIBULUS yt-dlp archive subscriptions.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    add_parser = subparsers.add_parser("add", help="download a URL and optionally subscribe")
    add_parser.add_argument("--url", required=True)
    add_parser.add_argument("--section", choices=sorted(DEST_ROOTS), required=True)
    add_parser.add_argument("--mode", choices=sorted(MODE_PLAYLIST_FLAG), required=True)
    add_parser.add_argument("--name")
    add_parser.add_argument("--subscribe", action="store_true")
    add_parser.add_argument("--dry-run", action="store_true")
    add_parser.set_defaults(func=add)

    sync_parser = subparsers.add_parser("sync", help="pull new videos for subscriptions")
    sync_parser.add_argument("--dry-run", action="store_true")
    sync_parser.set_defaults(func=sync)

    list_parser = subparsers.add_parser("list", help="show subscriptions")
    list_parser.set_defaults(func=list_subs)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
