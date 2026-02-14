#!/bin/bash
# 🦾 PIBULUS CYBERDECK v6.0 - "The Tactile Update"

# --- SOURCE CONFIG ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
[ -f "$SCRIPT_DIR/.env" ] && source "$SCRIPT_DIR/.env" || { echo "❌ No .env"; exit 1; }

# --- LOAD MODULES ---
source "$SCRIPT_DIR/modules/audio_feedback.sh"

# --- ONBOARDING ---
if [[ -z "$USER_NAME" || "$USER_NAME" == "pibulus" ]]; then
    "$SCRIPT_DIR/onboard.sh"
    source "$SCRIPT_DIR/.env"
fi

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
        "👤 $USER_NAME | 🌡️ $TEMP | 📼 $DISK | ⚓ $(get_status jellyfin) $(get_status immich_server) $(get_status azuracast_web)"
}

# --- WRAPPER FOR GUM CHOOSE ---
# Plays a sound when a choice is made
tactile_choose() {
    local choice=$(gum choose "$@")
    if [ ! -z "$choice" ]; then
        play_tone "click"
        echo "$choice"
    fi
}

manage_radio() {
    while true; do
        render_hud
        echo -e "--- 📻 KPAB.fm RADIO $(get_status azuracast_web) ---"
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
        echo -e "--- 📸 IMMICH VAULT $(get_status immich_server) ---"
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
        echo -e "--- 🏠 DASHBOARD OPS ---"
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
                gum spin --spinner pulse --title "Applying $theme style..." -- docker restart homepage
                ;;
            "Restart Dashboard") play_tone "confirm"; gum spin --spinner pulse --title "Cycling Homepage..." -- docker restart homepage ;;
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

show_help() {
    clear
    play_tone "startup"
    figlet -f slant "PIBULUS" | lolcat
    gum style --border normal --margin "1 2" --padding "1 2" --border-foreground 212 
    "Welcome to the Tactile Interface.

$(gum style --foreground 46 "FEEDBACK:")
- Every click has a sound.
- Every action has a confirmation tone.
- If it's silent, check your speakers.

$(gum style --foreground 46 "RADIO:")
- Drop files in /Radio/The_Bucket.
- Tune in at http://pibulus.local:8080." | lolcat
    gum input --placeholder "Press Enter..."
}

if [[ "$1" =~ ^(help|halp|sos|wtf|\-h|\-\-help)$ ]]; then
    show_help
    exit 0
fi

# --- STARTUP SOUND ---
play_tone "startup"

# --- THE MAIN DECK ---
while true; do
    render_hud
    local choice=$(tactile_choose 
        "🚀 Deploy New App" 
        "📊 System Status" 
        "🌐 Tunnel Status" 
        "🏴‍☠️ Pirate Station $(get_status jellyfin)" 
        "📻 KPAB.fm Radio $(get_status azuracast_web)" 
        "📸 Immich Vault $(get_status immich_server)" 
        "🏠 Dashboard Ops" 
        "📝 Edit Tunnel" 
        "❓ Help & Manual" 
        "🚪 Exit")

    case $choice in
        "🚀 Deploy New App") play_tone "confirm"; "$SCRIPT_DIR/scripts/deploy.sh" ;;
        "📊 System Status") play_tone "confirm"; pm2 list && gum input --placeholder "Enter to return..." ;;
        "🌐 Tunnel Status") play_tone "confirm"; sudo systemctl status cloudflared | head -n 20 && gum input --placeholder "Enter to return..." ;;
        "🏴‍☠️ Pirate Station") manage_stack "PIRATE STATION" "$PIRATE_CONFIG" "jellyfin" ;;
        "📻 KPAB.fm Radio") manage_radio ;;
        "📸 Immich Vault") manage_immich ;;
        "🏠 Dashboard Ops") manage_homepage ;;
        "📝 Edit Tunnel") play_tone "confirm"; sudo nano "$CF_CONFIG" && sudo systemctl restart cloudflared ;;
        "❓ Help & Manual") show_help ;;
        "🚪 Exit") play_tone "click"; clear; exit 0 ;;
    esac
done
