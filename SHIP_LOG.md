
---

## 2026-02-28 Session: KPAB.FM Player + System Cleanup

### Disk Cleanup (89% → 84%, freed ~3GB)
- Removed unused mariadb:latest image (492MB)
- Removed immich_machine_learning container + image (1.79GB)
- Removed immich_model-cache volume (823MB)
- Cleaned apt cache (132MB)

### KPAB.FM Landing Page Overhaul
- **Before:** Broken static page with default HTML5 audio element, no metadata, broken Drop a Track link, didn't fill viewport
- **After:** Full cyberpunk radio player with:
  - Live now-playing via AzuraCast API (artist, title, album, genre, album art)
  - Custom styled play/pause with CSS visualizer bars
  - Song history (last 5 tracks with thumbnails)
  - Listener count
  - Request a Song → AzuraCast public page
  - CRT scanlines + vignette, VT323 font, full viewport
  - Auto-polls every 10s, graceful SIGNAL LOST on API failure

### Cloudflared Tunnel Fix
- kpab.fm + www.kpab.fm routed from port 8500 → port 80 (nginx)
- Nginx now proxies /api/, /public/, /radio.mp3, /listen/ to AzuraCast/Icecast
- All player URLs are same-domain relative (no CORS issues)

### Nginx Config Updated
- Added reverse proxy blocks for kpab.fm: API (→8500), stream (→8000), art (→8500), public (→8500)
- Docker gateway IP 172.23.0.1 used for proxy_pass

### Comics Audit Complete (not yet applied)
- Identified 10+ duplicate series, ~30 folders needing rename cleanup
- Estimated ~8GB reclaimable from duplicate removal
- Full plan documented for next session

### Files Changed
-  - kpab.fm routes to port 80
-  - proxy blocks added
-  - new player page
-  - updated kpab.fm entry

### System State at End
- Load: ~5 (down from 44 at session start)
- Disk: 84% (9.1GB free)
- All 19 containers running, cloudflared active
- Golden image created

---

## 2026-02-28 Session 2 — Cleanup & Arcade

### Completed
- **OpenClaw killed**: Stopped + disabled openclaw-gateway service (~532MB freed)
- **Launcher --help**: Added --help/-h/help flag handler + quick subcommands (radio, games, status, deploy)
- **Fixed help alias**: help is a bash builtin — replaced alias with function override. halp/sos/wtf also work
- **Panels folder extracted** (8GB): Alien 2021 series → new folder, unique AvP/Prometheus → existing folders, Blacksad/Walk Through Hell/Code Pru/Cover → top-level Comics. Dupe Omnibus deleted.
- **Jerusalem epub** → moved to Books/Unsorted/ (was in Comics, it's a novel)
- **Transmetropolitan (Complete)** dupe deleted (4.2GB, background rm)
- **Games module upgraded**: Added Interactive Fiction submenu — reads games.json, plays via frotz (z-machine) or glulxe (Glulx) in terminal
- **Arcade web verified**: CORS headers working, Parchment integration confirmed, 30 games playable

### Architecture Notes
- frotz + glulxe both installed for terminal IF play
- Filebrowser (port 8080) already serves as file upload/download — no Droopy needed
- Kavita scan needs manual trigger (auth creds unknown from CLI)
- Watchmen still incomplete (4/12) — keeping for now
- Mean Machines gaming magazines still in Comics — Pablo's call

## 2026-02-28 Session 2b — Downloads & Retro Arcade

### Completed
- **Droopy pip removed** (wrong package — text analysis, not file upload)
- **Watchmen complete**: All 12 issues downloaded from IA (AlanMooreCollectionWatchmen), CBR/CBZ, 199MB
- **Mega Drive No-Intro set downloading**: ~1.7GB, 164+ files so far via ia CLI. Includes Normy's Beach Babe-O-Rama!
- **Retro arcade page**: Created /arcade/retro/ with EmulatorJS CDN integration — Mega Drive games playable in-browser with controller support, save states, fullscreen
- **Games manifest**: Auto-generated from ROM filenames, curated to skip betas/protos/demos, 49 games (growing)
- **Drop zone page**: Created /drop/ upload page (frontend only — backend upload handler still needed)
- **Navigation**: Arcade pages cross-linked (text adventures ↔ retro arcade ↔ quickcat.club)

### Downloads Running (tmux 'downloads')
1. **Mega Drive No-Intro** (1.7GB) — in progress, ia download
2. **Tiny Best Set Go** (93GB total) — 3 zips queued after MD finishes
3. **Myrient TeknoParrot** (29 curated picks) — in progress via wget
   - Fan translations: Chrono Regalia English
   - Shmups: Akai Katana, Caladrius, Cotton Rock'n'Roll, Rolling Gunner
   - Fighters: Guilty Gear Strive, Tekken 7 FR R2, Tekken Tag 2, DOA6, Persona 4U
   - Iconic: OutRun 2, HotD 4 + Scarlet Dawn, Castlevania, Contra Evolution
   - Racing: Wangan Midnight MT6RR, Densha de Go!!
   - Rhythm: Project DIVA, Groove Coaster 2
   - Total: ~29 new games, Myrient shutting down March 31 2026

### Architecture Notes
- EmulatorJS runs entirely client-side (CDN JS/WASM) — no ARM64 Docker needed
- .7z ROMs work directly with EmulatorJS — no extraction needed
- Post-download script /tmp/generate_retro_manifest.sh regenerates games.json
- Filebrowser (port 8080) exists for LAN file management but creds unknown
- Drop zone upload needs backend service (future session)

---

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

## 2026-03-01 23:30 — KPAB.FM v2 Radio Player
- Fixed catalog: 4,332 → 10,594 tracks (rewrote bash→Python generator)
- Added progress bar (elapsed/duration from API + client-side 1s tick)
- History track actions: YouTube + Wikipedia search on hover/tap
- PWA: manifest, service worker, apple-touch-icon, Media Session API
- Mobile polish: safe-area-insets, 100dvh, iOS zoom prevention
- Removed Club Home button
- Commit: 8a1a2fe

## 2026-03-01 00:50 — KPAB.FM Identity Layer
- Tagline: 'Pretty good most of the time. Sometimes great.'
- About/FAQ section with pirate radio philosophy
- Message drop integration for listener messages
- Request button moved above recently played
- History blink fixed (only re-renders on change)
- Offline page with auto-retry for Pi downtime
- Nginx: /msg/drop proxy for kpab.fm
- Commit: d897783

## 2026-03-02 00:45 — KPAB.FM FAQ Soul + ROM Download
- FAQ rewrite: anti-Spotify politics, no shuffle language, "my house"
- Added "WHY DOES THIS EXIST" + "WHATS COMING" sections
- Wizard of Oz principle: never reveal the shuffle
- Tiny Best Set Go ROM download restarted in tmux (nice/ionice, ~46GB)
- Pi power cycled after OOM from previous ia download attempt
- All 4 KPAB commits pushed to GitHub
- Commit: 24d9af9

## 2026-03-02 01:30 — KPAB.FM Design Polish
- Unified player chassis (now-playing + progress + controls as one panel)
- Container tightened 820→680px, breathing glow when playing
- 12 rotating cyan taglines, random on load (SubGenius energy)
- Copy polish: Mesa Cosa/Bone Soup links, pro wrestling bio
- History hover nudge, progress bar thicker, button hierarchy
- Stacey UX review implemented
- Commits: ff62540 → b0d9ff6

## 2026-03-03 - Golden Image Session

### What shipped:
- KPAB.FM JS crash fix (unescaped apostrophe)
- Deck dashboard status.json fix (nginx alias)
- Deck message drop → inbox viewer (read-only)
- Palestine + Conspiracy file browsers: in-page folder navigation with breadcrumbs
- Mary Poppins file renaming agent deployed
- Deck Knowledge Vault cards → green (solidarity)
- KPAB about/FAQ button styling, tagline rotation disabled, FAQ cleaned
- KPAB PWA manifest + service worker
- Music downloads: soundtracks (30), tony_hawk (5), electronic_deep (24) batches queued
- Catalog regenerated: 11,801 requestable tracks
- Alan Moore collection moved Shows → Comics

### Commit: 84a5897
### State: GOLDEN - all services running, Pi stable at 56C, 2.5GB/4GB RAM

## 2026-03-03 - Session 2: Polish + Tools + Downloads

### What shipped:
- kpab-grab: one-shot album downloader ("kpab-grab Artist Album")
- KPAB buttons: subtle gray default, cyan/magenta glow on hover
- KPAB FAQ: merged best-of, drop zone link, 10k blurb removed
- Deck: Admin moved to top, section headers colored (magenta/green/yellow)
- Deck: Forbidden Library + ROM Vault added to Fun section
- Pirate electronic batch: 46 albums (jungle/breaks/techno/dub/garage/acid)
- João Selva: Passarinho + Onda queued
- Comics cleaned via Mary Poppins, Alan Moore re-prefixed

### Commits: 84a5897 through d68e12e (8 commits)
### State: GOLDEN - all services up, downloads running in tmux

## 2026-03-04 — Nginx Simplification + Quick Wins
- Unified all 3 nginx server blocks to use same root (/usr/share/nginx/html)
- deck.quickcat.club and pibulus.local now rewrite / to /deck/index.html instead of using a different root
- Deleted ~36 lines of duplicated alias blocks (arcade, fiction, status.json)
- Fixed deck auth password (Church0fTheSubgeniu5!)
- Resurrected memos container (port 5230) in social.yml
- Added /memos/ and /go/ proxy routes to pibulus.local
- Added MEMOS and SHORTENER cards to deck admin section
- Fixed html volume mount — was :ro which broke overlay mounts, caused stale file cache
- All 12 endpoints verified 200
--- RECOVERY LOG 2026-03-24 ---
✅ SD Card Recovery: Full services restored.
✅ RAM/Swap Optimization: 4GB total swap (zram + file), swappiness 10.
✅ Redundancy: Golden Image created on HDD.
✅ UI/UX: Fixed deck terminal, gum, figlet, lolcat, and bunker alias.
