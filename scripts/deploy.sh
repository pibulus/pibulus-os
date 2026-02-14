#!/bin/bash
# 🚀 PIBULUS DEPLOY WIZARD v5.3 - "The DNS Whisperer"

# --- SOURCE CONFIG ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
[ -f "$PARENT_DIR/.env" ] && source "$PARENT_DIR/.env" || { echo "❌ No .env"; exit 1; }

# Tunnel Info from config
TUNNEL_ID="c79eb8a2-9791-4ece-8b54-bc9d0e6d01cd"
CNAME_TARGET="$TUNNEL_ID.cfargotunnel.com"

mkdir -p "$WEB_ROOT"

clear
figlet -f slant "DEPLOYER" | lolcat
echo -e "Another brick in the digital wall. Let's go." | lolcat

# 1. GET INPUT
REPO_URL=$(gum input --placeholder "🔗 Paste GitHub URL...")
[ -z "$REPO_URL" ] && { exit 1; }

DEFAULT_NAME=$(basename "$REPO_URL" .git)
APP_NAME=$(gum input --placeholder "📦 Name this app (default: $DEFAULT_NAME)..." --value "$DEFAULT_NAME")
APP_NAME=${APP_NAME:-$DEFAULT_NAME}

# 2. CLONE
TEMP_DIR="/tmp/$APP_NAME-deploy"
rm -rf "$TEMP_DIR"
gum spin --spinner dot --title "Pulling source..." -- git clone "$REPO_URL" "$TEMP_DIR"
[ ! -d "$TEMP_DIR" ] && { gum style --foreground 196 "❌ Clone failed."; exit 1; }
cd "$TEMP_DIR" || exit

# 3. TYPE DETECTION
gum style --foreground 212 "🔍 Sniffing type..."
TYPE="Static"
[ -f "package.json" ] && TYPE="Node/Svelte"
[ -f "index.html" ] && TYPE="Static HTML"

# 4. DEPLOYMENT
case $TYPE in
    "Static HTML"|"Static")
        mkdir -p "$WEB_ROOT/$APP_NAME" && cp -r . "$WEB_ROOT/$APP_NAME"
        LOCAL_URL="http://web_host:80/$APP_NAME"
        ;;
    "Node/Svelte")
        if gum confirm "Svelte detected. Run build?"; then
            gum spin --spinner pulse --title "Building..." -- npm install && npm run build
            BUILD_DIR="build"
            [ -d "dist" ] && BUILD_DIR="dist"
            cp -r "$BUILD_DIR"/* "$WEB_ROOT/$APP_NAME"
            LOCAL_URL="http://web_host:80/$APP_NAME"
        else
            exit 1
        fi
        ;;
esac

# 5. CLOUDFLARE
DOMAIN=$(gum input --placeholder "🌐 Enter Domain (e.g., $APP_NAME.quickcat.club)...")

if [ ! -z "$DOMAIN" ]; then
    # Stitch into config
    if ! sudo grep -q "$DOMAIN" "$CF_CONFIG"; then
        sudo sed -i "/# -- INSERT NEW APPS HERE --/a \  - hostname: $DOMAIN
    service: $LOCAL_URL" "$CF_CONFIG"
        gum spin --spinner moon --title "Restarting Tunnel..." -- sudo systemctl restart cloudflared
    fi

    # THE FINAL SUCCESS HUD
    clear
    figlet -f slant "SUCCESS" | lolcat
    gum style --border double --margin "1 2" --padding "1 2" --border-foreground 46 
    "$(gum style --foreground 46 "🚀 APP DEPLOYED LOCALLY!")

$(gum style --foreground 226 "DNS ACTION REQUIRED (Porkbun):")
1. Log into Porkbun.com
2. Go to DNS for '$(echo $DOMAIN | cut -d. -f2-)'
3. Add a $(gum style --foreground 212 "CNAME") record:
   - Host: $(echo $DOMAIN | cut -d. -f1)
   - Answer: $(gum style --foreground 212 "$CNAME_TARGET")

$(gum style --foreground 46 "URL:") https://$DOMAIN"
fi

rm -rf "$TEMP_DIR"
gum input --placeholder "Press Enter to return to the deck..."
