# 📖 GLOSSARY — Quick Cat Club / PIBULUS OS

> Everything named, everything pointed to. The map of the ship.

---

## 🐾 The System

| Name | What | Where |
|------|------|-------|
| **PIBULUS** | Raspberry Pi 5 (4GB) home server | Pablo's desk, Brunswick |
| **Quick Cat Club** | The project name, the domain, the vibe | quickcat.club |
| **KPAB.FM** | Pirate internet radio station | kpab.fm |
| **The Passport** | 5.5TB NTFS external hard drive | /media/pibulus/passport |
| **MEMBOT** | 1TB FAT32 USB drive (retro ROMs, media) | /media/pibulus/MEMBOT (UUID=649A-D7FA) |
| **The Deck** | TUI launcher for managing everything | `deck` command → launcher.sh |

---

## 📦 Docker Services

| Service | Container | Port | Stack |
|---------|-----------|------|-------|
| **Nginx** | web_host | 80 | admin.yml |
| **Jellyfin** | jellyfin | 8096 | pirate.yml |
| **Navidrome** | navidrome | 4533 | pirate.yml |
| **Calibre-Web** | calibre-web | 8083 | pirate.yml |
| **Kavita** | kavita | 5000 | pirate.yml |
| **Memos** | memos | 5230 | social.yml |
| **AzuraCast** | azuracast | 8500/8000 | ~/azuracast/ (own stack) |
| **URL Shortener** | shortener | 8088 | utilities.yml |
| **Immich** | (stopped) | — | immich.yml (RAM-heavy, start manually) |

---

## 🌐 Public URLs (quickcat.club)

| Path | Service | Notes |
|------|---------|-------|
| `/` | Landing page | Static |
| `/pico/` | PICO-8 Arcade (2995 carts) | In-browser player, gamepad support |
| `/arcade/` | Interactive Fiction hub | Text adventures |
| `/arcade/retro/` | EmulatorJS retro games | GB, GBA, NES, N64, SNES, TG16 |
| `/fiction/` | Fiction browser | Curated IF collection |
| `/wall/` | Community pixel wall | Place tiles, shoutbox |
| `/msg/` | Message drop system | Anonymous drops |
| `/wiki/` | Offline Wikipedia (Kiwix) | Proxy to :8084 |
| `/conspiracy/` | Conspiracy files | Static content |
| `/palestine/` | Palestine page | Static content |
| `/drop/` | Drop Zone upload page | File upload via :8085 |
| `/deck/` | Cyberdeck (read-only) | Proxy to :7683 |
| `/terminal/` | Admin web terminal | Proxy to :7682, auth required |
| `/memos/` | Personal notes (Memos) | Proxy to :5230 |
| `/go/` | URL shortener | Proxy to :8088 |
| `/mission-control/` | System dashboard | Static + status.json |
| `/terminal/` | Terminal page | Static |

## 🌐 Public URLs (kpab.fm)

| Path | Service | Notes |
|------|---------|-------|
| `/` | KPAB Radio player | PWA, IndexedDB catalog |
| `/api/` | AzuraCast API | Proxy to :8500 |
| `/radio.mp3` | Live audio stream | Proxy to :8000 |
| `/catalog.json` | Song request catalog | Regenerated every 6h |
| `/mutiny/` | Mutiny request system | Proxy to :8090 |
| `/msg/` | Shoutbox (shared) | Proxy to :8087 |

## 🔗 Subdomain URLs

| URL | Service | Access |
|-----|---------|--------|
| deck.quickcat.club | Admin dashboard (Homepage) | Basic auth |
| watch.quickcat.club | Jellyfin (movies & shows) | Friend tier |
| music.quickcat.club | Navidrome (hi-fi music) | Friend tier |
| read.quickcat.club | Calibre-Web (books) | Friend tier |
| comics.quickcat.club | Kavita (graphic novels) | Friend tier |

---

## 📁 Repo Structure

```
pibulus-os/
├── launcher.sh              # Cyberdeck TUI (type `deck`)
├── install.sh               # Fresh install bootstrap
├── onboard.sh               # First-run setup
├── welcome.sh               # Welcome screen
├── .env                     # Secrets (git-ignored)
│
├── config/
│   ├── stacks/              # Docker compose files
│   │   ├── pirate.yml       # Jellyfin, Navidrome, Calibre, Kavita
│   │   ├── social.yml       # Memos
│   │   ├── admin.yml        # Homepage, web terminal
│   │   ├── utilities.yml    # URL shortener
│   │   └── immich.yml       # Photo vault (stopped by default)
│   ├── nginx/
│   │   ├── hardening.conf   # Full nginx config (2 server blocks)
│   │   └── .htpasswd        # Basic auth for deck
│   ├── cloudflared/
│   │   ├── config.yml       # Tunnel routing
│   │   └── .gitignore       # Excludes credentials JSON
│   ├── systemd/             # Custom service files
│   │   ├── cloudflared.service
│   │   ├── cloudflared-update.service
│   │   ├── kpab-services.service
│   │   ├── mutiny.service
│   │   └── ttyd-terminal.service
│   ├── system/              # System configs for disaster recovery
│   │   ├── fstab
│   │   ├── crontab.txt
│   │   ├── fstrim-override.conf
│   │   ├── bashrc-custom.sh
│   │   └── README.txt
│   └── homepage-admin/      # Dashboard config + themes
│
├── modules/                 # Launcher TUI modules
│   ├── audio_feedback.sh    # Sound effects
│   ├── audit_module.sh      # System audit tools
│   ├── backup_module.sh     # Backup & golden image
│   ├── bunker_module.sh     # Security mode toggle
│   ├── downloads_module.sh  # Download management
│   ├── eject_module.sh      # Safe drive eject
│   ├── games_module.sh      # Arcade & retro games
│   ├── grey_hat_module.sh   # Hacking toolkit
│   ├── knowledge_vault_module.sh  # Offline knowledge manager
│   ├── librarian_module.sh  # Book/media library tools
│   ├── media_puller.sh      # Download media
│   ├── mission_control_module.sh  # System monitoring
│   ├── pirate_grab_module.sh     # Media acquisition
│   ├── radio_module.sh      # AzuraCast controls
│   ├── scavenger_module.sh  # Resource scavenger
│   ├── sigint_module.sh     # Network scanning tools
│   ├── terminal_travels.sh  # SSH into other machines
│   └── vault_module.sh      # Encrypted vault open/close
│
├── scripts/                 # Operational scripts
│   ├── backup.sh / nightly-backup.sh  # Backup systems
│   ├── deploy.sh            # Service deployment wizard
│   ├── dropzone.py          # File upload handler
│   ├── flush_ram.sh         # Emergency RAM flush
│   ├── gen_request_catalog.py  # Song catalog refresh
│   ├── golden_image.sh      # Full system snapshot
│   ├── jellyfin_merge.py    # Jellyfin library tools
│   ├── kpab-drop / kpab-grab  # KPAB sync tools
│   ├── kpab_shoutbox.py     # Shoutbox backend
│   ├── mary_poppins.py      # Media organizer
│   ├── msgdrop.py           # Message drop backend
│   ├── mutiny.py            # Song request system
│   ├── network_mode.sh      # Network config
│   ├── openclaw-guard.sh    # AI agent monitor
│   ├── pirate_grab.py       # Media acquisition
│   ├── selfcare.sh          # System maintenance
│   ├── shortener.py         # URL shortener backend
│   ├── status.sh            # Health → status.json
│   ├── sync_arcade_roms.py  # ROM sync
│   ├── wall_server.py       # Pixel wall backend
│   └── zipbrowser.py        # ZIP file browser
│
├── www/html/                # Web pages (see URLs above)
│
├── DOCS_INDEX.md            # Where to start reading
├── GLOSSARY.md              # This file
├── ELI.md                   # ELI12/27/42 explanations
├── FIELD_MANUAL.md          # Access tiers, ports, emergencies
├── CLAUDE.md                # AI assistant context
├── README.md                # Project overview
└── SHIP_LOG.md              # Session diary
```

---

## ⏰ Cron Schedule

| When | Script | What |
|------|--------|------|
| 0 */6 * * * | gen_request_catalog.py | Refresh KPAB song catalog |
| 0 3 * * * | nightly-backup.sh | Nightly backup to Passport drive |

---

## 🔧 Key Commands

| Command | What |
|---------|------|
| `deck` | Launch the cyberdeck TUI |
| `btop` | System monitor |
| `dust` | Visual disk usage |
| `glow FILE.md` | Render markdown in terminal |
| `bat FILE` | Syntax-highlighted file viewer |

---

## 🛡️ Security Layers

| Layer | What |
|-------|------|
| Cloudflare Tunnel | Pi's real IP never exposed (ID: c79eb8a2-...) |
| Nginx rate limiting | General: 1r/s burst=20 · Static: 50r/s burst=100 |
| Basic auth | deck.quickcat.club password-protected |
| ttyd auth | Web terminal requires login |
| Security headers | X-Frame-Options, X-Content-Type, CSP, etc |
| server_tokens off | Nginx version hidden |
| Cloudflare real IP | Rate limiting uses actual client IPs |
| Quad9 DNS | Encrypted, Swiss-based DNS |

---

## 🏗️ Architecture

- **OS**: Raspberry Pi OS Lite (Trixie/Bookworm arm64)
- **RAM**: 4GB + active swap/zram pressure
- **HDD**: `/media/pibulus/passport` (5.5TB NTFS, UUID=E8BC1973BC193D8E)
- **USB**: `/media/pibulus/MEMBOT` (1TB FAT32, UUID=649A-D7FA)
- **Tunnel**: Cloudflare (c79eb8a2-9791-4ece-8b54-bc9d0e6d01cd)
- **Backups**: Nightly to `/media/pibulus/passport/Backups/pi-system/`

---

*Updated: 2026-03-29*
