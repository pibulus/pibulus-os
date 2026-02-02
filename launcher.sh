#!/bin/bash
# THE PIBULUS TERMINAL v2.0
# Add this to your .bashrc alias: alias deck="~/pibulus-os/launcher.sh"

# --- CONFIGURATION ---
PIRATE_CONFIG="$HOME/pibulus-os/config/stacks/pirate.yml"
IMMICH_CONFIG="$HOME/pibulus-os/config/stacks/immich.yml"
# Homepage usually runs via a simple docker run command or compose, assuming compose here:
HOMEPAGE_DIR="$HOME/pibulus-os/config/homepage" 

# --- COLORS ---
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

# --- FUNCTIONS ---
manage_stack() {
    local name=$1
    local file=$2
    
    echo -e "${YELLOW}--- MANAGING $name ---${NC}"
    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: Config file not found at $file${NC}"
        read -p "Press Enter to return..."
        return
    fi

    # Show status
    docker compose -f "$file" ps
    echo "--------------------------------"
    echo " (U)p/Start  (D)own/Stop  (R)estart  (L)ogs  (B)ack"
    read -p " Command: " cmd
    
    case $cmd in
        [Uu]*) docker compose -f "$file" up -d ;;
        [Dd]*) docker compose -f "$file" down ;;
        [Rr]*) docker compose -f "$file" restart ;;
        [Ll]*) docker compose -f "$file" logs --tail=20 -f ;;
        *) ;;
    esac
}

while true; do
    clear
    echo -e "${CYAN}==========================================${NC}"
    echo -e "${CYAN}   👾  P I B U L U S   C Y B E R D E C K  ${NC}"
    echo -e "${CYAN}==========================================${NC}"
    echo " 1. 🚀 Deploy New App (Wizard)"
    echo " 2. 📊 System Status (PM2)"
    echo " 3. 📡 Tunnel Status"
    echo " 4. 🏴‍☠️ Pirate Station (Jellyfin/Torrents)"
    echo " 5. 🖼️  Immich (Photos)"
    echo " 6. 🏠 Dashboard (Homepage)"
    echo " 7. 🚪 Exit"
    echo -e "${CYAN}==========================================${NC}"
    read -p " Select Protocol: " choice

    case $choice in
        1) 
            ~/pibulus-os/scripts/deploy.sh 
            read -p "Press Enter..." 
            ;;
        2) 
            pm2 list
            read -p "Press Enter..." 
            ;;
        3) 
            sudo systemctl status cloudflared
            read -p "Press Enter..." 
            ;;
        4) 
            manage_stack "PIRATE STATION" "$PIRATE_CONFIG" 
            ;;
        5) 
            manage_stack "IMMICH" "$IMMICH_CONFIG" 
            ;;
        6) 
            # Homepage might be just a container restart if it doesn't have its own compose file
            echo "Restarting Homepage container..."
            docker restart homepage
            read -p "Done. Press Enter..."
            ;;
        7) 
            clear
            exit 0 
            ;;
        *) 
            echo "Invalid option." 
            ;;
    esac
done
