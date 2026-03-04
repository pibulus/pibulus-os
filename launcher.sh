#!/bin/bash
# 🐾 QUICK CAT CLUB - CYBERDECK v7.1
# Categorized. AI-Powered. Operational.

# --- TERMINAL SAFETY ---
case "$TERM" in
    xterm-ghostty|xterm-kitty) export TERM=xterm-256color ;;
esac

# --- SOURCE CONFIG ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
[ -f "$SCRIPT_DIR/.env" ] && source "$SCRIPT_DIR/.env" || { echo "❌ No .env found at $SCRIPT_DIR/.env"; exit 1; }

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
source "$SCRIPT_DIR/modules/scavenger_module.sh"
source "$SCRIPT_DIR/modules/pirate_grab_module.sh"
source "$SCRIPT_DIR/modules/downloads_module.sh"

# --- HELP FLAG ---
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "help" ]]; then
    echo ""
    gum style --border rounded --border-foreground 212 --padding "1 2" --margin "0 1" \
        "$(printf '%s\n' \
            '🐾 PIBULUS CYBERDECK v7.1' \
            '━━━━━━━━━━━━━━━━━━━━━━━━━━' \
            '' \
            'Usage: deck [command]' \
            '' \
            '  (no args)    Launch TUI menu' \
            '  radio        KPAB.fm control' \
            '  games        Terminal Arcade' \
            '  status       System snapshot' \
            '  audit        Security audit' \
            '  deploy       Deploy a new app' \
            '  search       Ask Bishop (AI librarian)' \
            '  scavenge     Scavenger bot (AI downloads)' \
            '  downloads    Active download monitor' \
            '  --help, -h   This help' \
            '' \
            'Aliases: help, halp, sos, wtf')"
    echo ""
    exit 0
fi

# --- QUICK COMMANDS ---
case "$1" in
    radio)     manage_radio; exit 0 ;;
    games)     manage_games; exit 0 ;;
    audit)     run_audit; exit 0 ;;
    search)    ask_bishop; exit 0 ;;
    scavenge)  manage_scavenger; exit 0 ;;
    downloads) manage_downloads; exit 0 ;;
    deploy)    play_tone "confirm"; "$SCRIPT_DIR/scripts/deploy.sh"; exit 0 ;;
    status)
        echo ""
        vcgencmd measure_temp 2>/dev/null
        free -h
        df -h / /media/pibulus/passport 2>/dev/null
        echo ""
        docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null | head -25
        exit 0
        ;;
esac

# --- UTILS ---
get_status() {
    if [ "$(docker ps -q -f name="$1" 2>/dev/null)" ]; then
        echo "🟢"
    else
        echo "🔴"
    fi
}

render_hud() {
    clear
    local TEMP=$(vcgencmd measure_temp 2>/dev/null | cut -d'=' -f2 || echo "N/A")
    local DISK=$(df -h "$PASSPORT_ROOT" 2>/dev/null | awk 'NR==2 {print $5}' || echo "N/A")
    local MEM=$(free -m | awk '/Mem:/ {printf "%dMB/%dMB", $3, $2}')
    local VPN=$(get_status gluetun)
    [ "$VPN" == "🟢" ] && VPN="🔒 VPN" || VPN="🔓 CLR"
    local PWR_HEX=$(vcgencmd get_throttled 2>/dev/null | cut -d'=' -f2)
    [ "$PWR_HEX" == "0x0" ] && PWR="⚡" || PWR="⚠️"
    local CONTAINERS=$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')
    local DL_COUNT=$(count_downloads 2>/dev/null)
    local DL_BADGE=""
    [ "$DL_COUNT" -gt 0 ] 2>/dev/null && DL_BADGE="  |  📥 ${DL_COUNT} dl"

    gum style --border double --border-foreground 212 --padding "0 2" --margin "1 0" --align center \
        "$PWR 🐾 $USER_NAME  |  🌡️ $TEMP  |  🧠 $MEM  |  📼 $DISK  |  $VPN  |  📦 ${CONTAINERS} up${DL_BADGE}"
}

tactile_choose() {
    local choice=$(gum choose "$@")
    [ -n "$choice" ] && play_tone "click"
    echo "$choice"
}

get_stealth_mode() {
    if sudo sshd -T 2>/dev/null | grep -q "passwordauthentication yes"; then
        echo "public"
    else
        echo "bunker"
    fi
}

# --- STACK MANAGER ---
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
        local action=$(tactile_choose \
            "$status Start/Restart" \
            "🔴 Stop" \
            "📋 Logs" \
            "Back")

        case $action in
            *"Start/Restart"*)
                gum spin --spinner dot --title "Starting $name..." -- \
                    docker compose -f "$config" up -d
                play_tone "confirm"
                ;;
            "🔴 Stop")
                gum spin --spinner dot --title "Stopping $name..." -- \
                    docker compose -f "$config" stop
                play_tone "click"
                ;;
            "📋 Logs")
                docker compose -f "$config" logs --tail 30 2>/dev/null | less
                ;;
            "Back") return ;;
        esac
    done
}

# ═══════════════════════════════════════════
# CATEGORY MENUS
# ═══════════════════════════════════════════

# --- MEDIA & ENTERTAINMENT ---
menu_media() {
    while true; do
        render_hud
        echo -e "$(gum style --foreground 51 '━━━ 🎬 MEDIA & ENTERTAINMENT ━━━')"

        local choice=$(tactile_choose \
            "🏴‍☠️ Pirate Station $(get_status jellyfin)" \
            "📻 KPAB.fm Radio $(get_status azuracast)" \
            "🤖 Scavenger Bot (AI Downloads)" \
            "📥 Media Scavenger (Manual)" \
            "🏴 Pirate Grab (Torrents)" \
            "🕹️ Terminal Arcade" \
            "Back")

        case $choice in
            "🏴‍☠️ Pirate Station"*) manage_stack "PIRATE STATION" "$PIRATE_CONFIG" "jellyfin" ;;
            "📻 KPAB.fm Radio"*) manage_radio ;;
            "🤖 Scavenger Bot"*) manage_scavenger ;;
            "📥 Media Scavenger"*) pull_media ;;
            "🏴 Pirate Grab"*) manage_pirate_grab ;;
            "🕹️ Terminal Arcade") manage_games ;;
            "Back") return ;;
        esac
    done
}

# --- KNOWLEDGE & COMMUNITY ---
menu_knowledge() {
    while true; do
        render_hud
        echo -e "$(gum style --foreground 226 '━━━ 📚 KNOWLEDGE & COMMUNITY ━━━')"

        local choice=$(tactile_choose \
            "🧠 Ask Bishop (AI Librarian)" \
            "📚 Vault Navigator" \
            "📖 Offline Wikipedia" \
            "📝 Memos $(get_status memos)" \
            "📁 File Browser $(get_status filebrowser)" \
            "🔗 URL Shortener" \
            "🕹️ Web Arcade" \
            "Back")

        case $choice in
            "🧠 Ask Bishop"*) ask_bishop ;;
            "📚 Vault Navigator") manage_knowledge_vault ;;
            "📖 Offline Wikipedia")
                gum style --foreground 46 "Kiwix: http://pibulus.local:8084"
                gum style --foreground 245 "Also: http://pibulus.local/wiki/"
                gum input --placeholder "Press Enter..." ;;
            "📝 Memos"*)
                gum style --foreground 46 "Memos: http://pibulus.local:5230"
                gum style --foreground 245 "Public: https://memo.quickcat.club (if exposed)"
                gum input --placeholder "Press Enter..." ;;
            "📁 File Browser"*)
                gum style --foreground 46 "Files: http://pibulus.local:8080"
                gum input --placeholder "Press Enter..." ;;
            "🔗 URL Shortener")
                local short_status=$(systemctl is-active shortener 2>/dev/null)
                if [ "$short_status" = "active" ]; then
                    gum style --foreground 46 "🟢 Shortener: http://pibulus.local:8088"
                    gum style --foreground 245 "Public: https://go.quickcat.club (if exposed)"
                else
                    gum style --foreground 226 "🔴 Shortener not running."
                    if gum confirm "Start it?"; then
                        sudo systemctl start shortener
                        play_tone "confirm"
                        gum style --foreground 46 "Started! http://pibulus.local:8088"
                    fi
                fi
                gum input --placeholder "Press Enter..." ;;
            "🕹️ Web Arcade")
                gum style --foreground 46 "Arcade: http://pibulus.local/arcade/"
                gum input --placeholder "Press Enter..." ;;
            "Back") return ;;
        esac
    done
}

# --- SECURITY & SIGNALS ---
menu_security() {
    while true; do
        render_hud
        local mode=$(get_stealth_mode)
        [ "$mode" == "public" ] && local mode_display="🔓 PUBLIC" || local mode_display="🔒 BUNKER"
        echo -e "$(gum style --foreground 196 "━━━ 🛡️ SECURITY & SIGNALS ━━━  [$mode_display]")"

        local choice=$(tactile_choose \
            "💀 Grey Hat Ops" \
            "📡 SIGINT Ops" \
            "🕵️ Stealth Toggle ($mode_display)" \
            "🚨 Nuclear Bunker Lockdown" \
            "Back")

        case $choice in
            "💀 Grey Hat Ops") manage_grey_hat ;;
            "📡 SIGINT Ops") manage_sigint ;;
            "🕵️ Stealth Toggle"*)
                if [ "$mode" == "public" ]; then
                    if gum confirm "Switch to BUNKER mode? (Keys only, tunnel down)"; then
                        "$SCRIPT_DIR/scripts/set_stealth.sh" bunker
                        play_tone "confirm"
                    fi
                else
                    if gum confirm "Switch to PUBLIC mode? (Password auth, tunnel up)"; then
                        "$SCRIPT_DIR/scripts/set_stealth.sh" public
                        play_tone "confirm"
                    fi
                fi
                sleep 1
                ;;
            "🚨 Nuclear Bunker Lockdown") run_bunker_lockdown ;;
            "Back") return ;;
        esac
    done
}

# --- SYSTEM & OPS ---
menu_system() {
    while true; do
        render_hud
        echo -e "$(gum style --foreground 46 '━━━ ⚙️ SYSTEM & OPS ━━━')"

        local kv_status=""
        tmux has-session -t knowledge-vault 2>/dev/null && kv_status="🟢" || kv_status="🔴"
        local dl_count=$(count_downloads 2>/dev/null)
        local dl_badge=""
        [ "$dl_count" -gt 0 ] 2>/dev/null && dl_badge=" ($dl_count active)"

        local choice=$(tactile_choose \
            "📊 System Status" \
            "🛡️ Security Audit" \
            "🤖 Mission Control" \
            "📥 Downloads Monitor${dl_badge}" \
            "📀 Vault & Recovery" \
            "🧠 Knowledge Vault DL $kv_status" \
            "💾 Create Backup" \
            "🚀 Deploy New App" \
            "🏠 Homepage Dashboard $(get_status homepage_admin)" \
            "⏏️ Safe Eject" \
            "Back")

        case $choice in
            "📊 System Status")
                render_hud
                echo ""
                gum style --foreground 212 "--- CONTAINERS ---"
                docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null | head -25
                echo ""
                gum style --foreground 212 "--- RESOURCES ---"
                free -h
                echo ""
                df -h / /media/pibulus/passport 2>/dev/null
                echo ""
                ~/pibulus-os/scripts/flush_ram.sh 2>/dev/null
                gum input --placeholder "Press Enter to return..."
                ;;
            "🛡️ Security Audit") run_audit ;;
            "🤖 Mission Control") manage_mission_control ;;
            "📥 Downloads Monitor"*) manage_downloads ;;
            "📀 Vault & Recovery") manage_vault ;;
            "🧠 Knowledge Vault DL"*)
                if tmux has-session -t knowledge-vault 2>/dev/null; then
                    gum style --foreground 46 "Knowledge Vault downloader is running."
                    if gum confirm "View live output?"; then
                        tmux attach-session -t knowledge-vault
                    fi
                else
                    gum style --foreground 245 "Knowledge Vault downloader is not running."
                    if gum confirm "Start download?"; then
                        ~/pibulus-os/scripts/knowledge-vault-downloader.sh
                    fi
                fi
                ;;
            "💾 Create Backup") run_backup ;;
            "🚀 Deploy New App") play_tone "confirm"; "$SCRIPT_DIR/scripts/deploy.sh" ;;
            "🏠 Homepage Dashboard"*)
                local hp_status=$(get_status homepage_admin)
                gum style --foreground 46 "Homepage: http://pibulus.local:8081  $hp_status"
                local hp_action=$(tactile_choose "Open (show URL)" "🔄 Restart" "Back")
                case $hp_action in
                    "Open"*) gum input --placeholder "Press Enter..." ;;
                    "🔄 Restart")
                        docker restart homepage_admin 2>/dev/null
                        play_tone "confirm"
                        gum style --foreground 46 "Restarted."
                        sleep 1 ;;
                esac
                ;;
            "⏏️ Safe Eject") safe_eject ;;
            "Back") return ;;
        esac
    done
}

# ═══════════════════════════════════════════
# THE MAIN LOOP
# ═══════════════════════════════════════════
play_tone "startup"

while true; do
    render_hud

    choice=$(tactile_choose \
        "🎬 Media & Entertainment" \
        "📚 Knowledge & Community" \
        "🛡️ Security & Signals" \
        "⚙️  System & Ops" \
        "🚪 Exit")

    case $choice in
        "🎬 Media & Entertainment") menu_media ;;
        "📚 Knowledge & Community") menu_knowledge ;;
        "🛡️ Security & Signals") menu_security ;;
        "⚙️  System & Ops") menu_system ;;
        "🚪 Exit") play_tone "click"; clear; exit 0 ;;
    esac
done
