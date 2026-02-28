#!/usr/bin/env python3
"""The Wall — pixel graffiti backend for quickcat.club
Stores a 64x64 grid of colours. No accounts, no text, just pixels."""

import json, os, time
from http.server import HTTPServer, BaseHTTPRequestHandler

GRID = 64
STATE_FILE = '/media/pibulus/passport/www/html/wall/state.json'
COOLDOWN = 1  # seconds per IP
PORT = 8086

# In-memory state
grid = [None] * (GRID * GRID)
visitors = set()
last_place = {}  # ip -> timestamp

def load():
    global grid, visitors
    try:
        with open(STATE_FILE) as f:
            data = json.load(f)
            grid = data.get('grid', grid)
            visitors = set(data.get('visitors', []))
    except (FileNotFoundError, json.JSONDecodeError):
        pass

def save():
    os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
    with open(STATE_FILE, 'w') as f:
        json.dump({'grid': grid, 'visitors': list(visitors)}, f)

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *a): pass  # quiet

    def do_GET(self):
        if self.path == '/wall/state.json':
            data = json.dumps({'grid': grid, 'visitors': list(visitors)}).encode()
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Cache-Control', 'no-cache')
            self.end_headers()
            self.wfile.write(data)
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        if self.path == '/wall/place':
            ip = self.headers.get('X-Real-IP', self.client_address[0])
            now = time.time()

            # Rate limit
            if ip in last_place and now - last_place[ip] < COOLDOWN:
                self.send_response(429)
                self.end_headers()
                self.wfile.write(b'{"error":"too fast"}')
                return

            try:
                length = int(self.headers.get('Content-Length', 0))
                body = json.loads(self.rfile.read(length))
                x = int(body['x'])
                y = int(body['y'])
                c = str(body['c'])[:7]  # max #rrggbb
                v = str(body.get('v', ''))[:10]

                if 0 <= x < GRID and 0 <= y < GRID and c.startswith('#'):
                    idx = y * GRID + x
                    grid[idx] = c
                    last_place[ip] = now
                    if v:
                        visitors.add(v)
                    save()

                    self.send_response(200)
                    self.send_header('Content-Type', 'application/json')
                    self.send_header('Access-Control-Allow-Origin', '*')
                    self.end_headers()
                    self.wfile.write(b'{"ok":true}')
                else:
                    self.send_response(400)
                    self.end_headers()
            except (ValueError, KeyError, json.JSONDecodeError):
                self.send_response(400)
                self.end_headers()
        else:
            self.send_response(404)
            self.end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

if __name__ == '__main__':
    load()
    print(f'The Wall listening on port {PORT}')
    print(f'Grid: {GRID}x{GRID}, Pixels placed: {sum(1 for c in grid if c)}, Visitors: {len(visitors)}')
    HTTPServer(('0.0.0.0', PORT), Handler).serve_forever()
