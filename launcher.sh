#!/bin/bash
# 🦾 PIBULUS CYBERDECK v6.4 - "The Fortress Update"

# --- SOURCE CONFIG ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
[ -f "$SCRIPT_DIR/.env" ] && source "$SCRIPT_DIR/.env" || { echo "❌ No .env"; exit 1; }

# --- LOAD MODULES ---
source "$SCRIPT_DIR/modules/audio_feedback.sh"
source "$SCRIPT_DIR/modules/media_puller.sh"
source "$SCRIPT_DIR/modules/terminal_travels.sh"
source "$SCRIPT_DIR/modules/backup_module.sh"

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
    local LOAD=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d',' -f1)
    gum style --border double --border-foreground 212 --padding "0 2" --margin "1 0" --align center 
        "👤 $USER_NAME  |  🌡️ $TEMP  |  📼 $DISK  |  ⚡ LOAD: $LOAD"
}

tactile_choose() {
    local choice=$(gum choose "$@")
    [ ! -z "$choice" ] && play_tone "click"
    echo "$choice"
}

# [Keep previous management functions]
manage_radio() {
    while true; do
        render_hud
        echo -e "$(gum style --foreground 212 '--- 📻 KPAB.fm RADIO OPS ---')"
        local action=$(tactile_choose "Start Station" "Stop Station" "Logs" "Back")
        case $action in
            "Start Station") play_tone "confirm"; cd ~/azuracast && ./docker.sh install ;;
            "Stop Station") play_tone "confirm"; cd ~/azuracast && docker compose down ;;
            "Logs") play_tone "confirm"; cd ~/azuracast && docker compose logs --tail=100 -f ;;
            "Back") return ;;
        esac
    done
}

manage_immich() {
    while true; do
        render_hud
        echo -e "$(gum style --foreground 46 '--- 📸 IMMICH VAULT ---')"
        local action=$(tactile_choose "Start/Update" "Stop" "Logs" "🔐 Authenticate iCloud" "Back")
        case $action in
            "Start/Update") play_tone "confirm"; gum spin --title "Booting..." -- docker compose -f "$IMMICH_CONFIG" up -d ;;
            "Stop") docker compose -f "$IMMICH_CONFIG" down ;;
            "Logs") docker compose -f "$IMMICH_CONFIG" logs --tail=100 -f ;;
            "🔐 Authenticate iCloud") play_tone "confirm"; docker exec -it icloudpd sync-icloud.sh --Initialise ;;
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
        echo -e "$(gum style --foreground 212 "--- 🛠️  MANAGING $name $indicator ---")"
        docker compose -f "$file" ps --format "table {{.Name}}	{{.Status}}" | gum style --foreground 212
        echo ""
        local action=$(tactile_choose "Start/Update" "Stop" "Restart" "Logs" "Back")
        case $action in
            "Start/Update") docker compose -f "$file" up -d ;;
            "Stop") docker compose -f "$file" down ;;
            "Restart") docker compose -f "$file" restart ;;
            "Logs") docker compose -f "$file" logs --tail=100 -f ;;
            "Back") return ;;
        esac
    done
}

show_help() {
    clear
    play_tone "startup"
    figlet -f slant "BUNKER" | lolcat
    gum style --border normal --margin "1 2" --padding "1 2" --border-foreground 212 
    "Bunker is sealed, $USER_NAME. 

$(gum style --foreground 46 "THREAT ASSESSMENT:")
- All stack access points monitored.
- System DNA backed up to Passport.
- No anomalies detected.

$(gum style --foreground 226 "STAY VIGILANT. STAY LOUD.")" | lolcat
    gum input --placeholder "Back to the bridge? Press Enter..."
}

# --- MAIN LOOP ---
play_tone "startup"

while true; do
    render_hud
    local choice=$(tactile_choose 
        "🚀 Deploy New App" 
        "📥 Media Puller" 
        "🕹️ Terminal Travels (BBS)" 
        "🏴‍☠️ Pirate Station $(get_status jellyfin)" 
        "📻 KPAB.fm Radio $(get_status azuracast_web)" 
        "📸 Immich Vault $(get_status immich_server)" 
        "🛡️ Bunker Lockdown (Backup)" 
        "🏠 Dashboard Ops" 
        "📊 System Status" 
        "🌐 Tunnel Status" 
        "📝 Edit Tunnel" 
        "❓ Help & Manual" 
        "🚪 Exit")

    case $choice in
        "🚀 Deploy New App") play_tone "confirm"; "$SCRIPT_DIR/scripts/deploy.sh" ;;
        "📥 Media Puller") pull_media ;;
        "🕹️ Terminal Travels (BBS)") play_games ;;
        "🏴‍☠️ Pirate Station") manage_stack "PIRATE STATION" "$PIRATE_CONFIG" "jellyfin" ;;
        "📻 KPAB.fm Radio") manage_radio ;;
        "📸 Immich Vault") manage_immich ;;
        "🛡️ Bunker Lockdown (Backup)") run_backup ;;
        "🏠 Dashboard Ops") manage_homepage ;;
        "📊 System Status") pm2 list && gum input --placeholder "Enter to return..." ;;
        "🌐 Tunnel Status") sudo systemctl status cloudflared | head -n 20 && gum input --placeholder "Enter to return..." ;;
        "📝 Edit Tunnel") play_tone "confirm"; sudo nano "$CF_CONFIG" && sudo systemctl restart cloudflared ;;
        "❓ Help & Manual") show_help ;;
        "🚪 Exit") play_tone "click"; clear; exit 0 ;;
    esac
done
