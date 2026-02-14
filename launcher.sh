#!/bin/bash
# 🦾 PIBULUS CYBERDECK v5.2 - "The Sovereign Update"
# Agnostic. Modular. Robust.

# --- SOURCE CONFIG ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
else
    echo "❌ Missing .env file. Run setup or create one."
    exit 1
fi

# Paths from .env (or defaults)
PIRATE_CONFIG="$SCRIPT_DIR/config/stacks/pirate.yml"
IMMICH_CONFIG="$SCRIPT_DIR/config/stacks/immich.yml"
TUNNEL_CONFIG="${CF_CONFIG:-/etc/cloudflared/config.yml}"

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

show_help() {
    clear
    figlet -f slant "PIBULUS OS" | lolcat
    gum style --border normal --margin "1 2" --padding "1 2" --border-foreground 212 
    "Sovereignty looks good on you. Here's the manual.

$(gum style --foreground 46 "THE STACKS:")
- $(gum style --foreground 226 "Pirate Station:") Media heart. (Jellyfin/Navidrome)
- $(gum style --foreground 226 "Immich Vault:") Photo archive + iCloud bridge.

$(gum style --foreground 46 "SOVEREIGN TIPS:")
- This deck reads from ~/pibulus-os/.env. Change the paths there, and the deck follows.
- No deck? No problem. Use 'docker compose' directly. The scripts are just shortcuts.
- Keep your Passport drive healthy. It's your history. 😉" | lolcat
    
    echo ""
    gum input --placeholder "Hit Enter to return to the mainframe..."
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
        "🏠 Restart Dashboard" 
        "📝 Edit Tunnel" 
        "❓ Help & Manual" 
        "🚪 Exit")

    case $choice in
        "🚀 Deploy New App") "$SCRIPT_DIR/scripts/deploy.sh" ;;
        "📊 System Status") pm2 list && gum input --placeholder "Enter to return..." ;;
        "🌐 Tunnel Status") sudo systemctl status cloudflared | head -n 20 && gum input --placeholder "Enter to return..." ;;
        "🏴‍☠️ Pirate Station") manage_stack "PIRATE STATION" "$PIRATE_CONFIG" ;;
        "📸 Immich Vault") manage_stack "IMMICH" "$IMMICH_CONFIG" ;;
        "🏠 Restart Dashboard") gum spin --spinner pulse --title "Cycling Homepage..." -- docker restart homepage ;;
        "📝 Edit Tunnel") sudo nano "$TUNNEL_CONFIG" && sudo systemctl restart cloudflared ;;
        "❓ Help & Manual") show_help ;;
        "🚪 Exit") clear; exit 0 ;;
    esac
done
