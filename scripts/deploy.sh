#!/bin/bash
# 🚀 PIBULUS DEPLOY WIZARD v5.0 - Stylish Edition
# "The Cyberdeck App Launcher"

WEB_ROOT="/media/pibulus/passport/www/html"
CF_CONFIG="/etc/cloudflared/config.yml"

# Ensure directories exist
mkdir -p "$WEB_ROOT"

clear
figlet -f slant "DEPLOYER" | lolcat
echo -e "Welcome to the Cyberdeck Deployment Wizard." | lolcat

# 1. GET INPUT
REPO_URL=$(gum input --placeholder "🔗 Paste GitHub URL...")
[ -z "$REPO_URL" ] && { gum style --foreground 196 "Error: URL required."; exit 1; }

DEFAULT_NAME=$(basename "$REPO_URL" .git)
APP_NAME=$(gum input --placeholder "📦 Name this app (default: $DEFAULT_NAME)..." --value "$DEFAULT_NAME")
APP_NAME=${APP_NAME:-$DEFAULT_NAME}

# 2. CLONE
TEMP_DIR="/tmp/$APP_NAME-deploy"
rm -rf "$TEMP_DIR"
gum spin --spinner dot --title "Cloning repository..." -- git clone "$REPO_URL" "$TEMP_DIR"

if [ ! -d "$TEMP_DIR" ]; then
    gum style --foreground 196 "❌ Clone failed."
    exit 1
fi

cd "$TEMP_DIR" || exit

# 3. TYPE DETECTION
gum style --foreground 212 "🔍 Detecting project type..."
TYPE="Static"
if [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
    TYPE="Deno"
elif [ -f "package.json" ]; then
    TYPE="Node/Svelte"
elif [ -f "index.html" ]; then
    TYPE="Static HTML"
fi

gum style --border normal --padding "1 2" --border-foreground 57 "Detected Type: $TYPE"

# 4. DEPLOYMENT LOGIC
case $TYPE in
    "Static HTML"|"Static")
        gum spin --spinner bouncer --title "Deploying Static Site..." -- mkdir -p "$WEB_ROOT/$APP_NAME" && cp -r . "$WEB_ROOT/$APP_NAME"
        LOCAL_URL="http://web_host:80/$APP_NAME"
        ;;
    "Node/Svelte")
        gum style --foreground 220 "⚠️ Node/Svelte detected. Building static output..."
        if gum confirm "Run 'npm install && npm run build'?"; then
            gum spin --spinner pulse --title "Building..." -- npm install && npm run build
            # Assuming SvelteKit/Vite standard 'build' or 'dist'
            BUILD_DIR="build"
            [ -d "dist" ] && BUILD_DIR="dist"
            gum spin --spinner bouncer --title "Copying build to web root..." -- cp -r "$BUILD_DIR"/* "$WEB_ROOT/$APP_NAME"
            LOCAL_URL="http://web_host:80/$APP_NAME"
        else
            gum style --foreground 196 "Aborted." ; exit 1
        fi
        ;;
    *)
        gum style --foreground 196 "Unsupported type for auto-deploy. Manual intervention needed."
        exit 1
        ;;
esac

# 5. CLOUDFLARE AUTOMATION
DOMAIN=$(gum input --placeholder "🌐 Enter Domain (e.g., $APP_NAME.quickcat.club)...")

if [ ! -z "$DOMAIN" ]; then
    # Check for Marker
    if ! grep -q "# -- INSERT NEW APPS HERE --" "$CF_CONFIG"; then
        gum style --foreground 208 "⚠️ Marker missing in config.yml! Adding..."
        sudo sed -i '/service: http_status:404/i # -- INSERT NEW APPS HERE --
' "$CF_CONFIG"
    fi

    # Inject new hostname
    if sudo grep -q "$DOMAIN" "$CF_CONFIG"; then
        gum style --foreground 220 "ℹ️ Domain already exists in tunnel config."
    else
        sudo sed -i "/# -- INSERT NEW APPS HERE --/a \  - hostname: $DOMAIN
    service: $LOCAL_URL" "$CF_CONFIG"
        gum style --foreground 46 "✅ Added $DOMAIN to Tunnel Config."
    fi

    gum spin --spinner moon --title "Restarting Tunnel..." -- sudo systemctl restart cloudflared
    gum style --foreground 46 "🚀 DEPLOYED! Visit: https://$DOMAIN"
fi

# Cleanup
rm -rf "$TEMP_DIR"
