#\!/bin/bash
# 📻 PIBULUS RADIO MODULE v1.0
# KPAB.fm Control Center

manage_radio() {
    while true; do
        render_hud
        echo -e "$(gum style --foreground 212 '--- 📻 KPAB.fm RADIO OPS ---')"
        local action=$(tactile_choose \
            "Station Status" \
            "Restart AzuraCast" \
            "📊 Audio Visualizer (cava)" \
            "📥 Start Track Drop" \
            "View Logs" \
            "Back")
        
        case $action in
            "Station Status")
                docker ps --filter "name=azuracast"
                gum input --placeholder "Press Enter to return..."
                ;;
            "Restart AzuraCast")
                if gum confirm "Restart the radio station?"; then
                    docker restart azuracast_web azuracast_services 2>/dev/null || echo "AzuraCast not found."
                    sleep 2
                fi
                ;;
            "📊 Audio Visualizer (cava)") cava ;;
            "📥 Start Track Drop") ~/pibulus-os/scripts/start_drop.sh ;;
            "View Logs")
                docker logs --tail 50 azuracast_web | less
                ;;
            "Back") return ;;
        esac
    done
}
