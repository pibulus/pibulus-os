#!/usr/bin/env python3
"""PIBULUS Claude Chat Gateway.

Small host-local HTTP service for the authenticated deck UI. It proxies one
mobile chat request at a time into `claude -p` using fixed server-side argv.
"""

from __future__ import annotations

import hashlib
import http.cookies
import json
import os
import secrets
import signal
import subprocess
import sys
import threading
import time
import uuid
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any


ROOT = Path(os.environ.get("CLAUDE_CHAT_ROOT", "/home/pibulus/pibulus-os")).resolve()
DATA_DIR = Path(os.environ.get("CLAUDE_CHAT_DATA", str(ROOT / "data" / "claude-chat"))).resolve()
SESSION_FILE = DATA_DIR / "sessions.json"
LOG_FILE = DATA_DIR / "events.log"

HOST = os.environ.get("CLAUDE_CHAT_HOST", "172.17.0.1")
PORT = int(os.environ.get("CLAUDE_CHAT_PORT", "9016"))
MAX_PROMPT_CHARS = int(os.environ.get("CLAUDE_CHAT_MAX_PROMPT_CHARS", "12000"))
ENABLE_FULL = os.environ.get("CLAUDE_CHAT_ENABLE_FULL", "1") == "1"
FULL_ARM_TTL = int(os.environ.get("CLAUDE_CHAT_FULL_ARM_TTL", "75"))
ALLOWED_ORIGINS = {
    item.strip()
    for item in os.environ.get(
        "CLAUDE_CHAT_ALLOWED_ORIGINS",
        "https://deck.quickcat.club",
    ).split(",")
    if item.strip()
}

WORKSPACES = {
    "pibulus-os": {"label": "pibulus-os", "path": ROOT},
    "apps": {"label": "apps", "path": Path("/home/pibulus/apps")},
    "deck-www": {"label": "deck-www", "path": ROOT / "www" / "html"},
}

MODE_CONFIG = {
    "plan": {
        "label": "Plan",
        "permission": "plan",
        "budget": os.environ.get("CLAUDE_CHAT_PLAN_BUDGET", "0.40"),
        "timeout": int(os.environ.get("CLAUDE_CHAT_PLAN_TIMEOUT", "900")),
    },
    "default": {
        "label": "Ask",
        "permission": "default",
        "budget": os.environ.get("CLAUDE_CHAT_DEFAULT_BUDGET", "0.90"),
        "timeout": int(os.environ.get("CLAUDE_CHAT_DEFAULT_TIMEOUT", "1200")),
    },
    "auto": {
        "label": "Act",
        "permission": "auto",
        "budget": os.environ.get("CLAUDE_CHAT_AUTO_BUDGET", "1.25"),
        "timeout": int(os.environ.get("CLAUDE_CHAT_AUTO_TIMEOUT", "1500")),
    },
    "full": {
        "label": "Full",
        "permission": "bypassPermissions",
        "budget": os.environ.get("CLAUDE_CHAT_FULL_BUDGET", "2.00"),
        "timeout": int(os.environ.get("CLAUDE_CHAT_FULL_TIMEOUT", "2400")),
    },
}

sessions_lock = threading.Lock()
active_lock = threading.Lock()
full_arm_lock = threading.Lock()
active_run: dict[str, Any] | None = None
full_arm_tokens: dict[str, dict[str, Any]] = {}


def ensure_data_dir() -> None:
    DATA_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)


def load_sessions() -> dict[str, Any]:
    ensure_data_dir()
    if not SESSION_FILE.exists():
        return {}
    try:
        return json.loads(SESSION_FILE.read_text())
    except Exception:
        return {}


def save_sessions(data: dict[str, Any]) -> None:
    ensure_data_dir()
    tmp = SESSION_FILE.with_suffix(".tmp")
    tmp.write_text(json.dumps(data, indent=2, sort_keys=True))
    tmp.chmod(0o600)
    tmp.replace(SESSION_FILE)


def audit(event: str, **fields: Any) -> None:
    ensure_data_dir()
    safe = {"ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), "event": event}
    safe.update(fields)
    with LOG_FILE.open("a") as fh:
        fh.write(json.dumps(safe, sort_keys=True) + "\n")


def prompt_hash(prompt: str) -> str:
    return hashlib.sha256(prompt.encode("utf-8", "replace")).hexdigest()[:16]


def json_bytes(data: Any) -> bytes:
    return json.dumps(data, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def workspace_path(key: str) -> Path:
    item = WORKSPACES.get(key)
    if item is None:
        raise ValueError("unknown workspace")
    path = item["path"]
    resolved = path.resolve()
    if not resolved.exists() or not resolved.is_dir():
        raise ValueError("workspace unavailable")
    return resolved


def mode_for_request(value: str) -> dict[str, Any]:
    if value not in MODE_CONFIG:
        raise ValueError("unknown mode")
    if value == "full" and not ENABLE_FULL:
        raise ValueError("full mode disabled")
    return MODE_CONFIG[value]


def claude_version() -> str:
    try:
        out = subprocess.check_output(["claude", "--version"], text=True, timeout=3)
        return out.strip()
    except Exception:
        return "unavailable"


def claude_auth_status() -> dict[str, Any]:
    if os.environ.get("ANTHROPIC_API_KEY"):
        return {"ok": True, "text": "ANTHROPIC_API_KEY loaded"}
    try:
        proc = subprocess.run(
            ["claude", "auth", "status", "--text"],
            text=True,
            capture_output=True,
            timeout=5,
            env={**os.environ, "HOME": "/home/pibulus", "TERM": "dumb"},
        )
        text = (proc.stdout or proc.stderr or "").strip()
        return {"ok": proc.returncode == 0, "text": text[:300]}
    except Exception as exc:
        return {"ok": False, "text": str(exc)[:300]}


def make_cookie_token() -> str:
    return secrets.token_urlsafe(32)


def cleanup_full_arm_tokens(now: float | None = None) -> None:
    current = now or time.time()
    expired = [token for token, meta in full_arm_tokens.items() if float(meta.get("expires", 0)) <= current]
    for token in expired:
        full_arm_tokens.pop(token, None)


def issue_full_arm_token(workspace_key: str) -> tuple[str, int]:
    token = secrets.token_urlsafe(32)
    expires = time.time() + FULL_ARM_TTL
    with full_arm_lock:
        cleanup_full_arm_tokens(expires - FULL_ARM_TTL)
        full_arm_tokens[token] = {"workspace": workspace_key, "expires": expires}
    return token, FULL_ARM_TTL


def consume_full_arm_token(token: str, workspace_key: str) -> bool:
    if not token:
        return False
    with full_arm_lock:
        cleanup_full_arm_tokens()
        meta = full_arm_tokens.pop(token, None)
    if not meta:
        return False
    return meta.get("workspace") == workspace_key


def parse_cookie(header: str | None) -> http.cookies.SimpleCookie:
    cookie = http.cookies.SimpleCookie()
    if header:
        try:
            cookie.load(header)
        except http.cookies.CookieError:
            pass
    return cookie


class StreamExtractor:
    def __init__(self) -> None:
        self.last_assistant_text = ""

    def text_from(self, payload: dict[str, Any]) -> str:
        delta = payload.get("delta")
        if isinstance(delta, dict) and isinstance(delta.get("text"), str):
            return delta["text"]

        content_delta = payload.get("content_block")
        if isinstance(content_delta, dict) and isinstance(content_delta.get("text"), str):
            return content_delta["text"]

        message = payload.get("message")
        if isinstance(message, dict):
            content = message.get("content")
            if isinstance(content, list):
                text = "".join(
                    item.get("text", "")
                    for item in content
                    if isinstance(item, dict) and item.get("type") == "text"
                )
                if text:
                    if text.startswith(self.last_assistant_text):
                        out = text[len(self.last_assistant_text):]
                    else:
                        out = text
                    self.last_assistant_text = text
                    return out

        if payload.get("type") == "result" and isinstance(payload.get("result"), str):
            result = payload["result"]
            if result and not self.last_assistant_text:
                self.last_assistant_text = result
                return result
        return ""


class Handler(BaseHTTPRequestHandler):
    server_version = "PibulusClaudeChat/1.0"

    def log_message(self, fmt: str, *args: Any) -> None:
        return

    def send_json(self, data: Any, status: int = 200, extra_headers: dict[str, str] | None = None) -> None:
        body = json_bytes(data)
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        if extra_headers:
            for key, value in extra_headers.items():
                self.send_header(key, value)
        self.end_headers()
        self.wfile.write(body)

    def read_json(self) -> Any:
        length = int(self.headers.get("Content-Length", "0") or "0")
        if length < 0:
            raise ValueError("bad content length")
        if length > 65536:
            raise ValueError("request too large")
        raw = self.rfile.read(length)
        return json.loads(raw.decode("utf-8"))

    def csrf_token_from_cookie(self) -> str | None:
        cookie = parse_cookie(self.headers.get("Cookie"))
        morsel = cookie.get("pibulus_claude_csrf")
        return morsel.value if morsel else None

    def require_post_guard(self) -> bool:
        origin = self.headers.get("Origin")
        if not origin or origin not in ALLOWED_ORIGINS:
            self.send_json({"error": "bad origin"}, HTTPStatus.FORBIDDEN)
            return False
        cookie_token = self.csrf_token_from_cookie()
        header_token = self.headers.get("X-PIBULUS-CSRF")
        if not cookie_token or not header_token or not secrets.compare_digest(cookie_token, header_token):
            self.send_json({"error": "bad csrf"}, HTTPStatus.FORBIDDEN)
            return False
        content_type = self.headers.get("Content-Type", "")
        if "application/json" not in content_type:
            self.send_json({"error": "json required"}, HTTPStatus.UNSUPPORTED_MEDIA_TYPE)
            return False
        return True

    def do_GET(self) -> None:
        if self.path == "/api/bootstrap":
            token = self.csrf_token_from_cookie() or make_cookie_token()
            with active_lock:
                is_active = active_run is not None
            workspaces = [
                {"key": key, "label": str(item["label"])}
                for key, item in WORKSPACES.items()
                if item["path"].exists()
            ]
            modes = [
                {
                    "key": key,
                    "label": value["label"],
                    "enabled": key != "full" or ENABLE_FULL,
                    "budget": value["budget"],
                }
                for key, value in MODE_CONFIG.items()
            ]
            self.send_json(
                {
                    "ok": True,
                    "csrf": token,
                    "claude_version": claude_version(),
                    "claude_auth": claude_auth_status(),
                    "workspaces": workspaces,
                    "modes": modes,
                    "active": is_active,
                    "max_prompt_chars": MAX_PROMPT_CHARS,
                },
                extra_headers={
                    "Set-Cookie": (
                        f"pibulus_claude_csrf={token}; Path=/claude/; "
                        "SameSite=Strict; Secure; HttpOnly"
                    )
                },
            )
            return

        if self.path == "/api/sessions":
            with sessions_lock:
                data = load_sessions()
            public = [
                {
                    "chat_id": chat_id,
                    "title": meta.get("title", "Claude session"),
                    "mode": meta.get("mode", "plan"),
                    "workspace": meta.get("workspace", "pibulus-os"),
                    "updated_at": meta.get("updated_at"),
                }
                for chat_id, meta in sorted(
                    data.items(),
                    key=lambda item: item[1].get("updated_at", ""),
                    reverse=True,
                )[:20]
            ]
            self.send_json({"sessions": public})
            return

        self.send_json({"error": "not found"}, HTTPStatus.NOT_FOUND)

    def do_POST(self) -> None:
        if self.path == "/api/chat":
            self.handle_chat()
            return
        if self.path == "/api/arm":
            self.handle_arm()
            return
        if self.path == "/api/stop":
            self.handle_stop()
            return
        self.send_json({"error": "not found"}, HTTPStatus.NOT_FOUND)

    def handle_arm(self) -> None:
        if not self.require_post_guard():
            return
        if not ENABLE_FULL:
            self.send_json({"error": "full mode disabled"}, HTTPStatus.FORBIDDEN)
            return
        try:
            request = self.read_json()
            workspace_key = str(request.get("workspace", "pibulus-os")).strip()
            workspace_path(workspace_key)
        except Exception as exc:
            self.send_json({"error": f"bad request: {exc}"}, HTTPStatus.BAD_REQUEST)
            return
        token, expires_in = issue_full_arm_token(workspace_key)
        audit("arm", workspace=workspace_key)
        self.send_json({"ok": True, "arm_token": token, "expires_in": expires_in})

    def handle_stop(self) -> None:
        if not self.require_post_guard():
            return
        try:
            request = self.read_json()
        except Exception:
            request = {}
        chat_id = str(request.get("chat_id") or "")
        if not chat_id:
            self.send_json({"error": "chat_id required"}, HTTPStatus.BAD_REQUEST)
            return
        global active_run
        with active_lock:
            run = active_run
            if not run or run.get("chat_id") != chat_id:
                self.send_json({"ok": True, "stopped": False})
                return
            proc = run.get("process")
            active_run = None
        if proc and proc.poll() is None:
            try:
                os.killpg(proc.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            audit("stop", chat_id=chat_id or run.get("chat_id"), pid=proc.pid)
            self.send_json({"ok": True, "stopped": True})
            return
        self.send_json({"ok": True, "stopped": False})

    def handle_chat(self) -> None:
        if not self.require_post_guard():
            return

        try:
            request = self.read_json()
            prompt = str(request.get("message", "")).strip()
            chat_id = str(request.get("chat_id", "")).strip()
            mode_key = str(request.get("mode", "plan")).strip()
            workspace_key = str(request.get("workspace", "pibulus-os")).strip()
        except Exception as exc:
            self.send_json({"error": f"bad request: {exc}"}, HTTPStatus.BAD_REQUEST)
            return

        if not prompt:
            self.send_json({"error": "empty message"}, HTTPStatus.BAD_REQUEST)
            return
        if len(prompt) > MAX_PROMPT_CHARS:
            self.send_json({"error": "message too long"}, HTTPStatus.BAD_REQUEST)
            return

        try:
            mode = mode_for_request(mode_key)
            cwd = workspace_path(workspace_key)
        except ValueError as exc:
            self.send_json({"error": str(exc)}, HTTPStatus.BAD_REQUEST)
            return

        if mode_key == "full" and not consume_full_arm_token(str(request.get("arm_token") or ""), workspace_key):
            self.send_json({"error": "full mode not armed"}, HTTPStatus.FORBIDDEN)
            return

        global active_run
        try:
            with active_lock:
                if active_run is not None:
                    self.send_json({"error": "another run is active"}, HTTPStatus.CONFLICT)
                    return
                active_run = {"chat_id": "", "process": None, "started": time.time()}

            with sessions_lock:
                sessions = load_sessions()
                if chat_id and chat_id in sessions:
                    meta = sessions[chat_id]
                    session_id = meta["session_id"]
                    is_new = False
                else:
                    chat_id = secrets.token_urlsafe(10)
                    session_id = str(uuid.uuid4())
                    meta = {
                        "session_id": session_id,
                        "created_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                        "title": f"{workspace_key} {prompt_hash(prompt)}",
                    }
                    is_new = True
                meta.update(
                    {
                        "mode": mode_key,
                        "workspace": workspace_key,
                        "updated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                    }
                )
                sessions[chat_id] = meta
                save_sessions(sessions)

            argv = [
                "claude",
                "-p",
                "--verbose",
                "--output-format",
                "stream-json",
                "--include-partial-messages",
                "--max-budget-usd",
                str(mode["budget"]),
                "--append-system-prompt",
                (
                    "You are being used through PIBULUS Claude Deck, a mobile web "
                    "operator interface for Pablo's Raspberry Pi server. Be direct, "
                    "state risky operations before doing them, and keep outputs readable on a phone."
                ),
            ]
            if is_new:
                argv.extend(["--session-id", session_id])
            else:
                argv.extend(["--resume", session_id])
            if mode_key == "full":
                argv.append("--dangerously-skip-permissions")
            else:
                argv.extend(["--permission-mode", str(mode["permission"])])
            argv.append(prompt)

            env = os.environ.copy()
            env.update({"HOME": "/home/pibulus", "TERM": "dumb", "NO_COLOR": "1"})

            proc = subprocess.Popen(
                argv,
                cwd=str(cwd),
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1,
                start_new_session=True,
            )
            with active_lock:
                active_run = {"chat_id": chat_id, "process": proc, "started": time.time()}
            audit(
                "start",
                chat_id=chat_id,
                session_id=session_id,
                mode=mode_key,
                workspace=workspace_key,
                prompt_hash=prompt_hash(prompt),
                pid=proc.pid,
            )
            self.stream_process(proc, chat_id, session_id, mode_key, int(mode["timeout"]))
        finally:
            with active_lock:
                active_run = None

    def send_ndjson_headers(self) -> None:
        self.send_response(200)
        self.send_header("Content-Type", "application/x-ndjson; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Accel-Buffering", "no")
        self.end_headers()

    def stream_event(self, data: dict[str, Any]) -> None:
        with self.stream_write_lock:
            self.wfile.write(json_bytes(data) + b"\n")
            self.wfile.flush()

    def stream_process(
        self,
        proc: subprocess.Popen[str],
        chat_id: str,
        session_id: str,
        mode_key: str,
        timeout_seconds: int,
    ) -> None:
        self.stream_write_lock = threading.Lock()
        self.send_ndjson_headers()
        self.stream_event(
            {
                "type": "started",
                "chat_id": chat_id,
                "session_id": session_id,
                "mode": mode_key,
            }
        )

        stderr_lines: list[str] = []

        def read_stderr() -> None:
            if not proc.stderr:
                return
            for line in proc.stderr:
                cleaned = line.rstrip("\n")
                stderr_lines.append(cleaned[:500])
                try:
                    self.stream_event({"type": "stderr", "text": cleaned[:500]})
                except Exception:
                    break

        stderr_thread = threading.Thread(target=read_stderr, daemon=True)
        stderr_thread.start()

        extractor = StreamExtractor()
        deadline = time.time() + timeout_seconds
        timed_out = False

        try:
            if proc.stdout:
                for line in proc.stdout:
                    if time.time() > deadline:
                        timed_out = True
                        os.killpg(proc.pid, signal.SIGTERM)
                        break
                    cleaned = line.rstrip("\n")
                    if not cleaned:
                        continue
                    try:
                        payload = json.loads(cleaned)
                    except json.JSONDecodeError:
                        self.stream_event({"type": "line", "text": cleaned})
                        continue
                    text = extractor.text_from(payload)
                    event: dict[str, Any] = {
                        "type": "claude",
                        "event_type": payload.get("type"),
                    }
                    if text:
                        event["text"] = text
                    if payload.get("type") == "result":
                        event["result"] = {
                            "subtype": payload.get("subtype"),
                            "cost_usd": payload.get("cost_usd"),
                            "duration_ms": payload.get("duration_ms"),
                        }
                    self.stream_event(event)
            try:
                code = proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                timed_out = True
                os.killpg(proc.pid, signal.SIGKILL)
                code = proc.wait(timeout=5)
        except BrokenPipeError:
            if proc.poll() is None:
                os.killpg(proc.pid, signal.SIGTERM)
            code = proc.wait(timeout=5)
        except Exception as exc:
            if proc.poll() is None:
                os.killpg(proc.pid, signal.SIGTERM)
            code = proc.wait(timeout=5)
            self.stream_event({"type": "error", "text": str(exc)})

        audit("finish", chat_id=chat_id, session_id=session_id, code=code, timed_out=timed_out)
        self.stream_event(
            {
                "type": "done",
                "chat_id": chat_id,
                "session_id": session_id,
                "code": code,
                "timed_out": timed_out,
                "stderr_tail": stderr_lines[-3:],
            }
        )


def main() -> None:
    ensure_data_dir()
    httpd = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"PIBULUS Claude Chat Gateway listening on {HOST}:{PORT}", flush=True)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
