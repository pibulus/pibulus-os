#!/bin/bash
# 📀 QUICK CAT CLUB - GOLDEN IMAGE CREATOR
# Packs the brains of the deck for redundancy.

BACKUP_DIR="/media/pibulus/passport/Backups/Golden_Images"
DATE=$(date +%Y-%m-%d_%H%M)
FILE="$BACKUP_DIR/pibulus_golden_v${DATE}.tar.gz"

mkdir -p "$BACKUP_DIR"

echo "📦 Creating Golden Image..."
# Archive: critical configs, modules, and scripts
tar -czf "$FILE" \
    -C "$HOME" pibulus-os/pibulus-os.env \
    -C "$HOME" pibulus-os/config \
    -C "$HOME" pibulus-os/modules \
    -C "$HOME" pibulus-os/scripts \
    -C "$HOME" pibulus-os/README.md \
    -C "$HOME" pibulus-os/CLAUDE.md \
    -C "$HOME" pibulus-os/SHIP_LOG.md 2>/dev/null

if [ $? -eq 0 ]; then
    gum style --foreground 46 "✅ GOLDEN IMAGE SAVED: $(basename $FILE)"
else
    gum style --foreground 196 "❌ FAILED TO CREATE IMAGE"
fi
