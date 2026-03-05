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

# --- DEFAULTS ---
: "${PIRATE_CONFIG:=$SCRIPT_DIR/config/stacks/pirate.yml}"

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
source "$SCRIPT_DIR/modules/librarian_module.sh"

# --- HELP FLAG ---
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "help" ]]; then
    echo "🐾 PIBULUS CYBERDECK v6.7"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Usage: deck [command]"
    echo ""
    echo "  (no args)    Launch TUI menu"
    echo "  --help, -h   Show this help"
    echo "  radio        Quick-launch KPAB.fm module"
    echo "  games        Quick-launch Terminal Arcade"
    echo "  status       System status snapshot"
    echo "  deploy       Deploy a new app"
    echo "  community    Community services"
    echo ""
    echo "Aliases: help, halp, sos, wtf"
    echo "Config:  ~/pibulus-os/.env"
    echo "Modules: ~/pibulus-os/modules/"
    exit 0
fi

# --- QUICK COMMANDS ---
case "$1" in
    radio)  manage_radio; exit 0 ;;
    games)  manage_games; exit 0 ;;
    status) vcgencmd measure_temp; free -h; df -h / /media/pibulus/passport; docker ps --format "table {{.Names}}	{{.Status}}" | head -25; exit 0 ;;
    deploy) play_tone "confirm"; "$SCRIPT_DIR/scripts/deploy.sh"; exit 0 ;;
    community) manage_community; exit 0 ;;
esac
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


manage_stack() {
    local name="$1"
    local config="$2"
    local container="$3"
    
    if [ ! -f "$config" ]; then
        gum style --foreground 196 "❌ Config not found: $config"
        sleep 2
        return
    fi
    
    while true; do
        render_hud
        echo -e "$(gum style --foreground 212 "--- $name ---")"
        local status=$(get_status "$container")
        local action=$(tactile_choose "$status Start/Restart" "🔴 Stop" "📋 Logs" "Back")
        
        case $action in
            *"Start/Restart"*)
                gum spin --spinner dot --title "Starting $name..." -- docker compose -f "$config" up -d
                play_tone "confirm"
                ;;
            "🔴 Stop")
                gum spin --spinner dot --title "Stopping $name..." -- docker compose -f "$config" stop
                play_tone "click"
                ;;
            "📋 Logs")
                docker compose -f "$config" logs --tail 30
                gum input --placeholder "Press Enter to return..."
                ;;
            "Back") return ;;
        esac
    done
}

manage_community() {
    while true; do
        render_hud
        echo -e "$(gum style --foreground 212 '--- 🤝 COMMUNITY OPS ---')"
        local action=$(tactile_choose \
            "📻 KPAB.fm Player" \
            "📖 Wikipedia Offline" \
            "🕹️ Web Arcade" \
            "📁 File Browser $(get_status filebrowser)" \
            "📝 Memos $(get_status memos)" \
            "Back")
        
        case $action in
            "📻 KPAB.fm"*) echo "URL: https://kpab.fm"; gum input --placeholder "Press Enter..." ;;
            "📖 Wikipedia"*) echo "URL: http://pibulus.local/wiki/"; gum input --placeholder "Press Enter..." ;;
            "🕹️ Web Arcade"*) echo "URL: http://pibulus.local/arcade/"; gum input --placeholder "Press Enter..." ;;
            "📁 File Browser"*) echo "URL: http://pibulus.local:8080"; gum input --placeholder "Press Enter..." ;;
            "📝 Memos"*) echo "URL: http://pibulus.local:5230"; gum input --placeholder "Press Enter..." ;;
            "Back") return ;;
        esac
    done
}

manage_homepage() {
    while true; do
        render_hud
        echo -e "$(gum style --foreground 212 '--- 🏠 DASHBOARD OPS ---')"
        local action=$(tactile_choose \
            "🌐 Open Homepage $(get_status homepage_admin)" \
            "🔄 Restart Homepage" \
            "📋 View Config" \
            "Back")
        
        case $action in
            "🌐 Open"*) echo "URL: http://pibulus.local:8081"; gum input --placeholder "Press Enter..." ;;
            "🔄 Restart"*) docker restart homepage_admin; play_tone "confirm"; sleep 1 ;;
            "📋 View"*) cat ~/pibulus-os/config/stacks/admin.yml 2>/dev/null | head -40; gum input --placeholder "Press Enter..." ;;
            "Back") return ;;
        esac
    done
}
# --- THE MAIN LOOP ---
play_tone "startup"

while true; do
    render_hud
    choice=$(tactile_choose \
        "🚀 Deploy New App" \
        "📥 Media Scavenger" \
        "📚 Vault Navigator" \
        "🧠 Knowledge Vault $(tmux has-session -t knowledge-vault 2>/dev/null && echo "🟢" || echo "🔴")" \
        "🤝 Community Ops" \
        "🕹️ Terminal Arcade" \
        "🏴‍☠️ Pirate Station $(get_status jellyfin)" \
        "📻 KPAB.fm Radio $(get_status azuracast)" \
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
        "🧠 Knowledge Vault"*) manage_knowledge_vault ;;
        "🤝 Community Ops") manage_community ;;
        "🕹️ Terminal Arcade") manage_games ;;
        "🏴‍☠️ Pirate Station"*) manage_stack "PIRATE STATION" "$PIRATE_CONFIG" "jellyfin" ;;
        "📻 KPAB.fm Radio"*) manage_radio ;;
        "📝 Quick Memos"*) echo "Memos at http://pibulus.local:5230"; gum input --placeholder "Press Enter to return..." ;;
        "💀 Grey Hat Ops") manage_grey_hat ;;
        "📡 SIGINT Ops") manage_sigint ;;
        "📀 Vault Ops") manage_vault ;;
        "🏠 Dashboard Ops") manage_homepage ;;
        "🕵️ Stealth Toggle") "$SCRIPT_DIR/scripts/set_stealth.sh" public ;;
        "🔒 Lock Bunker") "$SCRIPT_DIR/scripts/set_stealth.sh" bunker ;;
        "⏏️ Safe Eject") safe_eject ;;
        "📊 System Status") ~/pibulus-os/scripts/flush_ram.sh; docker ps --format "table {{.Names}}\t{{.Status}}" | head -25; gum input --placeholder "Press Enter to return..." ;;
        "🚪 Exit") play_tone "click"; clear; exit 0 ;;
    esac
done
