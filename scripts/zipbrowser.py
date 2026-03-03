#!/usr/bin/env python3
"""
Zip Browser - Browse and download files from zip archives without extracting.
Reads zip central directory (fast, no extraction) and serves individual files on demand.

Usage:
  python3 zipbrowser.py                    # Serve on port 8089
  python3 zipbrowser.py --port 8090        # Custom port

Serves a JSON API + simple HTML frontend.
"""

import os, sys, json, zipfile, io, mimetypes, argparse
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import unquote, quote, urlparse, parse_qs

# Zip files to serve - add paths here
ZIP_FILES = {
    "base": "/media/pibulus/passport/tiny-best-set-go-games.zip",
    "expansion": "/media/pibulus/passport/tiny-best-set-go-expansion-128-games.zip",
}

# Cache zip file listings (central directory only, no extraction)
_listing_cache = {}

def get_listing(zip_id):
    """Read zip central directory and cache it. Fast - doesn't extract anything."""
    if zip_id in _listing_cache:
        return _listing_cache[zip_id]

    path = ZIP_FILES.get(zip_id)
    if not path or not os.path.exists(path):
        return None

    entries = []
    try:
        with zipfile.ZipFile(path, 'r') as zf:
            for info in zf.infolist():
                entries.append({
                    "name": info.filename,
                    "size": info.file_size,
                    "compressed": info.compress_size,
                    "is_dir": info.is_dir(),
                })
    except Exception as e:
        print(f"Error reading {path}: {e}")
        return None

    _listing_cache[zip_id] = entries
    return entries


def browse_path(zip_id, subpath):
    """List entries at a specific directory level within the zip."""
    entries = get_listing(zip_id)
    if entries is None:
        return None

    # Normalize subpath
    subpath = subpath.strip('/')
    prefix = subpath + '/' if subpath else ''

    seen_dirs = set()
    results = []

    for e in entries:
        name = e["name"]
        if not name.startswith(prefix):
            continue

        # Get the relative part after prefix
        relative = name[len(prefix):]
        if not relative or relative == '/':
            continue

        parts = relative.split('/')
        # Direct child file
        if len(parts) == 1 and not e["is_dir"]:
            results.append({
                "name": parts[0],
                "size": e["size"],
                "type": "file",
            })
        # Direct child directory (or file nested deeper implying a dir)
        elif len(parts) >= 1:
            dirname = parts[0]
            if dirname and dirname not in seen_dirs:
                seen_dirs.add(dirname)
                results.append({
                    "name": dirname,
                    "type": "directory",
                })

    # Sort: directories first, then files, alphabetically
    results.sort(key=lambda x: (0 if x["type"] == "directory" else 1, x["name"].lower()))
    return results


def extract_file(zip_id, filepath):
    """Extract a single file from the zip into memory."""
    path = ZIP_FILES.get(zip_id)
    if not path or not os.path.exists(path):
        return None, None

    try:
        with zipfile.ZipFile(path, 'r') as zf:
            data = zf.read(filepath)
            mime = mimetypes.guess_type(filepath)[0] or 'application/octet-stream'
            return data, mime
    except (KeyError, Exception) as e:
        print(f"Extract error: {e}")
        return None, None


class ZipBrowserHandler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        # Quieter logging
        pass

    def do_GET(self):
        parsed = urlparse(self.path)
        path = unquote(parsed.path)
        params = parse_qs(parsed.query)

        # API: list zip archives
        if path == '/api/zips':
            data = []
            for zid, zpath in ZIP_FILES.items():
                exists = os.path.exists(zpath)
                size = os.path.getsize(zpath) if exists else 0
                data.append({"id": zid, "path": zpath, "exists": exists, "size": size})
            self.json_response(data)
            return

        # API: browse a zip
        if path.startswith('/api/browse/'):
            parts = path[len('/api/browse/'):].split('/', 1)
            zip_id = parts[0]
            subpath = parts[1] if len(parts) > 1 else ''
            result = browse_path(zip_id, subpath)
            if result is None:
                self.error_response(404, "Zip not found")
            else:
                self.json_response(result)
            return

        # API: download a file from zip
        if path.startswith('/api/download/'):
            rest = path[len('/api/download/'):]
            parts = rest.split('/', 1)
            zip_id = parts[0]
            filepath = parts[1] if len(parts) > 1 else ''
            data, mime = extract_file(zip_id, filepath)
            if data is None:
                self.error_response(404, "File not found in zip")
            else:
                filename = os.path.basename(filepath)
                self.send_response(200)
                self.send_header('Content-Type', mime)
                self.send_header('Content-Length', str(len(data)))
                self.send_header('Content-Disposition', f'attachment; filename="{filename}"')
                self.end_headers()
                self.wfile.write(data)
            return

        # Serve the HTML frontend
        if path == '/' or path == '/index.html' or path == '/roms' or path == '/roms/':
            self.send_response(200)
            self.send_header('Content-Type', 'text/html')
            self.end_headers()
            self.wfile.write(HTML_PAGE.encode())
            return

        self.error_response(404, "Not found")

    def json_response(self, data):
        body = json.dumps(data).encode()
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def error_response(self, code, msg):
        body = json.dumps({"error": msg}).encode()
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(body)


HTML_PAGE = r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ROM Vault - quickcat.club</title>
  <link href="https://fonts.googleapis.com/css2?family=VT323&display=swap" rel="stylesheet">
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    :root {
      --bg: #050505;
      --accent: #ff6644;
      --accent-dim: rgba(255,102,68,0.3);
      --text: #e0e0e0;
      --dim: #888;
      --dim-soft: #555;
      --panel: rgba(0,0,0,0.6);
      --border: rgba(255,102,68,0.2);
    }
    html { scrollbar-color: var(--accent) var(--bg); scrollbar-width: thin; }
    body {
      background: var(--bg);
      color: var(--text);
      font-family: 'VT323', monospace;
      font-size: 20px;
      line-height: 1.6;
      min-height: 100vh;
    }
    body::before {
      content: '';
      position: fixed; inset: 0;
      background: repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(0,0,0,0.12) 2px, rgba(0,0,0,0.12) 4px);
      pointer-events: none; z-index: 999;
    }
    .wrapper {
      position: relative; z-index: 1;
      max-width: 880px; margin: 0 auto; padding: 2rem 1.5rem 4rem;
    }
    .back { color: var(--dim); text-decoration: none; font-size: 1rem; }
    .back:hover { color: var(--accent); }
    header { text-align: center; padding: 2rem 0 1rem; }
    h1 {
      font-size: clamp(2.5rem, 8vw, 4rem);
      color: var(--accent);
      text-shadow: 0 0 10px var(--accent), 0 0 30px rgba(255,102,68,0.3);
      letter-spacing: 4px; line-height: 1;
    }
    .subtitle { color: var(--dim); font-size: 1.1rem; margin-top: 0.5rem; letter-spacing: 2px; }
    .intro {
      text-align: center; color: var(--dim-soft); font-size: 0.95rem;
      max-width: 600px; margin: 0.75rem auto 0; line-height: 1.5;
    }
    .zip-picker {
      display: flex; gap: 8px; justify-content: center; margin: 1.5rem 0;
      flex-wrap: wrap;
    }
    .zip-btn {
      background: var(--panel);
      border: 1px solid var(--border);
      color: var(--text);
      font-family: inherit; font-size: 1rem;
      padding: 10px 20px; cursor: pointer;
      transition: all 0.15s;
      letter-spacing: 2px;
    }
    .zip-btn:hover, .zip-btn.active {
      border-color: var(--accent);
      color: var(--accent);
      background: rgba(255,102,68,0.06);
    }
    .zip-btn .zip-size { font-size: 0.8rem; color: var(--dim); display: block; }
    .breadcrumbs {
      display: flex; flex-wrap: wrap; gap: 4px; align-items: center;
      margin: 1rem 0 0.5rem; font-size: 0.95rem; color: var(--dim);
    }
    .breadcrumbs a { color: var(--accent); text-decoration: none; cursor: pointer; }
    .breadcrumbs a:hover { text-decoration: underline; }
    .breadcrumbs .sep { color: var(--dim-soft); margin: 0 2px; }
    .count { font-size: 0.85rem; color: var(--dim); letter-spacing: 1px; margin: 0.5rem 0; text-align: right; }
    .file-list { display: flex; flex-direction: column; gap: 4px; }
    .file-item {
      display: flex; align-items: center; gap: 12px;
      padding: 14px 16px;
      background: var(--panel);
      border: 1px solid var(--border);
      border-left: 3px solid transparent;
      text-decoration: none;
      color: var(--text);
      transition: all 0.15s ease;
      cursor: pointer;
    }
    .file-item:hover {
      border-left-color: var(--accent);
      background: rgba(255,102,68,0.04);
    }
    .file-icon { font-size: 1.5rem; flex-shrink: 0; width: 2rem; text-align: center; }
    .file-info { flex: 1; min-width: 0; }
    .file-name { font-size: 1.15rem; line-height: 1.3; }
    .file-meta { font-size: 0.85rem; color: var(--dim); }
    .file-action {
      font-size: 0.85rem; color: var(--accent); letter-spacing: 2px;
      flex-shrink: 0; opacity: 0; transition: opacity 0.15s;
    }
    .file-item:hover .file-action { opacity: 1; }
    .loading { text-align: center; color: var(--dim); padding: 2rem 0; }
    footer { text-align: center; margin-top: 3rem; padding-top: 1rem; border-top: 1px solid rgba(255,102,68,0.1); }
    .footer-text { color: var(--dim-soft); font-size: 0.9rem; letter-spacing: 2px; }
    @media (max-width: 560px) {
      .file-name { font-size: 1rem; }
      .file-action { opacity: 1; }
    }
  </style>
</head>
<body>
  <div class="wrapper">
    <a href="/" class="back">&larr; quickcat.club</a>
    <header>
      <h1>ROM Vault</h1>
      <p class="subtitle">tiny best set go</p>
      <p class="intro">browse and download individual ROMs straight from the archive. no extraction needed, no waiting.</p>
    </header>

    <div class="zip-picker" id="zipPicker"></div>
    <div class="breadcrumbs" id="breadcrumbs"></div>
    <div class="count" id="itemCount"></div>
    <div class="file-list" id="items"><div class="loading">loading archives...</div></div>

    <footer>
      <p class="footer-text">press start</p>
    </footer>
  </div>
  <script>
    var currentZip = '';
    var currentPath = '';
    var zipMeta = {};
    var API = window.location.port === '8089'
      ? ''
      : window.location.origin.replace(window.location.port, '8089');

    // Detect if we're behind the proxy
    if (window.location.pathname.startsWith('/roms')) {
      API = '';  // Same origin, proxied
    }

    function sizeStr(bytes) {
      if (!bytes) return '';
      if (bytes > 1073741824) return (bytes/1073741824).toFixed(1) + ' GB';
      if (bytes > 1048576) return (bytes/1048576).toFixed(0) + ' MB';
      if (bytes > 1024) return (bytes/1024).toFixed(0) + ' KB';
      return bytes + ' B';
    }

    function iconFor(name) {
      var n = name.toLowerCase();
      if (n.endsWith('.zip') || n.endsWith('.7z') || n.endsWith('.rar')) return '\u{1F4E6}';
      if (n.endsWith('.bin') || n.endsWith('.cue') || n.endsWith('.iso')) return '\u{1F4BF}';
      if (n.endsWith('.png') || n.endsWith('.jpg') || n.endsWith('.bmp')) return '\u{1F5BC}';
      if (n.endsWith('.txt') || n.endsWith('.nfo') || n.endsWith('.md')) return '\u{1F4C4}';
      return '\u{1F3AE}';
    }

    function cleanRomName(name) {
      return name
        .replace(/\.(zip|7z|rar|bin|cue|iso|nes|snes|smc|sfc|gb|gbc|gba|nds|n64|z64|gen|md|smd|32x|gg|sms|pce|tg16|col|sg|ngp|ngc|ws|wsc|a26|a52|a78|lnx|jag|vb|vec)$/i, '')
        .replace(/\s*\(.*?\)/g, '')
        .replace(/\s*\[.*?\]/g, '')
        .trim() || name;
    }

    function renderBreadcrumbs() {
      var bc = document.getElementById('breadcrumbs');
      if (!currentPath) {
        bc.innerHTML = currentZip ? '<span style="color:var(--accent)">' + (zipMeta[currentZip] || currentZip) + '</span>' : '';
        return;
      }
      var parts = currentPath.split('/').filter(Boolean);
      var html = '<a onclick="navigate(\'\')">Root</a>';
      var accumulated = '';
      for (var i = 0; i < parts.length; i++) {
        accumulated += (accumulated ? '/' : '') + parts[i];
        html += '<span class="sep">/</span>';
        if (i === parts.length - 1) {
          html += '<span>' + parts[i] + '</span>';
        } else {
          var p = accumulated;
          html += '<a onclick="navigate(\'' + p.replace(/'/g, "\\'") + '\')">' + parts[i] + '</a>';
        }
      }
      bc.innerHTML = html;
    }

    function navigate(path) {
      currentPath = path;
      renderBreadcrumbs();
      loadDir();
    }

    function selectZip(zipId) {
      currentZip = zipId;
      currentPath = '';
      document.querySelectorAll('.zip-btn').forEach(function(b) {
        b.classList.toggle('active', b.dataset.id === zipId);
      });
      renderBreadcrumbs();
      loadDir();
    }

    function loadDir() {
      if (!currentZip) return;
      var list = document.getElementById('items');
      list.innerHTML = '<div class="loading">reading archive...</div>';
      document.getElementById('itemCount').textContent = '';

      var url = API + '/api/browse/' + encodeURIComponent(currentZip);
      if (currentPath) url += '/' + currentPath.split('/').map(encodeURIComponent).join('/');

      fetch(url)
        .then(function(r) { return r.json(); })
        .then(function(entries) {
          list.innerHTML = '';
          document.getElementById('itemCount').textContent = entries.length + ' items';

          entries.forEach(function(e) {
            var isDir = e.type === 'directory';
            var a = document.createElement('a');
            a.className = 'file-item';

            if (isDir) {
              var newPath = currentPath ? currentPath + '/' + e.name : e.name;
              a.onclick = function() { navigate(newPath); };
            } else {
              var filePath = currentPath ? currentPath + '/' + e.name : e.name;
              a.href = API + '/api/download/' + encodeURIComponent(currentZip) + '/' + filePath.split('/').map(encodeURIComponent).join('/');
            }

            a.innerHTML =
              '<span class="file-icon">' + (isDir ? '\u{1F4C1}' : iconFor(e.name)) + '</span>' +
              '<span class="file-info">' +
                '<span class="file-name">' + (isDir ? e.name : cleanRomName(e.name)) + '</span>' +
                '<span class="file-meta">' + (isDir ? 'folder' : sizeStr(e.size)) + '</span>' +
              '</span>' +
              '<span class="file-action">' + (isDir ? 'BROWSE' : 'GET') + '</span>';
            list.appendChild(a);
          });
        })
        .catch(function() {
          list.innerHTML = '<div class="loading">could not read archive</div>';
        });
    }

    // Init: load available zips
    fetch(API + '/api/zips')
      .then(function(r) { return r.json(); })
      .then(function(zips) {
        var picker = document.getElementById('zipPicker');
        var labels = { base: 'Base Set', expansion: 'Expansion 128' };
        zips.forEach(function(z) {
          if (!z.exists) return;
          zipMeta[z.id] = labels[z.id] || z.id;
          var btn = document.createElement('button');
          btn.className = 'zip-btn';
          btn.dataset.id = z.id;
          btn.innerHTML = (labels[z.id] || z.id) + '<span class="zip-size">' + sizeStr(z.size) + '</span>';
          btn.onclick = function() { selectZip(z.id); };
          picker.appendChild(btn);
        });
        document.getElementById('items').innerHTML = '<div class="loading">select an archive above</div>';
      });
  </script>
</body>
</html>
'''


def main():
    parser = argparse.ArgumentParser(description="Zip Browser - serve files from zip archives")
    parser.add_argument("--port", "-p", type=int, default=8089, help="Port to serve on")
    parser.add_argument("--host", default="0.0.0.0", help="Host to bind to")
    args = parser.parse_args()

    # Pre-cache listings on startup
    print(f"Zip Browser starting on port {args.port}")
    for zid, zpath in ZIP_FILES.items():
        if os.path.exists(zpath):
            print(f"  Indexing {zid}: {zpath}")
            listing = get_listing(zid)
            if listing:
                print(f"    {len(listing)} entries cached")
        else:
            print(f"  SKIP {zid}: {zpath} not found")

    server = HTTPServer((args.host, args.port), ZipBrowserHandler)
    print(f"\n  ROM Vault live at http://localhost:{args.port}/")
    print(f"  Press Ctrl+C to stop\n")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n  Shutting down...")
        server.shutdown()


if __name__ == "__main__":
    main()
