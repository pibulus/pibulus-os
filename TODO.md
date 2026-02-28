# TODO - Quick Cat Club

> Append new items. Check off when done. Move to LEDGER.md when a batch is complete.

---

## 🔥 Active

- [ ] **Calibre-Web** first-time setup: http://pibulus.local:8083 → library path `/books` → change password from admin123
- [ ] **Kavita** add Comics library: Admin → comics.quickcat.club → Libraries → Add → Comic/Manga → `/comics`
- [ ] **Jellyfin** setup wizard: http://pibulus.local:8096 → create admin → add libraries (music, movies, shows)
- [ ] **Gluetun/PureVPN** — add `PUREVPN_USER` + `PUREVPN_PASSWORD` to `~/pibulus-os/.env` then `docker compose -f pirate.yml up -d gluetun`
- [ ] **icloudpd** — needs Apple ID + app-specific password config, currently unhealthy
- [ ] **kpab.fm** — run remaining download batches once current ones finish: check with `tail -f /tmp/kpab_garage.log`

## 🧊 Backlog

- [ ] **ErsatzTV** — was crash-looping (.NET arm64 error), needs investigation before starting. tv.quickcat.club currently 404s
- [ ] **Immich ML** — run face detection pass then stop container to free ~2GB RAM
- [ ] **Sleaford Mods + black midi** — not on Soulseek right now, retry batches later
- [x] **OpenClaw** — killed (Session 3), process removed, RAM freed
- [x] **Security review** — nginx hardened (server_tokens off, security headers, Cloudflare real IP), rpcbind disabled, dead tunnel route removed

## ✅ Recently Done

- [x] AzuraCast stripped from ~100 ports to 9 ports — fixed port conflicts with Jellyfin/Calibre/Filebrowser
- [x] Calibre library: 430 Assorted books imported (964 total). Junk culled.
- [x] AzuraCast now sees both Soulseek dirs (My_Library + Soulseek_New)
- [x] Filebrowser port fix (8080->80 internal)
- [x] Docker disk cleanup: removed unused images (calibre:latest 4.7GB, gluetun), freed ~8GB on root
- [x] Immich ML stopped to save RAM (~500MB)
- [x] Kavita crash-loop fixed (ServerSetting enum fields CoverImageSize/PdfRenderResolution needed named values not numeric)
- [x] read.quickcat.club → Calibre-Web (8083), comics.quickcat.club → Kavita (5000)

- [x] Calibre-Web added on port 8083 for books (proper author/series browsing)
- [x] Kavita stripped to comics-only (no more "series of 1" weirdness)
- [x] Homepage: Library split into Comics + Books entries
- [x] Kavita DB: DarkPink theme, clean dashboard + sidenav
- [x] Comics library populated (~25GB from Mac)
- [x] kpab.fm downloader script (`~/kpab_downloader.py`) — 10 batches, 139 albums
- [x] aus + uk_bangers batches done (26/35 FLAC — Fontaines, Idles, TFS, Sampa, Hiatus Kaiyote etc.)
- [x] deck.quickcat.club htpasswd fixed (was broken hash)
- [x] slskd API patterns cracked + documented in TOOLS.md
- [x] MANIFESTO.md + GLOSSARY.md absorbed into other docs, removed
