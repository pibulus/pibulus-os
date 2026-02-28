#!/usr/bin/env python3
"""Drop Zone Upload Server — accepts file uploads via POST"""
import os, time, hashlib
from http.server import HTTPServer, BaseHTTPRequestHandler
import cgi

UPLOAD_DIR = "/media/pibulus/passport/Drops"
MAX_SIZE = 500 * 1024 * 1024  # 500MB
ALLOWED_EXT = {
    '.mp3','.flac','.ogg','.wav','.aac','.m4a',  # audio
    '.cbz','.cbr','.pdf','.epub','.mobi',          # books/comics
    '.zip','.7z','.rar','.tar.gz',                  # archives
    '.rom','.bin','.smc','.sfc','.nes','.gba','.gb','.gbc','.n64','.z64','.md','.gen',  # ROMs
    '.jpg','.jpeg','.png','.gif','.webp',           # images
}

os.makedirs(UPLOAD_DIR, exist_ok=True)

class UploadHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path != "/drop/upload":
            self.send_error(404)
            return

        content_type = self.headers.get("Content-Type", "")
        if "multipart/form-data" not in content_type:
            self.send_error(400, "multipart/form-data required")
            return

        try:
            form = cgi.FieldStorage(
                fp=self.rfile,
                headers=self.headers,
                environ={"REQUEST_METHOD": "POST", "CONTENT_TYPE": content_type}
            )
        except Exception as e:
            self.send_error(400, str(e))
            return

        if "file" not in form:
            self.send_error(400, "no file field")
            return

        item = form["file"]
        if not item.filename:
            self.send_error(400, "no filename")
            return

        # Check extension
        _, ext = os.path.splitext(item.filename.lower())
        if ext not in ALLOWED_EXT:
            self.send_response(400)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(f"file type {ext} not allowed".encode())
            return

        # Read file with size limit
        data = item.file.read(MAX_SIZE + 1)
        if len(data) > MAX_SIZE:
            self.send_response(413)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"file too large (500MB max)")
            return

        # Save with timestamp prefix to avoid collisions
        ts = time.strftime("%Y%m%d-%H%M%S")
        safe_name = "".join(c for c in item.filename if c.isalnum() or c in "._- ")[:200]
        dest = os.path.join(UPLOAD_DIR, f"{ts}_{safe_name}")
        with open(dest, "wb") as f:
            f.write(data)

        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(f"received {safe_name} ({len(data)} bytes)".encode())

    def do_GET(self):
        self.send_error(405, "POST only")

    def log_message(self, fmt, *args):
        pass  # quiet

if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", 8085), UploadHandler)
    print("Drop Zone listening on :8085")
    server.serve_forever()
