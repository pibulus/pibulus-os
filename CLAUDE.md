# PIBULUS CYBERDECK — Claude Code Instructions

## The System
Raspberry Pi 5 (4GB RAM) running Quick Cat Club — a personal internet on a tiny box.
Self-hosted platform: pirate radio (KPAB.FM), media libraries, retro arcades, offline knowledge.
Owner: Pablo (pibulus). Philosophy: anti-scale, anti-subscription, "can't scale IS the feature."

## Core Rules
1. Always operate within `~/pibulus-os/` for project work
2. Never track `.env` files or credentials in git
3. Use `gum` for TUI interactions when available
4. Never unmount Passport drive without user confirmation
5. Check `free -h` before launching heavy containers (4GB RAM, 2GB zram + 2GB file swap)
6. Pull Docker images ONE AT A TIME — concurrent pulls OOM-kill sshd
7. Validate YAML after writing: `python3 -c "import yaml; yaml.safe_load(open('file'))"`
8. `sed -i` on bind-mounted files breaks the mount (new inode) — use tmpfile+mv pattern instead
9. After editing bind-mounted configs: `docker compose up -d --force-recreate <service>`
10. SD card is ~87% full — write large files to Passport HDD, never SD card

## Key Paths
```
~/pibulus-os/                  # Project root (symlink → /media/pibulus/passport/pibulus-os/)
~/pibulus-os/config/stacks/    # Docker compose: pirate.yml, admin.yml, social.yml, utilities.yml
~/pibulus-os/config/nginx/     # hardening.conf (2 server blocks: quickcat.club + kpab.fm)
~/pibulus-os/config/cloudflared/ # Tunnel config
~/pibulus-os/scripts/          # All operational scripts
~/pibulus-os/modules/          # 18 launcher TUI modules
~/pibulus-os/www/html/         # Web pages served by nginx
~/azuracast/                   # AzuraCast compose (SEPARATE from stacks — own lifecycle)
~/jellyfin/                    # Jellyfin compose (SEPARATE from stacks — host network, port 8096)
/media/pibulus/passport/       # 5.5TB NTFS HDD (lowercase p, case-sensitive!)
/media/pibulus/MEMBOT/         # 1TB FAT32 USB (retro ROMs, media)
~/.config/api_keys             # All API keys (sourced by .bashrc)
~/.secrets/azuracast_key       # AzuraCast API key (chmod 600)
```

## Documentation (all in ~/pibulus-os/)
- `GLOSSARY.md` — Complete system map: services, URLs, ports, repo structure
- `FIELD_MANUAL.md` — Access tiers, internal ports, emergency procedures
- `ELI.md` — ELI12/27/42 explanations of the project
- `README.md` — Philosophy and architecture overview
- `SHIP_LOG.md` — Session diary / build history

## Docker Services
| Service | Container | Port | Stack | Notes |
|---------|-----------|------|-------|-------|
| Nginx | web_host | 80 | admin.yml | Reverse proxy for everything |
| Jellyfin | jellyfin | 8096 | ~/jellyfin/ | PINNED 10.11.5 — DO NOT UPDATE (arm64 bug) |
| Navidrome | navidrome | 4533 | pirate.yml | Groups by albumartist tag, not folders |
| Calibre-Web | calibre-web | 8083 | pirate.yml | calibredb add eats ~90MB RAM |
| Kavita | kavita | 5000 | pirate.yml | Memory capped: 1GB RAM / 1.5GB swap |
| Memos | memos | 5230 | social.yml | |
| AzuraCast | azuracast | 8500/8000 | ~/azuracast/ | Network 172.18.x.x, MariaDB eats ~480MB swap |
| URL Shortener | shortener | 8088 | utilities.yml | |
| Filebrowser | filebrowser | 8091 | utilities.yml | vault.quickcat.club, s6 image listens on 80 |
| slskd | slskd | 5030 | — | Soulseek, downloads to Passport/Soulseek |
| Kiwix | kiwix | 8084 | — | Offline Simple English Wikipedia |
| Tunarr | tunarr | 8100 | — | TV channel scheduling |
| Immich | (stopped) | — | immich.yml | RAM-heavy, start manually only |

## Custom Services (systemd)
| Service | Port | What |
|---------|------|------|
| kpab-services | 8086-8092 | Wall, shoutbox, dropzone, mutiny, hearts |
| ttyd-terminal | 7682 | Admin web terminal (authenticated) |
| ttyd-public | 7683 | Read-only cyberdeck terminal |
| cloudflared | — | Cloudflare tunnel |

## KPAB.FM Radio Stack
- Player: PWA with IndexedDB catalog (13K+ tracks), Media Session API
- Stream: AzuraCast Icecast on :8000, admin on :8500
- Catalog: `gen_request_catalog.py` regenerates every 6h (cron) — request IDs rotate!
- Mutiny: `mutiny.py` on :8090 — skip system, 1 skip per IP per 10min
- Hearts: `kpab_hearts.py` on :8092 — heart weighting, cron auto-requests favorites every 2h
- Shoutbox: `kpab_shoutbox.py` on :8087 — Transmission Wall
- AzuraCast API key: `~/.secrets/azuracast_key` — gets invalidated on container rebuild!

## Public URLs
**quickcat.club**: `/` `/pico/` (2995 PICO-8 carts) `/arcade/` (IF) `/arcade/retro/` (EmulatorJS) `/fiction/` `/wall/` `/msg/` `/wiki/` `/drop/` `/deck/` `/memos/` `/go/` `/mission-control/` `/terminal/` `/ttyd/` (auth) `/conspiracy/` `/palestine/`
**kpab.fm**: `/` (player) `/api/` `/radio.mp3` (stream) `/catalog.json` `/mutiny/` `/msg/` (shoutbox)
**Subdomains**: deck/watch/music/read/comics/vault.quickcat.club

## Tools Installed
- `yt-dlp` (~/.local/bin/) — video/audio downloads
- `aria2c` — multi-connection downloads (16 connections)
- `ia` (~/.local/bin/) — Internet Archive CLI
- `aichat` — Rust AI CLI (configured with Gemini)
- `bishop` — 11-mode TUI AI companion (gum + aichat)
- `gum` / `figlet` / `lolcat` / `bat` / `btop` / `dust` — TUI tools
- `transmission-cli` — terminal torrent client

## Deploy Pipeline (from Mac)
- `ship-to-pi.sh <app-dir>` — build → SCP → systemd → nginx → tunnel → DNS
- `activate-domain.sh <domain>` — Cloudflare zone + Porkbun NS + CNAME to tunnel
- Fresh/Deno apps run natively on Pi (Deno 2.7.9 installed)

## Critical Gotchas
- DO NOT autostart all Docker services on boot — stagger or start manually (OOM risk)
- AzuraCast API key gets invalidated when container is rebuilt — re-check after any AzuraCast Docker work
- Jellyfin library scan with TMDb on 200+ series = timeout cascade. Use MetadataRefreshMode=None first.
- Jellyfin episode filenames MUST be S01E01 format — no other format works
- nginx rate limiting: server-level limit_req hits static assets too. Use separate zones.
- Navidrome groups by albumartist tag, not folder structure — missing tags = split albums
- Docker bind mount with `:ro` on parent dir breaks overlay sub-mounts
- Filebrowser: DB file must be `touch`ed before Docker mount or Docker creates a directory
- Cloudflare DNS (not Porkbun) is authoritative for quickcat.club — Zone ID: b7fce43937c8160a9639c9d452bf5120

## Cron
- Every 6h: `gen_request_catalog.py` (KPAB catalog refresh)
- Every 2h: `kpab_heart_cron.py` (auto-request hearted tracks)
- 3am nightly: `nightly-backup.sh`

## Emergency
- OOM/SSH hang → power cycle Pi (pull USB-C)
- Nginx down → `docker restart web_host`
- All services down → `~/pibulus-os/scripts/start-kpab-services.sh`
- Tunnel down → `sudo systemctl restart cloudflared`
- High temp → check fan, `vcgencmd measure_temp`
- SD corruption → reflash from golden image at `/media/pibulus/passport/Backups/Golden_Images/`
- Drive disconnect → check USB-C power to Passport
