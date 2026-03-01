#!/bin/bash
# ⏏️ PIBULUS EJECT MODULE v1.1

safe_eject() {
    render_hud
    gum style --border double --margin "1 2" --padding "1 2" --border-foreground 226 \
        "$(printf '%s\n' '⏏️  SAFE EJECT' '' 'This will stop all services and unmount the Passport drive.' 'Make sure no transfers are in progress.')"

    if gum confirm "STOP ALL SERVICES & EJECT DRIVE?"; then
        play_tone "warning"

        echo "  Stopping Docker stacks..."
        find ~/pibulus-os/config/stacks -name "*.yml" -exec docker compose -f {} down \; 2>/dev/null

        echo "  Syncing filesystem..."
        sync

        echo "  Unmounting Passport..."
        sudo umount /media/pibulus/passport

        if [ $? -eq 0 ]; then
            play_tone "confirm"
            gum style --foreground 46 "✅ DRIVE SAFE TO REMOVE"
        else
            play_tone "error"
            gum style --foreground 196 "❌ EJECT FAILED: Drive still in use."
            gum style --foreground 245 "Check: lsof /media/pibulus/passport"
        fi
        sleep 3
    fi
}
