#!/bin/bash
# 💀 QUICK CAT CLUB - GREY HAT OPS v1.1

manage_grey_hat() {
    while true; do
        render_hud
        echo -e "$(gum style --foreground 196 '--- 💀 GREY HAT OPS ---')"
        local action=$(tactile_choose \
            "🔍 Scan Local Network" \
            "📡 Sniff Traffic" \
            "💬 IRC Underground (The Lounge)" \
            "Back")

        case $action in
            "🔍 Scan Local Network")
                if ! command -v nmap &>/dev/null; then
                    gum style --foreground 196 "nmap not installed"
                    sleep 2
                    continue
                fi
                local range=$(gum input --value "192.168.0.0/24" --placeholder "IP Range (e.g., 192.168.0.0/24)")
                if [ -n "$range" ]; then
                    gum style --foreground 51 "Scanning $range..."
                    sudo nmap -sn "$range" | less
                fi
                ;;
            "📡 Sniff Traffic")
                if ! command -v sniffglue &>/dev/null; then
                    gum style --foreground 196 "sniffglue not installed"
                    sleep 2
                    continue
                fi
                local iface=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | gum choose --header "Select interface:")
                [ -n "$iface" ] && sudo sniffglue "$iface"
                ;;
            "💬 IRC Underground (The Lounge)")
                gum style --foreground 46 "IRC: http://pibulus.local:9000"
                gum input --placeholder "Press Enter to return..."
                ;;
            "Back") return ;;
        esac
    done
}
