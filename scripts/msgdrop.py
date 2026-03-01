#!/usr/bin/env python3
"""Message Drop — tiny request/message backend for quickcat.club
POST /msg/drop — leave a message (rate limited)
GET /msg/inbox — admin view (returns all messages)
POST /msg/dismiss — mark a message as read
"""

import json, os, time, uuid
from http.server import HTTPServer, BaseHTTPRequestHandler

MSG_FILE = '/media/pibulus/passport/www/html/msg/inbox.json'
PORT = 8087
COOLDOWN = 30  # seconds per IP
MAX_MSG_LEN = 500
MAX_MESSAGES = 200

messages = []
last_post = {}  # ip -> timestamp

def load():
    global messages
    try:
        with open(MSG_FILE) as f:
            messages = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        messages = []

def save():
    os.makedirs(os.path.dirname(MSG_FILE), exist_ok=True)
    with open(MSG_FILE, 'w') as f:
        json.dump(messages, f, indent=2)

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *a): pass

    def _cors(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')

    def do_OPTIONS(self):
        self.send_response(200)
        self._cors()
        self.end_headers()

    def do_POST(self):
        if self.path == '/msg/drop':
            ip = self.headers.get('X-Real-IP', self.client_address[0])
            now = time.time()

            if ip in last_post and now - last_post[ip] < COOLDOWN:
                self.send_response(429)
                self._cors()
                self.end_headers()
                self.wfile.write(b'{"error":"easy tiger. wait a bit."}')
                return

            try:
                length = int(self.headers.get('Content-Length', 0))
                body = json.loads(self.rfile.read(length))
                text = str(body.get('msg', '')).strip()[:MAX_MSG_LEN]
                name = str(body.get('name', '')).strip()[:30] or 'anon'

                if not text or len(text) < 2:
                    self.send_response(400)
                    self._cors()
                    self.end_headers()
                    self.wfile.write(b'{"error":"say something"}')
                    return

                msg = {
                    'id': str(uuid.uuid4())[:8],
                    'name': name,
                    'msg': text,
                    'ts': int(now),
                    'ip': ip,
                    'read': False
                }
                messages.insert(0, msg)

                # Cap at max
                while len(messages) > MAX_MESSAGES:
                    messages.pop()

                last_post[ip] = now
                save()

                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self._cors()
                self.end_headers()
                self.wfile.write(b'{"ok":true}')

            except (ValueError, KeyError, json.JSONDecodeError):
                self.send_response(400)
                self._cors()
                self.end_headers()

        elif self.path == '/msg/dismiss':
            try:
                length = int(self.headers.get('Content-Length', 0))
                body = json.loads(self.rfile.read(length))
                msg_id = str(body.get('id', ''))
                for m in messages:
                    if m['id'] == msg_id:
                        m['read'] = True
                        save()
                        break
                self.send_response(200)
                self._cors()
                self.end_headers()
                self.wfile.write(b'{"ok":true}')
            except:
                self.send_response(400)
                self._cors()
                self.end_headers()
        else:
            self.send_response(404)
            self.end_headers()

    def do_GET(self):
        if self.path == '/msg/inbox':
            data = json.dumps(messages).encode()
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self._cors()
            self.send_header('Cache-Control', 'no-cache')
            self.end_headers()
            self.wfile.write(data)
        elif self.path == '/msg/count':
            unread = sum(1 for m in messages if not m.get('read'))
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self._cors()
            self.end_headers()
            self.wfile.write(json.dumps({'unread': unread, 'total': len(messages)}).encode())
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == '__main__':
    load()
    print(f'Message Drop listening on port {PORT}')
    print(f'Messages: {len(messages)} ({sum(1 for m in messages if not m.get("read"))} unread)')
    HTTPServer(('0.0.0.0', PORT), Handler).serve_forever()
