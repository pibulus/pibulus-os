#!/usr/bin/env python3
"""Drop Zone Upload Server — accepts file uploads via POST"""
import os, time, hashlib, re as _re
from http.server import HTTPServer, BaseHTTPRequestHandler
from email import message_from_bytes

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

        # Parse multipart boundary (replaces removed cgi.FieldStorage for Python 3.13+)
        boundary_match = _re.search(r'boundary=([^\s;]+)', content_type)
        if not boundary_match:
            self.send_error(400, "missing boundary")
            return
        boundary = boundary_match.group(1).encode()

        try:
            length = int(self.headers.get("Content-Length", 0))
            raw = self.rfile.read(length)
            # Parse as email message to extract parts
            msg = message_from_bytes(b"Content-Type: " + content_type.encode() + b"\r\n\r\n" + raw)
            filename = None
            data = None
            for part in msg.get_payload():
                disp = part.get("Content-Disposition", "")
                name_match = _re.search(r'name="([^"]+)"', disp)
                file_match = _re.search(r'filename="([^"]+)"', disp)
                if name_match and name_match.group(1) == "file" and file_match:
                    filename = file_match.group(1)
                    data = part.get_payload(decode=True)
                    break
        except Exception as e:
            self.send_error(400, str(e))
            return

        if not filename or data is None:
            self.send_error(400, "no file field")
            return

        # Check extension
        _, ext = os.path.splitext(filename.lower())
        if ext not in ALLOWED_EXT:
            self.send_response(400)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(f"file type {ext} not allowed".encode())
            return

        if len(data) > MAX_SIZE:
            self.send_response(413)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"file too large (500MB max)")
            return

        # Save with timestamp prefix to avoid collisions
        ts = time.strftime("%Y%m%d-%H%M%S")
        safe_name = "".join(c for c in filename if c.isalnum() or c in "._- ")[:200]
        dest = os.path.join(UPLOAD_DIR, f"{ts}_{safe_name}")
        with open(dest, "wb") as f:
            f.write(data)

        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(f"received {safe_name} ({len(data):,} bytes)".encode())

    def do_GET(self):
        self.send_error(405, "POST only")

    def log_message(self, fmt, *args):
        pass  # quiet

if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", 8085), UploadHandler)
    print("Drop Zone listening on :8085")
    server.serve_forever()
