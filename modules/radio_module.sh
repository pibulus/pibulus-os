#!/bin/bash
# 📻 PIBULUS RADIO MODULE v1.1
# KPAB.fm Control Center

manage_radio() {
    while true; do
        render_hud
        echo -e "$(gum style --foreground 212 '--- 📻 KPAB.fm RADIO OPS ---')"

        # Show live status
        local az_status=$(get_status azuracast)
        echo -e "  Station: $az_status KPAB.fm  |  Stream: https://kpab.fm/radio.mp3"
        echo ""

        local action=$(tactile_choose \
            "📊 Station Status" \
            "🔄 Restart AzuraCast" \
            "🎵 Audio Visualizer (cava)" \
            "📥 Start Track Drop" \
            "📋 View Logs" \
            "Back")

        case $action in
            "📊 Station Status")
                docker ps --filter "name=azuracast" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null
                echo ""
                gum style --foreground 245 "Admin: https://kpab.fm/login"
                gum input --placeholder "Press Enter to return..."
                ;;
            "🔄 Restart AzuraCast")
                if gum confirm "Restart the radio station?"; then
                    gum spin --spinner dot --title "Restarting KPAB.fm..." -- \
                        docker restart azuracast_web azuracast_services 2>/dev/null
                    play_tone "confirm"
                    gum style --foreground 46 "Station restarted."
                    sleep 1
                fi
                ;;
            "🎵 Audio Visualizer (cava)")
                if command -v cava &>/dev/null; then cava
                else gum style --foreground 196 "cava not installed"; sleep 2; fi
                ;;
            "📥 Start Track Drop")
                if [ -f ~/pibulus-os/scripts/start_drop.sh ]; then
                    ~/pibulus-os/scripts/start_drop.sh
                else
                    gum style --foreground 196 "start_drop.sh not found"
                    sleep 2
                fi
                ;;
            "📋 View Logs")
                docker logs --tail 50 azuracast_web 2>/dev/null | less
                ;;
            "Back") return ;;
        esac
    done
}
