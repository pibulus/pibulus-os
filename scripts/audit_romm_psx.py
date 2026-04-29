#!/usr/bin/env python3
"""
Quick PSX audit for RomM without extra Python deps.

Defaults assume the current Pi setup and read the password from local env.
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from textwrap import dedent

from env_utils import load_local_env

load_local_env()


def run_sql(container: str, user: str, password: str, database: str, query: str) -> str:
    cmd = [
        "docker",
        "exec",
        container,
        "mariadb",
        f"-u{user}",
        f"-p{password}",
        database,
        "-e",
        query,
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "mariadb command failed")
    return result.stdout.strip()


def print_block(title: str, sql_output: str) -> None:
    print(f"\n== {title} ==")
    print(sql_output or "none")


def main() -> None:
    parser = argparse.ArgumentParser(description="Audit RomM PSX metadata state")
    parser.add_argument("--container", default="romm-db")
    parser.add_argument("--user", default="romm")
    parser.add_argument("--password", default=os.environ.get("MARIADB_PASSWORD", ""))
    parser.add_argument("--database", default="romm")
    parser.add_argument("--limit", type=int, default=25)
    args = parser.parse_args()
    if not args.password:
        parser.error("--password is required or set MARIADB_PASSWORD in config/stacks/.env")

    try:
        summary = run_sql(
            args.container,
            args.user,
            args.password,
            args.database,
            dedent(
                """
                SELECT
                  COUNT(*) AS psx_total,
                  SUM(CASE WHEN r.igdb_id IS NULL AND r.moby_id IS NULL AND r.ss_id IS NULL
                             AND r.launchbox_id IS NULL AND r.tgdb_id IS NULL AND r.hasheous_id IS NULL
                           THEN 1 ELSE 0 END) AS no_ids,
                  SUM(CASE WHEN r.path_cover_s IS NULL OR r.path_cover_s = '' THEN 1 ELSE 0 END) AS no_cover
                FROM roms r
                JOIN platforms p ON r.platform_id = p.id
                WHERE p.slug = 'psx';
                """
            ).strip(),
        )
        duplicates = run_sql(
            args.container,
            args.user,
            args.password,
            args.database,
            dedent(
                """
                SELECT
                  r.name,
                  COUNT(*) AS copies,
                  SUM(CASE WHEN r.path_cover_s IS NULL OR r.path_cover_s = '' THEN 1 ELSE 0 END) AS no_cover,
                  SUM(CASE WHEN r.igdb_id IS NOT NULL OR r.moby_id IS NOT NULL OR r.ss_id IS NOT NULL
                             OR r.launchbox_id IS NOT NULL OR r.tgdb_id IS NOT NULL OR r.hasheous_id IS NOT NULL
                           THEN 1 ELSE 0 END) AS with_ids
                FROM roms r
                JOIN platforms p ON r.platform_id = p.id
                WHERE p.slug = 'psx'
                GROUP BY r.name
                HAVING COUNT(*) > 1
                ORDER BY copies DESC, r.name
                LIMIT {limit};
                """
            ).strip().format(limit=args.limit),
        )
        missing_ids = run_sql(
            args.container,
            args.user,
            args.password,
            args.database,
            dedent(
                """
                SELECT
                  r.id,
                  r.name,
                  r.fs_name
                FROM roms r
                JOIN platforms p ON r.platform_id = p.id
                WHERE p.slug = 'psx'
                  AND r.igdb_id IS NULL
                  AND r.moby_id IS NULL
                  AND r.ss_id IS NULL
                  AND r.launchbox_id IS NULL
                  AND r.tgdb_id IS NULL
                  AND r.hasheous_id IS NULL
                ORDER BY r.name
                LIMIT {limit};
                """
            ).strip().format(limit=args.limit),
        )
        missing_covers = run_sql(
            args.container,
            args.user,
            args.password,
            args.database,
            dedent(
                """
                SELECT
                  r.id,
                  r.name,
                  r.fs_name,
                  r.url_cover,
                  r.path_cover_s,
                  r.igdb_id,
                  r.moby_id,
                  r.ss_id,
                  r.launchbox_id,
                  r.tgdb_id,
                  r.hasheous_id
                FROM roms r
                JOIN platforms p ON r.platform_id = p.id
                WHERE p.slug = 'psx'
                  AND (r.path_cover_s IS NULL OR r.path_cover_s = '')
                ORDER BY r.name
                LIMIT {limit};
                """
            ).strip().format(limit=args.limit),
        )
        platform_split = run_sql(
            args.container,
            args.user,
            args.password,
            args.database,
            dedent(
                """
                SELECT
                  p.id,
                  p.slug,
                  p.fs_slug,
                  r.fs_path,
                  COUNT(*) AS row_count,
                  SUM(CASE WHEN r.path_cover_s IS NULL OR r.path_cover_s = '' THEN 1 ELSE 0 END) AS no_cover,
                  SUM(CASE WHEN r.igdb_id IS NULL AND r.moby_id IS NULL AND r.ss_id IS NULL
                             AND r.launchbox_id IS NULL AND r.tgdb_id IS NULL AND r.hasheous_id IS NULL
                           THEN 1 ELSE 0 END) AS no_ids
                FROM roms r
                JOIN platforms p ON r.platform_id = p.id
                WHERE p.slug = 'psx'
                GROUP BY p.id, p.slug, p.fs_slug, r.fs_path
                ORDER BY p.id, r.fs_path;
                """
            ).strip(),
        )
    except RuntimeError as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)

    print_block("Summary", summary)
    print_block("Platform Split", platform_split)
    print_block("Duplicate Names", duplicates)
    print_block("Missing IDs", missing_ids)
    print_block("Missing Covers", missing_covers)


if __name__ == "__main__":
    main()
