#!/bin/bash
# 🦾 PIBULUS OS - ONBOARDING
# The first handshake.

# Safety: bail if not interactive (prevents USER_NAME corruption)
if [ ! -t 0 ]; then
    exit 0
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ENV_FILE="$SCRIPT_DIR/.env"

# Ensure .env exists
[ ! -f "$ENV_FILE" ] && cp "$SCRIPT_DIR/.env.example" "$ENV_FILE"

# Source current config
source "$ENV_FILE"

# If USER_NAME is already set and not "pibulus" (default), we're good.
if [[ ! -z "$USER_NAME" && "$USER_NAME" != "pibulus" ]]; then
    exit 0
fi

clear
figlet -f slant "WELCOME" | lolcat
echo "This deck needs a name for the manifest." | lolcat
echo ""

NEW_NAME=$(gum input --placeholder "What should I call you? (e.g., Captain, Pablo, Ace)...")

if [ ! -z "$NEW_NAME" ]; then
    # Update or append USER_NAME to .env
    if grep -q "USER_NAME=" "$ENV_FILE"; then
        sed -i "s/USER_NAME=.*/USER_NAME="$NEW_NAME"/" "$ENV_FILE"
    else
        echo "USER_NAME="$NEW_NAME"" >> "$ENV_FILE"
    fi
    clear
    echo "Acknowledged, $NEW_NAME. Mainframe is yours." | lolcat
    sleep 2
fi
