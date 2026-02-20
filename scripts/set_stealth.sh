#!/bin/bash
# 🕵️ QUICK CAT CLUB - STEALTH TOGGLE

MODE=$1

if [ "$MODE" == "public" ]; then
    echo "🔓 Opening deck for password access (Travel Mode)..."
    sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    sudo systemctl restart ssh
    gum style --foreground 226 "⚠️ PASSWORD LOGIN ENABLED. Stay alert."
elif [ "$MODE" == "bunker" ]; then
    echo "🔒 Closing deck to key-only access (Bunker Mode)..."
    sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
    sudo systemctl restart ssh
    gum style --foreground 46 "✅ KEY-ONLY ACCESS RESTORED."
else
    echo "Usage: set_stealth.sh [public|bunker]"
fi
