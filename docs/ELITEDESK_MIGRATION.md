# EliteDesk Migration Guide

HP EliteDesk 800 G4 Mini
Intel i5-8500T, 16GB RAM, 256GB SSD

## Goal

Make the EliteDesk the first clean second home for PIBULUS.

Not a full reinvention.
Not a big-bang migration.
Not a new architecture hobby.

The 80/20 goal is:

- Passport stays the media spine
- the repo stays the portable logic/config spine
- the EliteDesk becomes a clean restore target and second host
- migration is reversible and boring

If this document and the live config disagree, trust the live config.

## Recommended Path

The easiest sane path is:

1. install Linux on the EliteDesk
2. mount Passport at the same path used on the Pi
3. clone `pibulus-os`
4. restore config/data backups from Passport
5. bring services up in layers
6. verify before changing any public routing

Do not try to preserve Windows as the main runtime unless there is a specific reason.
This stack is built around Docker, shell scripts, Linux paths, systemd, and bind mounts.
A Linux host is the shortest route.

## Source Of Truth Model

### Passport

Passport is the bulky, durable bridge.

It should hold:

- media
- ROMs
- books
- backups
- golden images
- app-data that already lives there

### Repo

`pibulus-os` is the portable brain.

It should hold:

- docs
- nginx config
- compose files
- systemd units
- scripts
- static web pages
- lightweight generated files that are part of the product

### Local host state

The EliteDesk SSD should hold:

- OS
- Docker runtime
- app configs restored from backup
- databases restored from backup
- local secrets and auth files that are intentionally not in git

## What Moves Cleanly

These are good migration targets:

- `~/pibulus-os`
- Docker stack files in `config/stacks/`
- nginx config in `config/nginx/`
- systemd units in `config/systemd/`
- backed-up app configs from `/media/pibulus/passport/Backups/pi-system/configs/`
- backed-up DB dumps from `/media/pibulus/passport/Backups/pi-system/docker-db/`
- AzuraCast station volume backup from `/media/pibulus/passport/Backups/pi-system/volumes/`

## What Does Not Move Cleanly

These should be treated as host-local or redo-once items:

- `.env` files
- htpasswd and auth secrets unless explicitly copied by you
- Cloudflare credentials / tunnel login state
- machine-specific network tuning
- Pi-specific performance workarounds

## Keep The Paths The Same

A lot of this setup gets simpler if the EliteDesk keeps the same important paths:

- repo: `/home/pibulus/pibulus-os`
- Passport: `/media/pibulus/passport`
- MEMBOT: `/media/pibulus/MEMBOT` if you keep using it

Path compatibility is worth more than theoretical neatness here.

## Migration Shape

### Phase 1: Prepare, do not cut over

On the Pi:

- confirm nightly backup is current
- confirm `pi-system` backup exists on Passport
- confirm repo is clean and pushed
- confirm docs match reality enough to trust them

On the EliteDesk:

- install Linux
- install Docker, git, rsync
- create user `pibulus`
- mount Passport at `/media/pibulus/passport`
- clone `pibulus-os` to `/home/pibulus/pibulus-os`

### Phase 2: Restore portable state

Restore from Passport:

- `configs/`
- `docker-db/`
- `volumes/`
- system files like `crontab.txt` as needed

Keep this simple.
Do not restore caches, logs, or junk if you do not need them.

### Phase 3: Bring services up in layers

Bring up the smallest useful shape first:

1. `web_host`
2. core friend-tier media services if wanted
3. Kiwix / Memos / utilities
4. AzuraCast only when you are ready to test it properly
5. heavy/optional services later

This is a restore drill first, not a flex.

### Phase 4: Verify before routing anything public

Verify:

- Passport mounts correctly after reboot
- repo paths resolve correctly
- nginx serves local pages
- Kiwix loads
- one media app works
- backups are readable
- one restored database is valid
- systemd services you care about start cleanly

Only after that should the EliteDesk become a public-facing or semi-public host.

## Minimal Setup Commands

### EliteDesk host prep

```bash
# Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker pibulus

# Useful tools
sudo apt install -y git rsync python3 python3-pip

# Passport mount point
sudo mkdir -p /media/pibulus/passport
```

### Clone repo

```bash
cd /home/pibulus
git clone <your-git-remote> pibulus-os
```

### Restore configs

```bash
BACKUP=/media/pibulus/passport/Backups/pi-system

mkdir -p ~/.config/{jellyfin,navidrome,kavita,calibre-web,memos,qbittorrent,thelounge}
mkdir -p ~/filebrowser-db

rsync -a "$BACKUP/configs/jellyfin/"    ~/.config/jellyfin/
rsync -a "$BACKUP/configs/navidrome/"   ~/.config/navidrome/
rsync -a "$BACKUP/configs/kavita/"      ~/.config/kavita/
rsync -a "$BACKUP/configs/calibre-web/" ~/.config/calibre-web/
rsync -a "$BACKUP/configs/memos/"       ~/.config/memos/
rsync -a "$BACKUP/configs/qbittorrent/" ~/.config/qbittorrent/
rsync -a "$BACKUP/configs/thelounge/"   ~/.config/thelounge/
rsync -a "$BACKUP/configs/filebrowser/" ~/filebrowser-db/
```

### Start stacks in order

```bash
cd /home/pibulus/pibulus-os

docker compose -f config/stacks/pirate.yml up -d
docker compose -f config/stacks/admin.yml up -d
docker compose -f config/stacks/social.yml up -d
docker compose -f config/stacks/utilities.yml up -d
```

### Restore crontab if wanted

```bash
crontab /media/pibulus/passport/Backups/pi-system/system/crontab.txt
```

## AzuraCast Note

AzuraCast is its own beast.
Do not treat it like just another stack.

Use the backup assets already produced by the Pi:

- MariaDB dump from `docker-db/`
- station data tarball from `volumes/`
- sync patches already living on Passport

Restore AzuraCast after the base host is stable, not before.

## What To Skip On Day One

Do not overdo the first pass.
You do not need to bring every service across immediately.

Skip until later if needed:

- qBittorrent
- slskd
- RomM
- Immich
- anything experimental or RAM-hungry

The first victory condition is:

- the EliteDesk can boot
- Passport mounts cleanly
- the repo works
- a few representative services restore correctly
- the backup/restore story stops feeling hypothetical

## Best Role For The EliteDesk

At first, the EliteDesk should be:

- second host
- restore target
- backup mirror target
- future heavier-app destination

Not necessarily:

- immediate Pi replacement
- same-day public cutover box

Let it earn trust first.

## Migration Day Checklist

- Passport mounted at the correct path
- repo cloned to the correct path
- backups visible
- secrets supplied manually where needed
- `docker compose config` works for the stacks you care about
- `docker ps` looks sane
- public pages render locally
- one restore test completed successfully
- notes updated with anything host-specific you had to improvise

## Final Advice

The win is not making the EliteDesk clever.
The win is making the move boring.

Same paths.
Same Passport.
Same repo.
Smaller number of surprises.

That is how this becomes maintainable.
