#!/usr/bin/env python3
"""KPAB Hearts — Track love system for KPAB.FM pirate radio.
Listeners heart tracks → hearts accumulate → cron auto-requests favorites.
"""

import json, time, hashlib, os, re, fcntl
from http.server import HTTPServer, BaseHTTPRequestHandler

PORT = 8092
HEARTS_FILE = "/home/pibulus/pibulus-os/data/hearts.json"
COOLDOWN = 0  # one heart per song per person, no time limit

os.makedirs(os.path.dirname(HEARTS_FILE), exist_ok=True)

SONG_ID_RE = re.compile(r'^[a-f0-9]{8,64}$')


def load_hearts():
    try:
        with open(HEARTS_FILE, "r") as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def save_hearts(data):
    lock_path = HEARTS_FILE + ".lock"
    with open(lock_path, "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        tmp = HEARTS_FILE + ".tmp"
        with open(tmp, "w") as f:
            json.dump(data, f, indent=2)
        os.replace(tmp, HEARTS_FILE)


def fingerprint(ip, song_id):
    return hashlib.sha256(f"{ip}:{song_id}".encode()).hexdigest()[:16]


class HeartHandler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        print(f"[HEARTS] {self.address_string()} {' '.join(str(a) for a in args)}")

    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_GET(self):
        if self.path == "/hearts/top":
            hearts = load_hearts()
            top = sorted(hearts.items(), key=lambda x: x[1].get("hearts", 0), reverse=True)[:20]
            result = [
                {"song_id": k, "text": v.get("text"), "hearts": v.get("hearts"), "last_hearted": v.get("last_hearted")}
                for k, v in top
            ]
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self._cors()
            self.end_headers()
            self.wfile.write(json.dumps(result).encode())
        elif self.path == "/hearts/health":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self._cors()
            self.end_headers()
            self.wfile.write(b"ok")
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        if self.path != "/hearts/love":
            self.send_response(404)
            self.end_headers()
            return

        try:
            length = int(self.headers.get("Content-Length", 0))
            if length > 2048:
                self.send_response(413)
                self.end_headers()
                return

            body = json.loads(self.rfile.read(length))
            song_id = body.get("song_id", "").strip()
            song_text = body.get("song_text", "").strip()[:200]

            if not song_id or not song_text:
                self.send_response(400)
                self.send_header("Content-Type", "application/json")
                self._cors()
                self.end_headers()
                self.wfile.write(json.dumps({"error": "missing song_id or song_text"}).encode())
                return

            if not SONG_ID_RE.match(song_id):
                self.send_response(400)
                self.send_header("Content-Type", "application/json")
                self._cors()
                self.end_headers()
                self.wfile.write(json.dumps({"error": "invalid song_id"}).encode())
                return

            # Trust forwarded headers only from localhost (nginx proxy)
            actual_ip = self.client_address[0]
            if actual_ip in ("127.0.0.1", "::1", "172.17.0.1"):
                ip = self.headers.get("X-Real-IP", self.headers.get("X-Forwarded-For", actual_ip))
            else:
                ip = actual_ip

            fp = fingerprint(ip, song_id)

            hearts = load_hearts()
            entry = hearts.get(song_id, {"text": song_text, "hearts": 0, "voters": {}, "first_hearted": time.time()})
            entry["text"] = song_text

            last_vote = entry.get("voters", {}).get(fp, 0)
            now = time.time()

            if last_vote > 0:
                self.send_response(429)
                self.send_header("Content-Type", "application/json")
                self._cors()
                self.end_headers()
                self.wfile.write(json.dumps({
                    "error": "already hearted this track",
                    "hearts": entry["hearts"]
                }).encode())
                return

            entry["hearts"] = entry.get("hearts", 0) + 1
            entry["last_hearted"] = now
            if "voters" not in entry:
                entry["voters"] = {}
            entry["voters"][fp] = now
            hearts[song_id] = entry
            save_hearts(hearts)

            print(f"[HEARTS] +1 for '{song_text}' (now {entry['hearts']})")

            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self._cors()
            self.end_headers()
            self.wfile.write(json.dumps({
                "ok": True,
                "hearts": entry["hearts"],
                "song_id": song_id
            }).encode())

        except (json.JSONDecodeError, ValueError):
            self.send_response(400)
            self.send_header("Content-Type", "application/json")
            self._cors()
            self.end_headers()
            self.wfile.write(json.dumps({"error": "bad request"}).encode())


if __name__ == "__main__":
    server = HTTPServer(("127.0.0.1", PORT), HeartHandler)
    print(f"[HEARTS] Listening on 127.0.0.1:{PORT}")
    server.serve_forever()
