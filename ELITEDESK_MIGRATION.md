# EliteDesk Migration Guide

HP EliteDesk 800 G4 Mini — i5-8500T, 16GB RAM, 256GB SSD

## Philosophy

- **Passport = media** (movies, music, roms, books — stays on Passport forever)
- **SSD = OS + Docker + app configs** (small, fast, reliable for databases)
- **Backups live on Passport** at `/media/pibulus/passport/Backups/pi-system/`

The Pi backs up to Passport nightly. On migration day you restore from those backups to the SSD, plug in Passport, done.

---

## Step 1 — Prep the EliteDesk

```bash
# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker pibulus

# Install tools
sudo apt install -y git rsync python3 python3-pip gum

# Mount Passport (find the right /dev/sdX first)
sudo mkdir -p /media/pibulus/passport
# Add to /etc/fstab:
# UUID=<passport-uuid>  /media/pibulus/passport  ntfs-3g  uid=1000,gid=1000,umask=022,nofail  0  0
```

## Step 2 — Clone pibulus-os

```bash
cd ~
git clone <your-git-remote> pibulus-os
# Or copy from Passport backup:
# rsync -a /media/pibulus/passport/Backups/pi-system/pibulus-os/ ~/pibulus-os/
```

## Step 3 — Restore app configs from Passport backup

```bash
BACKUP=/media/pibulus/passport/Backups/pi-system

# Create config dirs
mkdir -p ~/.config/{jellyfin,navidrome,kavita,calibre-web,memos,qbittorrent,thelounge}
mkdir -p ~/filebrowser-db

# Restore each app
rsync -a $BACKUP/configs/jellyfin/     ~/.config/jellyfin/
rsync -a $BACKUP/configs/navidrome/    ~/.config/navidrome/
rsync -a $BACKUP/configs/kavita/       ~/.config/kavita/
rsync -a $BACKUP/configs/calibre-web/  ~/.config/calibre-web/
rsync -a $BACKUP/configs/memos/        ~/.config/memos/
rsync -a $BACKUP/configs/qbittorrent/  ~/.config/qbittorrent/
rsync -a $BACKUP/configs/thelounge/    ~/.config/thelounge/
rsync -a $BACKUP/configs/filebrowser/  ~/filebrowser-db/
```

## Step 4 — Restore AzuraCast

```bash
BACKUP=/media/pibulus/passport/Backups/pi-system

# Start AzuraCast fresh first (creates volumes), then restore
cd ~/azuracast
docker compose up -d
sleep 30  # wait for MariaDB to initialise

# Restore database
MYSQL_PWD=$(grep ^MYSQL_PASSWORD ~/azuracast/azuracast.env | cut -d= -f2)
zcat $BACKUP/docker-db/azuracast-$(ls -t $BACKUP/docker-db/azuracast-*.sql.gz | head -1 | xargs basename | sed 's/azuracast-//;s/.sql.gz//').sql.gz \
  | docker exec -i -e MYSQL_PWD="$MYSQL_PWD" azuracast \
    sh -c 'mariadb -u azuracast -p"$MYSQL_PWD" azuracast'

# Restore station data (playlists, config)
docker run --rm \
  -v azuracast_station_data:/target \
  -v $BACKUP/volumes:/backup \
  alpine tar -xzf /backup/azuracast-station_data.tar.gz -C /target

docker compose restart
```

## Step 5 — Copy AzuraCast sync patches

The patched PHP files need to be reapplied if you update AzuraCast.
They live at `/media/pibulus/passport/app-data/azuracast/sync-patches/`
and are already bind-mounted in `~/azuracast/docker-compose.yml` — no action needed,
they'll mount automatically.

## Step 6 — Start everything

```bash
# Stacks
cd ~/pibulus-os
docker compose -f config/stacks/pirate.yml up -d
docker compose -f config/stacks/admin.yml up -d
docker compose -f config/stacks/social.yml up -d
docker compose -f config/stacks/utilities.yml up -d

# AzuraCast (already started in step 4)

# Add crontab
crontab ~/pibulus-os/scripts/setup-crontab.sh  # or manually apply crontab.txt from backup
```

## Step 7 — Restore crontab

```bash
crontab /media/pibulus/passport/Backups/pi-system/system/crontab.txt
```

## Step 8 — System tuning

```bash
# Apply sysctl tuning from pibulus-os if present
sudo cp ~/pibulus-os/config/system/99-pi-tuning.conf /etc/sysctl.d/ 2>/dev/null
sudo sysctl --system
```

---

## Notes

- slskd config is already on Passport at `/media/pibulus/passport/app-data/slskd/` — no restore needed
- RomM config/assets are already on Passport at `/media/pibulus/passport/app-data/romm/` — no restore needed
- AzuraCast PHP patches are already on Passport at `/media/pibulus/passport/app-data/azuracast/sync-patches/`
- Jellyfin media paths all point to Passport — no changes needed
- The EliteDesk has no RAM pressure (16GB) so swap tuning from Pi is irrelevant

## What you'll need to redo

- Cloudflare tunnel: `cloudflared tunnel login` then update `config.yml`
- Any `.env` files (passwords etc) — these are intentionally not backed up
- SSL/ACME certs if not using Cloudflare tunnel
