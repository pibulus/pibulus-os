#!/bin/bash
# 🕵️ QUICK CAT CLUB - STEALTH TOGGLE
# USAGE: ./set_stealth.sh [public|bunker]

MODE=$1

if [ "$MODE" == "public" ]; then
    echo "🔓 Opening deck for password access (Travel Mode)..."
    
    # 1. SSH: Allow passwords
    sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    sudo systemctl restart ssh
    echo "   - SSH: Password auth ENABLED."

    # 2. Cloudflare: Open tunnel
    if systemctl is-active --quiet cloudflared; then
        echo "   - Cloudflare: Already running."
    else
        sudo systemctl start cloudflared
        echo "   - Cloudflare: Tunnel RESTORED."
    fi

    gum style --foreground 226 "⚠️ TRAVEL MODE ACTIVE. Password Login + Public Tunnel ENABLED."

elif [ "$MODE" == "bunker" ]; then
    echo "🔒 Closing deck to key-only access (Bunker Mode)..."
    
    # 1. SSH: Keys only
    sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
    sudo systemctl restart ssh
    echo "   - SSH: Password auth DISABLED (Keys only)."

    # 2. Cloudflare: Kill tunnel
    if systemctl is-active --quiet cloudflared; then
        sudo systemctl stop cloudflared
        echo "   - Cloudflare: Tunnel SEVERED."
    else
        echo "   - Cloudflare: Already offline."
    fi

    gum style --foreground 46 "✅ BUNKER MODE ACTIVE. Dark. Silent. Secure."

else
    echo "Usage: $0 [public|bunker]"
    echo "  public = Travel Mode (Passwords allowed, Tunnel UP)"
    echo "  bunker = Lockdown Mode (Keys only, Tunnel DOWN)"
fi
