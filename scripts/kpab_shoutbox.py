#!/usr/bin/env python3
"""KPAB SHOUTBOX - Listener shouts with now-playing metadata.
Replaces msgdrop.py on port 8087.
"""

import json, os, time, uuid, threading
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.request import Request, urlopen
from urllib.parse import urlparse

# --- CONFIG ---
PORT = 8087
# Save to SD card for stability (like catalog.json)
SHOUT_FILE = '/media/pibulus/passport/pibulus-os/www/html/msg/shouts.json'
AZURACAST_URL = "http://localhost:8500"
STATION_ID = 1
MAX_SHOUTS = 100
COOLDOWN = 15  # seconds

# --- STATE ---
shouts = []
last_post = {} # ip -> timestamp
lock = threading.Lock()

def get_nowplaying():
    try:
        req = Request(f"{AZURACAST_URL}/api/nowplaying/{STATION_ID}")
        with urlopen(req, timeout=3) as r:
            data = json.loads(r.read())
            song = data["now_playing"]["song"]
            return f"{song['artist']} - {song['title']}"
    except:
        return "Something mysterious..."

def load():
    global shouts
    try:
        if os.path.exists(SHOUT_FILE):
            with open(SHOUT_FILE) as f:
                shouts = json.load(f)
    except:
        shouts = []

def save():
    try:
        os.makedirs(os.path.dirname(SHOUT_FILE), exist_ok=True)
        with open(SHOUT_FILE, 'w') as f:
            json.dump(shouts, f, separators=(',', ':'))
    except Exception as e:
        print(f"Save error: {e}")

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *a): pass

    def _cors(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')

    def _json(self, code, data):
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self._cors()
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def do_OPTIONS(self):
        self.send_response(200)
        self._cors()
        self.end_headers()

    def do_GET(self):
        if self.path == '/msg/shouts.json' or self.path == '/msg/inbox':
            with lock:
                self._json(200, shouts)
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        if self.path == '/msg/drop' or self.path == '/msg/shout':
            ip = self.headers.get('X-Real-IP', self.client_address[0])
            now = time.time()

            if ip in last_post and now - last_post[ip] < COOLDOWN:
                self._json(429, {"error": "Wait a bit, sailor." })
                return

            try:
                length = int(self.headers.get('Content-Length', 0))
                body = json.loads(self.rfile.read(length))
                
                # Support both old 'name'/'msg' and new 'n'/'m' keys
                name = str(body.get('name', body.get('n', 'anon'))).strip()[:30]
                text = str(body.get('message', body.get('msg', body.get('m', '')))).strip()[:500]

                if not text:
                    self._json(400, {"error": "Say something!"})
                    return

                track = get_nowplaying()

                shout = {
                    'id': str(uuid.uuid4())[:8],
                    'n': name,
                    'm': text,
                    'track': track,
                    't': int(now)
                }

                with lock:
                    shouts.insert(0, shout)
                    del shouts[MAX_SHOUTS:]
                    save()
                
                last_post[ip] = now
                self._json(200, {"ok": True})

            except Exception as e:
                print(f"POST error: {e}")
                self._json(400, {"error": "Malformed request"})
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == '__main__':
    load()
    print(f"KPAB Shoutbox listening on port {PORT}")
    HTTPServer(('0.0.0.0', PORT), Handler).serve_forever()
