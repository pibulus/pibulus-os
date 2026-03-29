#!/usr/bin/env python3
"""Drop Zone Upload Server — accepts file uploads via POST
   Python 3.13 compatible (no cgi module)
   Crash-resistant with proper error handling"""
import os, time, re, traceback
from http.server import HTTPServer, BaseHTTPRequestHandler

UPLOAD_DIR = "/media/pibulus/passport/Drops"
MAX_SIZE = 500 * 1024 * 1024  # 500MB
ALLOWED_EXT = {
    '.mp3','.flac','.ogg','.wav','.aac','.m4a',
    '.cbz','.cbr','.pdf','.epub','.mobi',
    '.zip','.7z','.rar','.tar.gz',
    '.rom','.bin','.smc','.sfc','.nes','.gba','.gb','.gbc','.n64','.z64','.md','.gen',
    '.jpg','.jpeg','.png','.gif','.webp',
    '.mp4','.mkv','.avi','.p8.png',
}

os.makedirs(UPLOAD_DIR, exist_ok=True)

def parse_multipart(rfile, content_type, content_length):
    """Parse multipart form data without cgi module."""
    boundary_match = re.search(r'boundary=([^\s;]+)', content_type)
    if not boundary_match:
        return None, None
    boundary = boundary_match.group(1).encode()

    data = rfile.read(min(content_length, MAX_SIZE + 1))

    parts = data.split(b'--' + boundary)
    for part in parts:
        if b'Content-Disposition' not in part:
            continue

        header_end = part.find(b'\r\n\r\n')
        if header_end < 0:
            continue
        headers = part[:header_end].decode('utf-8', errors='replace')
        body = part[header_end + 4:]

        if body.endswith(b'\r\n'):
            body = body[:-2]

        fn_match = re.search(r'filename="([^"]+)"', headers)
        if fn_match and 'name="file"' in headers:
            return fn_match.group(1), body
    return None, None

class UploadHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        try:
            if self.path != "/drop/upload":
                self.send_error(404)
                return

            content_type = self.headers.get("Content-Type", "")
            if "multipart/form-data" not in content_type:
                self.send_error(400, "multipart/form-data required")
                return

            content_length = int(self.headers.get("Content-Length", 0))
            if content_length > MAX_SIZE + 4096:
                self.send_response(413)
                self.send_header("Content-Type", "text/plain")
                self.end_headers()
                self.wfile.write(b"file too large (500MB max)")
                return

            filename, file_data = parse_multipart(self.rfile, content_type, content_length)

            if not filename or not file_data:
                self.send_error(400, "no file found in upload")
                return

            # Check extension (handle compound like .p8.png, .tar.gz)
            lower = filename.lower()
            ext = None
            for compound in ['.tar.gz', '.p8.png']:
                if lower.endswith(compound):
                    ext = compound
                    break
            if not ext:
                _, ext = os.path.splitext(lower)
            if ext not in ALLOWED_EXT:
                self.send_response(400)
                self.send_header("Content-Type", "text/plain")
                self.end_headers()
                self.wfile.write(f"file type {ext} not allowed".encode())
                return

            if len(file_data) > MAX_SIZE:
                self.send_response(413)
                self.send_header("Content-Type", "text/plain")
                self.end_headers()
                self.wfile.write(b"file too large (500MB max)")
                return

            ts = time.strftime("%Y%m%d-%H%M%S")
            safe_name = "".join(c for c in filename if c.isalnum() or c in "._- ")[:200]
            dest = os.path.join(UPLOAD_DIR, f"{ts}_{safe_name}")
            with open(dest, "wb") as f:
                f.write(file_data)

            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(f"received {safe_name} ({len(file_data)} bytes)".encode())
            print(f"[DROP] {safe_name} ({len(file_data)} bytes) from {self.headers.get('X-Real-IP', '?')}")

        except Exception as e:
            print(f"[ERROR] {traceback.format_exc()}")
            try:
                self.send_response(500)
                self.send_header("Content-Type", "text/plain")
                self.end_headers()
                self.wfile.write(b"server error - try again")
            except:
                pass

    def do_GET(self):
        self.send_error(405, "POST only")

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def log_message(self, fmt, *args):
        pass

    def handle_one_request(self):
        """Override to catch connection resets that crash the server."""
        try:
            super().handle_one_request()
        except (ConnectionResetError, BrokenPipeError, ConnectionAbortedError):
            pass
        except Exception as e:
            print(f"[CONN ERROR] {e}")

if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", 8085), UploadHandler)
    print(f"Drop Zone listening on :8085 -> {UPLOAD_DIR}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down.")
        server.server_close()
