#!/bin/bash
# ⏏️ PIBULUS EJECT MODULE

safe_eject() {
    if gum confirm "🛑 STOP ALL SERVICES & EJECT DRIVE?"; then
        echo "Stopping Docker stacks..."
        # Find all yml files and stop them
        find ~/pibulus-os/config/stacks -name "*.yml" -exec docker compose -f {} down \;
        
        echo "Unmounting Passport..."
        sudo umount /media/pibulus/passport
        
        if [ $? -eq 0 ]; then
            gum style --foreground 46 "✅ DRIVE SAFE TO REMOVE"
            play_tone "confirm" 2>/dev/null
        else
            gum style --foreground 196 "❌ EJECT FAILED: Drive still in use."
            play_tone "error" 2>/dev/null
        fi
        sleep 3
    fi
}
