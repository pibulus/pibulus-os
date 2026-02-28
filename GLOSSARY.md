# 📖 GLOSSARY — Quick Cat Club / PIBULUS OS

> Everything named, everything pointed to. The map of the ship.

---

## 🐾 The System

| Name | What | Where |
|------|------|-------|
| **PIBULUS** | Raspberry Pi 5 (4GB) home server | Pablo's desk, Brunswick |
| **Quick Cat Club** | The project name, the domain, the vibe | quickcat.club |
| **KPAB.FM** | Pirate internet radio station | kpab.fm |
| **Bishop** | OpenClaw AI agent (Gemini-powered, Telegram-connected) | ~/.openclaw/ |
| **The Passport** | 5.5TB NTFS external hard drive | /media/pibulus/passport |
| **The Deck** | TUI launcher for managing everything | `deck` command → launcher.sh |
| **KPAB-Hotspot** | WiFi AP for direct connection (no internet needed) | wlan0 @ 10.42.0.1 |

---

## 📦 Docker Stacks

| Stack | File | Services |
|-------|------|----------|
| **Admin** | config/stacks/admin.yml | Homepage, Web Terminal |
| **Immich** | config/stacks/immich.yml | Photo vault + ML (stopped by default) |
| **AzuraCast** | ~/azuracast/docker-compose.yml | Radio engine (its own stack) |
| **Kiwix** | standalone docker run | Offline Wikipedia |

---

## 🌐 Public URLs

| URL | Service | Access |
|-----|---------|--------|
| quickcat.club | Landing page, FAQ, arcade, wiki | Public |
| quickcat.club/wiki/ | Offline Wikipedia (Kiwix) | Public |
| quickcat.club/arcade/ | Text adventures (IF games) | Public |
| quickcat.club/arcade/retro/ | EmulatorJS retro games | Public |
| kpab.fm | Pirate radio + song requests | Public |
| deck.quickcat.club | Admin control panel | Basic auth |
| watch.quickcat.club | Jellyfin (movies & shows) | Friend tier |
| music.quickcat.club | Navidrome (hi-fi music) | Friend tier |
| read.quickcat.club | Calibre-Web (964 books) | Friend tier |
| comics.quickcat.club | Kavita (graphic novels) | Friend tier |

---

## 📁 Repo Structure

```
pibulus-os/
├── launcher.sh              # Cyberdeck TUI (type `deck`)
├── install.sh               # Fresh install bootstrap
├── onboard.sh               # First-run setup
├── welcome.sh               # Welcome screen
├── .env                     # Secrets (git-ignored values)
│
├── config/
│   ├── stacks/              # Docker compose files
│   │   ├── pirate.yml       # Media services
│   │   ├── social.yml       # Community services
│   │   ├── admin.yml        # Dashboard + terminal
│   │   ├── immich.yml       # Photo vault
│   │   └── .env             # Stack-level secrets
│   ├── nginx/
│   │   ├── hardening.conf   # Nginx config (4 server blocks)
│   │   └── .htpasswd        # Basic auth for deck
│   └── homepage-admin/      # Dashboard config + themes
│
├── modules/                 # Launcher TUI modules
│   ├── audio_feedback.sh    # Sound effects (confirm/alert/etc)
│   ├── media_puller.sh      # Download media via slskd
│   ├── terminal_travels.sh  # SSH into other machines
│   ├── backup_module.sh     # Backup & golden image
│   ├── audit_module.sh      # System audit tools
│   ├── knowledge_vault_module.sh  # Offline knowledge manager
│   ├── radio_module.sh      # AzuraCast controls
│   ├── eject_module.sh      # Safe drive eject
│   ├── bunker_module.sh     # Security mode toggle
│   ├── vault_module.sh      # Encrypted vault open/close
│   ├── sigint_module.sh     # Network scanning tools
│   ├── games_module.sh      # Arcade & retro games
│   ├── grey_hat_module.sh   # Hacking toolkit
│   ├── mission_control_module.sh  # System monitoring
│   └── librarian_module.sh  # Book/media library tools
│
├── scripts/
│   ├── selfcare.sh          # Weekly system maintenance (Wed 3am)
│   ├── status.sh            # Health check → status.json (every 5min)
│   ├── gen_request_catalog.sh  # Song catalog refresh (every 6hr)
│   ├── openclaw-guard.sh    # Smart start/stop for Bishop
│   ├── openclaw-cleanup.sh  # Session/log pruning (Sun 4am)
│   ├── flush_ram.sh         # Emergency RAM flush
│   ├── golden_image.sh      # Full system snapshot
│   ├── deploy.sh            # Service deployment wizard
│   ├── set_identity.sh      # MAC/hostname identity
│   ├── set_stealth.sh       # Stealth mode toggle
│   ├── vault-open.sh        # Mount encrypted vault
│   ├── vault-close.sh       # Unmount encrypted vault
│   ├── start_drop.sh        # Drop Zone upload server
│   ├── generate_manifest.sh # Retro game manifest builder
│   ├── knowledge-vault-downloader.sh  # Offline knowledge downloader
│   └── cloudflare-maintenance-worker.js  # "Technical Difficulties" page
│
├── www/html/                # Git-tracked web pages
│   ├── index.html           # quickcat.club landing page
│   ├── kpab/index.html      # KPAB.FM radio player
│   ├── deck/index.html      # Admin deck page
│   ├── drop/index.html      # Drop Zone upload page
│   ├── arcade/index.html    # Text adventure hub
│   ├── arcade/retro/index.html  # EmulatorJS retro arcade
│   ├── arcade/games.json    # IF game manifest
│   └── mission-control/index.html  # System dashboard
│
├── FIELD_MANUAL.md          # Captain's handbook (ports, access, emergencies)
├── SHIP_LOG.md              # Session diary (append-only)
├── TODO.md                  # Active tasks & backlog
├── AI_HANDBOOK.md           # AI assistant context
└── README.md                # Project overview
```

---

## ⏰ Cron Schedule

| When | Script | What |
|------|--------|------|
| */5 * * * * | status.sh | Health → status.json |
| 0 */6 * * * | gen_request_catalog.sh | Refresh song catalog |
| 0 3 * * 3 | selfcare.sh | System cleanup (Wed 3am) |
| 0 4 * * 0 | openclaw-cleanup.sh | OpenClaw prune (Sun 4am) |

---

## 🔧 Key Commands

| Command | What |
|---------|------|
| `deck` | Launch the cyberdeck TUI |
| `halp` | Help page |
| `btop` | System monitor |
| `dust` | Visual disk usage |
| `glow FILE.md` | Render markdown in terminal |
| `bat FILE` | Syntax-highlighted file viewer |
| `fzf` | Fuzzy file finder |

---

## 🛡️ Security Layers

| Layer | What |
|-------|------|
| Cloudflare Tunnel | Pi's real IP never exposed |
| Nginx rate limiting | 1 req/sec, burst=5, 10 conn/IP |
| Fail2Ban | 3 SSH fails = 24hr ban |
| Basic auth | deck.quickcat.club password-protected |
| Security headers | X-Frame-Options, X-Content-Type, etc |
| server_tokens off | Nginx version hidden |
| Cloudflare real IP | Rate limiting uses actual client IPs |
| MAC randomization | Hardware ID rotated per connection |
| Quad9 DNS | Encrypted, Swiss-based DNS |

---

*Updated: 2026-03-01*
