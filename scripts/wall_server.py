#!/usr/bin/env python3
import json, os, time, threading, socket, subprocess, struct, zlib
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import unquote, urlparse

GRID = 128
WALL_FILE = '/media/pibulus/passport/www/html/wall/state.json'
ARCHIVE_DIR = '/media/pibulus/passport/www/html/wall/archive'
ARCHIVE_MANIFEST = os.path.join(ARCHIVE_DIR, 'manifest.json')
SHOUT_FILE = '/media/pibulus/passport/www/html/msg/shoutbox.json'
PORT = 8086

grid = [None] * (GRID * GRID)
shouts = []
visitors = set()
wall_month = time.strftime('%Y-%m')
dirty_wall = False
dirty_shouts = False
lock = threading.Lock()

def current_month():
    return time.strftime('%Y-%m')

def month_label(month):
    try:
        year, month_num = month.split('-', 1)
        names = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec']
        return f'{names[int(month_num) - 1]} {year}'
    except Exception:
        return month

def clean_grid(value):
    if not isinstance(value, list):
        return [None] * (GRID * GRID)
    return (value + [None] * (GRID * GRID))[:GRID * GRID]

def write_json(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = f'{path}.tmp'
    with open(tmp, 'w') as f:
        json.dump(data, f, separators=(',', ':'))
    os.replace(tmp, path)

def wall_payload():
    return {'grid': grid, 'visitors': sorted(visitors), 'month': wall_month}

def save_wall_locked():
    write_json(WALL_FILE, wall_payload())

def load_archive_manifest():
    try:
        with open(ARCHIVE_MANIFEST) as f:
            data = json.load(f)
        if isinstance(data, dict):
            return data.get('archives', [])
        if isinstance(data, list):
            return data
    except FileNotFoundError:
        pass
    except Exception as e:
        print(f'Archive manifest load error: {e}')
    return []

def save_archive_manifest(entries):
    entries = sorted(entries, key=lambda item: str(item.get('month', '')), reverse=True)
    write_json(ARCHIVE_MANIFEST, {'archives': entries})

def parse_color(color):
    if not isinstance(color, str) or len(color) != 7 or color[0] != '#':
        return (0, 0, 0)
    try:
        return (int(color[1:3], 16), int(color[3:5], 16), int(color[5:7], 16))
    except ValueError:
        return (0, 0, 0)

def png_chunk(kind, data):
    return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data) & 0xffffffff)

def render_png(snapshot_grid):
    raw = bytearray()
    for y in range(GRID):
        raw.append(0)
        row = y * GRID
        for x in range(GRID):
            raw.extend(parse_color(snapshot_grid[row + x]))
    header = struct.pack('>IIBBBBB', GRID, GRID, 8, 2, 0, 0, 0)
    return b'\x89PNG\r\n\x1a\n' + png_chunk(b'IHDR', header) + png_chunk(b'IDAT', zlib.compress(bytes(raw), 9)) + png_chunk(b'IEND', b'')

def archive_wall_locked(month):
    filled = sum(1 for color in grid if color)
    if not filled and not visitors:
        return False

    os.makedirs(ARCHIVE_DIR, exist_ok=True)
    json_name = f'{month}.json'
    png_name = f'{month}.png'
    snapshot = {
        'month': month,
        'label': month_label(month),
        'archived_at': int(time.time()),
        'grid': grid,
        'visitors': sorted(visitors),
        'pixels': filled,
    }

    write_json(os.path.join(ARCHIVE_DIR, json_name), snapshot)
    png_tmp = os.path.join(ARCHIVE_DIR, f'{png_name}.tmp')
    with open(png_tmp, 'wb') as f:
        f.write(render_png(grid))
    os.replace(png_tmp, os.path.join(ARCHIVE_DIR, png_name))

    entry = {
        'month': month,
        'label': month_label(month),
        'png': f'/wall/archive/{png_name}',
        'json': f'/wall/archive/{json_name}',
        'archived_at': snapshot['archived_at'],
        'pixels': filled,
        'visitors': len(visitors),
    }
    entries = [item for item in load_archive_manifest() if item.get('month') != month]
    entries.append(entry)
    save_archive_manifest(entries)
    return True

def maybe_rollover_locked():
    global grid, visitors, wall_month, dirty_wall
    month = current_month()
    if not wall_month:
        wall_month = month
        dirty_wall = True
        return
    if wall_month == month:
        return

    archive_wall_locked(wall_month)
    grid = [None] * (GRID * GRID)
    visitors = set()
    wall_month = month
    save_wall_locked()
    dirty_wall = False

def load():
    global grid, visitors, shouts, wall_month, dirty_wall
    try:
        if os.path.exists(WALL_FILE):
            with open(WALL_FILE) as f:
                data = json.load(f)
                grid = clean_grid(data.get('grid', [None] * (GRID * GRID)))
                visitors = set(data.get('visitors', []))
                wall_month = str(data.get('month') or current_month())[:7]
                if not data.get('month'):
                    dirty_wall = True
        if os.path.exists(SHOUT_FILE):
            with open(SHOUT_FILE) as f:
                shouts = json.load(f)
    except Exception as e: print(f'Load error: {e}')

def save_loop():
    global dirty_wall, dirty_shouts
    while True:
        time.sleep(5)
        with lock:
            maybe_rollover_locked()
            if dirty_wall:
                try:
                    save_wall_locked()
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

    def send_json(self, data):
        body = json.dumps(data, separators=(',', ':')).encode()
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Cache-Control', 'no-cache')
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
    
    def do_GET(self):
        path = urlparse(self.path).path
        if path == '/wall/state.json':
            with lock:
                maybe_rollover_locked()
                data = wall_payload()
            self.send_json(data)
        elif path == '/wall/archive.json':
            self.send_json({'archives': load_archive_manifest()})
        elif path.startswith('/wall/archive/'):
            name = os.path.basename(unquote(path))
            if name.startswith('.') or name != unquote(path).rsplit('/', 1)[-1] or not name.endswith(('.png', '.json')):
                self.send_response(404); self.end_headers(); return
            file_path = os.path.join(ARCHIVE_DIR, name)
            if not os.path.exists(file_path):
                self.send_response(404); self.end_headers(); return
            content_type = 'image/png' if name.endswith('.png') else 'application/json'
            with open(file_path, 'rb') as f:
                data = f.read()
            self.send_response(200)
            self.send_header('Content-Type', content_type)
            self.send_header('Content-Length', str(len(data)))
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Cache-Control', 'public, max-age=86400')
            self.end_headers()
            self.wfile.write(data)
        elif path == '/msg/shouts.json':
            with lock: data = list(shouts)
            self.send_json(data)
        elif path == '/deploy/spawn':
            port = 9000
            while port < 9100:
                try:
                    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                        s.bind(('0.0.0.0', port))
                    break
                except: port += 1
            subprocess.Popen(f'/usr/local/bin/ttyd -p {port} -O -W bash /home/pibulus/pibulus-os/scripts/deploy.sh', shell=True)
            self.send_json({'url': f'http://pibulus.local:{port}'})
        else: self.send_response(404); self.end_headers()

    def do_POST(self):
        global dirty_wall, dirty_shouts
        try:
            path = urlparse(self.path).path
            length = int(self.headers.get('Content-Length', 0))
            body = json.loads(self.rfile.read(length))
            if path == '/wall/place':
                with lock:
                    maybe_rollover_locked()
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
            elif path == '/msg/shout':
                with lock:
                    shouts.append({'n': str(body['n'])[:20], 'm': str(body['m'])[:200], 't': int(time.time())})
                    dirty_shouts = True
                self.send_response(200); self.send_header('Access-Control-Allow-Origin', '*'); self.end_headers(); self.wfile.write(b'{"ok":true}')
        except Exception as e:
            print(f'POST error: {e}')
            self.send_response(400); self.end_headers()

if __name__ == '__main__':
    load()
    with lock:
        maybe_rollover_locked()
    threading.Thread(target=save_loop, daemon=True).start()
    HTTPServer(('0.0.0.0', PORT), Handler).serve_forever()
