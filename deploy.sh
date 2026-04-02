#!/bin/bash

# USAGE: ./deploy.sh <GITHUB_URL> <APP_NAME> [PORT]
# Example (Static): ./deploy.sh https://github.com/pibulus/ziplist ziplist
# Example (Deno):   ./deploy.sh https://github.com/pibulus/stargram stargram 8001

REPO_URL=$1
APP_NAME=$2
PORT=$3
WEB_ROOT="/media/pibulus/passport/www/html"
APPS_ROOT="/media/pibulus/passport/www/apps" # Where live servers live

if [ -z "$APP_NAME" ]; then
    echo "❌ Usage: ./deploy.sh <GITHUB_URL> <APP_NAME> [PORT_FOR_DENO]"
    exit 1
fi

echo "🚀 DETECTING APP TYPE FOR: $APP_NAME"

# Create a temp clone to check the files
TEMP_DIR="/tmp/$APP_NAME-deploy"
rm -rf $TEMP_DIR
git clone $REPO_URL $TEMP_DIR
cd $TEMP_DIR

# --- LOGIC BRANCH: IS IT DENO? ---
if [ -f "deno.json" ]; then
    echo "🦕 Deno/Fresh App Detected!"
    
    if [ -z "$PORT" ]; then
        echo "⚠️  ERROR: Deno apps require a PORT number."
        echo "👉 Usage: ./deploy.sh <URL> $APP_NAME <PORT_NUMBER>"
        echo "   (Example: 8001, 8002, etc.)"
        exit 1
    fi

    # Move to the Apps folder (not HTML folder)
    mkdir -p $APPS_ROOT
    TARGET_DIR="$APPS_ROOT/$APP_NAME"
    
    # Clean old version
    if [ -d "$TARGET_DIR" ]; then
        echo "♻️  Stopping old process..."
        pm2 delete $APP_NAME 2>/dev/null
        rm -rf $TARGET_DIR
    fi
    
    # Move files
    mv $TEMP_DIR $TARGET_DIR
    cd $TARGET_DIR
    
    echo "🦕 Starting Deno Server on Port $PORT..."
    # Start with PM2 (The magic command)
    PORT=$PORT pm2 start "deno task start" --name $APP_NAME
    
    # Save the process list so it restarts on boot
    pm2 save

    echo "✅ SUCCESS! App is running."
    echo "🌍 Local: http://pibulus.local:$PORT"
    echo "🔗 To map this to a domain, use Cloudflare Tunnel pointing to localhost:$PORT"

# --- LOGIC BRANCH: IS IT NODE/STATIC? ---
elif [ -f "package.json" ]; then
    echo "📦 Node/Static App Detected!"
    
    # Move to Web Root for Nginx
    cd $WEB_ROOT
    if [ -d "$APP_NAME" ]; then
        rm -rf $APP_NAME
    fi
    mv $TEMP_DIR $APP_NAME
    cd $APP_NAME

    echo "📦 Installing Dependencies..."
    npm install
    npm install -D @sveltejs/adapter-static

    # Inject the Svelte Config Hack
    echo "🔧 Injecting Config..."
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
    
    echo "✅ SUCCESS! Static site deployed."
    echo "🌍 Local: http://pibulus.local:8090/$APP_NAME/"

else
    echo "❌ Unknown App Type. No package.json or deno.json found."
fi
