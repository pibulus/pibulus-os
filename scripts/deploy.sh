#!/bin/bash
# PIBULUS DEPLOY WIZARD v3.1
# "The Cyberdeck App Launcher"

WEB_ROOT="/media/pibulus/passport/www/html"
APPS_ROOT="/media/pibulus/passport/www/apps"
# Note: We now link to the SYSTEM config, which is safer
CF_CONFIG="/etc/cloudflared/config.yml"
TUNNEL_NAME="pibulus-tunnel" 

# --- COLORS ---
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}------------------------------------------------${NC}"
echo -e "${CYAN}🧙‍♂️ PIBULUS CYBERDECK DEPLOYER v3.1${NC}"
echo -e "${CYAN}------------------------------------------------${NC}"

# 1. GET INPUT
read -p "🔗 Paste the GitHub URL: " REPO_URL
if [ -z "$REPO_URL" ]; then echo -e "${RED}❌ URL required.${NC}"; exit 1; fi

DEFAULT_NAME=$(basename $REPO_URL .git)
read -p "🏷️  Name this app (default: $DEFAULT_NAME): " APP_NAME
APP_NAME=${APP_NAME:-$DEFAULT_NAME}

echo "🚀 Analyzing $APP_NAME..."

# 2. CLONE & INSPECT
TEMP_DIR="/tmp/$APP_NAME-deploy"
rm -rf $TEMP_DIR
git clone $REPO_URL $TEMP_DIR
cd $TEMP_DIR

# 3. DETECT TYPE
APP_PORT=""

if [ -f "deno.json" ]; then
    echo -e "${GREEN}🦕 Deno/Fresh App Detected!${NC}"
    
    while true; do
        read -p "🔌 What PORT? (e.g. 8002): " PORT
        if [ -z "$PORT" ]; then echo "❌ Port required."; continue; fi
        
        # CHECK IF PORT IS BUSY
        if sudo lsof -i :$PORT > /dev/null; then
            echo -e "${RED}⚠️  Port $PORT is already in use! Pick another.${NC}"
        else
            APP_PORT=$PORT
            break
        fi
    done

    # Setup Directory
    mkdir -p $APPS_ROOT
    TARGET_DIR="$APPS_ROOT/$APP_NAME"
    
    if [ -d "$TARGET_DIR" ]; then
        echo "♻️  Stopping old process..."
        pm2 delete $APP_NAME 2>/dev/null
        rm -rf $TARGET_DIR
    fi
    
    mv $TEMP_DIR $TARGET_DIR
    cd $TARGET_DIR
    
    # Env & Start
    if [ ! -f ".env" ]; then
        echo "PORT=$APP_PORT" > .env
        echo "POSTHOG_KEY=dummy" >> .env
        echo "POSTHOG_HOST=fake" >> .env
    fi

    echo "🦕 Starting Server..."
    pm2 start "deno task start" --name $APP_NAME
    pm2 save
    LOCAL_URL="http://localhost:$APP_PORT"

elif [ -f "package.json" ]; then
    echo -e "${GREEN}📦 Static/Svelte App Detected!${NC}"
    
    cd $WEB_ROOT
    if [ -d "$APP_NAME" ]; then rm -rf $APP_NAME; fi
    mv $TEMP_DIR $APP_NAME
    cd $APP_NAME
    
    echo "🔧 Installing & Configuring..."
    npm install
    npm install -D @sveltejs/adapter-static
    
    # The Config Hack
    cat > svelte.config.js <<EOF
import adapter from '@sveltejs/adapter-static';
const config = {
	kit: {
		adapter: adapter({ pages: 'build', assets: 'build', fallback: 'index.html', strict: false }),
        paths: { base: '/$APP_NAME' },
        prerender: { handleHttpError: 'warn' }
	}
};
export default config;
EOF
    mkdir -p src/routes
    echo "export const ssr = false; export const prerender = true;" > src/routes/+layout.js

    echo "🏗️  Building..."
    npm run build
    cp -r build/* .
    LOCAL_URL="http://localhost:8090/$APP_NAME/"
fi

echo -e "${GREEN}✅ App Deployed Locally!${NC}"

# 4. CLOUDFLARE AUTOMATION
echo "------------------------------------------------"
read -p "🌐 Do you have a domain for this? (y/n): " HAS_DOMAIN

if [[ "$HAS_DOMAIN" == "y" ]]; then
    read -p "🌍 Enter Domain (e.g., hexbloop.app): " DOMAIN
    
    # SAFETY CHECK REMINDER
    echo -e "${RED}🛑 STOP! Did you add '$DOMAIN' to the Cloudflare Dashboard yet?${NC}"
    read -p "Type 'yes' to confirm: " CONFIRM
    if [[ "$CONFIRM" != "yes" ]]; then echo "👋 Go do that first, then run 'cloudflared tunnel route dns $TUNNEL_NAME $DOMAIN'"; exit 0; fi
    
    echo "🤖 Configuring Cloudflare..."
    
    # Edit Config using sudo because it's in /etc/ now
    if sudo grep -q "$DOMAIN" "$CF_CONFIG"; then
        echo "⚠️  Domain already in config."
    else
        # Use sudo sed
        sudo sed -i "/# -- INSERT NEW APPS HERE --/i \\  - hostname: $DOMAIN\\n    service: $LOCAL_URL\\n" "$CF_CONFIG"
    fi
    
    echo "📡 Routing DNS..."
    cloudflared tunnel route dns $TUNNEL_NAME $DOMAIN
    
    echo "🔄 Restarting Tunnel..."
    sudo systemctl restart cloudflared

    echo -e "${GREEN}🎉 DONE! Go to https://$DOMAIN${NC}"
else
    echo "👋 Local access only."
fi
