#!/bin/bash
# Quick backup of critical configs to HDD
DEST="/media/pibulus/passport/Backups/pi-config-$(date +%Y%m%d)"
mkdir -p "$DEST"

echo "🔒 Backing up critical configs to $DEST..."

# Systemd services we created
sudo cp /etc/systemd/system/ttyd-terminal.service "$DEST/" 2>/dev/null
sudo cp /etc/systemd/system/mutiny.service "$DEST/" 2>/dev/null
sudo cp /etc/cloudflared/config.yml "$DEST/cloudflared-config.yml" 2>/dev/null
sudo cp /etc/sysctl.d/99-pi-tuning.conf "$DEST/" 2>/dev/null

# Docker volumes (small config DBs, skip caches where possible)
rsync -a --exclude 'cache/' ~/.config/navidrome/ "$DEST/navidrome-config/" 2>/dev/null
rsync -a --exclude 'cache/' --exclude 'cache-long/' --exclude 'logs/' ~/.config/kavita/ "$DEST/kavita-config/" 2>/dev/null
rsync -a ~/.config/calibre-web/ "$DEST/calibre-web-config/" 2>/dev/null
rsync -a --exclude 'cache/' ~/.config/jellyfin/ "$DEST/jellyfin-config/" 2>/dev/null

# Git repo state
cd ~/pibulus-os && git bundle create "$DEST/pibulus-os.bundle" --all 2>/dev/null

# Bashrc
cp ~/.bashrc "$DEST/bashrc" 2>/dev/null

# Keep the most recent 7 quick snapshots.
ls -dt /media/pibulus/passport/Backups/pi-config-* 2>/dev/null | tail -n +8 | xargs rm -rf 2>/dev/null

echo "✅ Backup complete: $(du -sh "$DEST" | cut -f1)"
ls "$DEST/"
