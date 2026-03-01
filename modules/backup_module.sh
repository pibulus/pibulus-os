#!/bin/bash
# 🛡️ BUNKER BACKUP MODULE v1.1
# Seals the digital vaults and creates a system snapshot.

run_backup() {
    clear
    figlet -f slant "LOCKDOWN" | lolcat

    local BACKUP_DIR="$PASSPORT_ROOT/Backups/System_Snapshots"
    local DATE=$(date +%Y-%m-%d_%H-%M)
    local FILE="$BACKUP_DIR/pibulus_snapshot_$DATE.tar.gz"

    mkdir -p "$BACKUP_DIR"

    gum style --border double --margin "1 2" --padding "1 2" --border-foreground 196 \
        "$(printf '%s\n' '⚠️  INITIATING PERIMETER LOCKDOWN' '' 'This will briefly halt all services to ensure a clean seal.' 'Standby for environmental scan...')"

    if gum confirm "Begin secure snapshot?"; then
        play_tone "confirm"

        # 1. Halt the Empire
        gum spin --spinner dot --title "Halting Broadcasts..." -- \
            docker compose -f "$PIRATE_CONFIG" stop

        # 2. Seal the Vault (azuracast lives at ~/azuracast, not ~/.config/azuracast)
        gum spin --spinner moon --title "Compressing System DNA..." -- \
            tar -czf "$FILE" -C "$HOME" \
                pibulus-os \
                azuracast \
                .config/jellyfin \
                .config/navidrome \
                .config/calibre-web \
                .config/kavita \
                2>/dev/null

        # 3. Resume Operations
        gum spin --spinner pulse --title "Re-opening Gates..." -- \
            docker compose -f "$PIRATE_CONFIG" start

        play_tone "confirm"
        local SIZE=$(du -h "$FILE" 2>/dev/null | cut -f1)
        gum style --foreground 46 "✅ SECURE SNAPSHOT CREATED: $(basename $FILE) ($SIZE)"
    else
        play_tone "error"
        gum style --foreground 196 "Lockdown aborted. Gates remain open."
    fi

    sleep 3
}
