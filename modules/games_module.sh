#!/bin/bash
# 🕹️ QUICK CAT CLUB - ARCADE v1.1

GAMES_DIR="/media/pibulus/passport/www/html/arcade/games"
GAMES_JSON="/media/pibulus/passport/www/html/arcade/games.json"

play_if_game() {
    local file="$1"
    local ext="${file##*.}"
    case "$ext" in
        z3|z4|z5|z8) dfrotz "$GAMES_DIR/$file" ;;
        zblorb|gblorb|ulx)
            if command -v glulxe &>/dev/null; then
                glulxe "$GAMES_DIR/$file"
            else
                gum style --foreground 196 "glulxe not installed for this format."
                sleep 2
            fi
            ;;
        *) gum style --foreground 196 "Unsupported format: $ext"; sleep 2 ;;
    esac
}

manage_games() {
    while true; do
        render_hud
        echo -e "$(gum style --foreground 212 '--- 🕹️ TERMINAL ARCADE ---')"
        local choice=$(tactile_choose \
            "📖 Interactive Fiction" \
            "👾 Space Invaders" \
            "🗡️  NetHack" \
            "🧱 Tetris (Bastet)" \
            "Back")

        case $choice in
            "📖 Interactive Fiction")
                if [ ! -f "$GAMES_JSON" ]; then
                    gum style --foreground 196 "Games catalog not found: $GAMES_JSON"
                    sleep 2
                    continue
                fi
                while true; do
                    render_hud
                    echo -e "$(gum style --foreground 212 '--- 📖 TEXT ADVENTURES ---')"
                    echo -e "$(gum style --foreground 245 'tip: type LOOK, INVENTORY, EXAMINE, QUIT')"
                    echo

                    # Build game list safely using python (no shell injection)
                    local games_list
                    games_list=$(python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    games = json.load(f)
for g in games:
    if g.get('format') != 'tads':
        title = g.get('title', 'Unknown')
        year = g.get('year', '?')
        author = g.get('author', 'Unknown')
        print(f'📜 {title} ({year}) - {author}')
print('Back')
" "$GAMES_JSON" 2>/dev/null)

                    local pick=$(echo "$games_list" | gum choose --height 20)
                    [ -z "$pick" ] || [ "$pick" = "Back" ] && break

                    # Extract title and find file safely via python
                    local file
                    file=$(python3 -c "
import json, sys
query = sys.argv[1]
# Strip emoji prefix and extract just the title before the year
title = query.lstrip('📜 ').strip()
title = title.rsplit(' (', 1)[0].strip()
with open(sys.argv[2]) as f:
    games = json.load(f)
for g in games:
    if g.get('title', '') == title or title in g.get('title', ''):
        print(g.get('file', ''))
        break
" "$pick" "$GAMES_JSON" 2>/dev/null)

                    if [ -n "$file" ] && [ -f "$GAMES_DIR/$file" ]; then
                        play_if_game "$file"
                    else
                        gum style --foreground 196 "Game file not found"
                        sleep 2
                    fi
                done
                ;;
            "👾 Space Invaders")
                if command -v ninvaders &>/dev/null; then ninvaders
                else gum style --foreground 196 "ninvaders not installed"; sleep 2; fi
                ;;
            "🗡️  NetHack")
                if command -v nethack &>/dev/null; then nethack
                else gum style --foreground 196 "nethack not installed"; sleep 2; fi
                ;;
            "🧱 Tetris (Bastet)")
                if command -v bastet &>/dev/null; then bastet
                else gum style --foreground 196 "bastet not installed"; sleep 2; fi
                ;;
            "Back") return ;;
        esac
    done
}
