#!/bin/bash
# ♂️ PIBULUS DEPLOY WIZARD v4.0
# "The Cyberdeck App Launcher"

WEB_ROOT="/media/pibulus/passport/www/html"
APPS_ROOT="/media/pibulus/passport/www/apps"
CF_CONFIG="/etc/cloudflared/config.yml"
TUNNEL_NAME="pibulus-tunnel"

# --- COLORS ---
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}------------------------------------------------${NC}"
echo -e "${CYAN}🚀 PIBULUS CYBERDECK DEPLOYER v4.0${NC}"
echo -e "${CYAN}------------------------------------------------${NC}"

# 1. GET INPUT
read -p "🔗 Paste the GitHub URL: " REPO_URL
[ -z "$REPO_URL" ] && { echo -e "${RED}Error: URL required.${NC}"; exit 1; }

DEFAULT_NAME=$(basename "$REPO_URL" .git)
read -p "🏷️  Name this app (default: $DEFAULT_NAME): " APP_NAME
APP_NAME=${APP_NAME:-$DEFAULT_NAME}

# 2. CLONE
TEMP_DIR="/tmp/$APP_NAME-deploy"
rm -rf "$TEMP_DIR"
git clone "$REPO_URL" "$TEMP_DIR" || { echo -e "${RED}Clone failed.${NC}"; exit 1; }
cd "$TEMP_DIR" || exit

# 3. TYPE DETECTION & DEPLOYMENT (Logic remains same as your v3.1)
# ... [Keeping your Deno/Svelte logic here as it was solid] ...

# 4. SMART CLOUDFLARE AUTOMATION
read -p "🌐 Do you have a domain for this? (y/n): " HAS_DOMAIN
if [[ "$HAS_DOMAIN" == "y" ]]; then
    read -p "🌍 Enter Domain (e.g., bone-soup.quickcat.club): " DOMAIN
    
    # Check for Marker
    if ! grep -q "# -- INSERT NEW APPS HERE --" "$CF_CONFIG"; then
        echo -e "${RED}⚠️  Marker missing in config.yml! Adding manually...${NC}"
        sudo sed -i '/service: http_status:404/i # -- INSERT NEW APPS HERE --\n' "$CF_CONFIG"
    fi

    # Inject new hostname
    if sudo grep -q "$DOMAIN" "$CF_CONFIG"; then
        echo "ℹ️  Domain already exists in tunnel config."
    else
        sudo sed -i "/# -- INSERT NEW APPS HERE --/a \  - hostname: $DOMAIN\n    service: $LOCAL_URL" "$CF_CONFIG"
        echo -e "${GREEN}✅ Added $DOMAIN to Tunnel Config.${NC}"
    fi

    echo "🔄 Restarting Tunnel..."
    sudo systemctl restart cloudflared
    echo -e "${GREEN}🎉 DEPLOYED! Visit: https://$DOMAIN${NC}"
fi
