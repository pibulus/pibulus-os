#!/usr/bin/env python3
"""
🔗 PIBULUS URL SHORTENER — go.quickcat.club
Tiny, self-hosted, JSON-backed URL shortener.
Pattern: systemd service + nginx proxy (like dropzone, wall, msgdrop)

Endpoints:
  POST /shorten  {"url": "https://...", "slug": "optional-custom-slug"}
  GET  /:slug    → 302 redirect to original URL
  GET  /links    → JSON list of all shortened URLs
  GET  /stats    → Basic stats

Storage: /home/pibulus/pibulus-os/data/shortener.json
Port: 8088
"""

import json
import hashlib
import os
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse
from datetime import datetime

PORT = 8088
DATA_DIR = os.path.expanduser("~/pibulus-os/data")
DATA_FILE = os.path.join(DATA_DIR, "shortener.json")

def load_links():
    if os.path.exists(DATA_FILE):
        with open(DATA_FILE) as f:
            return json.load(f)
    return {}

def save_links(links):
    os.makedirs(DATA_DIR, exist_ok=True)
    with open(DATA_FILE, "w") as f:
        json.dump(links, f, indent=2)

def make_slug(url):
    """Generate a short hash slug from the URL."""
    h = hashlib.sha256(url.encode()).hexdigest()[:6]
    return h

class ShortHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Quiet logging
        pass

    def send_json(self, data, code=200):
        body = json.dumps(data, indent=2).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_GET(self):
        path = self.path.strip("/")

        if path == "links":
            links = load_links()
            result = []
            for slug, data in links.items():
                result.append({
                    "slug": slug,
                    "url": data["url"],
                    "created": data.get("created", "?"),
                    "hits": data.get("hits", 0)
                })
            self.send_json(result)
            return

        if path == "stats":
            links = load_links()
            total_hits = sum(d.get("hits", 0) for d in links.values())
            self.send_json({
                "total_links": len(links),
                "total_hits": total_hits
            })
            return

        if path == "" or path == "index.html":
            # Serve a tiny management UI
            html = LANDING_HTML.encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.send_header("Content-Length", str(len(html)))
            self.end_headers()
            self.wfile.write(html)
            return

        # Redirect
        links = load_links()
        if path in links:
            links[path]["hits"] = links[path].get("hits", 0) + 1
            save_links(links)
            self.send_response(302)
            self.send_header("Location", links[path]["url"])
            self.end_headers()
            return

        self.send_json({"error": "Not found"}, 404)

    def do_POST(self):
        path = self.path.strip("/")

        if path == "shorten":
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length)
            try:
                data = json.loads(body)
            except json.JSONDecodeError:
                self.send_json({"error": "Invalid JSON"}, 400)
                return

            url = data.get("url", "").strip()
            if not url:
                self.send_json({"error": "Missing url"}, 400)
                return

            # Basic URL validation
            parsed = urlparse(url)
            if not parsed.scheme:
                url = "https://" + url

            slug = data.get("slug", "").strip()
            if not slug:
                slug = make_slug(url)

            # Sanitize slug
            slug = slug.lower().replace(" ", "-")
            slug = "".join(c for c in slug if c.isalnum() or c == "-")[:32]

            links = load_links()
            links[slug] = {
                "url": url,
                "created": datetime.now().isoformat(),
                "hits": 0
            }
            save_links(links)

            self.send_json({
                "slug": slug,
                "short_url": f"/{slug}",
                "original": url
            }, 201)
            return

        self.send_json({"error": "Not found"}, 404)

LANDING_HTML = """<!DOCTYPE html>
<html>
<head>
<title>go.quickcat.club</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:system-ui,-apple-system,sans-serif;background:#0f0f1a;color:#e0e0e0;min-height:100vh;display:flex;flex-direction:column;align-items:center;padding:2rem 1rem}
h1{color:#e94560;font-size:2rem;margin-bottom:.5rem}
.sub{color:#666;margin-bottom:2rem;font-size:.9rem}
.card{background:#16213e;border:2px solid #e94560;border-radius:12px;padding:1.5rem;width:100%;max-width:500px;margin-bottom:1.5rem}
input,button{font-size:1rem;padding:.75rem 1rem;border-radius:8px;border:2px solid #333;background:#0f0f1a;color:#e0e0e0;width:100%;margin-bottom:.75rem;outline:none}
input:focus{border-color:#e94560}
button{background:#e94560;border-color:#e94560;color:#fff;cursor:pointer;font-weight:bold}
button:hover{background:#c73a52}
.result{background:#0a3d2e;border:2px solid #2ecc71;border-radius:8px;padding:1rem;margin-top:1rem;word-break:break-all;display:none}
.result a{color:#2ecc71}
.links{max-height:300px;overflow-y:auto}
.link{display:flex;justify-content:space-between;align-items:center;padding:.5rem 0;border-bottom:1px solid #222}
.link a{color:#e94560;text-decoration:none}
.link .hits{color:#666;font-size:.8rem}
.link .url{color:#888;font-size:.8rem;max-width:250px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
</style>
</head>
<body>
<h1>go.quickcat.club</h1>
<p class="sub">pibulus url shortener</p>

<div class="card">
  <input type="url" id="url" placeholder="Paste a long URL..." />
  <input type="text" id="slug" placeholder="Custom slug (optional)" />
  <button onclick="shorten()">Shorten</button>
  <div class="result" id="result">
    <a id="short-link" href="#" target="_blank"></a>
  </div>
</div>

<div class="card">
  <h3 style="margin-bottom:1rem;color:#e94560">Recent Links</h3>
  <div class="links" id="links">Loading...</div>
</div>

<script>
const BASE = window.location.origin;
async function shorten(){
  const url = document.getElementById('url').value;
  const slug = document.getElementById('slug').value;
  if(!url) return;
  const res = await fetch(BASE+'/shorten',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({url,slug})});
  const data = await res.json();
  const link = document.getElementById('short-link');
  link.href = BASE+'/'+data.slug;
  link.textContent = BASE+'/'+data.slug;
  document.getElementById('result').style.display='block';
  document.getElementById('url').value='';
  document.getElementById('slug').value='';
  loadLinks();
}
async function loadLinks(){
  const res = await fetch(BASE+'/links');
  const links = await res.json();
  const el = document.getElementById('links');
  el.innerHTML = links.sort((a,b)=>b.created.localeCompare(a.created)).map(l=>
    '<div class="link"><div><a href="'+BASE+'/'+l.slug+'">'+BASE+'/'+l.slug+'</a><div class="url">'+l.url+'</div></div><div class="hits">'+l.hits+' hits</div></div>'
  ).join('');
}
loadLinks();
</script>
</body>
</html>"""

if __name__ == "__main__":
    os.makedirs(DATA_DIR, exist_ok=True)
    server = HTTPServer(("0.0.0.0", PORT), ShortHandler)
    print(f"🔗 URL Shortener running on port {PORT}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down.")
        server.server_close()
