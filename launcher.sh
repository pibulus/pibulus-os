#!/bin/bash
# 🦾 PIBULUS CYBERDECK v5.1 - "The Ergonomic Update"
# Optimized for cognitive ease and cyberpunk aesthetics.

# --- CONFIGURATION ---
PIRATE_CONFIG="$HOME/pibulus-os/config/stacks/pirate.yml"
IMMICH_CONFIG="$HOME/pibulus-os/config/stacks/immich.yml"
TUNNEL_CONFIG="/etc/cloudflared/config.yml"

# --- COLORS ---
CYAN='#00FFFF'
MAGENTA='#FF00FF'
YELLOW='#FFFF00'
GREEN='#00FF00'

# --- HUD (Head-Up Display) ---
render_hud() {
    clear
    local TEMP=$(vcgencmd measure_temp | cut -d'=' -f2)
    local DISK=$(df -h /media/pibulus/passport | awk 'NR==2 {print $5}')
    local SD=$(df -h / | awk 'NR==2 {print $5}')
    
    # Create a nice HUD box
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
    "Welcome, Chummer. This deck is your gateway to the digital estate.

$(gum style --foreground 46 "THE STACKS:")
- $(gum style --foreground 226 "Pirate Station:") Your media heart. Jellyfin & Navidrome.
- $(gum style --foreground 226 "Immich Vault:") AI Photo archive + iCloud bridge.

$(gum style --foreground 46 "QUICK TIPS:")
- iCloud not syncing? Use the bridge command in the manual.
- Passport drive is your 'Gold Record'. Protect it.
- Everything is modular. If it breaks, we fix it in the YAML." | lolcat
    
    echo ""
    gum input --placeholder "Press Enter to return to the mainframe..."
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
    
    # The selection menu - Arrows + Enter (Low Cognitive Load)
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
        "🚀 Deploy New App") ~/pibulus-os/scripts/deploy.sh ;;
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
