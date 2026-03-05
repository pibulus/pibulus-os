#!/bin/bash
# 🛡️ BUNKER BACKUP MODULE
# Seals the digital vaults and creates a system snapshot.

run_backup() {
    clear
    figlet -f slant "LOCKDOWN" | lolcat
    
    local BACKUP_DIR="$PASSPORT_ROOT/Backups/System_Snapshots"
    local DATE=$(date +%Y-%m-%d_%H-%M)
    local FILE="$BACKUP_DIR/pibulus_snapshot_$DATE.tar.gz"
    
    mkdir -p "$BACKUP_DIR"
    
    gum style --border double --margin "1 2" --padding "1 2" --border-foreground 196 
        "⚠️  INITIATING PERIMETER LOCKDOWN
        
        This will briefly halt all services to ensure a clean seal.
        Standby for environmental scan..." | lolcat

    if gum confirm "Begin secure snapshot?"; then
        play_tone "confirm"
        
        # 1. Halt the Empire
        gum spin --spinner dot --title "Halting Broadcasts..." -- docker compose -f "$PIRATE_CONFIG" stop
        
        # 2. Seal the Vault
        gum spin --spinner moon --title "Compressing System DNA..." -- 
            tar -czf "$FILE" -C "$HOME" pibulus-os .config/jellyfin .config/navidrome .config/azuracast
            
        # 3. Resume Operations
        gum spin --spinner pulse --title "Re-opening Gates..." -- docker compose -f "$PIRATE_CONFIG" start
        
        play_tone "confirm"
        gum style --foreground 46 "✅ SECURE SNAPSHOT CREATED: $(basename $FILE)"
        echo "Size: $(du -h $FILE | cut -f1)" | lolcat
    else
        play_tone "error"
        echo "Lockdown aborted. Gates remain open." | lolcat
    fi
    
    sleep 3
}
