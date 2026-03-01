#!/bin/bash
# 📡 QUICK CAT CLUB - SIGINT (Signals Intelligence) v1.1

manage_sigint() {
    while true; do
        render_hud
        echo -e "$(gum style --foreground 51 '--- 📡 SIGNALS INTELLIGENCE ---')"

        # Build menu dynamically based on what's installed
        local options=()
        command -v pyradio &>/dev/null && options+=("🌍 World Radio (PyRadio)")
        command -v readsb &>/dev/null && options+=("✈️  Track Aircraft (Radar)")
        [ -f ~/pibulus-os/radio-lab/pagers.sh ] && options+=("📟 Pager Decoder")
        [ -f ~/pibulus-os/radio-lab/scan_fm.sh ] && options+=("🔍 Frequency Scanner")

        if [ ${#options[@]} -eq 0 ]; then
            gum style --foreground 245 "No SIGINT tools installed yet."
            gum style --foreground 245 "Install pyradio, readsb, or check radio-lab scripts."
            gum input --placeholder "Press Enter to return..."
            return
        fi

        options+=("Back")
        local action=$(tactile_choose "${options[@]}")

        case $action in
            "🌍 World Radio (PyRadio)") pyradio ;;
            "✈️  Track Aircraft (Radar)")
                gum style --foreground 51 "Starting Radar..."
                gum style --foreground 245 "Open browser at http://pibulus.local:8080/dump1090/gmap.html"
                sudo systemctl start readsb
                gum input --placeholder "Press Enter to stop radar..."
                sudo systemctl stop readsb
                ;;
            "📟 Pager Decoder") ~/pibulus-os/radio-lab/pagers.sh ;;
            "🔍 Frequency Scanner")
                ~/pibulus-os/radio-lab/scan_fm.sh
                gum input --placeholder "Press Enter to return..."
                ;;
            "Back") return ;;
        esac
    done
}
