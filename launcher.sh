#!/bin/bash
# 🦾 PIBULUS CYBERDECK v5.5 - "The ADHD Safety Net"

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

show_help() {
    clear
    figlet -f slant "DONT PANIC" | lolcat
    gum style --border normal --margin "1 2" --padding "1 2" --border-foreground 212 
    "It's okay. We all forget. Here is the cheat sheet.

$(gum style --foreground 46 "THE ONE COMMAND:")
- $(gum style --foreground 226 "deck") -> Type this to open the main menu. Everything is there.

$(gum style --foreground 46 "I WANT TO...")
- $(gum style --foreground 226 "See my photos?") -> Run 'deck', pick 'Immich'.
- $(gum style --foreground 226 "Fix iCloud?") -> Run 'deck', pick 'Immich', then 'Authenticate'.
- $(gum style --foreground 226 "Add movies?") -> Put files in /media/pibulus/passport/Movies.
- $(gum style --foreground 226 "Check if it's broken?") -> Look for 🔴 lights in the menu.

$(gum style --foreground 46 "EMERGENCY:")
- If the menu freezes: Press 'Ctrl+C'
- If the Pi freezes: Unplug it (brutal but effective).
- If you are lost: Type 'halp' again." | lolcat
    
    echo ""
    gum input --placeholder "Feeling better? Press Enter to fly..."
}

# --- ARGUMENT CHECK (The Safety Net) ---
if [[ "$1" =~ ^(help|halp|sos|wtf|\-h|\-\-help)$ ]]; then
    show_help
    exit 0
fi

# ... [Rest of the functions: manage_immich, manage_stack, etc.] ...
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
    # Re-sourcing themes logic from v5.3
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
        "🏠 Dashboard Ops") manage_homepage ;;
        "📝 Edit Tunnel") sudo nano "$CF_CONFIG" && sudo systemctl restart cloudflared ;;
        "❓ Help & Manual") show_help ;;
        "🚪 Exit") clear; exit 0 ;;
    esac
done
