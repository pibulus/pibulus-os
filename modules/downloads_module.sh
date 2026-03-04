#!/bin/bash
# 📥 DOWNLOADS MODULE v1.0
# Detached downloads via tmux + monitoring

# Run a command in a named tmux session (detached)
# Usage: start_download "session-name" "command to run"
start_download() {
    local name="$1"
    local cmd="$2"
    local timestamp=$(date +%s)
    local session="dl-${name}-${timestamp}"

    # Log the download
    local log_dir="$HOME/.cache/deck-downloads"
    mkdir -p "$log_dir"
    echo "{\"session\":\"$session\",\"name\":\"$name\",\"started\":\"$(date -Iseconds)\",\"status\":\"running\"}" >> "$log_dir/history.jsonl"

    # Launch in tmux - command runs, then waits for keypress before closing
    tmux new-session -d -s "$session" "bash -c '$cmd; echo; echo === DOWNLOAD COMPLETE ===; echo Press Enter to close...; read'"

    echo "$session"
}

# List all active download sessions
list_downloads() {
    local sessions=$(tmux list-sessions 2>/dev/null | grep "^dl-" | cut -d: -f1)
    if [ -z "$sessions" ]; then
        echo "none"
        return
    fi
    echo "$sessions"
}

# Count active downloads
count_downloads() {
    tmux list-sessions 2>/dev/null | grep -c "^dl-" || echo "0"
}

# Download monitor TUI
manage_downloads() {
    while true; do
        render_hud
        local count=$(count_downloads)
        echo -e "$(gum style --foreground 51 "--- DOWNLOADS ($count active) ---")"
        echo ""

        local sessions=$(list_downloads)

        if [ "$sessions" = "none" ]; then
            gum style --foreground 245 "No active downloads."
            echo ""

            # Show recent history
            local log="$HOME/.cache/deck-downloads/history.jsonl"
            if [ -f "$log" ]; then
                gum style --foreground 245 "Recent downloads:"
                tail -5 "$log" | python3 -c "
import sys, json
for line in sys.stdin:
    try:
        d = json.loads(line.strip())
        print(f\"  {d.get('started','?')[:16]}  {d.get('name','?')}\")
    except: pass
" 2>/dev/null
            fi
            echo ""
            gum input --placeholder "Press Enter to return..."
            return
        fi

        # Build menu from active sessions
        local items=()
        while IFS= read -r s; do
            [ -z "$s" ] && continue
            local friendly=$(echo "$s" | sed 's/^dl-//;s/-[0-9]*$//')
            items+=("$friendly  ($s)")
        done <<< "$sessions"
        items+=("Kill all downloads")
        items+=("Back")

        local pick=$(tactile_choose "${items[@]}")

        case "$pick" in
            "Kill all downloads")
                if gum confirm "Kill ALL active downloads?"; then
                    while IFS= read -r s; do
                        [ -z "$s" ] && continue
                        tmux kill-session -t "$s" 2>/dev/null
                    done <<< "$sessions"
                    play_tone "confirm"
                    gum style --foreground 46 "All downloads killed."
                    sleep 1
                fi
                ;;
            "Back") return ;;
            *)
                # Extract session name from pick
                local sess=$(echo "$pick" | grep -o "(dl-[^)]*)" | tr -d "()")
                [ -z "$sess" ] && continue

                local action=$(tactile_choose \
                    "Attach (view live output)" \
                    "Kill this download" \
                    "Back")

                case "$action" in
                    "Attach"*) tmux attach-session -t "$sess" ;;
                    "Kill"*)
                        tmux kill-session -t "$sess" 2>/dev/null
                        play_tone "confirm"
                        gum style --foreground 46 "Download killed."
                        sleep 1
                        ;;
                esac
                ;;
        esac
    done
}
