#!/usr/bin/env python3
"""Graffiti Wall — drawing backend for quickcat.club
Stores a 128x128 grid. Smooth drawing enabled by lowering cooldown."""

import json, os, time
from http.server import HTTPServer, BaseHTTPRequestHandler

GRID = 128
STATE_FILE = '/media/pibulus/passport/www/html/wall/state.json'
COOLDOWN = 0.05  # Faster for smooth drawing
PORT = 8086

grid = [None] * (GRID * GRID)
visitors = set()
last_place = {}

def load():
    global grid, visitors
    try:
        if os.path.exists(STATE_FILE):
            with open(STATE_FILE) as f:
                data = json.load(f)
                loaded_grid = data.get('grid', [])
                if len(loaded_grid) == GRID * GRID:
                    grid = loaded_grid
                elif len(loaded_grid) == 64 * 64:
                    # Upscale old 64x64 to 128x128
                    new_grid = [None] * (128 * 128)
                    for y in range(64):
                        for x in range(64):
                            color = loaded_grid[y * 64 + x]
                            if color:
                                # Place 2x2 block
                                new_grid[(y*2) * 128 + (x*2)] = color
                                new_grid[(y*2) * 128 + (x*2+1)] = color
                                new_grid[(y*2+1) * 128 + (x*2)] = color
                                new_grid[(y*2+1) * 128 + (x*2+1)] = color
                    grid = new_grid
                visitors = set(data.get('visitors', []))
    except Exception as e:
        print(f'Load error: {e}')

def save():
    try:
        os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
        with open(STATE_FILE, 'w') as f:
            json.dump({'grid': grid, 'visitors': list(visitors)}, f, separators=(',', ':'))
    except Exception as e:
        print(f'Save error: {e}')

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_GET(self):
        if self.path == '/wall/state.json':
            data = json.dumps({'grid': grid, 'visitors': list(visitors)}, separators=(',', ':')).encode()
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(data)
        else: self.send_response(404); self.end_headers()

    def do_POST(self):
        if self.path == '/wall/place':
            ip = self.headers.get('X-Real-IP', self.client_address[0])
            now = time.time()
            if ip in last_place and now - last_place[ip] < COOLDOWN:
                self.send_response(429); self.end_headers(); return
            try:
                length = int(self.headers.get('Content-Length', 0))
                body = json.loads(self.rfile.read(length))
                # Support multiple points for smooth drawing
                points = body.get('points', [])
                if not points and 'x' in body: points = [body]
                
                for p in points:
                    x, y, c = int(p['x']), int(p['y']), str(p['c'])[:7]
                    if 0 <= x < GRID and 0 <= y < GRID:
                        grid[y * GRID + x] = c
                
                v = str(body.get('v', ''))[:10]
                if v: visitors.add(v)
                last_place[ip] = now
                save()
                self.send_response(200); self.send_header('Access-Control-Allow-Origin', '*'); self.end_headers()
                self.wfile.write(b'{"ok":true}')
            except: self.send_response(400); self.end_headers()
    def do_OPTIONS(self):
        self.send_response(200); self.send_header('Access-Control-Allow-Origin', '*'); self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS'); self.send_header('Access-Control-Allow-Headers', 'Content-Type'); self.end_headers()

if __name__ == '__main__':
    load()
    HTTPServer(('0.0.0.0', PORT), Handler).serve_forever()
