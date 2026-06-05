#!/usr/bin/env python3
"""PIBULUS Deck chat gateway.

Small host-local HTTP service for the authenticated deck UI. It proxies one
mobile chat request at a time into server-side model CLIs using fixed argv.
"""

from __future__ import annotations

import hashlib
import http.cookies
import json
import os
import secrets
import signal
import shutil
import subprocess
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
CONTEXT_FILE = Path(
    os.environ.get("CLAUDE_CHAT_CONTEXT_FILE", str(ROOT / "docs" / "AI_COLLECTIVE_CONTEXT.md"))
).resolve()

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

CLAUDE_MODEL = os.environ.get("CLAUDE_CHAT_CLAUDE_MODEL", "").strip()
CODEX_MODEL = os.environ.get("CLAUDE_CHAT_CODEX_MODEL", "gpt-5.4").strip() or "gpt-5.4"
CODEX_TIMEOUT = int(os.environ.get("CLAUDE_CHAT_CODEX_TIMEOUT", "1200"))
GEMINI_MODEL = os.environ.get("CLAUDE_CHAT_GEMINI_MODEL", "").strip()
GEMINI_TIMEOUT = int(os.environ.get("CLAUDE_CHAT_GEMINI_TIMEOUT", "1200"))
DEEPSEEK_FLASH_MODEL = (
    os.environ.get("CLAUDE_CHAT_DEEPSEEK_FLASH_MODEL")
    or os.environ.get("CLAUDE_CHAT_DEEPSEEK_MODEL")
    or "deepseek/deepseek-v4-flash"
).strip()
DEEPSEEK_PRO_MODEL = os.environ.get("CLAUDE_CHAT_DEEPSEEK_PRO_MODEL", "deepseek/deepseek-v4-pro").strip()
OPENCODE_TIMEOUT = int(os.environ.get("CLAUDE_CHAT_OPENCODE_TIMEOUT", "1200"))
OLLAMA_TIMEOUT = int(os.environ.get("CLAUDE_CHAT_OLLAMA_TIMEOUT", "900"))

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


def clamp01(value: float) -> float:
    return max(0.0, min(1.0, value))


def read_first_float(path: str, divisor: float = 1.0) -> float | None:
    try:
        return float(Path(path).read_text().strip()) / divisor
    except Exception:
        return None


def read_proc_uptime() -> float | None:
    try:
        return float(Path("/proc/uptime").read_text().split()[0])
    except Exception:
        return None


def read_meminfo() -> dict[str, int]:
    values: dict[str, int] = {}
    try:
        for line in Path("/proc/meminfo").read_text().splitlines():
            key, raw = line.split(":", 1)
            parts = raw.strip().split()
            if parts and parts[0].isdigit():
                values[key] = int(parts[0]) * 1024
    except Exception:
        pass
    return values


def disk_usage(path: Path) -> dict[str, float | bool]:
    try:
        stat = os.statvfs(path)
        total = stat.f_blocks * stat.f_frsize
        free = stat.f_bavail * stat.f_frsize
        used = max(0, total - free)
        return {
            "ok": True,
            "used": round(clamp01(used / total if total else 0), 4),
        }
    except Exception:
        return {"ok": False, "used": 0.0}


def moon_phase(now: float | None = None) -> float:
    # Approximate lunation phase from a known new moon: 2000-01-06 18:14 UTC.
    seconds = (now if now is not None else time.time()) - 947182440
    return seconds / 2551442.877 % 1.0


def system_pulse() -> dict[str, Any]:
    try:
        load1 = float(Path("/proc/loadavg").read_text().split()[0])
    except Exception:
        load1 = 0.0

    meminfo = read_meminfo()
    mem_total = meminfo.get("MemTotal", 0)
    mem_available = meminfo.get("MemAvailable", 0)
    swap_total = meminfo.get("SwapTotal", 0)
    swap_free = meminfo.get("SwapFree", 0)
    mem_used = clamp01((mem_total - mem_available) / mem_total) if mem_total else 0.0
    swap_used = clamp01((swap_total - swap_free) / swap_total) if swap_total else 0.0
    temp_c = read_first_float("/sys/class/thermal/thermal_zone0/temp", 1000.0)
    uptime = read_proc_uptime()
    root = disk_usage(Path("/"))
    passport = disk_usage(Path("/media/pibulus/passport"))
    now = int(time.time())
    moon = moon_phase(now)
    seed_material = "|".join(
        [
            str(now // 60),
            f"{load1:.2f}",
            f"{mem_used:.3f}",
            f"{swap_used:.3f}",
            f"{root.get('used', 0):.3f}",
            f"{passport.get('used', 0):.3f}",
            f"{temp_c or 0:.1f}",
            f"{moon:.4f}",
            str(int((uptime or 0) // 37)),
        ]
    )
    seed = hashlib.sha256(seed_material.encode()).hexdigest()[:12]
    return {
        "ok": True,
        "seed": seed,
        "load": round(clamp01(load1 / 4.0), 4),
        "mem": round(mem_used, 4),
        "swap": round(swap_used, 4),
        "root": root,
        "passport": passport,
        "temp": round(clamp01(((temp_c or 40.0) - 35.0) / 45.0), 4),
        "uptime": round(((uptime or 0.0) % 86400) / 86400, 4),
        "moon": round(moon, 4),
        "minute": now // 60,
    }


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


def command_available(command: str) -> bool:
    return shutil.which(command) is not None


def env_key_loaded(name: str) -> bool:
    return bool(os.environ.get(name, "").strip())


def claude_version() -> str:
    try:
        out = subprocess.check_output(["claude", "--version"], text=True, timeout=3)
        return out.strip()
    except Exception:
        return "unavailable"


def gemini_version() -> str:
    try:
        out = subprocess.check_output(["gemini", "--version"], text=True, timeout=3)
        return out.strip()
    except Exception:
        return "unavailable"


def opencode_version() -> str:
    try:
        out = subprocess.check_output(["opencode", "--version"], text=True, timeout=3)
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


def ollama_models() -> list[str]:
    if not command_available("ollama"):
        return []
    try:
        out = subprocess.check_output(["ollama", "list"], text=True, timeout=5)
    except Exception:
        return []
    names: list[str] = []
    for line in out.splitlines()[1:]:
        parts = line.split()
        if parts:
            names.append(parts[0])
    return names


def collective_context() -> str:
    try:
        text = CONTEXT_FILE.read_text(encoding="utf-8", errors="replace").strip()
    except Exception:
        return ""
    return text[:9000]


def deck_system_prompt(model_key: str, mode_key: str, cwd: Path) -> str:
    context = collective_context()
    write_policy = (
        "Full mode was explicitly hold-armed by Pablo for this single run. "
        "You may create, edit, and delete files inside the selected workspace when it directly serves the request. "
        "Still do not sudo, expose secrets, run Docker pulls, run AzuraCast updates, change image tags, or unmount Passport without asking first."
        if mode_key == "full"
        else "This run is not Full-armed. Prefer inspection, planning, and concise answers. Do not force file edits through permission prompts."
    )
    parts = [
        "You are being used through PIBULUS Deck, Pablo's private mobile web operator for his Raspberry Pi server.",
        "Be direct, phone-readable, and practical. Name risky operations before doing them.",
        f"Selected workspace: {cwd}.",
        write_policy,
    ]
    if context:
        parts.extend(["", "Shared Pi AI context:", context])
    return "\n".join(parts)


def available_models(claude_auth: dict[str, Any] | None = None) -> list[dict[str, Any]]:
    claude_auth = claude_auth or claude_auth_status()
    gemini_installed = command_available("gemini")
    gemini_key = env_key_loaded("GEMINI_API_KEY")
    opencode_installed = command_available("opencode")
    deepseek_key = env_key_loaded("DEEPSEEK_API_KEY")
    models = [
        {
            "key": "claude",
            "label": "Claude Code",
            "detail": CLAUDE_MODEL or claude_version(),
            "enabled": command_available("claude") and bool(claude_auth.get("ok")),
            "modes": ["plan", "default", "auto", "full"],
            "default_mode": "auto",
        },
        {
            "key": "codex",
            "label": "Codex CLI",
            "detail": CODEX_MODEL,
            "enabled": command_available("codex"),
            "modes": ["plan", "default", "full"],
            "default_mode": "plan",
        },
        {
            "key": "deepseek-flash",
            "label": "DeepSeek Flash",
            "detail": DEEPSEEK_FLASH_MODEL if deepseek_key else "needs key",
            "enabled": opencode_installed and deepseek_key,
            "modes": ["plan", "default", "full"],
            "default_mode": "plan",
        },
        {
            "key": "deepseek-pro",
            "label": "DeepSeek Pro",
            "detail": DEEPSEEK_PRO_MODEL if deepseek_key else "needs key",
            "enabled": opencode_installed and deepseek_key,
            "modes": ["plan", "default", "full"],
            "default_mode": "plan",
        },
        {
            "key": "gemini",
            "label": "Gemini CLI",
            "detail": (GEMINI_MODEL or gemini_version()) if gemini_installed and gemini_key else "needs fresh key",
            "enabled": gemini_installed and gemini_key,
            "modes": ["plan", "default", "full"],
            "default_mode": "plan",
        },
    ]

    ollama = ollama_models()
    for name in ollama:
        models.append(
            {
                "key": f"ollama:{name}",
                "label": f"Ollama · {name}",
                "detail": "local",
                "enabled": True,
                "modes": ["plan", "default"],
                "default_mode": "default",
            }
        )

    return models


def model_for_request(value: str, claude_auth: dict[str, Any] | None = None) -> dict[str, Any]:
    key = value or "claude"
    if key == "deepseek":
        key = "deepseek-flash"
    for model in available_models(claude_auth):
        if model["key"] == key:
            if not model.get("enabled"):
                raise ValueError(f"{model['label']} unavailable")
            return model
    raise ValueError("unknown model")


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
        if self.path == "/api/pulse":
            self.send_json(system_pulse())
            return

        if self.path == "/api/bootstrap":
            token = self.csrf_token_from_cookie() or make_cookie_token()
            with active_lock:
                is_active = active_run is not None
            claude_auth = claude_auth_status()
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
                    "claude_auth": claude_auth,
                    "models": available_models(claude_auth),
                    "workspaces": workspaces,
                    "modes": modes,
                    "active": is_active,
                    "pulse": system_pulse(),
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
                    "model": meta.get("model", "claude"),
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
            model_key = str(request.get("model", "claude")).strip() or "claude"
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
            model = model_for_request(model_key)
            mode = mode_for_request(mode_key)
            cwd = workspace_path(workspace_key)
        except ValueError as exc:
            self.send_json({"error": str(exc)}, HTTPStatus.BAD_REQUEST)
            return

        supported_modes = set(model.get("modes") or [])
        if mode_key not in supported_modes:
            self.send_json({"error": f"{model['label']} does not support {mode['label']} mode"}, HTTPStatus.BAD_REQUEST)
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
                if chat_id and chat_id in sessions and sessions[chat_id].get("model", "claude") == model_key:
                    meta = sessions[chat_id]
                    session_id = meta["session_id"]
                    is_new = False
                else:
                    chat_id = secrets.token_urlsafe(10)
                    session_id = str(uuid.uuid4())
                    meta = {
                        "session_id": session_id,
                        "created_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                        "title": f"{model_key} {workspace_key} {prompt_hash(prompt)}",
                    }
                    is_new = True
                meta.update(
                    {
                        "model": model_key,
                        "mode": mode_key,
                        "workspace": workspace_key,
                        "updated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                    }
                )
                sessions[chat_id] = meta
                save_sessions(sessions)

            argv, stream_kind, timeout_seconds = self.build_argv(
                model_key=model_key,
                mode_key=mode_key,
                mode=mode,
                cwd=cwd,
                session_id=session_id,
                is_new=is_new,
                prompt=prompt,
            )

            env = os.environ.copy()
            env.update({"HOME": "/home/pibulus", "TERM": "dumb", "NO_COLOR": "1"})
            if model_key == "codex":
                env.pop("OPENAI_API_KEY", None)
                env.pop("CODEX_API_KEY", None)
            if model_key == "gemini":
                env.pop("GOOGLE_API_KEY", None)

            proc = subprocess.Popen(
                argv,
                cwd=str(cwd),
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                stdin=subprocess.DEVNULL,
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
                model=model_key,
                mode=mode_key,
                workspace=workspace_key,
                prompt_hash=prompt_hash(prompt),
                pid=proc.pid,
            )
            self.stream_process(proc, chat_id, session_id, model_key, mode_key, stream_kind, timeout_seconds)
        finally:
            with active_lock:
                active_run = None

    def build_argv(
        self,
        *,
        model_key: str,
        mode_key: str,
        mode: dict[str, Any],
        cwd: Path,
        session_id: str,
        is_new: bool,
        prompt: str,
    ) -> tuple[list[str], str, int]:
        system_prompt = deck_system_prompt(model_key, mode_key, cwd)

        if model_key == "claude":
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
                system_prompt,
            ]
            if CLAUDE_MODEL:
                argv.extend(["--model", CLAUDE_MODEL])
            if is_new:
                argv.extend(["--session-id", session_id])
            else:
                argv.extend(["--resume", session_id])
            if mode_key == "full":
                argv.append("--dangerously-skip-permissions")
            else:
                argv.extend(["--permission-mode", str(mode["permission"])])
            argv.append(prompt)
            return argv, "claude", int(mode["timeout"])

        if model_key == "codex":
            codex_prompt = (
                f"{system_prompt}\n\n"
                + (
                    "Codex Full mode is armed for this run; use the workspace deliberately.\n\n"
                    if mode_key == "full"
                    else "Codex is not Full-armed here. Inspect, reason, and answer; do not edit files.\n\n"
                )
                + f"{prompt}"
            )
            argv = [
                "codex",
                "exec",
                "--json",
                "--model",
                CODEX_MODEL,
                "-c",
                'approval_policy="never"',
                "--skip-git-repo-check",
                "-C",
                str(cwd),
            ]
            if mode_key == "full":
                argv.append("--dangerously-bypass-approvals-and-sandbox")
            else:
                argv.extend(["--sandbox", "read-only", "--ephemeral"])
            argv.append(codex_prompt)
            return argv, "codex", CODEX_TIMEOUT

        if model_key in {"deepseek", "deepseek-flash", "deepseek-pro"}:
            if not command_available("opencode") or not env_key_loaded("DEEPSEEK_API_KEY"):
                raise ValueError("DeepSeek unavailable")
            opencode_model = DEEPSEEK_PRO_MODEL if model_key == "deepseek-pro" else DEEPSEEK_FLASH_MODEL
            opencode_prompt = (
                f"{system_prompt}\n\n"
                + (
                    "DeepSeek is running through OpenCode with Full permissions for this hold-armed run.\n\n"
                    if mode_key == "full"
                    else "DeepSeek is running through OpenCode without Full permissions. Do not edit files in this mode.\n\n"
                )
                + f"{prompt}"
            )
            argv = [
                "opencode",
                "run",
                "--model",
                opencode_model,
                "--format",
                "json",
                "--dir",
                str(cwd),
            ]
            if mode_key == "full":
                argv.append("--dangerously-skip-permissions")
            argv.append(opencode_prompt)
            return argv, "opencode", OPENCODE_TIMEOUT

        if model_key == "gemini":
            if not command_available("gemini") or not env_key_loaded("GEMINI_API_KEY"):
                raise ValueError("Gemini unavailable")
            gemini_prompt = (
                f"{system_prompt}\n\n"
                + (
                    "Gemini Full mode is armed for this run; use yolo approval carefully.\n\n"
                    if mode_key == "full"
                    else "Gemini is not Full-armed here. Stay in read-only/plan behavior and do not edit files.\n\n"
                )
                + f"{prompt}"
            )
            argv = [
                "gemini",
                "--prompt",
                gemini_prompt,
                "--output-format",
                "stream-json",
                "--skip-trust",
            ]
            if GEMINI_MODEL:
                argv.extend(["--model", GEMINI_MODEL])
            if mode_key == "full":
                argv.extend(["--approval-mode", "yolo", "--yolo"])
            else:
                argv.extend(["--approval-mode", "plan"])
            return argv, "gemini", GEMINI_TIMEOUT

        if model_key.startswith("ollama:"):
            model_name = model_key.split(":", 1)[1]
            if model_name not in ollama_models():
                raise ValueError("Ollama model unavailable")
            ollama_prompt = (
                f"{system_prompt}\n\n"
                "You are a local chat model. You cannot edit files through this route.\n\n"
                f"{prompt}"
            )
            return ["ollama", "run", model_name, ollama_prompt], "plain", OLLAMA_TIMEOUT

        raise ValueError("unknown model")

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
        model_key: str,
        mode_key: str,
        stream_kind: str,
        timeout_seconds: int,
    ) -> None:
        self.stream_write_lock = threading.Lock()
        self.send_ndjson_headers()
        self.stream_event(
            {
                "type": "started",
                "chat_id": chat_id,
                "session_id": session_id,
                "model": model_key,
                "mode": mode_key,
            }
        )

        stderr_lines: list[str] = []
        result_summary: dict[str, Any] = {}

        def read_stderr() -> None:
            if not proc.stderr:
                return
            for line in proc.stderr:
                cleaned = line.rstrip("\n")
                if stream_kind == "codex" and cleaned == "Reading additional input from stdin...":
                    continue
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
                    if stream_kind == "plain":
                        self.stream_event({"type": "line", "text": cleaned})
                        continue
                    try:
                        payload = json.loads(cleaned)
                    except json.JSONDecodeError:
                        self.stream_event({"type": "line", "text": cleaned})
                        continue
                    if stream_kind == "claude":
                        text = extractor.text_from(payload)
                    elif stream_kind == "codex":
                        text = self.text_from_codex(payload)
                    elif stream_kind == "opencode":
                        text = self.text_from_opencode(payload)
                    elif stream_kind == "gemini":
                        text = self.text_from_gemini(payload)
                    else:
                        text = ""
                    event_type = str(payload.get("type") or "")
                    event: dict[str, Any] = {"type": "agent", "model": model_key, "event_type": event_type}
                    if text:
                        event["text"] = text
                    if stream_kind == "codex" and event_type == "error" and isinstance(payload.get("message"), str):
                        event["type"] = "error"
                        event["text"] = payload["message"]
                    if stream_kind == "claude" and payload.get("type") == "result":
                        result_summary = {
                            "subtype": payload.get("subtype"),
                            "cost_usd": payload.get("cost_usd"),
                            "duration_ms": payload.get("duration_ms"),
                        }
                        event["result"] = result_summary
                    if stream_kind == "opencode":
                        cost = self.cost_from_opencode(payload)
                        if cost is not None:
                            result_summary["cost_usd"] = cost
                    if stream_kind == "gemini":
                        error = self.error_from_payload(payload)
                        if error:
                            event["type"] = "error"
                            event["text"] = error
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

        audit("finish", chat_id=chat_id, session_id=session_id, model=model_key, code=code, timed_out=timed_out)
        done_event = {
            "type": "done",
            "chat_id": chat_id,
            "session_id": session_id,
            "model": model_key,
            "code": code,
            "timed_out": timed_out,
            "stderr_tail": stderr_lines[-3:],
        }
        if result_summary:
            done_event["result"] = result_summary
        self.stream_event(done_event)

    def text_from_codex(self, payload: dict[str, Any]) -> str:
        for key in ("text", "message", "delta"):
            value = payload.get(key)
            if isinstance(value, str):
                return value
            if isinstance(value, dict) and isinstance(value.get("text"), str):
                return value["text"]

        item = payload.get("item")
        if isinstance(item, dict):
            value = item.get("text")
            if isinstance(value, str):
                return value
            content = item.get("content")
            if isinstance(content, list):
                return "".join(
                    part.get("text", "")
                    for part in content
                    if isinstance(part, dict) and isinstance(part.get("text"), str)
                )

        event = payload.get("event")
        if isinstance(event, dict):
            value = event.get("message") or event.get("text")
            if isinstance(value, str):
                return value

        return ""

    def text_from_opencode(self, payload: dict[str, Any]) -> str:
        part = payload.get("part")
        if isinstance(part, dict) and isinstance(part.get("text"), str):
            return part["text"]
        for key in ("text", "message", "content"):
            value = payload.get(key)
            if isinstance(value, str):
                return value
            if isinstance(value, dict) and isinstance(value.get("text"), str):
                return value["text"]
        return self.text_from_codex(payload)

    def text_from_gemini(self, payload: dict[str, Any]) -> str:
        for key in ("text", "response", "output", "content"):
            value = payload.get(key)
            if isinstance(value, str):
                return value
            if isinstance(value, dict) and isinstance(value.get("text"), str):
                return value["text"]
            if isinstance(value, list):
                text = "".join(
                    item.get("text", "")
                    for item in value
                    if isinstance(item, dict) and isinstance(item.get("text"), str)
                )
                if text:
                    return text

        message = payload.get("message")
        if isinstance(message, dict):
            content = message.get("content") or message.get("parts")
            if isinstance(content, str):
                return content
            if isinstance(content, list):
                text = "".join(
                    part.get("text", "")
                    for part in content
                    if isinstance(part, dict) and isinstance(part.get("text"), str)
                )
                if text:
                    return text

        candidates = payload.get("candidates")
        if isinstance(candidates, list):
            text_parts: list[str] = []
            for candidate in candidates:
                if not isinstance(candidate, dict):
                    continue
                content = candidate.get("content")
                if isinstance(content, dict):
                    parts = content.get("parts")
                    if isinstance(parts, list):
                        text_parts.extend(
                            part.get("text", "")
                            for part in parts
                            if isinstance(part, dict) and isinstance(part.get("text"), str)
                        )
            if text_parts:
                return "".join(text_parts)

        return self.text_from_codex(payload)

    def error_from_payload(self, payload: dict[str, Any]) -> str:
        error = payload.get("error")
        if isinstance(error, str):
            return error
        if isinstance(error, dict):
            message = error.get("message") or error.get("error")
            if isinstance(message, str):
                return message
        return ""

    def cost_from_opencode(self, payload: dict[str, Any]) -> float | None:
        for value in (payload.get("cost"), payload.get("cost_usd")):
            if isinstance(value, (int, float)):
                return float(value)
        part = payload.get("part")
        if isinstance(part, dict):
            for value in (part.get("cost"), part.get("cost_usd")):
                if isinstance(value, (int, float)):
                    return float(value)
        return None


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
