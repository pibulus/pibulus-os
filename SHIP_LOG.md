# PIBULUS OS - Ship Log
> Append-only diary of sessions, changes, and decisions.
> Each entry is a snapshot. Read top-to-bottom for full history.

---

## 2026-02-21 | Session: The Great Wiring

### What happened
- Continued from 64GB SD card swap + 2.2TB content load onto passport drive
- Upgraded Node.js to v22.22.0 (needed for OpenClaw)
- Installed OpenClaw v2026.2.17 (running as openclaw-gateway, ~420MB RAM)
- Wired up all media services to their actual content directories
- Fixed 5 broken deck launcher scripts (menu syntax errors)
- Fixed romm env var rename (ROMM_AUTH_SECRET → ROMM_AUTH_SECRET_KEY)
- Fixed gluetun region (Australia → Victoria)
- Set up Cloudflare Tunnel subdomains for all media services
- Added 5 CNAME records via Cloudflare API
- Stored Cloudflare API token + static IP in ~/.config/api_keys on Mac
- Removed hexbloop.app from tunnel config
- Fixed emulatorjs port conflict (3000 → 3002, was clashing with gitea)
- Fixed gluetun/emulatorjs restart policies to "no" (prevent crash-loops)
- Added Soulseek download path to Navidrome (was missing new downloads)
- Removed ghost lowercase folders from passport (music/, roms/, media/)
- Removed stale Jellyfin /media mount
- Rebuilt Homepage admin dashboard (was missing most services)
- Fixed tv.quickcat.club port (8000 → 8001 for ErsatzTV)

### Live subdomains
| URL | Service | Status |
|-----|---------|--------|
| quickcat.club | nginx landing page | LIVE |
| watch.quickcat.club | Jellyfin | LIVE (needs setup wizard) |
| music.quickcat.club | Navidrome | LIVE (needs account setup) |
| read.quickcat.club | Kavita | LIVE |
| radio.quickcat.club | AzuraCast | LIVE (needs setup wizard) |
| tv.quickcat.club | ErsatzTV | NOT RUNNING |

### Still needs work
- [ ] **Jellyfin**: Complete setup wizard at watch.quickcat.club (create admin, add libraries)
- [ ] **AzuraCast**: Complete setup wizard at radio.quickcat.club (create admin, add station)
- [ ] **Navidrome**: May need account creation + library scan trigger
- [ ] **Immich ML**: Run face detection pass then stop ML container to free ~2GB RAM
- [ ] **Gluetun/Soulseek**: Add PureVPN credentials to .env file, then start gluetun
- [ ] **EmulatorJS**: Not created yet. Run  when ready
- [ ] **ErsatzTV**: Was crash-looping (.NET error). Needs investigation before starting
- [ ] **icloudpd**: Needs Apple ID configuration (run init script)
- [ ] **OpenClaw onboard**: Run  to connect messaging + API key
- [ ] **Security**: Consider basic auth on public subdomains, review exposed ports
- [ ] **Tailscale**: Works for Jellyfin (host network) but Docker bridge services may need firewall rules

### Port map (complete, no conflicts)
| Port | Service | Public? |
|------|---------|---------|
| 22 | SSH | no |
| 2022 | AzuraCast SFTP | no |
| 2222 | Gitea SSH | no |
| 2283 | Immich | no |
| 3001 | Gitea web | no |
| 3002 | EmulatorJS mgmt | no |
| 4533 | Navidrome | music.quickcat.club |
| 5000 | Kavita | read.quickcat.club |
| 5030 | Soulseek web (via gluetun) | no |
| 5031 | Soulseek P2P (via gluetun) | no |
| 5055 | Overseerr | no |
| 5230 | Memos | no |
| 7681 | Cyber Arcade | no |
| 7682 | Web Terminal | no |
| 8001 | ErsatzTV | tv.quickcat.club |
| 8080 | File Browser | no |
| 8081 | Homepage Admin | no |
| 8085 | EmulatorJS games | no |
| 8086 | RomM | no |
| 8090 | Nginx (quickcat.club) | quickcat.club |
| 8096 | Jellyfin | watch.quickcat.club |
| 8500 | AzuraCast | radio.quickcat.club |
| 8443 | AzuraCast HTTPS | no |
| 9000 | IRC (The Lounge) | no |
| 18789 | OpenClaw gateway | localhost only |

### Architecture notes
- Raspberry Pi 5, 4GB RAM, 64GB SD, Debian Trixie (arm64)
- 5.5TB passport drive at /media/pibulus/passport (NTFS, case-insensitive)
- Docker v29.2.0, 5 compose stacks: pirate, admin, social, immich, azuracast
- Cloudflare Tunnel (c79eb8a2) via systemd service
- Tailscale for private access (100.115.240.57)
- Static IP: 144.6.84.23 (Aussie Broadband)
- Domain: quickcat.club (Cloudflare DNS, Zone: b7fce439...)
- OpenClaw gateway running as system process (~420MB RAM)

### Key files
| File | What it does |
|------|-------------|
| ~/pibulus-os/config/stacks/pirate.yml | Main media/tools compose |
| ~/pibulus-os/config/stacks/admin.yml | Homepage + web terminal |
| ~/pibulus-os/config/stacks/social.yml | Gitea, Memos, IRC |
| ~/pibulus-os/config/stacks/immich.yml | Photos + iCloud sync |
| ~/azuracast/docker-compose.yml | Radio station (separate) |
| /etc/cloudflared/config.yml | Tunnel ingress rules |
| ~/pibulus-os/config/nginx/hardening.conf | Nginx config |
| ~/pibulus-os/config/homepage-admin/ | Dashboard config |
| ~/pibulus-os/launcher.sh | deck TUI main menu |
| ~/pibulus-os/modules/*.sh | deck sub-menus |
| ~/.config/api_keys (on Mac) | Cloudflare token, static IP |

### RAM budget (4GB total)
- System + kernel: ~800MB
- OpenClaw gateway: ~420MB
- Jellyfin: ~300-500MB
- AzuraCast: ~300-400MB
- Navidrome: ~100MB
- Kavita: ~100MB
- Everything else: ~200-400MB
- Swap: 2GB (safety net)
- DO NOT run immich_ml + all services simultaneously = OOM death spiral

### If everything is broken and you have no AI
1. Power cycle the Pi (pull USB-C, wait 5 sec, replug)
2. SSH in: Linux pibulus 6.12.47+rpt-rpi-2712 #1 SMP PREEMPT Debian 1:6.12.47-1+rpt1 (2025-09-16) aarch64 (password: meringue)
3. Check what's running: 
4. Check RAM: 
5. If swap is 2.0/2.0: stop heavy containers: 
6. Restart specific services: 
7. Restart AzuraCast: 
8. Check subdomains: HTTP/2 302 
date: Sat, 21 Feb 2026 07:19:14 GMT
location: web/
server: cloudflare
cf-cache-status: DYNAMIC
report-to: {"group":"cf-nel","max_age":604800,"endpoints":[{"url":"https://a.nel.cloudflare.com/report/v4?s=zr1Lircg%2BV6Y2WyOJZIFKjWOOQICCD%2FVIxGTINtE5MY4wf4V1SkBWh5XD969usIfBISnvXEztn4k%2BFIsFugqgQGmIb3%2F4RSj0oAO%2BfMc7AoEdp1S%2FLBgf65pPTH4P7c%3D"}]}
nel: {"report_to":"cf-nel","success_fraction":0.0,"max_age":604800}
cf-ray: 9d14796dddf9e697-MEL
alt-svc: h3=":443"; ma=86400

9. Cloudflared config: 
10. Restart tunnel: 


## [2026-02-25] - THE GREAT INFRASTRUCTURE AUDIT

### Network Architecture Overhaul
- **Two-Door System:** Separated public (`quickcat.club`) from private (`pibulus.local`) access
  - `pibulus.local` → PIBULUS DECK (admin dashboard, no auth, LAN only)
  - `quickcat.club` → Clean public page (media links via tunnel subdomains)
  - `deck.quickcat.club` → Admin deck remotely, basic auth protected (pibulus / Church0fTheSubgeniu5!)
- **Port Fix:** web_host nginx moved from :8090 → :80 (pibulus.local works without port number now)
- **Tunnel Rewrite:** All `*.quickcat.club` subdomains use proper tunnel routing, no more `quickcat.club:8096` style links

### KPAB.FM Radio Fix
- **Root Cause:** Stream URL had stale `/radio/8000/radio.mp3` path (old AzuraCast proxy format)
- **Fix:** `kpab.fm` + `www.kpab.fm` now route to AzuraCast web UI (port 8500) for full public player
- **CSS:** Uploaded cyberdeck CSS (`kpab-cyberdeck.css`) into AzuraCast station branding via API
- **Stream:** `radio.quickcat.club` → Icecast on port 8000, mount at `/radio.mp3`

### Jellyfin Reset & Library Cleanup
- **Account:** Deleted "Newt" admin, made "pibulus" sole admin, password cleared for fresh setup
- **Shows Library:** Reorganized 72 show folders - stripped torrent cruft from 37 names, merged 7 split-season shows (Rick and Morty 6→1, Mike Tyson Mysteries 3→1, The Boys 3→1, House of the Dragon 2→1, Noisey 2→1, PEN15 2→1, Infinity Train 2→1)
- **Note:** `Metalocalypse_old` kept as safety net, delete after confirming main folder has everything

### Navidrome Reset & Config
- **Account Reset:** Cleared old user, fresh admin `pibulus`/`meringue` + guest `guest`/`quickcat`
- **Config Deployed:** `~/.config/navidrome/navidrome.toml` with Dark theme, 80% volume, sharing enabled, 30-day sessions, full string search, welcome message
- **725 albums, 9022 songs** across Library + Soulseek directories

### Pages Deployed
- `/media/pibulus/passport/www/html/index.html` - Public quickcat.club (clean, tunnel-subdomain links only)
- `/media/pibulus/passport/www/html/deck/index.html` - PIBULUS DECK (full admin, all local service links)
- `/media/pibulus/passport/www/html/kpab/index.html` - KPAB.FM static fallback (fixed stream URL)

### Service Port Map (Current)
```
nginx (homepage/deck)  : 80     | web_host container
navidrome              : 4533   | music.quickcat.club
jellyfin               : 8096   | watch.quickcat.club (host network)
kavita                 : 5000   | read.quickcat.club
azuracast (web UI)     : 8500   | kpab.fm
azuracast (icecast)    : 8000   | radio.quickcat.club
filebrowser            : 8080   |
homepage-admin         : 8081   |
overseerr              : 5055   |
gitea                  : 3001   |
memos                  : 5230   |
web_terminal           : 7682   |
cyber_arcade           : 7681   |
irc                    : 9000   |
```

---
## 2026-02-27 - Media Library Overhaul + kpab.fm Music Fills

### Shipped
- **Calibre-Web** added on port 8083 for proper book browsing (author pages, sane UX)
- **Kavita** stripped to comics-only - no more series of 1 book weirdness
- **Homepage** updated: Library split into Comics + Books with correct links
- **kpab.fm downloader**:  - 10 genre batches, 139 albums queued via slskd API
  - Batches: uk_bangers, uk_grime, aus, hiphop, garage, hardcore, shoegaze, electronic, cool_indie, krautrock
  - ~26/35 first run FLAC, including: Fontaines x3, Idles x2, Bob Vylan, Shame x2, Tropical Fuck Storm x2, Drones x2, Sampa x2, Hiatus Kaiyote, Genesis Owusu, Civic, Cable Ties, The Chats...
- **Kavita DB** configured: DarkPink theme default, dashboard = Newly Added + On Deck only, sidenav = Comics + All Series only
- **Comics library** populated: ~25GB of graphic novels transferred from Mac (Locke & Key, Watchmen, Sandman, Preacher, Saga, From Hell, Maus, Berserk, Akira + dozens more)
- **slskd API** pattern documented in TOOLS.md - search→/responses endpoint, queue as array not object

### Key learnings
- slskd queue endpoint needs array payload  not 
- slskd search results at  not on main search object
- Kavita DB at  (root owned, stop container before swap)
- Swap hitting 1.8/2GB with full stack running - immich_ml must stay stopped

### Still needs doing (from previous session)
- [ ] Calibre-Web first-time setup: http://pibulus.local:8083 → library path = /books, admin/admin123
- [ ] Kavita: Add Comics library in Admin → Libraries → /comics
- [ ] Jellyfin: Complete setup wizard, add libraries
- [ ] Gluetun/PureVPN: Add credentials to .env before starting
- [ ] icloudpd: Needs Apple ID config (currently unhealthy)
- [ ] ErsatzTV: Was crash-looping, needs investigation
- [ ] Immich ML: Run face detection pass then stop to free RAM
- [ ] kpab.fm: Run remaining batches (garage, hardcore, shoegaze, electronic, hiphop, krautrock)
- [ ] Sleaford Mods + black midi: Not on Soulseek atm, retry later

---

## 2026-02-28 — The Port Massacre Fix

**Problem:** Pi crashed after power cycle, most services down. Ports 'kept fucking out'. Root disk at 98%.

**Root Cause Found:** AzuraCast's docker-compose.yml mapped ~100 Icecast relay ports (8000-8496) on the host. Only 1 station exists (kpab.fm). These ports were stealing 8080 (Filebrowser), 8083 (Calibre-Web), 8095, 8096 (Jellyfin) and more. Race condition on boot = random services fail.

**Fixes Applied:**
- Rewrote AzuraCast docker-compose.yml: 100+ ports → 9 ports (8000 stream, 8200-8216 station, 8500 admin, 8443 HTTPS, 2022 SFTP)
- Fixed filebrowser port mapping (was 8080:8080, container listens on 80, now 8080:80)
- Docker disk cleanup: removed unused calibre:latest (4.7GB!), gluetun, dangling images. Root: 98% → 87%
- Stopped Immich ML to save ~500MB RAM
- Added /passport/Soulseek mount to AzuraCast override (now sees both download dirs)
- Calibre library: bulk imported 430 books from Assorted (culled junk first). 964 books total.
- Verified all 13 services responding OK
- Golden image: qcc_golden_v2026-02-28_0744.tar.gz

**Status:** All services nominal. No port conflicts. Tunnel active.
