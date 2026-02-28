# PIBULUS OS

A personal internet running on a Raspberry Pi 5.

---

## What This Is

A Raspberry Pi 5 with 4GB of RAM and a 5.5TB hard drive, sitting under a desk in Melbourne. It runs pirate radio, a film library, a book collection, retro games, comics, an offline copy of Wikipedia, and a file drop for friends to contribute to the collection. No cloud provider. No tracking. No subscriptions. Just Docker containers doing their best on a computer that costs less than a month of streaming services.

It's a few things at once:

**A Noah's Ark.** Music, books, films, games, comics, and an encyclopedia — all preserved locally on a hard drive. If the internet disappeared tomorrow, the collection survives. 4,000+ songs, 964 books, 634 Mega Drive games, and all of Wikipedia in a box you can carry.

**A community centre.** Friends can stream movies, browse comics, play retro games, request songs on pirate radio, upload files to the collection, and read books — all from a single URL. No accounts for public stuff. Friend-tier services use a shared password. Nobody gets monetized.

**A WiFi hotspot.** Bring the Pi to a house show and people connect to KPAB-Hotspot directly. No internet required. They get radio, games, Wikipedia, and the landing page over local WiFi. Like a digital zine table.

**A deployment platform.** Apps and domains route through Cloudflare Tunnel. No port forwarding. Add a hostname, point it at a container, and it's live. It replaces Vercel for anything that fits on a Pi.

**A pirate radio station.** KPAB.FM broadcasts 24/7 with auto-DJ. Full song request system. 4,000+ tracks. No ads. No algorithms. Just music.

**A statement.** You can build your own internet outside the platforms. This is the proof.

---

## Services

### Public (no login)
| Service | What | URL |
|---------|------|-----|
| Landing page | The front door | quickcat.club |
| KPAB.FM | 24/7 pirate radio + requests | kpab.fm |
| Retro Arcade | 634 Mega Drive games in browser | quickcat.club/arcade/retro/ |
| Text Adventures | Interactive fiction | quickcat.club/arcade/ |
| Wikipedia | Offline encyclopedia | quickcat.club/wiki/ |
| Drop Zone | Upload files to the collection | quickcat.club/drop/ |

### Friends (shared password)
| Service | What | URL |
|---------|------|-----|
| Jellyfin | Movies, shows, audiobooks | watch.quickcat.club |
| Navidrome | Hi-fi music streaming | music.quickcat.club |
| Calibre-Web | 964+ ebook library | read.quickcat.club |
| Kavita | Comics and manga | comics.quickcat.club |

### Admin (auth required)
| Service | What | URL |
|---------|------|-----|
| Deck | Control panel + launcher | deck.quickcat.club |
| Filebrowser | Full drive access | (LAN only) |
| Soulseek | P2P music sharing | (LAN only) |
| Homepage | System dashboard | (LAN only) |
| The Lounge | IRC client | (LAN only) |

### Background
| Service | What |
|---------|------|
| AzuraCast | Radio automation engine |
| Kiwix | Wikipedia server |
| OpenClaw | AI agent gateway (Telegram + Gemini) |
| Dropzone | File upload backend |
| icloudpd | iCloud photo sync |

---

## Architecture

**Hardware:** Raspberry Pi 5 (4GB), 58GB SD card (OS), 5.5TB USB passport drive (everything else).

**Containers:** 15 Docker containers across 4 compose stacks:
- `pirate.yml` — media services (Jellyfin, Navidrome, Kavita, Calibre-Web, Soulseek, Filebrowser, nginx)
- `social.yml` — IRC
- `admin.yml` — Homepage, web terminal, Kiwix
- `immich.yml` — photo management (optional)

**Networking:** Cloudflare Tunnel routes public traffic. No ports exposed to the internet. Nginx handles virtual hosts, rate limiting, security headers, and Cloudflare real IP forwarding. fail2ban watches SSH.

**Self-care:** Weekly cron prunes Docker images, clears caches, flushes RAM, and checks system health. OpenClaw has a memory guard that won't start if RAM is too low. Logs rotate. The system maintains itself.

**Documentation:**
- `FIELD_MANUAL.md` — operational reference (ports, access, emergencies)
- `GLOSSARY.md` — maps every file, service, and script
- `TODO.md` — what's left to do
- `SHIP_LOG.md` — session diary

---

## Access Tiers

**Public** — anyone with the URL. Radio, arcade, Wikipedia, drop zone. No login, no tracking, no questions.

**Friends** — anyone Pablo trusts. Movies, music, books, comics. Shared credentials, given in person.

**Admin** — Pablo. Full system access via deck.quickcat.club (basic auth) or SSH.

**LAN** — anyone on the local network or KPAB-Hotspot WiFi. Gets the deck at pibulus.local. No internet needed.

---

## Quick Start

```bash
# SSH in
ssh pibulus@pibulus.local

# Launch the cyberdeck menu
deck

# Check system health
cat /media/pibulus/passport/www/html/status.json | python3 -m json.tool

# Start all stacks
cd ~/pibulus-os
docker compose -f config/stacks/pirate.yml up -d
docker compose -f config/stacks/social.yml up -d
docker compose -f config/stacks/admin.yml up -d

# Run self-care manually
bash ~/pibulus-os/scripts/selfcare.sh

# Emergency: everything is frozen
# Power cycle the Pi. It comes back. It always comes back.
```

---

## The Repo

```
pibulus-os/
├── config/
│   ├── nginx/          # Nginx config + htpasswd
│   └── stacks/         # Docker compose files
├── scripts/
│   ├── selfcare.sh     # Weekly system maintenance
│   ├── openclaw-guard.sh   # AI gateway RAM check
│   ├── openclaw-cleanup.sh # Session pruning
│   ├── dropzone.py     # Upload server
│   ├── deploy.sh       # Stack deployment wizard
│   └── status.sh       # Health check (runs every 5 min)
├── www/html/           # Git-tracked web content
├── FIELD_MANUAL.md     # Ops reference
├── GLOSSARY.md         # System map
├── TODO.md             # Remaining work
├── SHIP_LOG.md         # Session diary
└── README.md           # You are here
```

---

## Philosophy

This project exists because the internet became a shopping mall and we wanted a park.

Every service on this Pi does one thing. Jellyfin serves video. Navidrome serves music. Kavita serves comics. No service tries to be two things. No service tracks you. No service asks you to subscribe.

The constraint is the feature. 4GB of RAM means every container earns its place. A 58GB SD card means Docker images get pruned. A single hard drive means the collection is curated, not hoarded. Limitations force taste.

This isn't a homelab flex. It's not a resume project. It's a working server that real people use to watch films, listen to music, play games, and read books. It replaces Netflix, Spotify, Kindle, and a dozen other subscriptions with a box under a desk and a Cloudflare tunnel.

Software is politics. Every platform you use is a statement about who owns your attention. This server says: nobody does. The data lives on a drive you can hold. The services run on a computer you own. The radio plays what you choose. The books are yours to keep.

Build yours. A Pi, a drive, and a weekend. That's all it takes.

---

Built by Pablo. Melbourne. Quick Cat Club.

License: Do whatever you want with this. It's a zine, not a product.
