# 🤖 AI HANDBOOK - PIBULUS CYBERDECK
### Instructions for LLMs (Claude, etc.) managing this system.

## CORE RULES
1. **Workspace:** Always operate within `~/pibulus-os/`.
2. **Passport:** Primary data drive at `/media/pibulus/passport`. Never unmount without confirmation.
3. **Security:** Never track `.env` files or credentials in Git.
4. **Consistency:** Use `gum` for TUI interactions on Pi.
5. **RAM:** Pi has 4GB - be careful starting heavy containers. Check `free -h` before launching.
6. **SSH:** Always use `-4` flag (IPv6 times out). If SSH hangs, Pi is likely OOM - needs power cycle.
7. **YAML:** Always validate after writing: `python3 -c "import yaml; yaml.safe_load(open('file'))"`
8. **Heredocs:** SSH heredocs often fail via sshpass - use `cat > /tmp/script.py << 'EOF'` then execute.

## SSH ACCESS
```bash
sshpass -p 'meringue' ssh -4 -o ConnectTimeout=15 -o StrictHostKeyChecking=no pibulus@pibulus.local
```

## STACK ARCHITECTURE
All compose files in `~/pibulus-os/config/stacks/`:

| Stack | File | Services |
|-------|------|----------|
| Pirate | `pirate.yml` | Jellyfin, Navidrome, AzuraCast (separate), slskd, Kavita, Overseerr, Filebrowser, ErsatzTV, Gluetun VPN |
| Social | `social.yml` | Gitea, Memos, The Lounge (IRC) |
| Admin | `admin.yml` | Homepage, Web Terminal |

**AzuraCast** runs its own compose at `~/azuracast/docker-compose.yml` (managed by its own `docker.sh` script).

## SERVICE PORT MAP
| Port | Service | URL (external) | Notes |
|------|---------|----------------|-------|
| 80 | nginx (homepage/deck) | quickcat.club / deck.quickcat.club | Basic auth on deck |
| 4533 | Navidrome | music.quickcat.club | Music streaming, Subsonic API |
| 5000 | Kavita | read.quickcat.club | Ebooks & Comics |
| 5030 | slskd | (local only) | Soulseek P2P - web UI + API |
| 5055 | Overseerr | (local only) | Media requests |
| 5230 | Memos | (local only) | Microblogging |
| 7681 | Cyber Arcade | (local only) | Terminal games |
| 7682 | Web Terminal | (local only) | ttyd shell |
| 8000 | AzuraCast (Icecast) | radio.quickcat.club | Audio stream |
| 8080 | Filebrowser | (local only) | Passport drive browser |
| 8081 | Homepage Admin | (local only) | Dashboard |
| 8096 | Jellyfin | watch.quickcat.club | Video streaming (host network) |
| 8500 | AzuraCast (Web UI) | kpab.fm / www.kpab.fm | Radio admin at /login |
| 9000 | The Lounge | (local only) | IRC client |

## SOULSEEK (slskd)
- **Container:** `slskd` (standalone, no VPN)
- **Web UI:** `http://pibulus.local:5030` (login: slskd/slskd)
- **API:** Full REST API at `http://localhost:5030/api/v0/`
  - Auth: POST `/session` with `{"username":"slskd","password":"slskd"}` -> get JWT token
  - Search: POST `/searches` with `{"searchText":"query"}` -> get search ID
  - Results: GET `/searches/{id}/responses` (wait ~10-15s for results)
  - Download: POST `/transfers/downloads/{username}` with file list
- **Soulseek creds:** username `pibulus`, password `meringue`
- **Downloads:** `/media/pibulus/passport/Soulseek/` (mapped to `/app/downloads` in container)
- **Config:** `/opt/slskd/slskd.yml`
- **Note:** Soulseek throttles searches - one at a time. Wait for completion before next search.

## AZURACAST (KPAB.FM)
- **Admin:** `http://pibulus.local:8500/login` (email: pibulus@gmail.com)
- **CLI:** `docker exec azuracast azuracast_cli <command>`
  - `azuracast:account:list` - List users
  - `azuracast:settings:list` - View settings
  - `azuracast:settings:set <key> <value>` - Change settings
- **Settings:** `base_url=https://kpab.fm`, `prefer_browser_url=true`, `always_use_ssl=false`
- **Station:** `kpab.fm` (single station)
- **Media mount:** `/media/pibulus/passport/Music` -> `/var/azuracast/stations/kpab.fm/media/My_Library`
  - Contains: `MusicBee/` (organized library) and `Soulseek Downloads/` (raw downloads)
- **Override:** `~/azuracast/docker-compose.override.yml` handles the music mount

## NAVIDROME
- **API:** Subsonic API at `http://localhost:4533/rest/`
  - Auth params: `u=pibulus&p=meringue&v=1.16.1&c=claude&f=json`
  - Artists: GET `/rest/getArtists?...`
  - Albums: GET `/rest/getAlbumList2?type=newest&...`
- **Music dirs:** Library + Soulseek Legacy + Soulseek (new)
- **Admin:** pibulus/meringue, Guest: guest/quickcat

## KEY PATHS
```
~/pibulus-os/
├── config/stacks/         # Docker compose files
│   ├── pirate.yml         # Media & music stack
│   ├── social.yml         # Git, memos, IRC
│   ├── admin.yml          # Dashboard & terminal
│   └── .env               # Stack env vars (not tracked)
├── config/nginx/          # Nginx configs
├── config/homepage-admin/ # Homepage dashboard config
├── modules/               # Bash modules for deck menu
├── scripts/               # Utility scripts
├── welcome.sh             # SSH login greeting (v4.2)
├── AI_HANDBOOK.md         # THIS FILE
├── FIELD_MANUAL.md        # User-facing docs
├── LEDGER.md              # Change log
├── SHIP_LOG.md            # Session diary (append-only)
├── GLOSSARY.md            # Term definitions
├── MANIFESTO.md           # Project philosophy
└── README.md              # Project overview

~/azuracast/               # AzuraCast (separate compose)
├── docker-compose.yml
├── docker-compose.override.yml  # Music volume mount
├── azuracast.env
└── .env                   # Ports: HTTP=8500, HTTPS=8443

/media/pibulus/passport/   # 2TB external drive
├── Music/
│   ├── MusicBee/Music/    # Organized library
│   └── Soulseek Downloads/
│       ├── complete/      # Finished downloads
│       └── downloading/   # In progress
├── Soulseek/              # slskd download dir (new)
├── Movies/, Shows/, Audiobooks/, Comics/, Ebooks/
├── www/html/              # Static web pages
└── Backups/               # Golden images
```

## CLOUDFLARE TUNNEL
Config at `/etc/cloudflared/config.yml`. Tunnel ID: `c79eb8a2-9791-4ece-8b54-bc9d0e6d01cd`

| Hostname | Backend |
|----------|---------|
| quickcat.club | localhost:80 |
| deck.quickcat.club | localhost:80 (basic auth) |
| kpab.fm / www.kpab.fm | localhost:8500 |
| radio.quickcat.club | localhost:8000 |
| music.quickcat.club | localhost:4533 |
| watch.quickcat.club | localhost:8096 |
| read.quickcat.club | localhost:5000 |
| tv.quickcat.club | localhost:8001 |

## VPN (GLUETUN)
- Provider: PureVPN (OpenVPN)
- Creds in `~/pibulus-os/.env` (PUREVPN_USER, PUREVPN_PASSWORD)
- Currently set to `restart: "no"` - start manually if needed
- slskd runs standalone (no VPN) as of 2026-02-25

## GOLDEN IMAGE
Backup script creates compressed archive of `~/pibulus-os/` to Passport drive.
Recovery: Fresh OS install -> clone repo -> extract golden image.
