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
| 5000 | Kavita | comics.quickcat.club | Comics & graphic novels only |
| 8083 | Calibre-Web | read.quickcat.club | Book library — points at Calibre dir |
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
| 8088 | URL Shortener | go.quickcat.club | Python micro-app, systemd |
| 9000 | The Lounge | (local only) | IRC client |

## CALIBRE-WEB
- **Container:** `calibre-web` (port 8083)
- **Library:** `/media/pibulus/passport/Ebooks/Calibre-Library` (mounted as `/books`)
- **Config:** `/home/pibulus/.config/calibre-web/`
- **Default creds:** admin / admin123 (change after first login)
- **Stack:** pirate.yml

## KAVITA (Comics only)
- **Container:** `kavita` (port 5000)
- **Comics path:** `/media/pibulus/passport/Comics` (mounted as `/comics`)
- **Config/DB:** `/home/pibulus/.config/kavita/kavita.db` (root owned — stop container before editing)
- **Theme:** DarkPink (default for all users)
- **Note:** DB surgery via sqlite3 locally then scp back + `sudo cp`

## KPAB.FM MUSIC DOWNLOADER
- **Script:** `/home/pibulus/kpab_downloader.py`
- **Usage:** `python3 -u ~/kpab_downloader.py --list` / `--batch aus` / `--batch all`
- **Batches:** uk_bangers, uk_grime, aus, hiphop, garage, hardcore, shoegaze, electronic, cool_indie, krautrock
- **Run in tmux:** `tmux new-session -d -s kpab 'python3 -u ~/kpab_downloader.py --batch garage > /tmp/kpab.log 2>&1'`
- **Vibe rule:** Pirate radio. YES: garage/post-punk/grime/krautrock/shoegaze/underground hip-hop/Australian bands. NO: Dylan/ABBA/Queen/Fleetwood Mac/prog wank.

## SOULSEEK (slskd)
- **Two download dirs:**  (new, slskd) +  (legacy, 100GB)
- AzuraCast sees both via override mount (My_Library + Soulseek_New)
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
- **IMPORTANT:** docker-compose.yml was stripped to minimal ports (8000, 8200-8216, 8500, 8443, 2022). Old compose had 100+ ports (8000-8496) that stole ports from Jellyfin/Calibre/Filebrowser.
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

## BISHOP AI LIBRARIAN
- **Module:** `~/pibulus-os/modules/librarian_module.sh`
- **Quick command:** `deck search`
- **Engine:** `claude -p --model haiku` (headless, one-shot, $0.02 budget cap)
- **Data:** Searches `~/pibulus-os/mission-control/manifest.txt`
- **Fallback:** grep search when claude unavailable

## SCAVENGER BOT
- **Module:** `~/pibulus-os/modules/scavenger_module.sh`
- **Quick command:** `deck scavenge`
- **Engine:** `claude -p --model haiku` for tool selection ($0.03 budget cap)
- **Tools:** slskd API (Soulseek), yt-dlp, ia CLI, aria2
- **Smart Search:** Describe what you want, AI picks the best tool and crafts the query
- **Fallback:** Keyword heuristics when claude unavailable

## URL SHORTENER
- **Script:** `~/pibulus-os/scripts/shortener.py`
- **Service:** `shortener.service` (systemd, 32MB memory cap)
- **Port:** 8088
- **URL:** go.quickcat.club (needs Porkbun CNAME)
- **Storage:** `~/pibulus-os/data/shortener.json`
- **API:** POST `/shorten` with `{"url":"...","slug":"optional"}`, GET `/:slug` for redirect

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
| read.quickcat.club | localhost:8083 |
| comics.quickcat.club | localhost:5000 |
| memo.quickcat.club | localhost:5230 |
| go.quickcat.club | localhost:8088 |
| tv.quickcat.club | localhost:8001 |

## VPN (GLUETUN)
- Provider: PureVPN (OpenVPN)
- Creds in `~/pibulus-os/.env` (PUREVPN_USER, PUREVPN_PASSWORD)
- Currently set to `restart: "no"` - start manually if needed
- slskd runs standalone (no VPN) as of 2026-02-25

## GOLDEN IMAGE
Backup script creates compressed archive of `~/pibulus-os/` to Passport drive.
Recovery: Fresh OS install -> clone repo -> extract golden image.

## MEDIA ORGANIZATION (SHOWS)
- **Primary Path:** `/media/pibulus/passport/Shows`
- **Naming Rule:** Clean, simple titles (e.g., `Better Call Saul`, not `Better.Call.Saul.S01.1080p...`).
- **Structure:** `Show Title/Season X/Episode.mkv`.
- **Consolidation:** Avoid split season folders in the root. Always merge into a single show directory.
- **Jellyfin:** Host network mode (port 8096). Rescans automatically on file changes.

## JELLYFIN LIBRARY TOOLS

### jellyfin-merge (Season Merger)
- **Script:** `~/pibulus-os/scripts/jellyfin_merge.py`
- **Symlink:** `~/.local/bin/jellyfin-merge`
- **Purpose:** Merges split-season folders into proper Jellyfin structure (Show/Season XX/)
- **Zero AI calls** - pure pattern matching, very cheap to run
- **Usage:**
  ```bash
  jellyfin-merge /media/pibulus/passport/Shows --scan --dry-run   # Find problems
  jellyfin-merge /media/pibulus/passport/Shows --scan              # Fix them (confirms first)
  jellyfin-merge /media/pibulus/passport/Shows --eject "Folder"    # Move non-show out
  ```

### mary_poppins.py (Filename Cleaner)
- **Script:** `~/pibulus-os/scripts/mary_poppins.py`
- **Purpose:** Cleans messy filenames using AI (haiku model)
- **Uses claude CLI** - costs a few cents per batch
- **Patterns:** comics, music, movies, generic
- **Usage:**
  ```bash
  python3 ~/pibulus-os/scripts/mary_poppins.py /path/to/folder --pattern movies --dry-run
  python3 ~/pibulus-os/scripts/mary_poppins.py /path/to/folder --pattern music
  ```

## KPAB-DROP (URL to Radio)
- **Script:** `~/pibulus-os/scripts/kpab-drop`
- **Symlink:** `~/.local/bin/kpab-drop`
- **Purpose:** Download audio from any URL (SoundCloud, YouTube, Bandcamp, etc) into AzuraCast media
- **Engine:** yt-dlp (supports 1000+ sites)
- **Usage:**
  ```bash
  kpab-drop "https://soundcloud.com/artist/track"           # Single track
  kpab-drop "https://soundcloud.com/artist/sets/playlist"    # Full playlist/mix
  kpab-drop "https://youtube.com/watch?v=xxx"                # YouTube
  kpab-drop URL --dry-run                                     # Preview
  ```
- **Output:** Downloads to /media/pibulus/passport/Soulseek/ (AzuraCast auto-picks up)

## SIMPSONS GOLDMINE
- **Script:** `~/pibulus-os/scripts/simpsons_goldmine.py`
- **Symlink:** `~/.local/bin/simpsons-goldmine`
- **Purpose:** Find highly-rated episodes from later Simpsons seasons using IMDb data
- **Data:** IMDb public datasets (cached 7 days), pre-computed gems at ~/.cache/simpsons-goldmine/gems.json
- **Note:** Pi DNS (Tailscale) may not resolve datasets.imdbws.com - run from Mac and SCP cache
- **Usage:**
  ```bash
  simpsons-goldmine                          # S20+, 7.0+ rating
  simpsons-goldmine --min-season 15          # From S15
  simpsons-goldmine --min-rating 7.5         # Higher bar
  simpsons-goldmine --format torrent         # Output search strings
  ```

## PIRATE-GRAB (TV/Movie Grabber)
- **Script:** `~/pibulus-os/scripts/pirate_grab.py`
- **Symlink:** `~/.local/bin/pirate-grab`
- **Purpose:** Search torrents and download via transmission-cli. For legally owned media preservation.
- **Sources:** 1337x (primary) + Pirate Bay (fallback). Has relevance filtering to avoid garbage results.
- **Engine:** requests + BeautifulSoup scraping, NO heavy services (no Sonarr/Prowlarr/Jackett)
- **Usage:**
  ```bash
  pirate-grab "Show Name" --season 2 --dry-run      # Preview
  pirate-grab "Show Name" --season 2                  # Download
  pirate-grab "Show Name" -s 3 -e 6                   # Specific episode
  pirate-grab "Movie Name" --movie                     # Movies
  pirate-grab "query" --quality 720                    # Prefer 720p
  pirate-grab "query" --top 10                         # Show more results
  pirate-grab "query" --pick 3                         # Pick 3rd result
  ```
- **Output:** Downloads to /media/pibulus/passport/Shows (or /Movies with --movie)
- **Tip:** Run `jellyfin-merge --scan` after to organize any new season folders
- **Note:** Niche shows may only be on TPB. Very niche stuff might need manual search or slskd.
