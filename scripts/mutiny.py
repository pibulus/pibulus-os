#!/usr/bin/env python3
"""MUTINY - Listener skip for KPAB.FM pirate radio
Simple: one person = one skip. 10 minute cooldown per listener.
"""

import json, time, hashlib
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.request import Request, urlopen
from urllib.parse import urlparse

AZURACAST_URL = "http://localhost:8500"
API_KEY = "dc496426609c5cf3:4d97815b1d07bcb062831493911d3c59"
STATION_ID = 1
COOLDOWN = 600  # 10 minutes

cooldowns = {}  # fingerprint -> last skip timestamp


def api_post(path):
    req = Request(f"{AZURACAST_URL}{path}", data=b"", method="POST")
    req.add_header("X-API-Key", API_KEY)
    with urlopen(req, timeout=5) as r:
        return json.loads(r.read())


def do_skip():
    try:
        result = api_post(f"/api/station/{STATION_ID}/backend/skip")
        print(f"[MUTINY] Skip executed: {result}")
        return True
    except Exception as e:
        print(f"[MUTINY] Skip failed: {e}")
        return False


def fingerprint(ip, ua):
    return hashlib.sha256(f"{ip}:{ua}".encode()).hexdigest()[:12]


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

        now = time.time()
        if fp in cooldowns and (now - cooldowns[fp]) < COOLDOWN:
            remaining = int(COOLDOWN - (now - cooldowns[fp]))
            self._json(429, {
                "error": "cooldown",
                "message": f"Easy, sailor. {remaining}s cooldown remaining.",
                "remaining": remaining
            })
            return

        if do_skip():
            cooldowns[fp] = now
            # Clean old cooldowns
            expired = [k for k, v in cooldowns.items() if now - v > COOLDOWN]
            for k in expired:
                del cooldowns[k]
            self._json(200, {
                "action": "skipped",
                "message": "Track walked the plank.",
                "remaining": COOLDOWN
            })
        else:
            self._json(500, {
                "action": "failed",
                "message": "Mutiny failed. Radio resists."
            })


if __name__ == "__main__":
    port = 8090
    server = HTTPServer(("0.0.0.0", port), MutinyHandler)
    print(f"[MUTINY] Armed on port {port} | Cooldown={COOLDOWN}s")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[MUTINY] Standing down.")
