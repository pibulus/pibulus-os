# PIBULUS CYBERDECK - Claude Code Instructions

## System Overview
Raspberry Pi 5 (4GB RAM) running the Quick Cat Club cyberdeck. Start at `~/pibulus-os/DOCS_INDEX.md`, then use `FIELD_MANUAL.md`, `GLOSSARY.md`, and the operational truth docs as needed.

## EMERGENCY / BREAK GLASS
**Read this FIRST if something is broken.**

1. **Service crash-looping?** Check `git log --oneline -10` for recent image changes FIRST. Roll back with `git checkout <hash> -- path/to/file` before trying anything else.
2. **DO NOT** patch container internals (PHP files, config inside containers, stub libraries). Containers are immutable — fix the compose file or roll back the image.
3. **DO NOT** run `docker compose pull` or `docker compose up` without explicit user approval. These can silently swap images.
4. **DO NOT** run any AzuraCast update script (`docker.sh`, `update.sh`). AzuraCast has a built-in updater that WILL break things.
5. **DO NOT** add Watchtower labels to any container.
6. If nginx returns 502/504, check `docker ps` — the upstream container probably restarted. Fix: `docker restart web_host`.
7. If in doubt: **stop, do nothing, ask the user.**

## Core Rules
1. Always operate within `~/pibulus-os/` for project work
2. Never track `.env` files or credentials in Git
3. Use `gum` for TUI interactions
4. Never unmount Passport drive without user confirmation
5. Check `free -h` before launching heavy containers (4GB RAM, swap often full)
6. SSH: always use `-4` flag (IPv6 times out)
7. Validate YAML after writing: `python3 -c "import yaml; yaml.safe_load(open('file'))"`
8. **NEVER run `docker compose pull`** — all images are pinned. Updates are a deliberate human decision.
9. **NEVER change an image tag** in a compose file without explicit user approval.
10. **NEVER run `docker system prune -a`** — this removes ALL images including ones in use.

## AzuraCast — TWO COPIES EXIST (Read Carefully)
- **LIVE config**: `~/azuracast/` — this is what Docker actually runs
- **Git reference**: `~/pibulus-os/azuracast/` — version-controlled copy of overrides
- The git copy has a `DO_NOT_EDIT.md` — read it
- **NEVER** run `docker compose` from `~/pibulus-os/azuracast/`
- **NEVER** sync git copy to live copy without user confirmation
- **NEVER** run `~/azuracast/docker.sh` (AzuraCast auto-updater — will pull new images and break things)
- To change AzuraCast: edit `~/azuracast/docker-compose.override.yml`, then `cd ~/azuracast && docker compose up -d`

## Docker Image Policy
**ALL images are pinned to exact versions as of 2026-04-15.**
- No `:latest` tags allowed — every service uses a specific version or digest
- Updates happen ONLY when the user explicitly requests it
- After any update: test the service, then update the pin comment date
- If a service breaks after compose recreate, the image was probably swapped — check `docker inspect <container> --format "{{.Config.Image}}"`

## Key Paths
- Project root: `~/pibulus-os/`
- Docker stacks: `~/pibulus-os/config/stacks/` (`pirate.yml`, `admin.yml`, `social.yml`, `utilities.yml`, `immich.yml`, `scummvm.yml`)
- AzuraCast LIVE: `~/azuracast/` (separate compose, NOT in stacks)
- AzuraCast GIT: `~/pibulus-os/azuracast/` (reference only — DO NOT RUN)
- Passport drive: `/media/pibulus/passport/` (lowercase p - NTFS, 5.5TB)
- Full docs: `~/pibulus-os/DOCS_INDEX.md`

## Port Registry (LOCKED — do not change without user approval)
All nginx proxy_pass directives use `172.17.0.1` (Docker bridge gateway).
This IP is stable and does NOT change when containers restart.
**NEVER** use container-specific IPs (172.18.x.x, 172.19.x.x, etc.) — they change on recreate.

| Port  | Service          | Stack        | Notes                          |
|-------|------------------|--------------|--------------------------------|
| 22    | SSH              | system       | Pi system SSH                  |
| 80    | nginx (web_host) | pirate.yml   | Reverse proxy for everything   |
| 2022  | AzuraCast SFTP   | ~/azuracast  | AzuraCast file transfer        |
| 2283  | Immich           | immich.yml   | Photo library (when running)   |
| 4533  | Navidrome        | pirate.yml   | Music streaming                |
| 5000  | Kavita           | pirate.yml   | Comic/manga reader             |
| 5030  | Slskd            | pirate.yml   | Soulseek web UI                |
| 5230  | Memos            | social.yml   | Notes/microblog                |
| 6881  | qBittorrent      | pirate.yml   | Torrent peer port              |
| 7682  | ttyd terminal    | systemd      | Admin terminal                 |
| 7683  | ttyd deck        | systemd      | Public cyberdeck               |
| 7684  | ttyd (extra)     | systemd      | Additional terminal            |
| 8000  | AzuraCast radio  | ~/azuracast  | KPAB.FM stream                 |
| 8004  | Deno app         | systemd      | Custom Deno service            |
| 8080  | File Browser     | pirate.yml   | Passport file manager          |
| 8081  | Homepage admin   | admin.yml    | Dashboard (when running)       |
| 8083  | Calibre-Web      | pirate.yml   | Ebook library                  |
| 8084  | Kiwix            | (manual)     | Offline Wikipedia              |
| 8085  | Drop Zone        | systemd      | File upload service            |
| 8086  | The Wall         | systemd      | Pixel graffiti backend         |
| 8087  | Shoutbox/Msg     | systemd      | Message services               |
| 8088  | URL Shortener    | utilities.yml| Custom shortener               |
| 8090  | Python service   | systemd      | Custom Python app              |
| 8092  | Python service   | systemd      | Custom Python app              |
| 8093  | Archive Peek     | systemd      | Read-only archive API          |
| 8095  | RomM             | romm/        | ROM manager (internal 8080)    |
| 8096  | Jellyfin         | pirate.yml   | Media server (host network)    |
| 8200  | AzuraCast        | ~/azuracast  | AzuraCast web (alt)            |
| 8443  | AzuraCast HTTPS  | ~/azuracast  | AzuraCast secure               |
| 8500  | AzuraCast        | ~/azuracast  | AzuraCast management           |
| 8888  | qBittorrent UI   | pirate.yml   | Torrent web interface          |
| 9000  | The Lounge       | social.yml   | IRC client (when running)      |
| 9001  | Deno app         | systemd      | Custom service                 |
| 9002  | Node app         | systemd      | Custom service                 |
| 9003  | Node app         | systemd      | Custom service                 |
| 9004  | Node app         | systemd      | Custom service                 |
| 9005  | Node app         | systemd      | Custom service                 |
| 13378 | Audiobookshelf   | pirate.yml   | Audiobook library (internal 80)|
| 50300 | Slskd peer       | pirate.yml   | Soulseek listen port           |

## Important Notes
- Passport mount is at `/media/pibulus/passport/` (lowercase p, case-sensitive!)
- Root disk is ~85% full — avoid writing large files to SD card. Run `docker image prune` if needed.
- Swap is often heavily used — be cautious with memory-heavy operations
- Jellyfin runs on host network, port 8096
- AzuraCast has its own compose lifecycle — don't manage it from stacks
- Kavita may show as "unhealthy" — it has a flaky healthcheck, usually works fine
