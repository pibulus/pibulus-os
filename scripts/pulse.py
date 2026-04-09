#!/usr/bin/env python3
"""
Quick Cat Pulse — live stats panel.
Called in a loop by the launcher. Ctrl-C to exit.
"""

import json
import subprocess
import urllib.request
from datetime import datetime

W = 46  # panel width
JF_TOKEN = "1980cdafcfec43b58b04b89c4d1f5b99"
QB_USER = "admin"
QB_PASS = "meringue"


def hr(char="━"):
    return char * W


def fetch(url, headers=None, timeout=3):
    try:
        req = urllib.request.Request(url, headers=headers or {})
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return json.load(r)
    except Exception:
        return None


def fmt_speed(bps):
    if bps < 1024:
        return f"{bps} B/s"
    elif bps < 1_048_576:
        return f"{bps / 1024:.1f} KB/s"
    else:
        return f"{bps / 1_048_576:.1f} MB/s"


def trunc(s, n):
    return s if len(s) <= n else s[: n - 1] + "…"


def qb_session():
    try:
        data = b"username=admin&password=meringue"
        req = urllib.request.Request(
            "http://localhost:8888/api/v2/auth/login", data=data
        )
        req.add_header("Content-Type", "application/x-www-form-urlencoded")
        with urllib.request.urlopen(req, timeout=3) as r:
            for part in r.headers.get("Set-Cookie", "").split(";"):
                if part.strip().startswith("SID="):
                    return part.strip()
    except Exception:
        pass
    return None


def qb_get(sid, path):
    req = urllib.request.Request(f"http://localhost:8888{path}")
    req.add_header("Cookie", sid)
    try:
        with urllib.request.urlopen(req, timeout=3) as r:
            return json.load(r)
    except Exception:
        return None


out = []
out.append(hr())
out.append(f"  ░ QUICK CAT PULSE  ·  {datetime.now().strftime('%H:%M:%S')} ░")
out.append(hr())

# ── AzuraCast ────────────────────────────────────────
out.append("")
az = fetch("http://localhost:8500/api/nowplaying/kpab.fm")
if az:
    n = az.get("listeners", {}).get("current", 0)
    song = az.get("now_playing", {}).get("song", {})
    artist = song.get("artist", "?")
    title = song.get("title", "?")
    dot = "●" if n > 0 else "○"
    out.append(f"  {dot} KPAB.FM          {n} listener{'s' if n != 1 else ''}")
    out.append(f"    ♫  {trunc(f'{artist} — {title}', W - 7)}")
else:
    out.append("  ○ KPAB.FM          offline")

# ── Jellyfin ─────────────────────────────────────────
out.append("")
jf = fetch("http://localhost:8096/Sessions", headers={"X-Emby-Token": JF_TOKEN})
if jf is not None:
    playing = [s for s in jf if s.get("NowPlayingItem")]
    dot = "●" if playing else "○"
    out.append(f"  {dot} JELLYFIN         {len(playing)} watching")
    for s in playing[:4]:
        item = s.get("NowPlayingItem", {})
        user = s.get("UserName", "?")
        name = item.get("Name", "?")
        itype = item.get("Type", "")
        tag = {"Movie": "🎬", "Episode": "📺", "Audio": "🎵"}.get(itype, "▶")
        out.append(f"    {tag}  {trunc(user + ' — ' + name, W - 8)}")
else:
    out.append("  ○ JELLYFIN         offline")

# ── Navidrome ────────────────────────────────────────
out.append("")
nd = fetch(
    "http://localhost:4533/rest/getNowPlaying"
    "?u=pibulus&p=meringue&v=1.16.0&c=pulse&f=json"
)
if nd:
    entries = (
        nd.get("subsonic-response", {}).get("nowPlaying", {}).get("entry", [])
    )
    if not isinstance(entries, list):
        entries = [entries] if entries else []
    dot = "●" if entries else "○"
    out.append(f"  {dot} NAVIDROME        {len(entries)} listening")
    for e in entries[:4]:
        uname = e.get("username", "?")
        title = e.get("title", "?")
        out.append(f"    🎵  {trunc(uname + ' — ' + title, W - 8)}")
else:
    out.append("  ○ NAVIDROME        offline")

# ── qBittorrent ──────────────────────────────────────
out.append("")
sid = qb_session()
if sid:
    info = qb_get(sid, "/api/v2/transfer/info") or {}
    dl_list = qb_get(sid, "/api/v2/torrents/info?filter=downloading") or []
    seed_list = qb_get(sid, "/api/v2/torrents/info?filter=seeding") or []
    dl_speed = fmt_speed(info.get("dl_info_speed", 0))
    up_speed = fmt_speed(info.get("up_info_speed", 0))
    out.append(f"  ● QBITTORRENT")
    out.append(f"    ↓  {len(dl_list):>2} downloading   {dl_speed}")
    out.append(f"    ↑  {len(seed_list):>2} seeding       {up_speed}")
else:
    out.append("  ○ QBITTORRENT      offline")

# ── Network ──────────────────────────────────────────
out.append("")
def ping_ms(host):
    try:
        r = subprocess.check_output(
            ["ping", "-c", "2", "-W", "2", host],
            text=True, stderr=subprocess.DEVNULL
        )
        for line in r.splitlines():
            if "avg" in line or "rtt" in line:
                return line.split("/")[4] + "ms"
    except Exception:
        pass
    return "timeout"

cf = ping_ms("1.1.1.1")
ggl = ping_ms("8.8.8.8")

# Read eth0 throughput over 1s sample from /proc/net/dev
def iface_speed(iface, interval=1):
    def read():
        for line in open("/proc/net/dev"):
            if iface in line:
                cols = line.split()
                return int(cols[1]), int(cols[9])
        return 0, 0
    rx1, tx1 = read()
    import time; time.sleep(interval)
    rx2, tx2 = read()
    return rx2 - rx1, tx2 - tx1

rx_bps, tx_bps = iface_speed("eth0")
out.append(f"  ● NETWORK")
out.append(f"    ↓  {fmt_speed(rx_bps):<12}  ping 1.1.1.1  {cf}")
out.append(f"    ↑  {fmt_speed(tx_bps):<12}  ping 8.8.8.8  {ggl}")

# ── System ───────────────────────────────────────────
out.append("")
out.append(hr("─"))
try:
    raw = subprocess.check_output(["uptime"], text=True)
    load_val = raw.split("load average:")[-1].split(",")[0].strip()
except Exception:
    load_val = "?"

try:
    mem_raw = subprocess.check_output(["free", "-h"], text=True)
    mem_avail = mem_raw.splitlines()[1].split()[6]
except Exception:
    mem_avail = "?"

try:
    raw = subprocess.check_output(["vcgencmd", "measure_temp"], text=True)
    temp = raw.strip().split("=")[-1]
except Exception:
    temp = "n/a"

out.append(f"  🌡 {temp}   load {load_val}   🧠 {mem_avail} free")
out.append(hr("─"))
out.append("  ctrl-c to exit · refreshes every 15s")

print("\n".join(out))
