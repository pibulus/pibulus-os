#!/bin/bash
# 📀 QUICK CAT CLUB - GOLDEN IMAGE CREATOR
# Packs the brains of the deck for redundancy.

BACKUP_DIR="/media/pibulus/passport/Backups/Golden_Images"
DATE=$(date +%Y-%m-%d_%H%M)
FILE="$BACKUP_DIR/qcc_golden_v${DATE}.tar.gz"

mkdir -p "$BACKUP_DIR"

echo "📦 Creating Golden Image..."
# Archive: .env, all stacks, all modules, and scripts
tar -czf "$FILE" \
    -C "$HOME" pibulus-os/.env \
    -C "$HOME" pibulus-os/config \
    -C "$HOME" pibulus-os/modules \
    -C "$HOME" pibulus-os/scripts \
    -C "$HOME" pibulus-os/FIELD_MANUAL.md \
    -C "$HOME" pibulus-os/MANIFESTO.md 2>/dev/null

if [ $? -eq 0 ]; then
    gum style --foreground 46 "✅ GOLDEN IMAGE SAVED: $(basename $FILE)"
    play_tone "confirm" 2>/dev/null
else
    gum style --foreground 196 "❌ FAILED TO CREATE IMAGE"
    play_tone "error" 2>/dev/null
fi
