#!/bin/bash
# 📀 QUICK CAT CLUB - VAULT OPS

manage_vault() {
    while true; do
        render_hud
        echo -e "$(gum style --foreground 226 '--- 📀 VAULT & RECOVERY OPS ---')"
        local action=$(tactile_choose "💾 Create Golden Image" "📄 Read Manifesto" "Back")
        
        case $action in
            "💾 Create Golden Image")
                ~/pibulus-os/scripts/golden_image.sh
                gum input --placeholder "Press Enter to return..."
                ;;
            "📄 Read Manifesto")
                glow ~/pibulus-os/MANIFESTO.md || less ~/pibulus-os/MANIFESTO.md
                ;;
            "Back")
                return
                ;;
        esac
    done
}
