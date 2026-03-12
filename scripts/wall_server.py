#!/usr/bin/env python3
import json, os, time, threading, socket, subprocess
from http.server import HTTPServer, BaseHTTPRequestHandler

GRID = 128
WALL_FILE = '/media/pibulus/passport/www/html/wall/state.json'
SHOUT_FILE = '/media/pibulus/passport/www/html/msg/shoutbox.json'
PORT = 8086

grid = [None] * (GRID * GRID)
shouts = []
visitors = set()
dirty_wall = False
dirty_shouts = False
lock = threading.Lock()

def load():
    global grid, visitors, shouts
    try:
        if os.path.exists(WALL_FILE):
            with open(WALL_FILE) as f:
                data = json.load(f)
                grid = data.get('grid', [None] * (GRID * GRID))
                visitors = set(data.get('visitors', []))
        if os.path.exists(SHOUT_FILE):
            with open(SHOUT_FILE) as f:
                shouts = json.load(f)
    except Exception as e: print(f'Load error: {e}')

def save_loop():
    global dirty_wall, dirty_shouts
    while True:
        time.sleep(5)
        with lock:
            if dirty_wall:
                try:
                    with open(WALL_FILE, 'w') as f:
                        json.dump({'grid': grid, 'visitors': list(visitors)}, f, separators=(',', ':'))
                    dirty_wall = False
                except Exception as e: print(f'Wall save error: {e}')
            if dirty_shouts:
                try:
                    with open(SHOUT_FILE, 'w') as f:
                        json.dump(shouts[-50:], f, separators=(',', ':'))
                    dirty_shouts = False
                except Exception as e: print(f'Shout save error: {e}')

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
    
    def do_GET(self):
        if self.path == '/wall/state.json':
            with lock: data = json.dumps({'grid': grid, 'visitors': list(visitors)}, separators=(',', ':')).encode()
            self.send_response(200); self.send_header('Content-Type', 'application/json'); self.send_header('Access-Control-Allow-Origin', '*'); self.end_headers(); self.wfile.write(data)
        elif self.path == '/msg/shouts.json':
            with lock: data = json.dumps(shouts, separators=(',', ':')).encode()
            self.send_response(200); self.send_header('Content-Type', 'application/json'); self.send_header('Access-Control-Allow-Origin', '*'); self.end_headers(); self.wfile.write(data)
        elif self.path == '/deploy/spawn':
            port = 9000
            while port < 9100:
                try:
                    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                        s.bind(('0.0.0.0', port))
                    break
                except: port += 1
            subprocess.Popen(f'/usr/local/bin/ttyd -p {port} -O -W bash /home/pibulus/pibulus-os/scripts/deploy.sh', shell=True)
            self.send_response(200); self.send_header('Content-Type', 'application/json'); self.send_header('Access-Control-Allow-Origin', '*'); self.end_headers(); self.wfile.write(json.dumps({'url': f'http://pibulus.local:{port}'}).encode())
        else: self.send_response(404); self.end_headers()

    def do_POST(self):
        global dirty_wall, dirty_shouts
        try:
            length = int(self.headers.get('Content-Length', 0))
            body = json.loads(self.rfile.read(length))
            if self.path == '/wall/place':
                with lock:
                    points = body.get('points', [body])
                    for p in points:
                        try:
                            x, y, c = int(p['x']), int(p['y']), str(p['c'])[:7]
                            if 0 <= x < GRID and 0 <= y < GRID: grid[y * GRID + x] = c
                        except: continue
                    v = str(body.get('v', ''))[:10]
                    if v: visitors.add(v)
                    dirty_wall = True
                self.send_response(200); self.send_header('Access-Control-Allow-Origin', '*'); self.end_headers(); self.wfile.write(b'{"ok":true}')
            elif self.path == '/msg/shout':
                with lock:
                    shouts.append({'n': str(body['n'])[:20], 'm': str(body['m'])[:200], 't': int(time.time())})
                    dirty_shouts = True
                self.send_response(200); self.send_header('Access-Control-Allow-Origin', '*'); self.end_headers(); self.wfile.write(b'{"ok":true}')
        except Exception as e:
            print(f'POST error: {e}')
            self.send_response(400); self.end_headers()

if __name__ == '__main__':
    load()
    threading.Thread(target=save_loop, daemon=True).start()
    HTTPServer(('0.0.0.0', PORT), Handler).serve_forever()
