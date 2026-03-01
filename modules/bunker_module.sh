#!/bin/bash
# 🛡️ QUICK CAT CLUB - BUNKER LOCKDOWN v1.1

run_bunker_lockdown() {
    render_hud
    gum style --border double --margin "1 2" --padding "1 2" --border-foreground 196 \
        "$(printf '%s\n' '🚨 NUCLEAR BUNKER LOCKDOWN' '' 'This will:' '  - Kill Wi-Fi hotspot' '  - Disconnect Tailscale' '  - Stop ALL Docker services' '  - Clear shell history' '  - Exit the deck' '' 'The device will go DARK.')"

    if gum confirm "INITIATE BUNKER LOCKDOWN?"; then
        play_tone "warning"

        echo "  Killing Wi-Fi Hotspot..."
        sudo nmcli con down KPAB-Hotspot 2>/dev/null

        echo "  Killing Tailscale..."
        sudo tailscale down 2>/dev/null

        echo "  Stopping all Docker stacks..."
        find ~/pibulus-os/config/stacks -name "*.yml" -exec docker compose -f {} down \; 2>/dev/null

        echo "  Clearing shell history..."
        history -c
        cat /dev/null > ~/.bash_history

        play_tone "error"
        gum style --border double --margin "1 2" --padding "1 2" --foreground 196 \
            "🔒 BUNKER LOCKED. DEVICE IS DARK."
        sleep 3
        clear
        exit 0
    fi
}
