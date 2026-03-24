#!/bin/bash
# 🕹️ QUICK CAT CLUB - ARCADE

GAMES_DIR="/media/pibulus/passport/www/html/arcade/games"

play_if_game() {
    local file="$1"
    local ext="${file##*.}"
    case "$ext" in
        z3|z4|z5|z8) dfrotz "$GAMES_DIR/$file" ;;
        zblorb|gblorb|ulx) glulxe "$GAMES_DIR/$file" ;;
        *) echo "Unsupported format: $ext"; sleep 2 ;;
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
                while true; do
                    render_hud
                    echo -e "$(gum style --foreground 212 '--- 📖 TEXT ADVENTURES ---')"
                    echo -e "$(gum style --foreground 245 'tip: type LOOK, INVENTORY, EXAMINE, QUIT')"
                    echo

                    # Build game list from games.json
                    local games_list=()
                    while IFS= read -r line; do
                        games_list+=("$line")
                    done < <(python3 -c "
import json
with open('$GAMES_DIR/../games.json') as f:
    games = json.load(f)
for g in games:
    if g['format'] != 'tads':
        print(f\"📜 {g['title']} ({g['year']}) - {g['author']}\")
print('Back')
" 2>/dev/null)

                    local pick=$(printf '%s\n' "${games_list[@]}" | gum choose --height 20)
                    [ -z "$pick" ] || [ "$pick" = "Back" ] && break

                    # Extract title to find matching file
                    local title=$(echo "$pick" | sed 's/^📜 //;s/ ([0-9].*//') 
                    local file=$(python3 -c "
import json
with open('$GAMES_DIR/../games.json') as f:
    games = json.load(f)
for g in games:
    if g['title'] == '$title' or '$title' in g['title']:
        print(g['file'])
        break
" 2>/dev/null)

                    if [ -n "$file" ] && [ -f "$GAMES_DIR/$file" ]; then
                        play_if_game "$file"
                    else
                        echo "Game file not found"
                        sleep 2
                    fi
                done
                ;;
            "👾 Space Invaders") ninvaders ;;
            "🗡️  NetHack") nethack ;;
            "🧱 Tetris (Bastet)") bastet ;;
            "Back") return ;;
        esac
    done
}
