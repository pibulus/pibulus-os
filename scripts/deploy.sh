#!/bin/bash
# 🚀 PIBULUS DEPLOY WIZARD v6.0 — "The DNS Whisperer"
# Clones, builds, deploys, wires Cloudflare + DNS in one shot.

# --- SOURCE CONFIG ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
[ -f "$PARENT_DIR/.env" ] && source "$PARENT_DIR/.env" || { echo "❌ No .env"; exit 1; }

CF_CONFIG="${CF_CONFIG:-/etc/cloudflared/config.yml}"
CNAME_TARGET="${TUNNEL_ID:-c79eb8a2-9791-4ece-8b54-bc9d0e6d01cd}.cfargotunnel.com"

mkdir -p "$WEB_ROOT"

clear
figlet -f slant "DEPLOYER" | lolcat
echo ""
gum style --foreground 245 "Digital sovereignty starts here."
echo ""

# ── 1. CHOOSE SOURCE ──
SOURCE_TYPE=$(gum choose \
    "📦 Clone from GitHub URL" \
    "📁 Deploy local folder" \
    "📝 Create blank site")

case "$SOURCE_TYPE" in
    "📦 Clone from GitHub URL")
        REPO_URL=$(gum input --placeholder "🔗 Paste GitHub URL...")
        [ -z "$REPO_URL" ] && exit 1

        DEFAULT_NAME=$(basename "$REPO_URL" .git)
        APP_NAME=$(gum input --placeholder "Name this app" --value "$DEFAULT_NAME")
        APP_NAME=${APP_NAME:-$DEFAULT_NAME}

        TEMP_DIR="/tmp/$APP_NAME-deploy"
        rm -rf "$TEMP_DIR"
        gum spin --spinner dot --title "Cloning..." -- git clone "$REPO_URL" "$TEMP_DIR"
        [ ! -d "$TEMP_DIR" ] && { gum style --foreground 196 "❌ Clone failed."; exit 1; }
        DEPLOY_SOURCE="$TEMP_DIR"
        ;;

    "📁 Deploy local folder")
        DEPLOY_SOURCE=$(gum input --placeholder "Path to folder (e.g., /tmp/my-site)")
        [ ! -d "$DEPLOY_SOURCE" ] && { gum style --foreground 196 "❌ Folder not found."; exit 1; }
        APP_NAME=$(gum input --placeholder "Name this app" --value "$(basename "$DEPLOY_SOURCE")")
        ;;

    "📝 Create blank site")
        APP_NAME=$(gum input --placeholder "Name your new site")
        [ -z "$APP_NAME" ] && exit 1
        DEPLOY_SOURCE="/tmp/$APP_NAME-blank"
        mkdir -p "$DEPLOY_SOURCE"
        cat > "$DEPLOY_SOURCE/index.html" << 'BLANK'
<!DOCTYPE html>
<html>
<head><title>New Site</title><style>
body{font-family:system-ui;background:#1a1a2e;color:#e0e0e0;display:flex;justify-content:center;align-items:center;min-height:100vh;margin:0}
.box{background:#16213e;padding:3rem;border-radius:12px;border:2px solid #e94560;text-align:center;max-width:600px}
h1{color:#e94560;margin-top:0}
</style></head>
<body><div class="box"><h1>🐾 Coming Soon</h1><p>This site is being built on PIBULUS.</p></div></body>
</html>
BLANK
        ;;
esac

# ── 2. TYPE DETECTION & BUILD ──
cd "$DEPLOY_SOURCE" || exit 1
gum style --foreground 212 "🔍 Detecting project type..."

TYPE="Static"
[ -f "package.json" ] && TYPE="Node"
[ -f "index.html" ] && TYPE="Static HTML"
[ -f "requirements.txt" ] && TYPE="Python"

gum style --foreground 46 "Type: $TYPE"

case $TYPE in
    "Static HTML"|"Static")
        mkdir -p "$WEB_ROOT/$APP_NAME"
        cp -r . "$WEB_ROOT/$APP_NAME"
        LOCAL_PORT="80"
        LOCAL_PATH="/$APP_NAME"
        ;;
    "Node")
        if gum confirm "Run npm build?"; then
            gum spin --spinner pulse --title "Installing deps..." -- npm install 2>/dev/null
            gum spin --spinner pulse --title "Building..." -- npm run build 2>/dev/null
            BUILD_DIR="build"
            [ -d "dist" ] && BUILD_DIR="dist"
            [ -d "public" ] && [ ! -d "build" ] && [ ! -d "dist" ] && BUILD_DIR="public"
            mkdir -p "$WEB_ROOT/$APP_NAME"
            cp -r "$BUILD_DIR"/* "$WEB_ROOT/$APP_NAME" 2>/dev/null || cp -r . "$WEB_ROOT/$APP_NAME"
            LOCAL_PORT="80"
            LOCAL_PATH="/$APP_NAME"
        else
            exit 1
        fi
        ;;
    "Python")
        gum style --foreground 226 "Python app detected. You'll need to set up a systemd service manually."
        gum style --foreground 245 "See: dropzone.service, wall.service, msgdrop.service for examples."
        LOCAL_PORT=$(gum input --placeholder "What port will it run on?")
        LOCAL_PATH=""
        ;;
esac

# ── 3. DOMAIN SETUP ──
echo ""
DOMAIN=$(gum input --placeholder "Domain (e.g., $APP_NAME.quickcat.club, or leave empty to skip)")

if [ -n "$DOMAIN" ]; then
    # Add to Cloudflare tunnel config
    if ! sudo grep -q "$DOMAIN" "$CF_CONFIG" 2>/dev/null; then
        gum style --foreground 212 "Adding $DOMAIN to Cloudflare tunnel..."

        # Build the service URL
        if [ -n "$LOCAL_PATH" ]; then
            SERVICE_URL="http://localhost:$LOCAL_PORT"
        else
            SERVICE_URL="http://localhost:$LOCAL_PORT"
        fi

        # Insert before the catch-all 404 rule (last line of ingress)
        sudo python3 -c "
import sys
config_path = '$CF_CONFIG'
with open(config_path, 'r') as f:
    lines = f.readlines()

# Find the catch-all line (service: http_status:404)
insert_idx = None
for i, line in enumerate(lines):
    if 'http_status:404' in line:
        insert_idx = i
        break

if insert_idx is not None:
    new_lines = [
        '  - hostname: $DOMAIN\n',
        '    service: $SERVICE_URL\n',
        '\n',
    ]
    lines = lines[:insert_idx] + new_lines + lines[insert_idx:]
    with open(config_path, 'w') as f:
        f.writelines(lines)
    print('OK')
else:
    print('WARN: Could not find catch-all rule. Add manually.')
" 2>/dev/null

        # Restart tunnel
        gum spin --spinner moon --title "Restarting Cloudflare tunnel..." -- \
            sudo systemctl restart cloudflared
        play_tone "confirm" 2>/dev/null
    else
        gum style --foreground 226 "Domain already in tunnel config."
    fi

    # Show DNS instructions
    echo ""
    local subdomain=$(echo "$DOMAIN" | cut -d. -f1)
    local root_domain=$(echo "$DOMAIN" | cut -d. -f2-)

    gum style --border double --margin "1 2" --padding "1 2" --border-foreground 46 \
        "$(printf '%s\n' \
            "🚀 APP DEPLOYED" \
            "" \
            "Local: http://localhost:${LOCAL_PORT}${LOCAL_PATH}" \
            "Public: https://$DOMAIN" \
            "" \
            "📡 DNS ACTION (Porkbun $root_domain):" \
            "Add CNAME record:" \
            "  Host: $subdomain" \
            "  Answer: $CNAME_TARGET" \
            "" \
            "Or ask Claude to do it via Porkbun API.")"
else
    gum style --border rounded --margin "1 2" --padding "1 2" --border-foreground 46 \
        "$(printf '%s\n' \
            "🚀 APP DEPLOYED (local only)" \
            "" \
            "URL: http://pibulus.local:${LOCAL_PORT}${LOCAL_PATH}")"
fi

# Cleanup
[ -n "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
echo ""
gum input --placeholder "Press Enter to return..."
