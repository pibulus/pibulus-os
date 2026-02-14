#!/bin/bash
# 🦾 PIBULUS CYBERDECK v6.2 - "The Final Frontier"
# Final Pass: Flair, Power, and Sovereignty.

# --- SOURCE CONFIG ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
[ -f "$SCRIPT_DIR/.env" ] && source "$SCRIPT_DIR/.env" || { echo "❌ No .env"; exit 1; }

# --- LOAD MODULES ---
source "$SCRIPT_DIR/modules/audio_feedback.sh"
source "$SCRIPT_DIR/modules/media_puller.sh"

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
    
    # High-Flair HUD
    gum style 
        --border double 
        --border-foreground 212 
        --padding "0 2" 
        --margin "1 0" 
        --align center 
        "👤 $USER_NAME  |  🌡️ $TEMP  |  📼 $DISK  |  ⚡ LOAD: $LOAD"
}

tactile_choose() {
    local choice=$(gum choose "$@")
    [ ! -z "$choice" ] && play_tone "click"
    echo "$choice"
}

# --- STACK MANAGEMENT ---
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
            "Stop") play_tone "confirm"; docker compose -f "$IMMICH_CONFIG" down ;;
            "Logs") play_tone "confirm"; docker compose -f "$IMMICH_CONFIG" logs --tail=100 -f ;;
            "🔐 Authenticate iCloud") play_tone "confirm"; docker exec -it icloudpd sync-icloud.sh --Initialise ;;
            "Back") return ;;
        esac
    done
}

manage_homepage() {
    HOMEPAGE_DIR="$SCRIPT_DIR/config/homepage"
    THEMES_DIR="$HOMEPAGE_DIR/themes"
    while true; do
        render_hud
        echo -e "$(gum style --foreground 226 '--- 🏠 DASHBOARD OPS ---')"
        local action=$(tactile_choose "Switch Theme" "Restart Dashboard" "Back")
        case $action in
            "Switch Theme")
                local theme=$(tactile_choose "Cyberpunk" "Vaporwave" "NeoBrutalist" "NeutralDark")
                case $theme in
                    "Cyberpunk") cp "$THEMES_DIR/cyberpunk.css" "$HOMEPAGE_DIR/custom.css" ;;
                    "Vaporwave") cp "$THEMES_DIR/vaporwave.css" "$HOMEPAGE_DIR/custom.css" ;;
                    "NeoBrutalist") cp "$THEMES_DIR/neobrutalist.css" "$HOMEPAGE_DIR/custom.css" ;;
                    "NeutralDark") cp "$THEMES_DIR/neutraldark.css" "$HOMEPAGE_DIR/custom.css" ;;
                esac
                play_tone "confirm"
                gum spin --spinner pulse --title "Shifting Vibe..." -- docker restart homepage
                ;;
            "Restart Dashboard") play_tone "confirm"; docker restart homepage ;;
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
            "Start/Update") play_tone "confirm"; docker compose -f "$file" up -d ;;
            "Stop") play_tone "confirm"; docker compose -f "$file" down ;;
            "Restart") play_tone "confirm"; docker compose -f "$file" restart ;;
            "Logs") play_tone "confirm"; docker compose -f "$file" logs --tail=100 -f ;;
            "Back") return ;;
        esac
    done
}

# --- THE HELP SCREEN ---
show_help() {
    clear
    play_tone "startup"
    figlet -f slant "PIBULUS" | lolcat
    gum style --border normal --margin "1 2" --padding "1 2" --border-foreground 212 
    "Welcome back, $USER_NAME. Sovereignty is simple.

$(gum style --foreground 46 "THE DECK:")
- 🟢 = Online. 🔴 = Offline.
- Every click has a sound. Every action a confirmation.

$(gum style --foreground 46 "THE EMPIRE:")
- 🏴‍☠️ Pirate Station: Movies & Music.
- 📻 KPAB.fm: Your voice, your rules.
- 📸 Immich: Your history, unmonitored.

$(gum style --foreground 226 "STAY LOUD. STAY SOVEREIGN.")" | lolcat
    gum input --placeholder "Hit Enter to return to the bridge..."
}

# --- MAIN LOOP ---
if [[ "$1" =~ ^(help|halp|sos|wtf)$ ]]; then
    show_help
    exit 0
fi

play_tone "startup"

while true; do
    render_hud
    local choice=$(tactile_choose 
        "🚀 Deploy New App" 
        "📥 Media Puller" 
        "🏴‍☠️ Pirate Station $(get_status jellyfin)" 
        "📻 KPAB.fm Radio $(get_status azuracast_web)" 
        "📸 Immich Vault $(get_status immich_server)" 
        "🏠 Dashboard Ops" 
        "📊 System Status" 
        "🌐 Tunnel Status" 
        "📝 Edit Tunnel" 
        "❓ Help & Manual" 
        "🚪 Exit")

    case $choice in
        "🚀 Deploy New App") play_tone "confirm"; "$SCRIPT_DIR/scripts/deploy.sh" ;;
        "📥 Media Puller") pull_media ;;
        "🏴‍☠️ Pirate Station") manage_stack "PIRATE STATION" "$PIRATE_CONFIG" "jellyfin" ;;
        "📻 KPAB.fm Radio") manage_radio ;;
        "📸 Immich Vault") manage_immich ;;
        "🏠 Dashboard Ops") manage_homepage ;;
        "📊 System Status") pm2 list && gum input --placeholder "Enter to return..." ;;
        "🌐 Tunnel Status") sudo systemctl status cloudflared | head -n 20 && gum input --placeholder "Enter to return..." ;;
        "📝 Edit Tunnel") play_tone "confirm"; sudo nano "$CF_CONFIG" && sudo systemctl restart cloudflared ;;
        "❓ Help & Manual") show_help ;;
        "🚪 Exit") play_tone "click"; clear; exit 0 ;;
    esac
done
