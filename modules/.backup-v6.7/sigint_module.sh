#!/bin/bash
# 📡 QUICK CAT CLUB - SIGINT (Signals Intelligence)

manage_sigint() {
    while true; do
        render_hud
        echo -e "$(gum style --foreground 51 '--- 📡 SIGNALS INTELLIGENCE ---')"
        local action=$(tactile_choose "🌍 World Radio (PyRadio)" "✈️  Track Aircraft (Radar)" "📟 Pager Decoder" "🔍 Frequency Scanner" "Back")
        
        case $action in
            "🌍 World Radio (PyRadio)")
                pyradio
                ;;
            "✈️  Track Aircraft (Radar)")
                echo "Starting Radar... Open browser at http://pibulus.local:8080/dump1090/gmap.html"
                sudo systemctl start readsb
                gum input --placeholder "Press Enter to stop radar..."
                sudo systemctl stop readsb
                ;;
            "📟 Pager Decoder")
                ~/pibulus-os/radio-lab/pagers.sh
                ;;
            "🔍 Frequency Scanner")
                ~/pibulus-os/radio-lab/scan_fm.sh
                gum input --placeholder "Press Enter to return..."
                ;;
            "Back")
                return
                ;;
        esac
    done
}
