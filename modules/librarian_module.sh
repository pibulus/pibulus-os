#!/bin/bash
# 🧠 BISHOP LIBRARIAN MODULE v2.0
# AI-powered vault librarian using headless Claude Code.
# Falls back to grep search if claude isn't available or fails.

MANIFEST_FILE="$HOME/pibulus-os/mission-control/manifest.txt"
BISHOP_BUDGET="0.02"

bishop_query() {
    local query="$1"
    local manifest_snippet=""

    # Build a focused manifest excerpt — grep first to keep context small
    if [ -f "$MANIFEST_FILE" ]; then
        # Get relevant lines + surrounding context, cap at 300 lines
        manifest_snippet=$(grep -i -C 1 "$query" "$MANIFEST_FILE" 2>/dev/null | head -300)
        # If grep found nothing, send a random sample so Bishop knows what's there
        if [ -z "$manifest_snippet" ]; then
            manifest_snippet=$(shuf -n 200 "$MANIFEST_FILE" 2>/dev/null)
        fi
    fi

    if command -v claude &>/dev/null && [ -n "$manifest_snippet" ]; then
        # Use Claude in headless mode — haiku for speed and cost
        local response
        response=$(claude -p \
            --model haiku \
            --no-session-persistence \
            --max-budget-usd "$BISHOP_BUDGET" \
            --append-system-prompt "You are Bishop, the AI librarian for the PIBULUS cyberdeck — a Raspberry Pi home server with a 2TB drive of media, books, comics, music, conspiracies, and offline knowledge. You're dry, pithy, and helpful. When suggesting files, give the full path. Keep responses under 10 lines. If you don't know, say so." \
            "Here are relevant files from our vault manifest:
$manifest_snippet

USER QUESTION: $query" 2>/dev/null)

        if [ -n "$response" ]; then
            echo "$response"
            return 0
        fi
    fi

    # Fallback: simple grep search
    if [ -f "$MANIFEST_FILE" ]; then
        local results=$(grep -i "$query" "$MANIFEST_FILE" 2>/dev/null | head -20)
        if [ -n "$results" ]; then
            echo "  [grep fallback — claude unavailable]"
            echo ""
            echo "$results" | while IFS= read -r line; do
                echo "  📁 $line"
            done
        else
            echo "  Nothing matching '$query' in the manifest."
        fi
    else
        echo "  Manifest not found. Run: ~/pibulus-os/scripts/generate_manifest.sh"
    fi
}

ask_bishop() {
    while true; do
        render_hud
        echo -e "$(gum style --foreground 212 '━━━ 🧠 BISHOP — AI LIBRARIAN ━━━')"
        echo -e "$(gum style --foreground 245 'Ask about anything in the vault. Bishop knows the manifest.')"
        echo ""

        local query=$(gum input --placeholder "What are you looking for? (or 'back' to exit)")
        [ -z "$query" ] || [ "$query" = "back" ] && return

        echo ""
        gum style --foreground 245 "Bishop is thinking..."
        echo ""

        local answer
        answer=$(bishop_query "$query")

        gum style --border rounded --border-foreground 212 --padding "1 2" --margin "0 1" \
            "$(echo "$answer")"

        echo ""
        gum input --placeholder "Press Enter to ask another question..."
    done
}
