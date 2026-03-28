#!/usr/bin/env python3
"""MUTINY - Listener skip voting for KPAB.FM pirate radio
Solo listener = instant skip. Multiple = majority vote in 30s window.
Cooldown: 1 skip per 10 min per listener fingerprint.
"""

import json, time, hashlib, threading
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.request import Request, urlopen
from urllib.parse import urlparse

AZURACAST_URL = "http://localhost:8500"
API_KEY = "dc496426609c5cf3:4d97815b1d07bcb062831493911d3c59"
STATION_ID = 1
VOTE_WINDOW = 30        # seconds to collect votes
COOLDOWN = 300           # 10 min cooldown per voter

# State
votes = {}               # song_id -> set of voter fingerprints
vote_timers = {}          # song_id -> timer thread
cooldowns = {}            # fingerprint -> last skip timestamp
lock = threading.Lock()


def api_get(path):
    req = Request(f"{AZURACAST_URL}{path}")
    req.add_header("X-API-Key", API_KEY)
    with urlopen(req, timeout=5) as r:
        return json.loads(r.read())


def api_post(path):
    req = Request(f"{AZURACAST_URL}{path}", data=b"", method="POST")
    req.add_header("X-API-Key", API_KEY)
    with urlopen(req, timeout=5) as r:
        return json.loads(r.read())


def get_nowplaying():
    data = api_get(f"/api/nowplaying/{STATION_ID}")
    return {
        "song_id": data["now_playing"]["song"]["id"],
        "artist": data["now_playing"]["song"]["artist"],
        "title": data["now_playing"]["song"]["title"],
        "listeners": data["listeners"]["unique"],
        "duration": data["now_playing"]["duration"],
        "elapsed": data["now_playing"]["elapsed"],
    }


def do_skip():
    try:
        result = api_post(f"/api/station/{STATION_ID}/backend/skip")
        print(f"[MUTINY] Skip executed: {result}")
        return True
    except Exception as e:
        print(f"[MUTINY] Skip failed: {e}")
        return False


def fingerprint(ip, ua):
    return hashlib.sha256(f"{ip}:{ua}".encode()).hexdigest()[:12]


def check_cooldown(fp):
    now = time.time()
    if fp in cooldowns and (now - cooldowns[fp]) < COOLDOWN:
        remaining = int(COOLDOWN - (now - cooldowns[fp]))
        return False, remaining
    return True, 0


def resolve_votes(song_id):
    """Called after vote window expires - check if majority reached."""
    with lock:
        if song_id not in votes:
            return
        try:
            np = get_nowplaying()
        except Exception:
            votes.pop(song_id, None)
            vote_timers.pop(song_id, None)
            return
        if np["song_id"] != song_id:
            votes.pop(song_id, None)
            return
        voter_count = len(votes[song_id])
        listeners = max(np["listeners"], 1)
        needed = (listeners // 2) + 1
        print(f"[MUTINY] Vote window closed: {voter_count}/{needed} ({listeners} listeners)")
        if voter_count >= needed:
            if do_skip():
                now = time.time()
                for fp in votes[song_id]:
                    cooldowns[fp] = now
        votes.pop(song_id, None)
        vote_timers.pop(song_id, None)


class MutinyHandler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        if "/health" not in str(args):
            print(f"[MUTINY] {args[0]}")

    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def _json(self, code, data):
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self._cors()
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_GET(self):
        path = urlparse(self.path).path
        if path == "/health":
            self._json(200, {"status": "armed"})
        elif path == "/status":
            try:
                np = get_nowplaying()
                song_id = np["song_id"]
                with lock:
                    vote_count = len(votes.get(song_id, set()))
                    voting_active = song_id in vote_timers
                np["votes"] = vote_count
                np["voting_active"] = voting_active
                np["needed"] = (max(np["listeners"], 1) // 2) + 1
                np["cooldown_seconds"] = COOLDOWN
                self._json(200, np)
            except Exception as e:
                self._json(500, {"error": str(e)})
        else:
            self._json(404, {"error": "not found"})

    def do_POST(self):
        path = urlparse(self.path).path
        if path != "/mutiny":
            self._json(404, {"error": "not found"})
            return

        ip = self.headers.get("X-Real-IP", self.client_address[0])
        ua = self.headers.get("User-Agent", "unknown")
        fp = fingerprint(ip, ua)

        can_vote, remaining = check_cooldown(fp)
        if not can_vote:
            self._json(429, {
                "error": "cooldown",
                "message": f"Easy, sailor. {remaining}s cooldown remaining.",
                "remaining": remaining
            })
            return

        try:
            np = get_nowplaying()
        except Exception as e:
            self._json(500, {"error": str(e)})
            return

        song_id = np["song_id"]
        listeners = max(np["listeners"], 1)

        with lock:
            if listeners <= 1:
                if do_skip():
                    cooldowns[fp] = time.time()
                    self._json(200, {
                        "action": "skipped",
                        "message": "Solo mutiny! Track walked the plank."
                    })
                else:
                    self._json(500, {
                        "action": "failed",
                        "message": "Mutiny failed — AzuraCast refused the skip."
                    })
                return

            needed = (listeners // 2) + 1
            if song_id not in votes:
                votes[song_id] = set()

            votes[song_id].add(fp)
            vote_count = len(votes[song_id])

            if vote_count >= needed:
                skipped = do_skip()
                if skipped:
                    now = time.time()
                    for vfp in votes[song_id]:
                        cooldowns[vfp] = now
                votes.pop(song_id, None)
                if song_id in vote_timers:
                    vote_timers[song_id].cancel()
                    vote_timers.pop(song_id, None)
                if skipped:
                    self._json(200, {
                        "action": "skipped",
                        "message": f"Mutiny successful! {vote_count}/{needed} voted. Track overboard."
                    })
                else:
                    self._json(500, {
                        "action": "failed",
                        "message": "Votes reached but AzuraCast refused the skip."
                    })
                return

            if song_id not in vote_timers:
                timer = threading.Timer(VOTE_WINDOW, resolve_votes, args=[song_id])
                timer.daemon = True
                timer.start()
                vote_timers[song_id] = timer

            self._json(200, {
                "action": "voted",
                "message": f"Vote logged. {vote_count}/{needed} needed. {VOTE_WINDOW}s window.",
                "votes": vote_count,
                "needed": needed,
                "listeners": listeners
            })


if __name__ == "__main__":
    port = 8090
    server = HTTPServer(("0.0.0.0", port), MutinyHandler)
    print(f"[MUTINY] Armed on port {port}")
    print(f"[MUTINY] Solo=instant | Multi={VOTE_WINDOW}s vote | Cooldown={COOLDOWN}s")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[MUTINY] Standing down.")
