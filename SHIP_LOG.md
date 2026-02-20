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
- Fixed romm env var rename (ROMM_AUTH_SECRET -> ROMM_AUTH_SECRET_KEY)
- Fixed gluetun region (Australia -> Victoria)
- Set up Cloudflare Tunnel subdomains for all media services
- Added 5 CNAME records via Cloudflare API
- Stored Cloudflare API token + static IP in ~/.config/api_keys on Mac
- Removed hexbloop.app from tunnel config
- Fixed emulatorjs port conflict (3000 -> 3002, was clashing with gitea)
- Fixed gluetun/emulatorjs restart policies to "no" (prevent crash-loops)
- Added Soulseek download path to Navidrome (was missing new downloads)
- Removed ghost lowercase folders from passport (music/, roms/, media/)
- Removed stale Jellyfin /media mount
- Rebuilt Homepage admin dashboard (was missing most services)
- Fixed tv.quickcat.club port (8000 -> 8001 for ErsatzTV)

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
- [ ] **EmulatorJS**: Not created yet. `docker compose -f pirate.yml up -d emulatorjs`
- [ ] **ErsatzTV**: Was crash-looping (.NET error). Needs investigation before starting
- [ ] **icloudpd**: Needs Apple ID configuration (run init script)
- [ ] **OpenClaw onboard**: Run `openclaw onboard` to connect messaging + API key
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
2. SSH in: `ssh pibulus@pibulus.local` (password: meringue)
3. Check what's running: `docker ps`
4. Check RAM: `free -h`
5. If swap is 2.0/2.0: stop heavy containers: `docker stop immich_machine_learning romm ersatztv`
6. Restart media: `cd ~/pibulus-os/config/stacks && docker compose -f pirate.yml up -d jellyfin navidrome kavita web_host`
7. Restart radio: `cd ~/azuracast && docker compose up -d`
8. Check subdomains: `curl -I https://watch.quickcat.club`
9. Cloudflared config: `/etc/cloudflared/config.yml`
10. Restart tunnel: `sudo systemctl restart cloudflared`
