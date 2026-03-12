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

### Quick wins
- Pages v2: removed all service branding (Jellyfin/Navidrome/Kavita etc), replaced with descriptive text
- Public page: added Palestine section (films, books, comics - green accent cards)
- Font sizes bumped 18px→20px, --dim brightened #666→#888 for legibility
- ErsatzTV confirmed broken on arm64 - removed image (saved 1.1GB)
- Immich, Overseerr brought back online

### 2026-02-28 17:45 - MEDIA CONSOLIDATION & HYGIENE
- **Shows Folder Cleanup:** Bulk renamed and consolidated over 100+ shows on the Passport drive.
- **Root Cause Found:** Complex "scene" folder names and split season folders were confusing Jellyfin's scanner.
- **Fixes Applied:**
  - Consolidated `Mr Pickles`, `Red Dwarf`, `Better Call Saul`, `Smiling Friends`, `The Legend of Vox Machina`, and `The Wire` into clean multi-season structures.
  - Simplified 50+ complex folder names (Garfield, Aeon Flux, ALF, Breaking Bad, etc.).
  - Merged duplicate show folders (`NewsRadio`, `Over the Garden Wall`, `Deadwood`, `The Wire`).
  - Deleted redundant `Metalocalypse_old` and other stale directories.
- **Dashboard Audit:** Verified links and ports on `pibulus.deck` (local) and `quickcat.club` (public). All services (`Jellyfin`, `Navidrome`, `Kavita`, `Memos`, etc.) are correctly routed.
- **Documentation:** Updated `AI_HANDBOOK.md` with media organization rules and clean structure guidelines.
- **Status:** All services nominal. Jellyfin library significantly expanded.

**Commit:** Show consolidation, dashboard audit, and AI handbook update.


## ARCHIVED LEDGER (HISTORICAL)
# 📜 THE CYBERDECK LEDGER
### A chronological record of modifications and deployments.

## [2026-02-18] - THE REBRAND & HARDENING SESSION
- **Identity:** Rebranded from 'Pibulus' to 'Quick Cat Club'.
- **Security:** Enabled MAC randomization, Quad9 Private DNS, and Fail2Ban.
- **Remote:** Enabled 'Stealth Mode' (password toggle) and Web-Terminal (Port 7682).
- **Social:** Deployed Gitea (Port 3001) and Memos (Port 5230).
- **Broadcast:** Integrated 80s Ads into ErsatzTV and mapped Music/Radio to AzuraCast.
- **AI:** Installed Claude Code and prepped Node v22 for OpenClaw.
- **Redundancy:** Created 'Golden Image' backup system.

## [2026-02-19] - MISSION CONTROL & AI UPGRADE SESSION
- **AI Upgrades:** Installed Homebrew, GCC, GH CLI, and UV.
- **OpenClaw:** Integrated ♊️ gemini, 🐙 github, 🧾 summarize, 🍌 nano-banana, and 🌊 songsee.
- **Mission Control:** Deployed 'Mission Control' UI (Web + Terminal) for task tracking.
- **Identity:** Rebranded login experience to 'PIBULUS' with 'BISHOP' operative.
- **UX:** Streamlined welcome dashboard with horizontal layout and live port map.
- **Stability:** Stopped RAM-heavy containers (Immich ML, etc.) to rescue Swap memory.

## [2026-02-22] - RADIO STATION INTEGRATION
- **Domain:** Configured Nginx to serve 'kpab.fm' alongside 'quickcat.club'.
- **Content:** Created dedicated Lush landing page for KPAB.fm with live audio player.
- **Redundancy:** Synchronized new configs with Passport drive.

## [2026-02-22] - THE BROADCAST ERA BEGINS
- **Domain Acquisition:** Purchased 'kpab.fm' - the permanent home for Brunswick Pirate Radio.
- **Nginx Multi-Site:** Configured the deck to host two separate worlds: 'quickcat.club' (Guest Home) and 'kpab.fm' (Radio Landing Page).
- **Lush Web UI:** Deployed a dedicated radio player page for KPAB.fm with live stream integration.
- **Radio Lab Expansion:** Created 'antenna_calc.sh' to prepare for physical FM transmission using the TR508 hardware.
- **Identity Lock:** Updated BISHOP welcome dashboard to proudly display the new broadcast identity.
- **Hardware Strategy:** Finalized specs for the 0.5W FM transmitter and Nooelec SDR integration.

## [2026-02-25] - SOULSEEK RESURRECTION & DOCS OVERHAUL
- **slskd:** Rebuilt standalone (removed VPN dependency). Updated to v0.24.4.
- **slskd API:** Confirmed full REST API access - search, download, transfer management all working via CLI.
- **AzuraCast Fix:** Recovered from SSL lockout (base_url was set to https, always_use_ssl=true). Reset via CLI.
- **Welcome Script:** v4.2 - added port override map (azuracast=8500, jellyfin=8096), hides noise containers.
- **PureVPN:** Credentials configured in .env but Gluetun TLS failing (stale server list). slskd runs direct for now.
- **AI Handbook:** Complete rewrite with full API docs, port map, path reference, and operational notes.
- **Music Downloads:** Queued first batch - King Gizzard, Butthole Surfers, Slayer, Cake (7 FLAC albums).
## Session 3 — 2026-02-28 (Late Night)

### KPAB.FM Song Request System — SHIPPED
- Built inline search-as-you-type request panel into KPAB.FM player
- Static catalog approach: gen_request_catalog.sh scrapes 4,332 songs → catalog.json (1.1MB)
- Catalog auto-refreshes every 6 hours via cron
- Search filters client-side (artist/title/album), 50 results max, album art thumbnails
- One-click REQUEST → POST to AzuraCast API → toast confirmation
- ESC to close, whole-row clickable, smooth panel transition

### QOL Juice Pass (11 improvements)
- Responsive request panel for mobile
- Smooth scroll-to on panel open
- Real CSS transition (max-height) replacing broken display:none animation
- Search input glow when active
- SENT button cyan glow
- Button press feedback (scale)
- History item hover highlights
- OG meta tags for link previews
- ESC hint inline with close button
- Cleaned up script

### Full Audit
- All KPAB.FM routes verified: homepage, catalog, API, stream, art, request POST
- All quickcat.club routes: homepage, arcade, retro arcade
- Deck auth (401) confirmed working
- pibulus.local LAN access confirmed
- 19 Docker containers all running

### Git: WWW HTML pages now tracked
- Added www/html/ to pibulus-os repo (HTML/JSON pages only, ~152K)
- Binary files (game ROMs, generated catalogs) excluded via .gitignore
- Source of truth remains /media/pibulus/passport/www/html/

### Downloads Status
- Mega Drive No-Intro: 1,773 ROMs (1.1GB) downloaded via ia into nointro.md subfolder
- Myrient TP: 57 games (1 new: Chrono Regalia), remaining 28 stalled (RAM pressure)
- Tiny Best Set Go: Not started (queued behind MD)
- Downloads tmux session alive but stalled — Pi at 507MB available, swap 100%

### ErsatzTV Status
- Empty config at ~/.config/ersatztv/, no Docker image
- NOT viable right now — Pi at RAM ceiling (4GB, swap maxed)
- Defer until RAM pressure drops (kill unused services or add swap)

### System Health
- RAM: ~500MB available, swap 2047/2047 used (100%)
- Temp: 57.1°C (healthy)
- Root disk: 85% (8.3GB free of 58GB) — needs monitoring
- Passport: 66% (1.9TB free of 5.5TB) — comfortable
- AzuraCast: Healthy, playing music, 0 listeners at time of check

### Session 3 — Continued (Post-Reboot)

#### Kiwix Wikipedia — LIVE
- Simple English Wikipedia (3.2GB ZIM) served via Kiwix on port 8084
- Nginx /wiki/ proxy on quickcat.club + pibulus.local
- ~20MB RAM footprint, survives reboot (--restart unless-stopped)

#### Landing Page Update
- Added KPAB.FM, Retro Arcade, Wikipedia cards (were missing)
- Knowledge section with Wikipedia + Notes
- 6-question FAQ accordion (what is this, radio, access, uploads, downtime, DIY)

#### Launcher Audit — 9 Fixes
- azuracast_web -> azuracast (container name)
- local keyword in main loop (bash error)
- 3 missing functions added: manage_stack, manage_community, manage_homepage
- PIRATE_CONFIG default, Knowledge Vault dedup, community quick command

#### Cloudflare Worker (prepped, not deployed)
- scripts/cloudflare-maintenance-worker.js ready
- CRT-styled Technical Difficulties page with auto-retry
- Needs manual deploy via Cloudflare Dashboard

#### Notes
- Immich (3 containers) did not auto-start after reboot = 1.7GB available RAM
- Root disk at 86% — monitor this
- Kiwix image only 88MB, great citizen

---

## Session 2026-03-01 — Cyberdeck v7.1: The Big Audit + AI Upgrade

### Summary
Full audit and rebuild of launcher.sh and all 16 modules. Added AI-powered features.

### P0 Bugs Fixed
- backup_module.sh: Broken line continuations + wrong AzuraCast path (~/azuracast not ~/.config/azuracast)
- mission_control_module.sh: JSON corruption via raw append (now uses proper python json.load/dump)
- games_module.sh: Shell injection via game titles in inline Python (now uses sys.argv)

### P1 Fixes
- Wikipedia port 8083→8084 (was pointing to Calibre-Web instead of Kiwix)
- Stealth toggle now actually checks state and toggles (was hardcoded to "public")
- Deduplicated "Vault Navigator"/"Knowledge Vault" menu entries
- Wired orphaned modules: Mission Control, Security Audit, Bishop Librarian
- nmap -sP→-sn (deprecated flag)
- command -v guards for pyradio, gemini, and other missing tools

### P2 Polish
- Fixed escaped shebangs (#\! → #!/bin/bash) in 3 modules
- Audio device guard — silently skips tones when no HDMI audio
- Reorganized 18-item flat menu into 4 categories (Media, Knowledge, Security, System)
- Improved HUD: memory usage + container count
- Cleaned up dead code (terminal_travels play_games, inline manage_community)

### New Features
- 🧠 Bishop AI Librarian: headless claude -p with manifest search (deck search)
- 🤖 Scavenger Bot: AI-powered tool selector — slskd + yt-dlp + ia + aria2 (deck scavenge)
- 🔗 URL Shortener: Python micro-app on port 8088, systemd service, pastel-punk UI
- 📝 memo.quickcat.club: Memos exposed via Cloudflare tunnel
- 🔗 go.quickcat.club: URL shortener exposed via Cloudflare tunnel
- 🚀 Deploy Wizard v6.0: local folder deploy, blank site creator, proper cloudflare injection

### DNS Action Needed
quickcat.club needs API access enabled in Porkbun dashboard, then:
- CNAME: memo → c79eb8a2-...cfargotunnel.com
- CNAME: go → c79eb8a2-...cfargotunnel.com

### Files Changed
18 files, 1473 insertions, 332 deletions. Commit: 6b91ad1

### Backup
v6.7 originals at ~/pibulus-os/modules/.backup-v6.7/

## 2026-03-03 - Retro Arcade Fix + Enhance + Wikipedia Fix
- **Retro Arcade**: Fixed garbled audio/no video — iframe-based EmulatorJS player (player.html)
- **Curated catalog**: 634 → 251 Mega Drive games + 41 PSX games = 292 total
- **Save states**: EJS_gameName per game, IndexedDB persistence works
- **PSX added**: Symlinked /Roms/psx into roms dir, 41 titles (Alundra to Vib-Ribbon)
- **Links**: RETRO card on quickcat.club, deck, arcade hub banner
- **Wikipedia fix**: Kiwix --urlRootLocation /wiki + nginx proxy_pass trailing slash removed
- **Files**: retro/index.html, retro/player.html, retro/games.json, arcade/index.html, main index.html, deck index.html, hardening.conf
- **Note**: Sonic 1/2/3 + Streets of Rage missing from nointro ROM set

## 2026-03-05 - The Sovereign Sanctuary Polish
- **Radio (KPAB.FM)**: Fixed broken request system. Re-indexed all 13,771 tracks. Hardened `gen_request_catalog.py` with atomic write safety.
- **Frontend Refactor**: Standardized all radio buttons. Cleaned up FAQ.
- **Graffiti Wall**: Overhaul to 128x128 resolution + VHS palette.
- **PWA + SEO**: Added manifest, service worker, and metadata to quickcat.club.
- **Media Cleanup**: Consolidated The Simpsons, Succession, and Cosmos.
- **App Hygiene**: Calibre-Web password policy disabled. Kavita root-file errors fixed.
- **Scripts Audit**: Fixed port extraction bug in `welcome.sh`.


## 2026-03-05 — SESSION: THE NEURAL LINK UPGRADE
- **The Wall Refactored**: Optimized 128x128 grid with debounced disk saves & batching. Smooth drawing enabled.
- **Cyberdeck Portal**: Launched `/terminal/` with CRT scanlines, flicker, and a rainbow TUI launcher.
- **Tiered Access**: Created restricted `deck` user for public SSH (`ssh deck@quickcat.club`).
- **Live Shoutbox**: Added real-time anonymous chat with "Mighty Duck" name generator.
- **The Deploy Deck**: Added one-click Git-to-Cloudflare deployment button on Admin Dashboard.
- **Library Upgrades**: Added video preview with CRT overlays and download confirmation modals.

---
## 2026-03-12 - Cyberdeck v0.9.2 - RECOVERY & ACCELERATION

### Shipped
- **Jellyfin HW Acceleration**: Mapped `/dev/dri` and `/dev/video19` (Pi 5 HEVC decoder) into `pirate.yml`. Added video/render groups (44/992).
- **Calibre-Web Fix**: Repaired `app.db` by surgically re-inserting missing Guest user (ID 2) with ROLE_ANONYMOUS (32) to resolve Internal Server Error.
- **Terminal Proxy**: Restored `/terminal/` in `hardening.conf` pointing to ttyd on port 7682 with proper WebSocket upgrade headers.
- **Interactive Fiction**: Mounted `/fiction/games/` from Passport drive into `web_host` container. Zork and 29 other games now playable via iplayif.com.
- **Nginx Hygiene**: Removed duplicate Cache-Control headers and escaped shell variables in `hardening.conf`.

### Status
- **Stack**: All 13 services in `pirate.yml` healthy and responding.
- **Media**: Jellyfin library accessible with hardware-assisted decoding.
- **Books**: Calibre-Web live at read.quickcat.club.
- **Arcade**: Fiction library reachable at quickcat.club/fiction.
- **Shell**: Web terminal live at quickcat.club/terminal.

**Checkpoint**: v0.9.2 STABLE
