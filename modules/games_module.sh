#!/bin/bash
# 🕹️ QUICK CAT CLUB - ARCADE

manage_games() {
    while true; do
        render_hud
        echo -e "$(gum style --foreground 212 '--- 🕹️ TERMINAL ARCADE ---')"
        local game=$(tactile_choose \
            "👾 Space Invaders" \
            "🗡️  NetHack" \
            "🧱 Tetris (Bastet)" \
            "Back")
        
        case $game in
            "👾 Space Invaders") ninvaders ;;
            "🗡️  NetHack") nethack ;;
            "🧱 Tetris (Bastet)") bastet ;;
            "Back") return ;;
        esac
    done
}
