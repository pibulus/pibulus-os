#!/bin/bash
# 🦾 PIBULUS CYBERDECK v5.3 - "The Aesthetic Update"

# --- SOURCE CONFIG ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
else
    echo "❌ Missing .env file."
    exit 1
fi

# Paths
PIRATE_CONFIG="$SCRIPT_DIR/config/stacks/pirate.yml"
IMMICH_CONFIG="$SCRIPT_DIR/config/stacks/immich.yml"
HOMEPAGE_DIR="$SCRIPT_DIR/config/homepage"
THEMES_DIR="$HOMEPAGE_DIR/themes"

# --- HUD ---
render_hud() {
    clear
    local TEMP=$(vcgencmd measure_temp | cut -d'=' -f2)
    local DISK=$(df -h "$PASSPORT_ROOT" | awk 'NR==2 {print $5}')
    local SD=$(df -h / | awk 'NR==2 {print $5}')
    
    gum style 
        --border double 
        --border-foreground 212 
        --padding "0 2" 
        --margin "1 0" 
        "🌡️ CPU: $TEMP  |  📼 PASSPORT: $DISK  |  💾 SD: $SD"
}

manage_homepage() {
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
            "Restart Dashboard")
                gum spin --spinner pulse --title "Cycling Homepage..." -- docker restart homepage
                ;;
            "Back") return ;;
        esac
    done
}

manage_stack() {
    local name=$1
    local file=$2
    while true; do
        render_hud
        echo -e "--- 🛠️  MANAGING $name ---"
        docker compose -f "$file" ps --format "table {{.Name}}	{{.Status}}" | gum style --foreground 212
        
        echo ""
        local action=$(gum choose "Start/Update" "Stop" "Restart" "Logs" "Back")
        
        case $action in
            "Start/Update") gum spin --spinner dot --title "Deploying..." -- docker compose -f "$file" up -d ;;
            "Stop") gum spin --spinner dot --title "Halting..." -- docker compose -f "$file" down ;;
            "Restart") gum spin --spinner dot --title "Cycling..." -- docker compose -f "$file" restart ;;
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
        "🏴‍☠️ Pirate Station" 
        "📸 Immich Vault" 
        "🏠 Dashboard Ops" 
        "📝 Edit Tunnel" 
        "❓ Help & Manual" 
        "🚪 Exit")

    case $choice in
        "🚀 Deploy New App") "$SCRIPT_DIR/scripts/deploy.sh" ;;
        "📊 System Status") pm2 list && gum input --placeholder "Enter to return..." ;;
        "🌐 Tunnel Status") sudo systemctl status cloudflared | head -n 20 && gum input --placeholder "Enter to return..." ;;
        "🏴‍☠️ Pirate Station") manage_stack "PIRATE STATION" "$PIRATE_CONFIG" ;;
        "📸 Immich Vault") manage_stack "IMMICH" "$IMMICH_CONFIG" ;;
        "🏠 Dashboard Ops") manage_homepage ;;
        "📝 Edit Tunnel") sudo nano "$CF_CONFIG" && sudo systemctl restart cloudflared ;;
        "❓ Help & Manual") "$SCRIPT_DIR/launcher.sh" --help ;; # Just a placeholder
        "🚪 Exit") clear; exit 0 ;;
    esac
done
