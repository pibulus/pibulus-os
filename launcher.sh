#!/bin/bash
# 🦾 PIBULUS CYBERDECK v3.0 - Saturday Night Special

# --- CONFIGURATION ---
PIRATE_CONFIG="$HOME/pibulus-os/config/stacks/pirate.yml"
IMMICH_CONFIG="$HOME/pibulus-os/config/stacks/immich.yml"
TUNNEL_CONFIG="/etc/cloudflared/config.yml"

# --- COLORS ---
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

# --- FUNCTIONS ---
get_vitals() {
    TEMP=$(vcgencmd measure_temp | cut -d'=' -f2)
    DISK=$(df -h /media/pibulus/passport | awk 'NR==2 {print $5}')
    SD=$(df -h / | awk 'NR==2 {print $5}')
    echo -e "${MAGENTA}🔥 CPU: $TEMP  📼 Passport: $DISK  💾 SD: $SD${NC}"
}

show_help() {
    clear
    figlet -f slant "PIBULUS OS" | lolcat
    echo -e "${CYAN}Welcome to the Cyberdeck Manual, Chummer.${NC}" | lolcat
    echo ""
    gum style --border normal --margin "1 2" --padding "1 2" --border-foreground 212 "This deck is a modular stack system. Use the numbers to navigate.
    
${GREEN}COMMANDS:${NC}
- ${YELLOW}deck:${NC} Re-opens this main menu.
- ${YELLOW}docker ps:${NC} See what's alive.
- ${YELLOW}lsblk:${NC} Check if the Passport drive is mounted.

${GREEN}TASKS:${NC}
- ${MAGENTA}iCloud Sync:${NC} Run 'docker exec -it icloudpd sync-icloud.sh --Initialise'
- ${MAGENTA}Media:${NC} Drop files in /media/pibulus/passport/Music or Movies.

${RED}REMEMBER:${NC} Infrastructure is code. Stacks live in ~/pibulus-os/config/stacks/" | lolcat
    echo ""
    gum spin --spinner dot --title "Returning to Mainframe..." -- sleep 3
}

manage_stack() {
    local name=$1
    local file=$2
    clear
    echo -e "${YELLOW}--- MANAGING $name ---${NC}"
    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: Config file not found at $file${NC}"
        read -p "Press Enter to return..."
        return
    fi
    docker compose -f "$file" ps
    echo "------------------------------------------------"
    echo " (U)p/Start  (D)own/Stop  (R)estart  (L)ogs  (B)ack"
    read -p " Command: " cmd
    case $cmd in
        [Uu]*) docker compose -f "$file" up -d ;;
        [Dd]*) docker compose -f "$file" down ;;
        [Rr]*) docker compose -f "$file" restart ;;
        [Ll]*) docker compose -f "$file" logs --tail=50 -f ;;
        *) return ;;
    esac
}

# --- THE MAIN DECK ---
while true; do
    clear
    echo -e "${CYAN}┌──────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│     🐙  Q U I C K C A T . C L U B        │${NC}"
    echo -e "${CYAN}│     MEXI-AUSTRALIAN CYBERDECK v3.0       │${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────┘${NC}"
    get_vitals
    echo -e "--------------------------------------------"
    echo -e " 1. 🚀 ${GREEN}Deploy New App${NC} (Wizard)"
    echo -e " 2. 📊 ${GREEN}System Status${NC} (PM2)"
    echo -e " 3. 🌐 ${GREEN}Tunnel Status${NC} (Cloudflare)"
    echo -e " 4. 🏴‍☠️  ${YELLOW}Pirate Station${NC} (Jellyfin/Navi)"
    echo -e " 5. 📸  ${YELLOW}Immich${NC} (Photos)"
    echo -e " 6. 🏠 ${YELLOW}Dashboard${NC} (Homepage)"
    echo -e " 7. 📝 ${RED}Edit Tunnel Config${NC}"
    echo -e " 8. ❓ ${CYAN}Help & Manual${NC}"
    echo -e " 9. 🚪 Exit"
    echo -e "--------------------------------------------"
    read -p " Select Protocol: " choice

    case $choice in
        1) ~/pibulus-os/scripts/deploy.sh ; read -p "Press Enter..." ;;
        2) pm2 list ; read -p "Press Enter..." ;;
        3) sudo systemctl status cloudflared ; read -p "Press Enter..." ;;
        4) manage_stack "PIRATE STATION" "$PIRATE_CONFIG" ;;
        5) manage_stack "IMMICH" "$IMMICH_CONFIG" ;;
        6) echo "Restarting Dashboard..."; docker restart homepage ; sleep 2 ;;
        7) sudo nano "$TUNNEL_CONFIG" && sudo systemctl restart cloudflared ;;
        8) show_help ;;
        9) clear ; exit 0 ;;
        *) echo "Invalid Protocol." ; sleep 1 ;;
    esac
done
