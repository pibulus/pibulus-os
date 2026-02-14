#!/bin/bash
# 🚀 PIBULUS DEPLOY WIZARD v5.2 - Sovereign Edition

# --- SOURCE CONFIG ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
if [ -f "$PARENT_DIR/.env" ]; then
    source "$PARENT_DIR/.env"
else
    # Fallbacks if called standalone
    WEB_ROOT="${WEB_ROOT:-/media/pibulus/passport/www/html}"
    CF_CONFIG="${CF_CONFIG:-/etc/cloudflared/config.yml}"
fi

mkdir -p "$WEB_ROOT"

clear
figlet -f slant "DEPLOYER" | lolcat
echo -e "Digital sovereignty starts here. Let's build something." | lolcat

# 1. GET INPUT
REPO_URL=$(gum input --placeholder "🔗 Paste GitHub URL...")
[ -z "$REPO_URL" ] && { gum style --foreground 196 "Error: URL required."; exit 1; }

DEFAULT_NAME=$(basename "$REPO_URL" .git)
APP_NAME=$(gum input --placeholder "📦 Name this app (default: $DEFAULT_NAME)..." --value "$DEFAULT_NAME")
APP_NAME=${APP_NAME:-$DEFAULT_NAME}

# 2. CLONE
TEMP_DIR="/tmp/$APP_NAME-deploy"
rm -rf "$TEMP_DIR"
gum spin --spinner dot --title "Pulling source from the ether..." -- git clone "$REPO_URL" "$TEMP_DIR"

if [ ! -d "$TEMP_DIR" ]; then
    gum style --foreground 196 "❌ Clone failed. Check the URL."
    exit 1
fi

cd "$TEMP_DIR" || exit

# 3. TYPE DETECTION
gum style --foreground 212 "🔍 Sniffing out the project type..."
TYPE="Static"
if [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
    TYPE="Deno"
elif [ -f "package.json" ]; then
    TYPE="Node/Svelte"
elif [ -f "index.html" ]; then
    TYPE="Static HTML"
fi

gum style --border normal --padding "1 2" --border-foreground 57 "Detected: $TYPE"

# 4. DEPLOYMENT LOGIC
case $TYPE in
    "Static HTML"|"Static")
        gum spin --spinner bouncer --title "Shipping static assets..." -- mkdir -p "$WEB_ROOT/$APP_NAME" && cp -r . "$WEB_ROOT/$APP_NAME"
        LOCAL_URL="http://web_host:80/$APP_NAME"
        ;;
    "Node/Svelte")
        gum style --foreground 220 "⚠️ Node/Svelte detected. Building for production..."
        if gum confirm "Run the build pipeline?"; then
            gum spin --spinner pulse --title "Grinding gears (npm build)..." -- npm install && npm run build
            BUILD_DIR="build"
            [ -d "dist" ] && BUILD_DIR="dist"
            gum spin --spinner bouncer --title "Injecting build into web root..." -- cp -r "$BUILD_DIR"/* "$WEB_ROOT/$APP_NAME"
            LOCAL_URL="http://web_host:80/$APP_NAME"
        else
            gum style --foreground 196 "Deployment aborted by user." ; exit 1
        fi
        ;;
    *)
        gum style --foreground 196 "Manual intervention required for this project type."
        exit 1
        ;;
esac

# 5. CLOUDFLARE AUTOMATION
DOMAIN=$(gum input --placeholder "🌐 Domain name (e.g., $APP_NAME.quickcat.club)...")

if [ ! -z "$DOMAIN" ]; then
    # Inject new hostname
    if sudo grep -q "$DOMAIN" "$CF_CONFIG"; then
        gum style --foreground 220 "ℹ️ Domain already exists. Skipping config update."
    else
        sudo sed -i "/# -- INSERT NEW APPS HERE --/a \  - hostname: $DOMAIN
    service: $LOCAL_URL" "$CF_CONFIG"
        gum style --foreground 46 "✅ $DOMAIN wired into the tunnel."
    fi

    gum spin --spinner moon --title "Restarting the tunnel..." -- sudo systemctl restart cloudflared
    gum style --foreground 46 "🚀 LIVE! Visit: https://$DOMAIN"
fi

# Cleanup
rm -rf "$TEMP_DIR"
gum input --placeholder "Press Enter to return to the deck..."
