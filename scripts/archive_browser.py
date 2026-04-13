#!/usr/bin/env python3
"""
Read-only archive browser for Quick Cat Club library pages.

The service never extracts archives to disk. It lists archives with 7z and streams
one selected entry at a time through stdout, bounded by size and path checks.
"""

from __future__ import annotations

import argparse
import json
import mimetypes
import os
import posixpath
import re
import subprocess
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, unquote, urlparse

PORT = 8093
SEVEN_ZIP = "/usr/bin/7z"
MAX_ARCHIVE_BYTES = 16 * 1024 * 1024 * 1024
MAX_ENTRY_BYTES = 512 * 1024 * 1024
LIST_TIMEOUT = 20
STREAM_TIMEOUT = 120
CACHE_TTL = 300
MAX_LIST_OUTPUT = 16 * 1024 * 1024
ARCHIVE_EXTS = {".zip", ".cbz", ".7z", ".rar", ".iso"}

PUBLIC_ROOTS = (
    ("/conspiracy/files/Uninstalled Games/", Path("/media/pibulus/passport/Games/@Uninstalled")),
    ("/conspiracy/files/", Path("/media/pibulus/passport/Conspiracy")),
    ("/palestine/files/", Path("/media/pibulus/passport/Palestine")),
    ("/crates/files/Guitar/", Path("/media/pibulus/passport/Resources/Guitar")),
    ("/crates/files/Piano/", Path("/media/pibulus/passport/Resources/Piano")),
    ("/crates/files/Music Theory/", Path("/media/pibulus/passport/Ebooks/Music Theory - eBook Collection")),
    ("/loops/files/", Path("/media/pibulus/passport/Resources/Loops")),
)

_listing_cache: dict[str, tuple[float, int, float, list[dict]]] = {}


def json_bytes(data) -> bytes:
    return json.dumps(data, separators=(",", ":")).encode("utf-8")


def clean_public_path(raw: str) -> str:
    parsed = urlparse(raw)
    path = unquote(parsed.path if parsed.scheme or parsed.netloc else raw)
    if not path.startswith("/"):
        path = "/" + path
    norm = posixpath.normpath(path)
    if path.endswith("/") and not norm.endswith("/"):
        norm += "/"
    if norm == "/":
        raise ValueError("missing archive path")
    if any(part == ".." for part in norm.split("/")):
        raise ValueError("bad archive path")
    return norm


def resolve_archive(public_path: str) -> Path:
    public_path = clean_public_path(public_path)
    for prefix, root in PUBLIC_ROOTS:
        if public_path.startswith(prefix):
            rel = public_path[len(prefix) :]
            candidate = (root / rel).resolve()
            root_real = root.resolve()
            if root_real != candidate and root_real not in candidate.parents:
                raise ValueError("archive path escaped library root")
            if candidate.suffix.lower() not in ARCHIVE_EXTS:
                raise ValueError("not a supported archive")
            if not candidate.is_file():
                raise FileNotFoundError("archive not found")
            if candidate.stat().st_size > MAX_ARCHIVE_BYTES:
                raise ValueError("archive too large to inspect")
            return candidate
    raise ValueError("archive path is not in a public library")


def clean_inner_path(raw: str) -> str:
    inner = unquote(raw or "").replace("\\", "/").strip("/")
    if not inner:
        return ""
    parts = [p for p in inner.split("/") if p and p != "."]
    if any(p == ".." for p in parts):
        raise ValueError("bad inner path")
    return "/".join(parts)


def parse_7z_slt(output: str) -> list[dict]:
    entries = []
    current: dict[str, str] = {}

    def flush():
        if "Path" not in current or current.get("Path", "").startswith("/"):
            current.clear()
            return
        name = current["Path"].strip("/")
        if not name:
            current.clear()
            return
        is_dir = current.get("Folder", "-") == "+"
        size = int(current.get("Size") or 0) if not is_dir else 0
        encrypted = current.get("Encrypted", "-") == "+"
        entries.append({"path": name, "size": size, "type": "directory" if is_dir else "file", "encrypted": encrypted})
        current.clear()

    for line in output.splitlines():
        if not line.strip():
            flush()
            continue
        if " = " not in line:
            continue
        key, value = line.split(" = ", 1)
        if key == "Path" and current:
            flush()
        current[key] = value
    flush()
    return entries


def archive_entries(archive: Path) -> list[dict]:
    stat = archive.stat()
    key = str(archive)
    cached = _listing_cache.get(key)
    if cached and time.time() - cached[0] < CACHE_TTL and cached[1] == stat.st_size and cached[2] == stat.st_mtime:
        return cached[3]

    proc = subprocess.run(
        [SEVEN_ZIP, "l", "-slt", "--", str(archive)],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        timeout=LIST_TIMEOUT,
        check=False,
    )
    if len(proc.stdout) > MAX_LIST_OUTPUT:
        raise ValueError("archive listing too large")
    if proc.returncode != 0:
        raise ValueError("archive could not be read")

    entries = parse_7z_slt(proc.stdout)
    _listing_cache[key] = (time.time(), stat.st_size, stat.st_mtime, entries)
    return entries


def browse_entries(archive: Path, inner: str) -> list[dict]:
    inner = clean_inner_path(inner)
    prefix = inner + "/" if inner else ""
    children: dict[str, dict] = {}

    for entry in archive_entries(archive):
        path = entry["path"]
        if not path.startswith(prefix):
            continue
        rel = path[len(prefix) :]
        if not rel:
            continue
        head = rel.split("/", 1)[0]
        child_path = prefix + head
        if "/" in rel or entry["type"] == "directory":
            children.setdefault(head, {"name": head, "path": child_path, "type": "directory", "size": 0})
        else:
            children[head] = {
                "name": head,
                "path": path,
                "type": "file",
                "size": entry.get("size", 0),
                "encrypted": entry.get("encrypted", False),
            }

    return sorted(children.values(), key=lambda item: (0 if item["type"] == "directory" else 1, item["name"].lower()))


def find_entry(archive: Path, entry_path: str) -> dict:
    entry_path = clean_inner_path(entry_path)
    for entry in archive_entries(archive):
        if entry["path"] == entry_path and entry["type"] == "file":
            return entry
    raise FileNotFoundError("entry not found")


def content_disposition_name(name: str) -> str:
    safe = re.sub(r'["\\\\\\r\\n]', "_", os.path.basename(name)) or "archive-entry"
    return safe


class ArchiveHandler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        pass

    def send_json(self, data, code=200):
        body = json_bytes(data)
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def send_error_json(self, code, message):
        self.send_json({"error": message}, code)

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Methods", "GET, HEAD, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_GET(self):
        self.handle_request(send_body=True)

    def do_HEAD(self):
        self.handle_request(send_body=False)

    def handle_request(self, send_body: bool):
        parsed = urlparse(self.path)
        params = parse_qs(parsed.query)
        try:
            if parsed.path == "/archive/list":
                archive = resolve_archive(params.get("file", [""])[0])
                inner = params.get("inner", [""])[0]
                data = {"items": browse_entries(archive, inner), "archive": archive.name}
                if send_body:
                    self.send_json(data)
                else:
                    body = json_bytes(data)
                    self.send_response(200)
                    self.send_header("Content-Type", "application/json")
                    self.send_header("Cache-Control", "no-store")
                    self.send_header("Content-Length", str(len(body)))
                    self.end_headers()
                return
            if parsed.path == "/archive/file":
                archive = resolve_archive(params.get("file", [""])[0])
                entry = find_entry(archive, params.get("entry", [""])[0])
                if entry.get("encrypted"):
                    self.send_error_json(423, "locked archive entry")
                    return
                if int(entry.get("size") or 0) > MAX_ENTRY_BYTES:
                    self.send_error_json(413, "archive entry too large")
                    return
                self.stream_entry(archive, entry["path"], int(entry.get("size") or 0), send_body=send_body)
                return
            self.send_error_json(404, "not found")
        except FileNotFoundError as exc:
            self.send_error_json(404, str(exc))
        except subprocess.TimeoutExpired:
            self.send_error_json(504, "archive read timed out")
        except ValueError as exc:
            self.send_error_json(400, str(exc))
        except Exception:
            self.send_error_json(500, "archive browser failed")

    def stream_entry(self, archive: Path, entry_path: str, size: int, send_body: bool = True):
        mime = mimetypes.guess_type(entry_path)[0] or "application/octet-stream"
        filename = content_disposition_name(entry_path)
        self.send_response(200)
        self.send_header("Content-Type", mime)
        if size:
            self.send_header("Content-Length", str(size))
        self.send_header("Content-Disposition", f'inline; filename="{filename}"')
        self.end_headers()
        if not send_body:
            return

        proc = subprocess.Popen(
            [SEVEN_ZIP, "x", "-so", "--", str(archive), entry_path],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
        )
        started = time.time()
        sent = 0
        try:
            assert proc.stdout is not None
            while True:
                if time.time() - started > STREAM_TIMEOUT:
                    proc.kill()
                    break
                chunk = proc.stdout.read(128 * 1024)
                if not chunk:
                    break
                sent += len(chunk)
                if sent > MAX_ENTRY_BYTES:
                    proc.kill()
                    break
                self.wfile.write(chunk)
        finally:
            try:
                proc.stdout.close() if proc.stdout else None
            finally:
                try:
                    proc.wait(timeout=2)
                except subprocess.TimeoutExpired:
                    proc.kill()
                    proc.wait(timeout=2)


def main():
    parser = argparse.ArgumentParser(description="Quick Cat Club read-only archive browser")
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=PORT)
    args = parser.parse_args()
    server = ThreadingHTTPServer((args.host, args.port), ArchiveHandler)
    print(f"Archive browser listening on {args.host}:{args.port}")
    server.serve_forever()


if __name__ == "__main__":
    main()
