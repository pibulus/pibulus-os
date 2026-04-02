#!/usr/bin/env python3
import json
import re
import sqlite3
import sys
from pathlib import Path

SOURCE_OF_TRUTH = Path("/home/pibulus/pibulus-os/config/user-accounts.txt")
ADMIN_USERS = {"pibulus"}

SERVICES = {
    "kavita": {
        "db": Path("/home/pibulus/.config/kavita/kavita.db"),
        "query": "select lower(UserName) from AspNetUsers where UserName is not null",
    },
    "navidrome": {
        "db": Path("/home/pibulus/.config/navidrome/navidrome.db"),
        "query": "select lower(user_name) from user where user_name is not null",
    },
    "calibre_web": {
        "db": Path("/home/pibulus/.config/calibre-web/app.db"),
        "query": "select lower(name) from user where name is not null",
    },
    "jellyfin": {
        "db": Path("/home/pibulus/.config/jellyfin/data/jellyfin.db"),
        "query": "select lower(Username) from Users where Username is not null",
    },
}


def parse_expected_accounts(path: Path) -> list[str]:
    usernames = []
    for raw in path.read_text().splitlines():
        match = re.match(r"\s*([a-z0-9]+)\s*/\s*([a-z0-9!]+)", raw)
        if match and match.group(1) not in ADMIN_USERS:
            usernames.append(match.group(1))
    return sorted(set(usernames))


def fetch_service_users(db_path: Path, query: str) -> set[str]:
    con = sqlite3.connect(db_path)
    try:
        return {row[0] for row in con.execute(query) if row[0] and row[0] not in ADMIN_USERS}
    finally:
        con.close()


def build_report() -> dict:
    expected = parse_expected_accounts(SOURCE_OF_TRUTH)
    expected_set = set(expected)
    report = {
        "source_of_truth": str(SOURCE_OF_TRUTH),
        "expected_count": len(expected),
        "services": {},
    }
    for name, meta in SERVICES.items():
        present = fetch_service_users(meta["db"], meta["query"])
        report["services"][name] = {
            "count": len(present),
            "missing": [user for user in expected if user not in present],
            "extra": sorted(present - expected_set),
        }
    return report


def print_text_report(report: dict) -> None:
    print(f"Source of truth: {report['source_of_truth']}")
    print(f"Expected accounts: {report['expected_count']}")
    for service, data in report["services"].items():
        status = "OK" if not data["missing"] and not data["extra"] else "DRIFT"
        print(f"\n[{service}] {status}")
        print(f"count: {data['count']}")
        print("missing:", ", ".join(data["missing"]) if data["missing"] else "-")
        print("extra:", ", ".join(data["extra"]) if data["extra"] else "-")


def main() -> int:
    report = build_report()
    if "--json" in sys.argv:
        print(json.dumps(report, indent=2))
    else:
        print_text_report(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
