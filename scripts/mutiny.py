#!/usr/bin/env python3
"""MUTINY - Listener skip for KPAB.FM pirate radio
One skip per 10 minutes per listener. No voting. Just skip.
"""

import json, os, time, hashlib
from http.server import HTTPServer, BaseHTTPRequestHandler
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.parse import urlparse

AZURACAST_URL = "http://localhost:8500"
API_KEY_FILE = Path(os.environ.get("AZURACAST_API_KEY_FILE", "/home/pibulus/.config/azuracast-api-key"))
STATION_ID = 1
COOLDOWN = 600  # 10 minutes

cooldowns = {}  # fingerprint -> last skip timestamp


def get_api_key():
    env_key = os.environ.get("AZURACAST_API_KEY")
    if env_key:
        return env_key.strip()
    if API_KEY_FILE.exists():
        return API_KEY_FILE.read_text().strip()
    raise RuntimeError(f"Missing AzuraCast API key. Set AZURACAST_API_KEY or create {API_KEY_FILE}")


def api_post(path):
    req = Request(f"{AZURACAST_URL}{path}", data=b"", method="POST")
    req.add_header("X-API-Key", get_api_key())
    with urlopen(req, timeout=5) as r:
        return json.loads(r.read())


def fingerprint(ip, ua):
    return hashlib.sha256(f"{ip}:{ua}".encode()).hexdigest()[:12]


def check_cooldown(fp):
    now = time.time()
    if fp in cooldowns and (now - cooldowns[fp]) < COOLDOWN:
        remaining = int(COOLDOWN - (now - cooldowns[fp]))
        return False, remaining
    return True, 0


def do_skip():
    try:
        result = api_post(f"/api/station/{STATION_ID}/backend/skip")
        print(f"[MUTINY] Skip executed: {result}")
        return True
    except Exception as e:
        print(f"[MUTINY] Skip failed: {e}")
        return False


class MutinyHandler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        if "/health" not in str(args):
            print(f"[MUTINY] {args[0]}")

    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def _json(self, code, data):
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self._cors()
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_GET(self):
        path = urlparse(self.path).path
        if path == "/health":
            self._json(200, {"status": "armed"})
        else:
            self._json(404, {"error": "not found"})

    def do_POST(self):
        path = urlparse(self.path).path
        if path != "/mutiny":
            self._json(404, {"error": "not found"})
            return

        ip = self.headers.get("X-Real-IP", self.client_address[0])
        ua = self.headers.get("User-Agent", "unknown")
        fp = fingerprint(ip, ua)

        can_skip, remaining = check_cooldown(fp)
        if not can_skip:
            self._json(429, {
                "error": "cooldown",
                "message": f"Easy, sailor. {remaining}s cooldown remaining.",
                "remaining": remaining
            })
            return

        if do_skip():
            cooldowns[fp] = time.time()
            self._json(200, {
                "action": "skipped",
                "message": "Track walked the plank.",
                "remaining": COOLDOWN
            })
        else:
            self._json(500, {
                "error": "skip_failed",
                "message": "Mutiny failed. Radio resists."
            })


if __name__ == "__main__":
    port = 8090
    server = HTTPServer(("0.0.0.0", port), MutinyHandler)
    print(f"[MUTINY] Armed on port {port} | Cooldown={COOLDOWN}s | No voting, just skip")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[MUTINY] Standing down.")
