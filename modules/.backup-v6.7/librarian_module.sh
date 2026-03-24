#!/bin/bash
# 🧠 BISHOP LIBRARIAN MODULE

ask_bishop() {
    render_hud
    echo -e "$(gum style --foreground 212 '--- 🧠 ASK BISHOP (Librarian Mode) ---')"
    local query=$(gum input --placeholder "What are you looking for? (e.g., 'Suggest a weird movie' or 'Find guitar tabs')")
    
    if [ \! -z "$query" ]; then
        echo "Bishop is consulting the manifest..."
        # We send the manifest snippet + query to Gemini
        (head -n 500 ~/pibulus-os/mission-control/manifest.txt; echo "QUESTION: $query") | gemini ask "You are Bishop, the librarian AI for the Quick Cat Club Cyberdeck. Based on the file list provided, answer the user's question or suggest something cool. Be brief and pithy."
        echo ""
        gum input --placeholder "Press Enter to return..."
    fi
}
