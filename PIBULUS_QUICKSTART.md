# PIBULUS Quickstart for AI Agents

Purpose: fast orientation for Codex/Claude/other agents after SSHing into the Pi, so Pablo does not have to re-explain the setup every session.

Read this first, then use:

- `CLAUDE.md` for hard safety rules and port registry
- `DOCS_INDEX.md` for the full documentation map
- `FIELD_MANUAL.md` for operator commands and access tiers
- `APP_DEPLOYMENT_MAP.md` for TalkType, ZipList, Stargram, Ghost Note, and other custom apps
- `docs/INGRESS_METRICS_MAP.md` for public routing truth

## Identity

PIBULUS is Pablo's Raspberry Pi 5 home server in Melbourne. It runs Quick Cat Club, KPAB.FM, media libraries, custom apps, game/archive pages, and admin tools through a mix of Docker, systemd, static files, and Cloudflare Tunnel.

Default working directory:

```bash
cd /home/pibulus/pibulus-os
```

SSH from the LAN should force IPv4:

```bash
ssh -4 pibulus@192.168.0.40
```

Remote SSH may also be available through Cloudflare Tunnel as `ssh.quickcat.club`; from Pablo's Mac there may be an SSH alias such as `ssh pibulus-remote`.

## First 90 Seconds

Run narrow checks before changing anything:

```bash
cd /home/pibulus/pibulus-os
git status --short
uptime
free -h
df -hT / /media/pibulus/passport /media/pibulus/MEMBOT 2>/dev/null || true
vcgencmd measure_temp 2>/dev/null || true
vcgencmd get_throttled 2>/dev/null || true
systemctl --failed --no-pager
systemctl status cloudflared docker pibulus-watchdog.timer --no-pager
docker ps --format '{{.Names}} {{.Status}} {{.Ports}}'
```

Quick public smoke tests:

```bash
curl -I https://quickcat.club
curl -I https://kpab.fm
curl -I https://watch.quickcat.club/web/
curl -I https://talktype.app
curl -I https://ziplist.app
```

If a public hostname is down, test local first. If local works but Cloudflare returns `530`, focus on `cloudflared`, not the app.

```bash
curl -sS -o /dev/null -w 'local80 %{http_code} %{time_total}\n' http://127.0.0.1/
curl -sS -o /dev/null -w 'jellyfin %{http_code} %{time_total}\n' http://127.0.0.1:8096/web/
systemctl show -p ActiveState -p SubState -p Result -p TimeoutStartUSec cloudflared
journalctl -u cloudflared -n 80 --no-pager
```

## Hard Guardrails

Do not do these without explicit user approval:

- Do not run `docker compose pull`.
- Do not change Docker image tags or digests.
- Do not run `docker system prune -a`.
- Do not run AzuraCast updater scripts such as `~/azuracast/docker.sh`.
- Do not run compose commands from `~/pibulus-os/azuracast`; that copy is a git reference, not the live AzuraCast deployment.
- Do not patch files inside running containers. Fix compose, mounted config, source, or roll back.
- Do not build multiple Node apps in parallel on the Pi.
- Do not unmount `/media/pibulus/passport` without Pablo confirming.
- Do not commit secrets, `.env` files, tunnel credentials, htpasswd files, or local-only state.

The Pi has 4GB RAM and can look dead when CPU, swap, or USB disk I/O is overloaded. Prefer one careful operation at a time.

## Architecture

Main layers:

- Cloudflare Tunnel exposes public hostnames without opening the home IP.
- `cloudflared.service` runs the tunnel.
- Docker handles the media/static/service stack.
- `web_host` is an nginx container on port `80` and is the clean shared front door.
- Some public hostnames bypass nginx and go straight to app ports through Cloudflare Tunnel.
- Custom web apps live under `/home/pibulus/apps` and run as systemd services, not Docker containers.
- AzuraCast lives separately at `~/azuracast`.
- Media and bulky runtime data live on `/media/pibulus/passport`.

Important paths:

```text
/home/pibulus/pibulus-os                         repo and operational source
/home/pibulus/apps                               live custom apps
/home/pibulus/azuracast                          live AzuraCast deployment
/home/pibulus/pibulus-os/azuracast               git reference copy only
/etc/cloudflared/config.yml                      live Cloudflare Tunnel ingress
/etc/systemd/system                              installed systemd units
/home/pibulus/pibulus-os/config/systemd          repo copies of systemd units
/home/pibulus/pibulus-os/config/stacks           Docker compose stacks
/home/pibulus/pibulus-os/config/nginx            nginx config mounted into web_host
/media/pibulus/passport                          5.5TB NTFS media/config/backup drive
/media/pibulus/MEMBOT                            1TB FAT32 extra media/ROM drive
```

## Ingress Model

Live tunnel config:

```bash
sudo sed -n '1,220p' /etc/cloudflared/config.yml
```

Core examples:

- `quickcat.club` -> `localhost:80` -> `web_host`
- `kpab.fm` / `www.kpab.fm` -> `localhost:80` -> `web_host`
- `deck.quickcat.club` -> `localhost:80` -> `web_host`
- `comics.quickcat.club` -> `localhost:80` -> nginx -> Kavita
- `watch.quickcat.club` -> `localhost:8096` -> Jellyfin direct
- `music.quickcat.club` -> `localhost:4533` -> Navidrome direct
- `read.quickcat.club` -> `localhost:8083` -> Calibre-Web direct
- `audiobooks.quickcat.club` -> `localhost:13378` -> Audiobookshelf direct
- `games.quickcat.club` -> `localhost:8095` -> RomM direct
- `photos.quickcat.club` -> `localhost:2283` -> Immich direct
- `talktype.app` -> `localhost:9002` -> systemd Node app
- `ziplist.app` -> `localhost:9003` -> systemd Node app
- `riffrap.app` -> `localhost:9004` -> systemd app
- `stargram.app` -> `localhost:9012` -> systemd Deno/Fresh app
- `ghostnote.rip` -> `localhost:9013` -> systemd Deno/Fresh app

Use `docs/INGRESS_METRICS_MAP.md` for metric meaning. Nginx visitor counts only include traffic that hits `web_host`; direct app subdomains bypass those logs.

## Docker

Main compose stacks:

```text
config/stacks/pirate.yml       core media/front-door stack
config/stacks/social.yml       social/notes/chat-style services
config/stacks/admin.yml        admin dashboard services
config/stacks/utilities.yml    utility services such as shortener
config/stacks/immich.yml       photo stack
config/stacks/scummvm.yml      optional browser ScummVM
config/stacks/romm/            RomM stack/config
```

Common narrow commands:

```bash
docker ps
docker logs --tail 80 web_host
docker restart web_host
docker compose -f config/stacks/pirate.yml ps
docker compose -f config/stacks/pirate.yml up -d web_host
```

Only start/recreate the service you are fixing. Avoid broad `up -d` across a whole stack unless Pablo asked for it.

## Systemd Services

Cloudflare Tunnel:

```bash
systemctl status cloudflared --no-pager
journalctl -u cloudflared -n 100 --no-pager
sudo systemctl restart cloudflared
systemctl show -p TimeoutStartUSec cloudflared
```

The cloudflared unit should include:

```text
TimeoutStartSec=120
Type=notify
ExecStart=/usr/bin/cloudflared --no-autoupdate --config /etc/cloudflared/config.yml tunnel run
Restart=on-failure
RestartSec=10s
```

Watchdog:

```bash
systemctl status pibulus-watchdog.timer --no-pager
sudo systemctl start pibulus-watchdog.service
journalctl -u pibulus-watchdog.service -n 100 --no-pager
```

The watchdog is intentionally narrow. It checks:

- `cloudflared.service`
- `docker.service`
- `web_host` / local port 80
- `jellyfin` / local port 8096

It should not become a broad restart machine.

Custom app services are documented in `APP_DEPLOYMENT_MAP.md`; inspect with:

```bash
systemctl status talktype ziplist riffrap stargram ghostnote --no-pager
journalctl -u talktype -n 80 --no-pager
```

## Custom App Deploys

Read `APP_DEPLOYMENT_MAP.md` before touching custom apps.

Rules:

- Live app dirs are under `/home/pibulus/apps`.
- SvelteKit Node app live dirs are usually adapter-node build output, not git checkouts.
- Deno/Fresh apps may be source checkouts.
- Use the helper when possible:

```bash
/home/pibulus/pibulus-os/scripts/deploy_app.sh talktype
/home/pibulus/pibulus-os/scripts/deploy_app.sh ziplist
/home/pibulus/pibulus-os/scripts/deploy_app.sh stargram
/home/pibulus/pibulus-os/scripts/deploy_app.sh ghostnote
```

Do not run multiple builds in parallel on the Pi.

## AzuraCast / KPAB

Live AzuraCast is special:

```text
/home/pibulus/azuracast          live deployment
/home/pibulus/pibulus-os/azuracast reference copy only
```

Do not run the AzuraCast updater. Do not run live compose from the git reference copy.

Useful checks:

```bash
cd /home/pibulus/azuracast
docker compose ps
docker compose logs --tail 80
curl -I http://127.0.0.1:8500/
curl -I http://127.0.0.1:8000/
curl -I https://kpab.fm
```

## Backups

Current backup posture is practical but not fully off-box.

Scripts:

```text
scripts/nightly-backup.sh
scripts/backup.sh
scripts/golden_image.sh
```

Important backup destinations:

```text
/media/pibulus/passport/Backups/pi-system
/media/pibulus/passport/Backups/pi-config-*
/media/pibulus/passport/Backups/Golden_Images
```

Nightly backup records service config, DB dumps, Docker manifests, and a repo mirror. It does not make the whole setup immune to Passport failure.

## Outage Decision Tree

Public hostname returns Cloudflare `530`:

1. Test the local app port.
2. If local works, inspect/restart `cloudflared`.
3. If `cloudflared.service` is malformed or missing `ExecStart`, restore from `config/systemd/cloudflared.service`, then run:

```bash
sudo install -m 0644 config/systemd/cloudflared.service /etc/systemd/system/cloudflared.service
sudo systemctl daemon-reload
sudo systemctl restart cloudflared
```

Nginx/front door returns 502/504:

```bash
docker ps
docker logs --tail 80 web_host
docker restart web_host
curl -I http://127.0.0.1/
```

Jellyfin/watch route down:

```bash
docker ps --filter name=jellyfin
curl -I http://127.0.0.1:8096/web/
docker restart jellyfin
curl -I https://watch.quickcat.club/web/
```

Pi feels hung:

```bash
uptime
free -h
vcgencmd measure_temp
vcgencmd get_throttled
journalctl -b -p warning..emerg --no-pager | tail -120
```

If SSH and LAN are both flapping and the Pi is not recoverable interactively, Pablo may power-cycle it. After a hard power cut, expect journald to report old journal files as corrupted or uncleanly shut down; that is not automatically evidence that app/config files are corrupt.

## Corruption Check

On 2026-05-30, `cloudflared.service` was malformed and two untracked repo files were NUL-filled:

- `scripts/pibulus-watchdog.sh`
- `PIBULUS_QUICKSTART.md`

The corrupt evidence was archived at:

```text
/home/pibulus/corrupt-files-20260530-233855/
```

If corruption is suspected again, run a targeted recent text/config scan:

```bash
cd /home/pibulus/pibulus-os
find . -xdev -type f -newermt "2026-05-30 20:00:00" \
  \( -name "*.md" -o -name "*.sh" -o -name "*.service" -o -name "*.timer" -o -name "*.yml" -o -name "*.yaml" -o -name "*.conf" -o -name "*.json" -o -name "*.env" -o -name "*.txt" \) \
  -print0 | while IFS= read -r -d "" f; do
    type=$(file -b "$f")
    first=$(od -An -tx1 -N 16 "$f" | tr -d " \n")
    case "$type:$first" in
      *data*|*:00000000000000000000000000000000*)
        printf "%s\t%s\t%s\t%s\n" "$(stat -c %s "$f")" "$first" "$type" "$f"
        ;;
    esac
  done
```

Also inspect storage/kernel warnings:

```bash
sudo journalctl -b -k -p warning..emerg --no-pager | egrep -i '(ext4|i/o error|buffer i/o|mmc|sd[a-z]|uas|usb|under-voltage|voltage|thrott|reset|readonly|corrupt|error)' || true
```

## Documentation Rule

If docs disagree:

1. Trust live config and scripts first.
2. Trust operational truth docs second.
3. Treat narrative docs and older logs as historical.

If this file helps during an incident, keep it tracked in git. It is agent context, not disposable scratch.
