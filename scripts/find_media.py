#!/usr/bin/env python3
import argparse
import json
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class SearchRoot:
    label: str
    path: Path
    media_type: str


ROOTS = [
    SearchRoot("Ebooks", Path("/media/pibulus/passport/Ebooks"), "book"),
    SearchRoot("Comics", Path("/media/pibulus/passport/Comics"), "comic"),
    SearchRoot("Soulseek", Path("/media/pibulus/passport/Soulseek"), "download"),
    SearchRoot("Knowledge Vault", Path("/media/pibulus/passport/Knowledge-Vault"), "document"),
    SearchRoot("Palestine", Path("/media/pibulus/passport/Palestine"), "library"),
    SearchRoot("Conspiracy", Path("/media/pibulus/passport/Conspiracy"), "library"),
    SearchRoot("The Bucket", Path("/media/pibulus/passport/The_Bucket"), "download"),
    SearchRoot("Movies", Path("/media/pibulus/passport/Movies"), "movie"),
    SearchRoot("Shows", Path("/media/pibulus/passport/Shows"), "show"),
]

TEXT_EXTS = {
    ".epub",
    ".pdf",
    ".mobi",
    ".azw3",
    ".djvu",
    ".cbr",
    ".cbz",
    ".txt",
    ".md",
}


def normalize(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", " ", text.lower()).strip()


def tokenize(text: str) -> list[str]:
    return [t for t in normalize(text).split() if t]


def score_match(query_tokens: list[str], candidate: str, media_type: str) -> int:
    haystack = normalize(candidate)
    if not haystack:
        return 0

    score = 0
    for token in query_tokens:
        if token in haystack:
            score += 12
        if haystack.startswith(token):
            score += 5

    phrase = " ".join(query_tokens)
    if phrase and phrase in haystack:
        score += 20

    if media_type in {"book", "comic", "document", "library"} and any(
        token in {"book", "ebook", "comic", "pdf"} for token in query_tokens
    ):
        score += 4

    return score


def iter_candidates(root: SearchRoot):
    if not root.path.exists():
        return
    for dirpath, dirnames, filenames in os.walk(root.path):
        for name in filenames:
            path = Path(dirpath) / name
            if path.suffix.lower() in TEXT_EXTS or root.media_type in {"movie", "show", "download", "library"}:
                yield path
        for name in dirnames:
            yield Path(dirpath) / name


def search(query: str, limit: int) -> list[dict]:
    query_tokens = tokenize(query)
    results = []

    for root in ROOTS:
        for path in iter_candidates(root) or []:
            rel = str(path.relative_to(root.path))
            score = score_match(query_tokens, rel, root.media_type)
            if score <= 0:
                continue
            results.append(
                {
                    "score": score,
                    "label": root.label,
                    "type": root.media_type,
                    "name": path.name,
                    "path": str(path),
                    "parent": str(path.parent),
                }
            )

    results.sort(key=lambda item: (-item["score"], item["name"].lower(), item["path"].lower()))
    deduped = []
    seen = set()
    for item in results:
        if item["path"] in seen:
            continue
        seen.add(item["path"])
        deduped.append(item)
        if len(deduped) >= limit:
            break
    return deduped


def print_text(results: list[dict]) -> int:
    if not results:
        print("No local matches.")
        return 1

    for i, item in enumerate(results, start=1):
        print(f"{i:>2}. [{item['label']}] {item['name']}")
        print(f"    {item['path']}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Find local media by rough human query.")
    parser.add_argument("query", nargs="+", help="Search terms")
    parser.add_argument("--limit", type=int, default=20, help="Max results")
    parser.add_argument("--json", action="store_true", help="Emit JSON")
    args = parser.parse_args()

    query = " ".join(args.query)
    results = search(query, args.limit)

    if args.json:
        print(json.dumps({"query": query, "results": results}, indent=2))
        return 0
    return print_text(results)


if __name__ == "__main__":
    raise SystemExit(main())
