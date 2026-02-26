# TODO - Quick Cat Club

> Append new items. Check off when done. Move to LEDGER.md when a batch is complete.

---

## 🔥 Active

- [ ] **Calibre-Web** first-time setup: http://pibulus.local:8083 → library path `/books` → change password from admin123
- [ ] **Kavita** add Comics library: Admin → Libraries → Add → Comic/Manga → `/comics`
- [ ] **Jellyfin** setup wizard: http://pibulus.local:8096 → create admin → add libraries (music, movies, shows)
- [ ] **Gluetun/PureVPN** — add `PUREVPN_USER` + `PUREVPN_PASSWORD` to `~/pibulus-os/.env` then `docker compose -f pirate.yml up -d gluetun`
- [ ] **icloudpd** — needs Apple ID + app-specific password config, currently unhealthy
- [ ] **kpab.fm** — run remaining download batches once current ones finish: check with `tail -f /tmp/kpab_garage.log`

## 🧊 Backlog

- [ ] **ErsatzTV** — was crash-looping (.NET arm64 error), needs investigation before starting. tv.quickcat.club currently 404s
- [ ] **Immich ML** — run face detection pass then stop container to free ~2GB RAM
- [ ] **Sleaford Mods + black midi** — not on Soulseek right now, retry batches later
- [ ] **read.quickcat.club** — currently points to Kavita (5000). Consider if Calibre-Web should get its own subdomain
- [ ] **AzuraCast port cleanup** — review if hundreds of Icecast relay ports are needed or can be trimmed
- [ ] **OpenClaw** — run `openclaw onboard` to connect messaging + API key if not done
- [ ] **Security review** — basic auth on any other public subdomains? Review what's exposed

## ✅ Recently Done

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
