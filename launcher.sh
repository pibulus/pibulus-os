#!/bin/bash
# 🦾 PIBULUS CYBERDECK v5.4 - "The High-Vis Update"

# --- SOURCE CONFIG ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
[ -f "$SCRIPT_DIR/.env" ] && source "$SCRIPT_DIR/.env" || { echo "❌ No .env"; exit 1; }

# --- UTILS ---
get_status() {
    if [ "$(docker ps -q -f name=$1)" ]; then
        echo "🟢"
    else
        echo "🔴"
    fi
}

render_hud() {
    clear
    local TEMP=$(vcgencmd measure_temp | cut -d'=' -f2)
    local DISK=$(df -h "$PASSPORT_ROOT" | awk 'NR==2 {print $5}')
    gum style --border double --border-foreground 212 --padding "0 2" --margin "1 0" 
        "🌡️ CPU: $TEMP  |  📼 PASSPORT: $DISK  |  ⚓ STACKS: $(get_status jellyfin) $(get_status immich_server)"
}

manage_immich() {
    while true; do
        render_hud
        echo -e "--- 📸 IMMICH VAULT $(get_status immich_server) ---"
        local action=$(gum choose "Start/Update" "Stop" "Logs" "🔐 Authenticate iCloud" "Back")
        case $action in
            "Start/Update") gum spin --title "Booting..." -- docker compose -f "$IMMICH_CONFIG" up -d ;;
            "Stop") docker compose -f "$IMMICH_CONFIG" down ;;
            "Logs") docker compose -f "$IMMICH_CONFIG" logs --tail=100 -f ;;
            "🔐 Authenticate iCloud") docker exec -it icloudpd sync-icloud.sh --Initialise ;;
            "Back") return ;;
        esac
    done
}

manage_stack() {
    local name=$1
    local file=$2
    local indicator=$(get_status $3)
    while true; do
        render_hud
        echo -e "--- 🛠️  MANAGING $name $indicator ---"
        docker compose -f "$file" ps --format "table {{.Name}}	{{.Status}}" | gum style --foreground 212
        echo ""
        local action=$(gum choose "Start/Update" "Stop" "Restart" "Logs" "Back")
        case $action in
            "Start/Update") docker compose -f "$file" up -d ;;
            "Stop") docker compose -f "$file" down ;;
            "Restart") docker compose -f "$file" restart ;;
            "Logs") docker compose -f "$file" logs --tail=100 -f ;;
            "Back") return ;;
        esac
    done
}

# --- THE MAIN DECK ---
while true; do
    render_hud
    local choice=$(gum choose 
        "🚀 Deploy New App" 
        "📊 System Status" 
        "🌐 Tunnel Status" 
        "🏴‍☠️ Pirate Station $(get_status jellyfin)" 
        "📸 Immich Vault $(get_status immich_server)" 
        "🏠 Dashboard Ops" 
        "📝 Edit Tunnel" 
        "❓ Help & Manual" 
        "🚪 Exit")

    case $choice in
        "🚀 Deploy New App") "$SCRIPT_DIR/scripts/deploy.sh" ;;
        "📊 System Status") pm2 list && gum input --placeholder "Enter to return..." ;;
        "🌐 Tunnel Status") sudo systemctl status cloudflared | head -n 20 && gum input --placeholder "Enter to return..." ;;
        "🏴‍☠️ Pirate Station") manage_stack "PIRATE STATION" "$PIRATE_CONFIG" "jellyfin" ;;
        "📸 Immich Vault") manage_immich ;;
        "🏠 Dashboard Ops") manage_homepage ;; # Still exists from v5.3
        "📝 Edit Tunnel") sudo nano "$CF_CONFIG" && sudo systemctl restart cloudflared ;;
        "❓ Help & Manual") "$SCRIPT_DIR/launcher.sh" --help ;; # Placeholder
        "🚪 Exit") clear; exit 0 ;;
    esac
done
