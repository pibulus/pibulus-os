#!/usr/bin/env python3
"""Drop Zone Upload Server — accepts file uploads via POST
   Python 3.13 compatible (no cgi module)"""
import os, time, re, io
from http.server import HTTPServer, BaseHTTPRequestHandler

UPLOAD_DIR = "/media/pibulus/passport/Drops"
MAX_SIZE = 500 * 1024 * 1024  # 500MB
ALLOWED_EXT = {
    '.mp3','.flac','.ogg','.wav','.aac','.m4a',
    '.cbz','.cbr','.pdf','.epub','.mobi',
    '.zip','.7z','.rar','.tar.gz',
    '.rom','.bin','.smc','.sfc','.nes','.gba','.gb','.gbc','.n64','.z64','.md','.gen',
    '.jpg','.jpeg','.png','.gif','.webp',
    '.mp4','.mkv','.avi',
}

os.makedirs(UPLOAD_DIR, exist_ok=True)

def parse_multipart(rfile, content_type, content_length):
    """Parse multipart form data without cgi module."""
    boundary_match = re.search(r'boundary=([^\s;]+)', content_type)
    if not boundary_match:
        return None, None
    boundary = boundary_match.group(1).encode()
    
    data = rfile.read(min(content_length, MAX_SIZE + 1))
    
    # Split on boundary
    parts = data.split(b'--' + boundary)
    for part in parts:
        if b'Content-Disposition' not in part:
            continue
        
        # Parse headers and body
        header_end = part.find(b'\r\n\r\n')
        if header_end < 0:
            continue
        headers = part[:header_end].decode('utf-8', errors='replace')
        body = part[header_end + 4:]
        
        # Remove trailing \r\n
        if body.endswith(b'\r\n'):
            body = body[:-2]
        
        # Extract filename
        fn_match = re.search(r'filename="([^"]+)"', headers)
        if fn_match and 'name="file"' in headers:
            return fn_match.group(1), body
    
    return None, None

class UploadHandler(BaseHTTPRequestHandler):
    def do_POST(self):
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

        # Check extension
        _, ext = os.path.splitext(filename.lower())
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

        # Save with timestamp prefix
        ts = time.strftime("%Y%m%d-%H%M%S")
        safe_name = "".join(c for c in filename if c.isalnum() or c in "._- ")[:200]
        dest = os.path.join(UPLOAD_DIR, f"{ts}_{safe_name}")
        with open(dest, "wb") as f:
            f.write(file_data)

        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(f"received {safe_name} ({len(file_data)} bytes)".encode())
        print(f"[DROP] {safe_name} ({len(file_data)} bytes)")

    def do_GET(self):
        self.send_error(405, "POST only")

    def log_message(self, fmt, *args):
        pass

if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", 8085), UploadHandler)
    print("Drop Zone listening on :8085")
    server.serve_forever()
