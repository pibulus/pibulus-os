#!/bin/bash
# 🚀 PIBULUS DEPLOY WIZARD v7.0 — "The Sovereign Shipper"
# Now with Fresh/Deno support + Porkbun DNS automation

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
[ -f "$PARENT_DIR/.env" ] && source "$PARENT_DIR/.env" || { echo "❌ No .env"; exit 1; }

CF_CONFIG="${CF_CONFIG:-/etc/cloudflared/config.yml}"
CNAME_TARGET="${TUNNEL_ID:-c79eb8a2-9791-4ece-8b54-bc9d0e6d01cd}.cfargotunnel.com"
NGINX_CONF="$PARENT_DIR/config/nginx/hardening.conf"
DENO="$HOME/.deno/bin/deno"

mkdir -p "$WEB_ROOT"

clear
figlet -f slant "DEPLOYER" 2>/dev/null | lolcat 2>/dev/null || echo "=== DEPLOYER v7.0 ==="
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
        gum spin --spinner dot --title "Cloning..." -- git clone --depth 1 "$REPO_URL" "$TEMP_DIR"
        [ ! -d "$TEMP_DIR" ] && { gum style --foreground 196 "❌ Clone failed."; exit 1; }
        DEPLOY_SOURCE="$TEMP_DIR"
        ;;
    "📁 Deploy local folder")
        DEPLOY_SOURCE=$(gum input --placeholder "Path to folder")
        [ ! -d "$DEPLOY_SOURCE" ] && { gum style --foreground 196 "❌ Folder not found."; exit 1; }
        APP_NAME=$(gum input --placeholder "Name this app" --value "$(basename "$DEPLOY_SOURCE")")
        ;;
    "📝 Create blank site")
        APP_NAME=$(gum input --placeholder "Name your new site")
        [ -z "$APP_NAME" ] && exit 1
        DEPLOY_SOURCE="/tmp/$APP_NAME-blank"
        mkdir -p "$DEPLOY_SOURCE"
        cat > "$DEPLOY_SOURCE/index.html" << BLANK
<!DOCTYPE html><html><head><title>Coming Soon</title>
<style>body{font-family:system-ui;background:#0D0F14;color:#e0e0e0;display:flex;justify-content:center;align-items:center;min-height:100vh;margin:0}
.box{background:#16213e;padding:3rem;border-radius:12px;border:2px solid #E040FB;text-align:center;max-width:600px}h1{color:#E040FB;margin-top:0}</style>
</head><body><div class="box"><h1>🐾 Coming Soon</h1><p>Built on PIBULUS.</p></div></body></html>
BLANK
        ;;
esac

# ── 2. TYPE DETECTION & BUILD ──
cd "$DEPLOY_SOURCE" || exit 1
gum style --foreground 212 "🔍 Detecting project type..."

TYPE="Static"
LOCAL_PORT="80"
LOCAL_PATH="/$APP_NAME"
PROXY_PORT=""

if [ -f "deno.json" ] && grep -q "fresh" deno.json 2>/dev/null; then
    TYPE="Fresh/Deno"
    if [ ! -x "$DENO" ]; then
        gum style --foreground 196 "❌ Deno not installed. Run: curl -fsSL https://deno.land/install.sh | sh"
        exit 1
    fi
    gum spin --spinner pulse --title "Installing Fresh deps..." -- $DENO install 2>/dev/null
    gum spin --spinner pulse --title "Building Fresh app..." -- $DENO task build 2>/dev/null

    if [ ! -d "_fresh" ]; then
        gum style --foreground 196 "❌ Fresh build failed."
        exit 1
    fi

    # Deploy as Deno server
    mkdir -p "$HOME/apps/$APP_NAME"
    cp -r _fresh "$HOME/apps/$APP_NAME/"
    [ -d "static" ] && cp -r static "$HOME/apps/$APP_NAME/"
    cp deno.json "$HOME/apps/$APP_NAME/"

    # Find free port
    for p in $(seq 9001 9050); do
        if ! ss -tlnp 2>/dev/null | grep -q ":$p "; then
            PROXY_PORT=$p
            break
        fi
    done

    # Create systemd service
    cat > /tmp/$APP_NAME.service << UNIT
[Unit]
Description=$APP_NAME Fresh App
After=network.target
[Service]
Type=simple
User=$SYSTEM_USER
WorkingDirectory=$HOME/apps/$APP_NAME
ExecStart=$DENO serve -A --port=$PROXY_PORT _fresh/server.js
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
UNIT
    sudo mv /tmp/$APP_NAME.service /etc/systemd/system/$APP_NAME.service
    sudo systemctl daemon-reload
    sudo systemctl enable "$APP_NAME"
    gum spin --spinner moon --title "Starting $APP_NAME on port $PROXY_PORT..." -- sudo systemctl restart "$APP_NAME"

    gum style --foreground 46 "Type: $TYPE | Port: $PROXY_PORT"

elif [ -f "package.json" ]; then
    TYPE="Node"
    gum style --foreground 46 "Type: $TYPE"
    if gum confirm "Run npm build?"; then
        gum spin --spinner pulse --title "Installing deps..." -- npm install 2>/dev/null
        gum spin --spinner pulse --title "Building..." -- npm run build 2>/dev/null
        BUILD_DIR="build"
        [ -d "dist" ] && BUILD_DIR="dist"
        [ -d "public" ] && [ ! -d "build" ] && [ ! -d "dist" ] && BUILD_DIR="public"
        mkdir -p "$WEB_ROOT/$APP_NAME"
        cp -r "$BUILD_DIR"/* "$WEB_ROOT/$APP_NAME" 2>/dev/null || cp -r . "$WEB_ROOT/$APP_NAME"
    else
        exit 1
    fi

elif [ -f "index.html" ]; then
    TYPE="Static HTML"
    gum style --foreground 46 "Type: $TYPE"
    mkdir -p "$WEB_ROOT/$APP_NAME"
    cp -r . "$WEB_ROOT/$APP_NAME"
else
    TYPE="Static"
    gum style --foreground 46 "Type: $TYPE (generic)"
    mkdir -p "$WEB_ROOT/$APP_NAME"
    cp -r . "$WEB_ROOT/$APP_NAME"
fi

# ── 3. NGINX CONFIG ──
if [ -n "$PROXY_PORT" ] || [ "$TYPE" != "Fresh/Deno" ]; then
    # Will be configured in domain step if domain is given
    :
fi

# ── 4. DOMAIN SETUP ──
echo ""
DOMAIN=$(gum input --placeholder "Domain (e.g., $APP_NAME.quickcat.club, or leave empty)")

if [ -n "$DOMAIN" ]; then
    # NGINX server block
    if ! grep -q "server_name $DOMAIN" "$NGINX_CONF" 2>/dev/null; then
        gum style --foreground 212 "Adding nginx server block for $DOMAIN..."

        if [ -n "$PROXY_PORT" ]; then
            # Fresh/Deno — reverse proxy
            cat >> "$NGINX_CONF" << NGINX

# --- $APP_NAME ($DOMAIN) ---
server {
    listen 80;
    server_name $DOMAIN;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    location / {
        proxy_pass http://172.17.0.1:$PROXY_PORT;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
NGINX
        else
            # Static — serve from web root
            cat >> "$NGINX_CONF" << NGINX

# --- $APP_NAME ($DOMAIN) ---
server {
    listen 80;
    server_name $DOMAIN;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    root /usr/share/nginx/html/$APP_NAME;
    index index.html;
    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
NGINX
        fi
        sudo docker exec web_host nginx -s reload 2>/dev/null || sudo docker restart web_host
    else
        gum style --foreground 226 "nginx block already exists."
    fi

    # CLOUDFLARE TUNNEL
    if ! sudo grep -q "$DOMAIN" "$CF_CONFIG" 2>/dev/null; then
        gum style --foreground 212 "Adding $DOMAIN to Cloudflare tunnel..."
        sudo python3 -c "
with open(, r) as f:
    lines = f.readlines()
for i, line in enumerate(lines):
    if http_status:404 in line:
        while i > 0 and - service: not in lines[i]:
            i -= 1
        new = [ - hostname: n,  service: http://localhost:80n, n]
        lines = lines[:i] + new + lines[i:]
        break
with open(, w) as f:
    f.writelines(lines)
print(OK)
" 2>/dev/null
        gum spin --spinner moon --title "Restarting tunnel..." -- sudo systemctl restart cloudflared
    else
        gum style --foreground 226 "Domain already in tunnel config."
    fi

    # PORKBUN DNS
    if [ -f "$HOME/.secrets/porkbun_keys" ]; then
        source "$HOME/.secrets/porkbun_keys"
    fi

    if [ -n "$PORKBUN_API_KEY" ] && [ -n "$PORKBUN_SECRET_KEY" ]; then
        PARTS=$(echo "$DOMAIN" | awk -F. '{print NF}')
        if [ "$PARTS" -gt 2 ]; then
            ROOT_DOMAIN=$(echo "$DOMAIN" | awk -F. '{print $(NF-1)"." $NF}')
            SUBDOMAIN=$(echo "$DOMAIN" | sed "s/\.$ROOT_DOMAIN$//")
        else
            ROOT_DOMAIN="$DOMAIN"
            SUBDOMAIN=""
        fi

        gum style --foreground 212 "Setting DNS: $DOMAIN → tunnel..."
        DNS_RESULT=$(curl -s -X POST "https://api.porkbun.com/api/json/v3/dns/create/$ROOT_DOMAIN" \
            -H "Content-Type: application/json" \
            -d "{
                \"apikey\":\"$PORKBUN_API_KEY\",
                \"secretapikey\":\"$PORKBUN_SECRET_KEY\",
                \"type\":\"CNAME\",
                \"name\":\"$SUBDOMAIN\",
                \"content\":\"$CNAME_TARGET\",
                \"ttl\":600
            }")

        if echo "$DNS_RESULT" | grep -q "SUCCESS"; then
            gum style --foreground 46 "✅ DNS set: $DOMAIN → tunnel"
        else
            gum style --foreground 226 "⚠️  DNS auto-set failed. Set manually:"
            gum style --foreground 245 "CNAME $DOMAIN → $CNAME_TARGET"
        fi
    else
        gum style --foreground 245 "No Porkbun keys found at ~/.secrets/porkbun_keys"
        gum style --foreground 245 "Set CNAME manually: $DOMAIN → $CNAME_TARGET"
        gum style --foreground 245 "Or create ~/.secrets/porkbun_keys with PORKBUN_API_KEY and PORKBUN_SECRET_KEY"
    fi

    # RESULT
    echo ""
    gum style --border double --margin "1 2" --padding "1 2" --border-foreground 46 \
        "$(printf %sn \
            "🚀 APP DEPLOYED: $APP_NAME" \
            "" \
            "Type: $TYPE" \
            "Public: https://$DOMAIN" \
            $([ -n "$PROXY_PORT" ] && echo "Port: $PROXY_PORT") \
            $([ -n "$PROXY_PORT" ] && echo "Service: systemctl status $APP_NAME") \
            "" \
            "DNS may take a few minutes to propagate.")"
else
    gum style --border rounded --margin "1 2" --padding "1 2" --border-foreground 46 \
        "$(printf %sn \
            "🚀 APP DEPLOYED (local only)" \
            "" \
            "URL: http://pibulus.local${LOCAL_PATH}")"
fi

# Cleanup
[ -n "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
echo ""
gum input --placeholder "Press Enter to return..."
