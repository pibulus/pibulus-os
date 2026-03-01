#!/bin/bash
# 🕹️ TERMINAL TRAVELS MODULE v1.1
# Launches the curated text adventure collection.
# NOTE: This is a legacy launcher. The games_module.sh handles
# the arcade menu now. This is kept for direct `play_games` calls.

play_games() {
    local TT_DIR="$HOME/Projects/active/experiments/terminal-travels"
    if [ -d "$TT_DIR" ] && [ -x "$TT_DIR/terminal-travels" ]; then
        clear
        play_tone "confirm"
        cd "$TT_DIR" && ./terminal-travels
    else
        gum style --foreground 245 "Terminal Travels not found at $TT_DIR"
        gum style --foreground 245 "Use the Terminal Arcade instead."
        sleep 2
    fi
}
