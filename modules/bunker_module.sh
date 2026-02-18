#!/bin/bash
# 🛡️ QUICK CAT CLUB - BUNKER LOCKDOWN

run_bunker_lockdown() {
    if gum confirm "🚨 INITIATE BUNKER LOCKDOWN? (Kills all connections and services)"; then
        echo "Killing Wi-Fi Hotspot..."
        sudo nmcli con down KPAB-Hotspot 2>/dev/null
        
        echo "Killing Tailscale..."
        sudo tailscale down 2>/dev/null
        
        echo "Stopping all Docker stacks..."
        find ~/pibulus-os/config/stacks -name "*.yml" -exec docker compose -f {} down \;
        
        echo "Clearing bash history..."
        history -c
        cat /dev/null > ~/.bash_history
        
        gum style --border double --margin "1 2" --foreground 196 "🔒 BUNKER LOCKED. DEVICE IS DARK."
        play_tone "error" 2>/dev/null
        sleep 5
        exit 0
    fi
}
