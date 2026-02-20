#!/bin/bash
# 💀 QUICK CAT CLUB - GREY HAT OPS

manage_grey_hat() {
    while true; do
        render_hud
        echo -e "$(gum style --foreground 196 '--- 💀 GREY HAT OPS ---')"
        local action=$(tactile_choose "🔍 Scan Local Network (nmap)" "📡 Sniff Traffic (sniffglue)" "💬 IRC Underground (The Lounge)" "Back")
        
        case $action in
            "🔍 Scan Local Network (nmap)")
                local range=$(gum input --placeholder "IP Range (e.g., 192.168.0.0/24)")
                [ ! -z "$range" ] && sudo nmap -sP "$range" | less
                ;;
            "📡 Sniff Traffic (sniffglue)")
                sudo sniffglue wlan0
                ;;
            "💬 IRC Underground (The Lounge)")
                echo "IRC accessible at http://pibulus.local:9000"
                gum input --placeholder "Press Enter to return..."
                ;;
            "Back") return ;;
        esac
    done
}
