#!/bin/bash
# 🐾 QUICK CAT CLUB - CYBERDECK v6.7
# The Final Polish.

# --- TERMINAL SAFETY ---
case "$TERM" in
    xterm-ghostty|xterm-kitty) export TERM=xterm-256color ;;
esac

# --- SOURCE CONFIG ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
[ -f "$SCRIPT_DIR/.env" ] && source "$SCRIPT_DIR/.env" || { echo "❌ No .env"; exit 1; }

# --- LOAD MODULES ---
source "$SCRIPT_DIR/modules/audio_feedback.sh"
source "$SCRIPT_DIR/modules/media_puller.sh"
source "$SCRIPT_DIR/modules/terminal_travels.sh"
source "$SCRIPT_DIR/modules/backup_module.sh"
source "$SCRIPT_DIR/modules/audit_module.sh"
source "$SCRIPT_DIR/modules/knowledge_vault_module.sh"
source "$SCRIPT_DIR/modules/radio_module.sh"
source "$SCRIPT_DIR/modules/eject_module.sh"
source "$SCRIPT_DIR/modules/bunker_module.sh"
source "$SCRIPT_DIR/modules/vault_module.sh"
source "$SCRIPT_DIR/modules/sigint_module.sh"
source "$SCRIPT_DIR/modules/games_module.sh"
source "$SCRIPT_DIR/modules/grey_hat_module.sh"
source "$SCRIPT_DIR/modules/mission_control_module.sh"

# --- UTILS ---
get_status() {
    if [ "$(docker ps -q -f name=$1)" ]; then
        echo "🟢"
    else
        echo "🔴"
    fi
}

render_hud() {
    clear
    local TEMP=$(vcgencmd measure_temp | cut -d'=' -f2)
    local DISK=$(df -h "$PASSPORT_ROOT" | awk 'NR==2 {print $5}')
    local VPN=$(get_status gluetun)
    [ "$VPN" == "🟢" ] && VPN="🔒 VPN" || VPN="🔓 CLR"
    local PWR_HEX=$(vcgencmd get_throttled | cut -d'=' -f2)
    [ "$PWR_HEX" == "0x0" ] && PWR="⚡ OK" || PWR="⚠️ VOLT"
    local LOAD=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d',' -f1)
    
    gum style --border double --border-foreground 212 --padding "0 2" --margin "1 0" --align center \
        "🐾 $USER_NAME  |  🌡️ $TEMP  |  📼 $DISK  |  $PWR  |  $VPN  |  🧵 LOAD: $LOAD"
}

tactile_choose() {
    local choice=$(gum choose "$@")
    [ \! -z "$choice" ] && play_tone "click"
    echo "$choice"
}

# --- THE MAIN LOOP ---
play_tone "startup"

while true; do
    render_hud
    local choice=$(tactile_choose \
        "🚀 Deploy New App" \
        "📥 Media Scavenger" \
        "📚 Vault Navigator" \
        "🧠 Knowledge Vault $(tmux has-session -t knowledge-vault 2>/dev/null && echo "🟢" || echo "🔴")" \
        "🤝 Community Ops" \
        "🕹️ Terminal Arcade" \
        "🏴‍☠️ Pirate Station $(get_status jellyfin)" \
        "📻 KPAB.fm Radio $(get_status azuracast_web)" \
        "📝 Quick Memos $(get_status memos)" \
        "💀 Grey Hat Ops" \
        "📡 SIGINT Ops" \
        "📀 Vault Ops" \
        "🏠 Dashboard Ops" \
        "🕵️ Stealth Toggle" \
        "🔒 Lock Bunker" \
        "⏏️ Safe Eject" \
        "📊 System Status" \
        "🚪 Exit")

    case $choice in
        "🚀 Deploy New App") play_tone "confirm"; "$SCRIPT_DIR/scripts/deploy.sh" ;;
        "📥 Media Scavenger") pull_media ;;
        "📚 Vault Navigator") manage_knowledge_vault ;;
        "🧠 Knowledge Vault"*) bash "$SCRIPT_DIR/modules/knowledge_vault_module.sh" ;;
        "🤝 Community Ops") manage_community ;;
        "🕹️ Terminal Arcade") manage_games ;;
        "🏴‍☠️ Pirate Station"*) manage_stack "PIRATE STATION" "$PIRATE_CONFIG" "jellyfin" ;;
        "📻 KPAB.fm Radio"*) manage_radio ;;
        "📝 Quick Memos"*) echo "Memos at http://pibulus.local:5230"; gum input --placeholder "Press Enter to return..." ;;
        "🤖 Mission Control") manage_mission_control ;;
        "🤖 Mission Control" "💀 Grey Hat Ops") manage_grey_hat ;;
        "📡 SIGINT Ops") manage_sigint ;;
        "📀 Vault Ops") manage_vault ;;
        "🏠 Dashboard Ops") manage_homepage ;;
        "🕵️ Stealth Toggle") "$SCRIPT_DIR/scripts/set_stealth.sh" public ;;
        "🔒 Lock Bunker") "$SCRIPT_DIR/scripts/set_stealth.sh" bunker ;;
        "⏏️ Safe Eject") safe_eject ;;
        "📊 System Status") pm2 list && gum input --placeholder "Press Enter to return..." ;;
        "🚪 Exit") play_tone "click"; clear; exit 0 ;;
    esac
done
