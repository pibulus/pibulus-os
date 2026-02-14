#!/bin/bash
# 🦾 PIBULUS CYBERDECK v5.7 - "The Radio Empire Update"

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
        "👤 $USER_NAME | 🌡️ $TEMP | 📼 $DISK | ⚓ $(get_status jellyfin) $(get_status immich_server) $(get_status azuracast_web)"
}

manage_radio() {
    while true; do
        render_hud
        echo -e "--- 📻 KPAB.fm RADIO $(get_status azuracast_web) ---"
        local action=$(gum choose "Start Station" "Stop Station" "Logs" "Back")
        case $action in
            "Start Station") cd ~/azuracast && ./docker.sh install ;;
            "Stop Station") cd ~/azuracast && docker compose down ;;
            "Logs") cd ~/azuracast && docker compose logs --tail=100 -f ;;
            "Back") return ;;
        esac
    done
}

# ... [Keep previous manage_immich, manage_homepage, manage_stack functions] ...
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

manage_homepage() {
    HOMEPAGE_DIR="$SCRIPT_DIR/config/homepage"
    THEMES_DIR="$HOMEPAGE_DIR/themes"
    while true; do
        render_hud
        echo -e "--- 🏠 DASHBOARD OPS ---"
        local action=$(gum choose "Switch Theme" "Restart Dashboard" "Back")
        case $action in
            "Switch Theme")
                local theme=$(gum choose "Cyberpunk" "Vaporwave" "NeoBrutalist" "NeutralDark")
                case $theme in
                    "Cyberpunk") cp "$THEMES_DIR/cyberpunk.css" "$HOMEPAGE_DIR/custom.css" ;;
                    "Vaporwave") cp "$THEMES_DIR/vaporwave.css" "$HOMEPAGE_DIR/custom.css" ;;
                    "NeoBrutalist") cp "$THEMES_DIR/neobrutalist.css" "$HOMEPAGE_DIR/custom.css" ;;
                    "NeutralDark") cp "$THEMES_DIR/neutraldark.css" "$HOMEPAGE_DIR/custom.css" ;;
                esac
                gum spin --spinner pulse --title "Applying $theme style..." -- docker restart homepage
                ;;
            "Restart Dashboard") gum spin --spinner pulse --title "Cycling Homepage..." -- docker restart homepage ;;
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

show_help() {
    clear
    figlet -f slant "KPAB FM" | lolcat
    gum style --border normal --margin "1 2" --padding "1 2" --border-foreground 212 
    "Welcome to the Voice of the Fortress.

$(gum style --foreground 46 "RADIO TIPS:")
- Drop MP3s in /media/pibulus/passport/Radio/Tunes.
- Drop rants in /media/pibulus/passport/Radio/Rants.
- AzuraCast will handle the smart mixing. You just provide the vibes.

$(gum style --foreground 46 "SOVEREIGNTY:")
- Your voice, your hardware, your rules. Stay loud." | lolcat
    gum input --placeholder "Back to the bridge? Press Enter..."
}

if [[ "$1" =~ ^(help|halp|sos|wtf|\-h|\-\-help)$ ]]; then
    show_help
    exit 0
fi

# --- THE MAIN DECK ---
while true; do
    render_hud
    local choice=$(gum choose 
        "🚀 Deploy New App" 
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
        "🚀 Deploy New App") "$SCRIPT_DIR/scripts/deploy.sh" ;;
        "🏴‍☠️ Pirate Station") manage_stack "PIRATE STATION" "$PIRATE_CONFIG" "jellyfin" ;;
        "📻 KPAB.fm Radio") manage_radio ;;
        "📸 Immich Vault") manage_immich ;;
        "🏠 Dashboard Ops") manage_homepage ;;
        "📊 System Status") pm2 list && gum input --placeholder "Enter to return..." ;;
        "🌐 Tunnel Status") sudo systemctl status cloudflared | head -n 20 && gum input --placeholder "Enter to return..." ;;
        "📝 Edit Tunnel") sudo nano "$CF_CONFIG" && sudo systemctl restart cloudflared ;;
        "❓ Help & Manual") show_help ;;
        "🚪 Exit") clear; exit 0 ;;
    esac
done
