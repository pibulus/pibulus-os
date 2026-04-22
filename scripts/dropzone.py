#!/usr/bin/env python3
"""QuickCat Drop Zone upload server."""

from __future__ import annotations

import hashlib
import json
import mmap
import os
import re
import tempfile
import time
import uuid
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT_DROP_DIR = Path("/media/pibulus/passport/Drops")
INBOX_DIR = ROOT_DROP_DIR / "inbox"
TMP_DIR = ROOT_DROP_DIR / ".tmp"
MAX_FILE_SIZE = 500 * 1024 * 1024  # 500MB per public upload
MAX_BODY_SIZE = MAX_FILE_SIZE + 512 * 1024
CHUNK_SIZE = 1024 * 1024
UPLOAD_PATH = "/drop/upload"

ALLOWED_SUFFIXES = (
    ".mp3", ".flac", ".ogg", ".opus", ".wav", ".aac", ".m4a", ".m4b",
    ".cbz", ".cbr", ".cb7", ".pdf", ".epub", ".mobi", ".azw3", ".djvu",
    ".zip", ".7z", ".rar", ".tar", ".tar.gz",
    ".rom", ".bin", ".smc", ".sfc", ".nes", ".gba", ".gb", ".gbc", ".n64", ".z64", ".md", ".gen",
    ".jpg", ".jpeg", ".png", ".gif", ".webp",
    ".mp4", ".mkv", ".webm", ".mov", ".avi",
)

ALLOWED_CATEGORIES = {
    "auto", "music", "audiobooks", "books", "comics", "video", "roms", "images", "misc"
}

FIELD_RE = re.compile(r'([A-Za-z0-9_*-]+)="([^"]*)"')
SAFE_FILENAME_RE = re.compile(r"[^A-Za-z0-9._() \-]+")
SAFE_TEXT_RE = re.compile(r"\s+")
SAFE_DIR_RE = re.compile(r"[^A-Za-z0-9._\-]+")

for path in (ROOT_DROP_DIR, INBOX_DIR, TMP_DIR):
    path.mkdir(parents=True, exist_ok=True)


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def json_bytes(payload: dict) -> bytes:
    return json.dumps(payload, indent=2, sort_keys=True).encode("utf-8")


def safe_filename(name: str) -> str:
    base = os.path.basename((name or "").replace("\x00", ""))
    cleaned = SAFE_FILENAME_RE.sub("", base).strip(" .")
    return (cleaned[:180] or "upload.bin")


def safe_dirname(name: str | None, fallback: str = "drop") -> str:
    cleaned = SAFE_DIR_RE.sub("-", (name or "").strip().lower()).strip("._-")
    return cleaned[:96] or fallback


def safe_text(value: str | None, max_len: int = 400) -> str:
    if not value:
        return ""
    text = value.replace("\x00", " ").replace("\r", " ").replace("\n", " ").strip()
    text = SAFE_TEXT_RE.sub(" ", text)
    return text[:max_len]


def parse_int(value: str | None, default: int, minimum: int, maximum: int) -> int:
    try:
        parsed = int(value or "")
    except ValueError:
        return default
    return max(minimum, min(maximum, parsed))


def ensure_unique_path(directory: Path, filename: str) -> Path:
    candidate = directory / filename
    if not candidate.exists():
        return candidate

    stem = Path(filename).stem[:120] or "upload"
    suffix = "".join(Path(filename).suffixes)
    counter = 2
    while True:
        candidate = directory / f"{stem}-{counter}{suffix}"
        if not candidate.exists():
            return candidate
        counter += 1


def load_batch_meta(meta_path: Path) -> dict:
    if not meta_path.exists():
        return {}
    try:
        return json.loads(meta_path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def save_batch_meta(meta_path: Path, payload: dict) -> None:
    temp_path = meta_path.with_suffix(".tmp")
    temp_path.write_bytes(json_bytes(payload))
    temp_path.replace(meta_path)


def suffix_for(name: str) -> str | None:
    lowered = (name or "").lower()
    for suffix in ALLOWED_SUFFIXES:
        if lowered.endswith(suffix):
            return suffix
    return None


def guess_category(category: str, suffix: str | None) -> str:
    category = (category or "auto").strip().lower()
    if category in ALLOWED_CATEGORIES and category != "auto":
        return category

    suffix = suffix or ""
    if suffix in {".mp3", ".flac", ".ogg", ".opus", ".wav", ".aac", ".m4a"}:
        return "music"
    if suffix in {".m4b"}:
        return "audiobooks"
    if suffix in {".cbz", ".cbr", ".cb7"}:
        return "comics"
    if suffix in {".pdf", ".epub", ".mobi", ".azw3", ".djvu"}:
        return "books"
    if suffix in {".mp4", ".mkv", ".webm", ".mov", ".avi"}:
        return "video"
    if suffix in {".jpg", ".jpeg", ".png", ".gif", ".webp"}:
        return "images"
    if suffix in {".zip", ".7z", ".rar", ".tar", ".tar.gz", ".rom", ".bin", ".smc", ".sfc", ".nes", ".gba", ".gb", ".gbc", ".n64", ".z64", ".md", ".gen"}:
        return "roms"
    return "misc"


def parse_header_params(header_value: str) -> dict[str, str]:
    return {match.group(1).lower(): match.group(2) for match in FIELD_RE.finditer(header_value or "")}


def parse_headers(blob: bytes) -> dict[str, str]:
    headers: dict[str, str] = {}
    for line in blob.decode("utf-8", "replace").split("\r\n"):
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        headers[key.strip().lower()] = value.strip()
    return headers


def write_range(mm: mmap.mmap, start: int, end: int, dest: Path) -> tuple[int, str]:
    digest = hashlib.sha256()
    written = 0
    with dest.open("wb") as handle:
        cursor = start
        while cursor < end:
            chunk_end = min(end, cursor + CHUNK_SIZE)
            chunk = mm[cursor:chunk_end]
            handle.write(chunk)
            digest.update(chunk)
            written += len(chunk)
            cursor = chunk_end
    return written, digest.hexdigest()


def parse_multipart(temp_path: Path, boundary: bytes) -> tuple[dict[str, str], dict[str, object]]:
    fields: dict[str, str] = {}
    file_part: dict[str, object] | None = None
    boundary_token = b"--" + boundary
    marker = b"\r\n" + boundary_token

    with temp_path.open("rb") as handle, mmap.mmap(handle.fileno(), 0, access=mmap.ACCESS_READ) as mm:
        if mm.find(boundary_token) != 0:
            raise ValueError("invalid multipart payload")

        pos = len(boundary_token)
        while True:
            if mm[pos:pos + 2] == b"--":
                break
            if mm[pos:pos + 2] != b"\r\n":
                raise ValueError("malformed multipart boundary")
            pos += 2

            headers_end = mm.find(b"\r\n\r\n", pos)
            if headers_end < 0:
                raise ValueError("malformed multipart headers")

            headers = parse_headers(mm[pos:headers_end])
            body_start = headers_end + 4
            next_boundary = mm.find(marker, body_start)
            if next_boundary < 0:
                raise ValueError("multipart boundary not closed")
            body_end = next_boundary

            disposition = parse_header_params(headers.get("content-disposition", ""))
            field_name = disposition.get("name", "")
            filename = disposition.get("filename")

            if filename is not None:
                if file_part is not None:
                    raise ValueError("one file per request only")
                file_part = {
                    "field_name": field_name,
                    "filename": filename,
                    "content_type": headers.get("content-type", "application/octet-stream"),
                    "body_start": body_start,
                    "body_end": body_end,
                }
            else:
                fields[field_name] = mm[body_start:body_end].decode("utf-8", "replace")

            pos = next_boundary + 2 + len(boundary_token)

        if file_part is None:
            raise ValueError("no file field")

        return fields, file_part


class UploadHandler(BaseHTTPRequestHandler):
    server_version = "QuickCatDrop/2.0"

    def send_json(self, code: int, payload: dict) -> None:
        body = json_bytes(payload)
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def send_error_json(self, code: int, message: str) -> None:
        self.send_json(code, {"ok": False, "error": message})

    def do_GET(self) -> None:
        if self.path == "/drop/health":
            self.send_json(200, {"ok": True, "status": "alive", "received_at": now_iso()})
            return
        self.send_error(405, "POST only")

    def do_POST(self) -> None:
        if self.path != UPLOAD_PATH:
            self.send_error_json(404, "not found")
            return

        content_type = self.headers.get("Content-Type", "")
        if "multipart/form-data" not in content_type:
            self.send_error_json(400, "multipart/form-data required")
            return

        boundary_match = re.search(r"boundary=([^\s;]+)", content_type)
        if not boundary_match:
            self.send_error_json(400, "missing multipart boundary")
            return
        boundary = boundary_match.group(1).strip('"').encode("utf-8")

        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            self.send_error_json(400, "invalid content length")
            return

        if length <= 0:
            self.send_error_json(400, "empty upload body")
            return
        if length > MAX_BODY_SIZE:
            self.send_error_json(413, "file too large (500MB max)")
            return

        temp_path: Path | None = None
        upload_dir: Path | None = None
        created_batch_dir = False
        stored_path: Path | None = None
        try:
            temp_path = self._stream_request_to_temp(length)
            fields, file_part = parse_multipart(temp_path, boundary)

            original_name = safe_filename(str(file_part["filename"]))
            suffix = suffix_for(original_name)
            if not suffix:
                self.send_error_json(400, f"file type not allowed: {original_name}")
                return

            body_start = int(file_part["body_start"])
            body_end = int(file_part["body_end"])
            file_size = body_end - body_start
            if file_size <= 0:
                self.send_error_json(400, "empty file upload")
                return
            if file_size > MAX_FILE_SIZE:
                self.send_error_json(413, "file too large (500MB max)")
                return

            received_at = now_iso()
            stamp = time.strftime("%Y%m%d-%H%M%S")
            upload_id = f"{stamp}_{uuid.uuid4().hex[:8]}"
            batch_id = safe_text(fields.get("batch_id"), 48) or f"single_{upload_id}"
            batch_index = parse_int(fields.get("batch_index"), 1, 1, 9999)
            batch_total = parse_int(fields.get("batch_total"), 1, batch_index, 9999)
            batch_token = safe_dirname(fields.get("batch_token"), fallback="")
            if not batch_token:
                safe_stem = safe_dirname(Path(original_name).stem[:48], fallback="drop")
                batch_token = safe_dirname(f"{stamp}_{safe_stem}_{batch_id[:8]}", fallback=f"{stamp}_drop")

            upload_dir = INBOX_DIR / batch_token
            if not upload_dir.exists():
                upload_dir.mkdir(parents=True, exist_ok=False)
                created_batch_dir = True

            stored_name = safe_filename(original_name)
            stored_path = ensure_unique_path(upload_dir, stored_name)
            with temp_path.open("rb") as handle, mmap.mmap(handle.fileno(), 0, access=mmap.ACCESS_READ) as mm:
                written, sha256 = write_range(mm, body_start, body_end, stored_path)

            category_raw = safe_text(fields.get("category"), 24).lower() or "auto"
            category = guess_category(category_raw, suffix)
            note = safe_text(fields.get("note"), 800)
            source = safe_text(fields.get("source"), 40) or "public-drop"
            rel_path = safe_text(fields.get("client_relpath"), 240)
            meta_path = upload_dir / "drop.json"
            batch_meta = load_batch_meta(meta_path)
            files = list(batch_meta.get("files") or [])
            files.append({
                "upload_id": upload_id,
                "received_at": received_at,
                "original_name": original_name,
                "stored_name": stored_path.name,
                "relative_path": rel_path or None,
                "content_type": safe_text(str(file_part["content_type"]), 120),
                "suffix": suffix,
                "size": written,
                "sha256": sha256,
                "batch_index": batch_index,
            })
            files.sort(key=lambda item: (item.get("batch_index", 9999), item.get("stored_name", "")))

            existing_note = safe_text(batch_meta.get("note"), 800)
            existing_category = safe_text(batch_meta.get("category"), 24).lower()
            existing_total = parse_int(str((batch_meta.get("batch") or {}).get("total") or batch_total), batch_total, batch_total, 9999)
            final_category = category
            if category_raw == "auto" and existing_category in ALLOWED_CATEGORIES and existing_category != "auto":
                final_category = existing_category
            batch_meta = {
                "batch_id": batch_id,
                "batch_token": batch_token,
                "status": "pending_review",
                "received_at": batch_meta.get("received_at") or received_at,
                "updated_at": received_at,
                "source": batch_meta.get("source") or source,
                "category": final_category,
                "note": note or existing_note,
                "batch": {
                    "index_last": batch_index,
                    "total": max(existing_total, batch_total, len(files)),
                },
                "request": {
                    "remote_addr": self.headers.get("X-Real-IP") or self.client_address[0],
                    "user_agent": safe_text(self.headers.get("User-Agent"), 300),
                },
                "files": files,
            }

            save_batch_meta(meta_path, batch_meta)

            self.send_json(200, {
                "ok": True,
                "upload_id": upload_id,
                "category": batch_meta["category"],
                "batch": {
                    "id": batch_id,
                    "token": batch_token,
                    "path": str(upload_dir.relative_to(ROOT_DROP_DIR)),
                },
                "stored_at": str(stored_path.relative_to(ROOT_DROP_DIR)),
                "file": {
                    "name": stored_path.name,
                    "size": written,
                    "sha256": sha256,
                },
            })
        except ValueError as exc:
            if stored_path and stored_path.exists():
                stored_path.unlink(missing_ok=True)
            if created_batch_dir and upload_dir and upload_dir.exists() and not any(upload_dir.iterdir()):
                upload_dir.rmdir()
            self.send_error_json(400, str(exc))
        except Exception:
            if stored_path and stored_path.exists():
                stored_path.unlink(missing_ok=True)
            if created_batch_dir and upload_dir and upload_dir.exists() and not any(upload_dir.iterdir()):
                upload_dir.rmdir()
            self.send_error_json(500, "upload failed")
        finally:
            if temp_path and temp_path.exists():
                temp_path.unlink(missing_ok=True)

    def _stream_request_to_temp(self, length: int) -> Path:
        with tempfile.NamedTemporaryFile(
            dir=TMP_DIR,
            prefix="drop-",
            suffix=".multipart",
            delete=False,
        ) as handle:
            remaining = length
            while remaining > 0:
                chunk = self.rfile.read(min(CHUNK_SIZE, remaining))
                if not chunk:
                    raise ValueError("incomplete upload body")
                handle.write(chunk)
                remaining -= len(chunk)
            return Path(handle.name)

    def log_message(self, fmt: str, *args: object) -> None:
        pass


if __name__ == "__main__":
    server = ThreadingHTTPServer(("0.0.0.0", 8085), UploadHandler)
    print("Drop Zone listening on :8085")
    server.serve_forever()
