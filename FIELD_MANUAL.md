# 🐾 QUICK CAT CLUB - FIELD MANUAL
### You are the Captain. This is your ship.

Type `deck` to launch the mainframe. Type `halp` if lost.

---

## 🗺️ THE MAP (What Runs Where)

| Port | Service | Public URL | Notes |
|------|---------|-----------|-------|
| 80 | Nginx (web_host) | quickcat.club / deck.quickcat.club | deck requires basic auth |
| 2222 | Gitea SSH | — | Git over SSH |
| 3001 | Gitea | — | Local Git server |
| 4533 | Navidrome | music.quickcat.club | Hi-fi music streaming |
| 5000 | Kavita | comics.quickcat.club | Comics & graphic novels |
| 5030 | slskd | — | Soulseek P2P (local only) |
| 5055 | Overseerr | — | Media requests |
| 5230 | Memos | — | Private microblogging |
| 7682 | Web Terminal | — | Browser shell |
| 8000 | AzuraCast (Icecast) | kpab.fm (via nginx proxy) | Audio stream |
| 8080 | Filebrowser | — | Passport drive browser |
| 8081 | Homepage Admin | — | Admin dashboard |
| 8083 | Calibre-Web | read.quickcat.club | Book library (964 books) |
| 8084 | Kiwix | quickcat.club/wiki/ | Offline Wikipedia |
| 8096 | Jellyfin | watch.quickcat.club | Movies & shows |
| 8500 | AzuraCast (UI) | kpab.fm (via nginx proxy) | Radio admin + API + art |
| 9000 | IRC (The Lounge) | — | Chat client |

---

## 🔐 ACCESS TIERS

### Public (anyone with the URL)
- quickcat.club — landing page, FAQ, guestbook
- quickcat.club/wiki/ — offline Wikipedia
- quickcat.club/arcade/ — text adventures
- quickcat.club/arcade/retro/ — Mega Drive + retro games
- kpab.fm — pirate radio + song requests

### Friend Tier (need the login)
- watch.quickcat.club — Jellyfin (movies & shows)
- music.quickcat.club — Navidrome (hi-fi music)
- read.quickcat.club — Calibre-Web (books)
- comics.quickcat.club — Kavita (graphic novels)

### Admin (deck password)
- deck.quickcat.club — admin control panel (basic auth)

### LAN Only (pibulus.local)
- pibulus.local — full deck, no auth needed
- Filebrowser, Gitea, Overseerr, slskd, Memos, IRC

---

## ⌨️ TERMINAL POWERS

```bash
deck          # Launch the mainframe TUI
halp          # You're lost
free -h       # Check RAM (swap at 1.8/2GB = danger zone)
docker ps     # What's running
df -h /media/pibulus/passport   # Passport space
btop          # System monitor
dust          # Visual disk usage
```

**Key tools:** `fzf` (fuzzy find), `glow` (markdown viewer), `bat` (syntax highlight), `dust` (disk usage), `btop` (system monitor), `gum` (TUI toolkit)

---

## 🚨 EMERGENCY PROTOCOLS

**Pi won't SSH in:**
1. Power cycle (pull USB-C, wait 5s, replug)
2. SSH in: `ssh pibulus@pibulus.local` (pw: meringue)
3. Check RAM: `free -h` — if swap full, stop heavy containers:
   `docker stop jellyfin azuracast`
4. Restart services:
   `cd ~/pibulus-os/config/stacks && docker compose -f pirate.yml up -d`

**Cloudflare tunnel down:**
```bash
sudo systemctl restart cloudflared
curl -I https://quickcat.club
```

**AzuraCast not streaming:**
```bash
cd ~/azuracast && docker compose up -d
```

**Flush RAM in a pinch:**
```bash
bash ~/pibulus-os/scripts/flush_ram.sh
```

**Golden Image (backup):**
Run via `deck` → Vault Ops → Golden Image
Recovery: Fresh OS → clone pibulus-os repo → extract golden image from Passport

---

## 📦 STACK OVERVIEW

5 compose stacks in `~/pibulus-os/config/stacks/`:
- **pirate.yml** — Jellyfin, Navidrome, Kavita, Calibre-Web, slskd, Overseerr, Filebrowser, Gluetun
- **social.yml** — Gitea, Memos, IRC
- **admin.yml** — Homepage + Web Terminal
- **immich.yml** — Photos + ML (stopped by default to save RAM)
- **~/azuracast/** — Radio (its own compose)

Standalone containers:
- **kiwix** — Offline Wikipedia (docker run, auto-restart)

---

## ⚠️ RAM BUDGET (4GB total)

| Container | RAM |
|-----------|-----|
| System + kernel | ~800MB |
| Jellyfin | ~300-500MB |
| AzuraCast | ~300-400MB |
| Navidrome | ~100MB |
| Kavita | ~100MB |
| Kiwix | ~20MB |
| Everything else | ~200-400MB |
| **Swap** | **2GB safety net** |

**Golden rules:**
- Immich ML is OFF by default — run face detection then stop
- Docker pulls can OOM the Pi — stop heavy services first
- If swap hits 1.8/2GB, things will start dying

---

## 🛡️ SECURITY POSTURE

### Network
- **Cloudflare Tunnel** — all public traffic goes through Cloudflare, Pi's real IP is never exposed
- **No open ports to internet** — everything proxied via tunnel
- **Real IP forwarding** — nginx extracts real client IPs from Cloudflare headers for rate limiting
- **Rate limiting** — 1 req/sec with burst=5, 10 connections per IP (nginx)
- **Fail2Ban** — SSH monitoring, 3 fails = 24hr ban

### Authentication
- **deck.quickcat.club** — nginx basic auth (htpasswd)
- **Friend-tier services** — each service has its own login
- **SSH** — password auth enabled (LAN only, not exposed via tunnel)

### Headers
- `server_tokens off` — nginx version hidden
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: SAMEORIGIN`
- `Referrer-Policy: strict-origin-when-cross-origin`
- `Permissions-Policy: camera=(), microphone=(), geolocation=()`

### Privacy
- **MAC randomization** — NetworkManager randomizes hardware IDs
- **Private DNS** — Quad9 encrypted DNS (Swiss-based)
- **VPN** — Gluetun tunnel for P2P traffic (when configured)
- **.env blacklisted** from git

### Known Gaps
- Passport drive not LUKS encrypted (physical theft risk)
- Gitea needs 2FA enabled
- rpcbind running (port 111) — disable if NFS not needed
- Guestbook is client-side only (no persistence backend yet)

---

## 🌐 WIFI HOTSPOT

KPAB-Hotspot runs on wlan0 at 10.42.0.1
- Public services accessible without internet
- WPA2-PSK secured
- Visitors get: radio, arcade, Wikipedia, landing page

---

## 📻 CRON JOBS

| Schedule | Script | What |
|----------|--------|------|
| */5 * * * * | status.sh | System health check |
| 0 */6 * * * | gen_request_catalog.sh | Refresh 4,332-song request catalog |

---

*Stay modular. Stay redundant. Stay sovereign.*
