#!/bin/bash
# 📥 SCAVENGER v1.2 — media grab helper
# Tools: slskd (Soulseek), yt-dlp, aria2, ia (Internet Archive)
# Optional assist: Claude can help choose a tool or tighten a query, but the
# workflow should still make sense without it.

SCAVENGER_BUDGET="0.20"
SLSKD_URL="http://localhost:5030"
SLSKD_USER="slskd"
SLSKD_PASS="slskd"
PASSPORT_ROOT="${PASSPORT_ROOT:-/media/pibulus/passport}"

# Source API keys (not auto-loaded in non-interactive SSH)
[ -f ~/.config/api_keys ] && source ~/.config/api_keys

# --- SOULSEEK HELPERS ---
slskd_auth() {
    curl -s -X POST "$SLSKD_URL/api/v0/session" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$SLSKD_USER\",\"password\":\"$SLSKD_PASS\"}" 2>/dev/null \
        | python3 -c "import sys,json; print(json.load(sys.stdin).get('token',''))" 2>/dev/null
}

slskd_search() {
    local token="$1"
    local query="$2"

    # Start search
    local search_id=$(curl -s -X POST "$SLSKD_URL/api/v0/searches" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "{\"searchText\":\"$query\"}" 2>/dev/null \
        | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)

    [ -z "$search_id" ] && return 1

    # Wait for results (soulseek is slow)
    sleep 12

    # Get results
    curl -s "$SLSKD_URL/api/v0/searches/$search_id/responses" \
        -H "Authorization: Bearer $token" 2>/dev/null \
        | python3 -c "
import sys, json
data = json.load(sys.stdin)
results = []
for resp in data[:10]:
    user = resp.get('username', '?')
    for f in resp.get('files', [])[:3]:
        name = f.get('filename', '').split('\\\\')[-1]
        size = f.get('size', 0)
        size_mb = f'{size/1024/1024:.1f}MB' if size else '?'
        results.append(f'{user}|{name}|{size_mb}|{f.get(\"filename\",\"\")}')
for r in results[:15]:
    print(r)
" 2>/dev/null
}

slskd_download() {
    local token="$1"
    local username="$2"
    local filename="$3"

    curl -s -X POST "$SLSKD_URL/api/v0/transfers/downloads/$username" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "[{\"filename\":\"$filename\"}]" &>/dev/null
}

# --- AI BRAIN ---
ai_decide_tool() {
    local request="$1"

    # Try claude first if available and authed
    if command -v claude &>/dev/null && [ -n "$ANTHROPIC_API_KEY" ]; then
        local result
        result=$(claude --bare -p \
            --model haiku \
            --max-budget-usd "$SCAVENGER_BUDGET" \
            "You are a tool selector. Given a media request, respond with ONLY one word: soulseek, ytdlp, ia, or aria2. Rules: Music/albums/songs/artists = soulseek. YouTube/video URLs = ytdlp. Books/ebooks/academic papers = ia. Direct download URLs = aria2. Audio from YouTube/SoundCloud/Bandcamp = ytdlp. Request: $request" 2>/dev/null | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')

        # Validate we got a real tool name back (not error text)
        case "$result" in
            soulseek|ytdlp|ia|aria2) echo "$result"; return ;;
        esac
    fi

    # Fallback: keyword heuristics (always works, no API needed)
    local lower=$(echo "$request" | tr '[:upper:]' '[:lower:]')
    case "$lower" in
        *youtube*|*youtu.be*|*soundcloud*|*bandcamp*|*vimeo*|*http*://*) echo "ytdlp" ;;
        *archive.org*|*"internet archive"*) echo "ia" ;;
        *book*|*pdf*|*epub*|*ebook*|*paper*|*textbook*|*manual*) echo "ia" ;;
        *album*|*song*|*music*|*artist*|*band*|*flac*|*mp3*|*vinyl*|*discography*) echo "soulseek" ;;
        *) echo "soulseek" ;;
    esac
}

ai_craft_query() {
    local request="$1"
    local tool="$2"

    # Try claude first if available and authed
    if command -v claude &>/dev/null && [ -n "$ANTHROPIC_API_KEY" ]; then
        local result
        result=$(claude --bare -p \
            --model haiku \
            --max-budget-usd "$SCAVENGER_BUDGET" \
            "Output ONLY the search query — no explanation, no quotes, no preamble, nothing else. For soulseek: artist album or song name. For ia: search terms. For ytdlp: the URL or search terms. Tool: $tool. Request: $request" 2>/dev/null)

        # Validate: if result is short enough to be a query (not a paragraph), use it
        local word_count=$(echo "$result" | wc -w)
        if [ "$word_count" -gt 0 ] && [ "$word_count" -le 12 ]; then
            echo "$result"
            return
        fi
    fi

    # Fallback: just use the request as-is (it's usually fine)
    echo "$request"
}

# --- SCAVENGER FLOWS ---
scavenge_soulseek() {
    local query="$1"
    gum style --foreground 51 "🎵 Searching Soulseek for: $query"

    local token=$(slskd_auth)
    if [ -z "$token" ]; then
        gum style --foreground 196 "Failed to auth with slskd. Is it running?"
        gum style --foreground 245 "Try: docker start slskd"
        sleep 2
        return
    fi

    gum spin --spinner moon --title "Searching the network (takes ~12s)..." -- sleep 12
    local results=$(slskd_search "$token" "$query")

    if [ -z "$results" ]; then
        gum style --foreground 226 "No results. Try different terms."
        sleep 2
        return
    fi

    # Show results for picking
    local display=()
    while IFS='|' read -r user name size filepath; do
        display+=("$name ($size) from $user")
    done <<< "$results"

    gum style --foreground 46 "Found ${#display[@]} results:"
    local pick=$(printf '%s\n' "${display[@]}" | gum choose --height 15)
    [ -z "$pick" ] && return

    # Find the matching result line
    while IFS='|' read -r user name size filepath; do
        local check="$name ($size) from $user"
        if [ "$check" = "$pick" ]; then
            if gum confirm "Download from $user?"; then
                slskd_download "$token" "$user" "$filepath"
                play_tone "confirm" 2>/dev/null
                gum style --foreground 46 "✅ Download queued! Check slskd UI for progress."
                gum style --foreground 245 "Will land in: /media/pibulus/passport/Soulseek/"
            fi
            break
        fi
    done <<< "$results"

    sleep 2
}

scavenge_ytdlp() {
    local query="$1"
    gum style --foreground 51 "📹 yt-dlp target: $query"

    if ! command -v yt-dlp &>/dev/null; then
        gum style --foreground 196 "yt-dlp not installed"
        sleep 2
        return
    fi

    local media_type=$(gum choose "🎵 Audio only (mp3)" "📹 Video (mp4)")
    local dest_type=$(gum choose "Music/Inbox" "Radio/Tunes" "Movies" "Shows" "The_Bucket")
    [ -z "$dest_type" ] && return
    local DEST="$PASSPORT_ROOT/$dest_type"

    case "$media_type" in
        *Audio*)
            gum spin --spinner moon --title "Extracting audio..." -- \
                yt-dlp -x --audio-format mp3 --audio-quality 0 \
                -o "$DEST/%(title)s.%(ext)s" "$query"
            ;;
        *Video*)
            gum spin --spinner moon --title "Downloading video..." -- \
                yt-dlp -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best' \
                -o "$DEST/%(title)s.%(ext)s" "$query"
            ;;
    esac

    if [ $? -eq 0 ]; then
        play_tone "confirm" 2>/dev/null
        gum style --foreground 46 "✅ Captured to $dest_type"
    else
        play_tone "error" 2>/dev/null
        gum style --foreground 196 "❌ Download failed"
    fi
    sleep 2
}

scavenge_ia() {
    local query="$1"
    gum style --foreground 51 "📚 Searching Internet Archive: $query"

    if ! command -v ia &>/dev/null; then
        gum style --foreground 196 "ia CLI not installed (~/.local/bin/ia)"
        sleep 2
        return
    fi

    # Search IA
    local results=$(ia search "$query" --itemlist 2>/dev/null | head -15)
    if [ -z "$results" ]; then
        gum style --foreground 226 "No results on Internet Archive."
        sleep 2
        return
    fi

    gum style --foreground 46 "Found items:"
    local pick=$(echo "$results" | gum choose --height 15)
    [ -z "$pick" ] && return

    # Show item details
    local details=$(ia metadata "$pick" 2>/dev/null | python3 -c "
import sys, json
m = json.load(sys.stdin).get('metadata', {})
title = m.get('title', '?')
size = m.get('item_size', '?')
desc = m.get('description', 'No description')[:200]
print(f'Title: {title}')
print(f'Size: {size} bytes')
print(f'Desc: {desc}')
" 2>/dev/null)

    echo "$details"
    echo ""

    local dest=$(gum choose "Ebooks" "Music" "Movies" "The_Bucket")
    [ -z "$dest" ] && return

    if gum confirm "Download '$pick' to $dest?"; then
        local DEST="$PASSPORT_ROOT/$dest"
        mkdir -p "$DEST"
        gum spin --spinner moon --title "Downloading from Internet Archive..." -- \
            ia download "$pick" --destdir="$DEST" --no-directories 2>/dev/null
        if [ $? -eq 0 ]; then
            play_tone "confirm" 2>/dev/null
            gum style --foreground 46 "✅ Downloaded to $DEST"
        else
            play_tone "error" 2>/dev/null
            gum style --foreground 196 "❌ Download failed (may need: ia configure)"
        fi
    fi
    sleep 2
}

scavenge_aria2() {
    local url="$1"
    gum style --foreground 51 "⬇️  Direct download: $url"

    if ! command -v aria2c &>/dev/null; then
        gum style --foreground 196 "aria2 not installed"
        sleep 2
        return
    fi

    local dest=$(gum choose "Music/Inbox" "Ebooks" "Movies" "The_Bucket" "Soulseek")
    [ -z "$dest" ] && return
    local DEST="$PASSPORT_ROOT/$dest"

    gum spin --spinner moon --title "Downloading (16 connections)..." -- \
        aria2c -x 16 -s 16 -d "$DEST" "$url" 2>/dev/null

    if [ $? -eq 0 ]; then
        play_tone "confirm" 2>/dev/null
        gum style --foreground 46 "✅ Downloaded to $DEST"
    else
        play_tone "error" 2>/dev/null
        gum style --foreground 196 "❌ Download failed"
    fi
    sleep 2
}

# --- MAIN SCAVENGER MENU ---
manage_scavenger() {
    while true; do
        render_hud
        echo -e "$(gum style --foreground 51 '━━━ 📥 SCAVENGER ━━━')"
        echo -e "$(gum style --foreground 245 'Grab music, video, books, or direct downloads.')"
        echo ""

        local action=$(tactile_choose \
            "🧭 Help Me Choose" \
            "🎵 Search Soulseek" \
            "📹 Use yt-dlp" \
            "📚 Search Internet Archive" \
            "⬇️  Direct Download URL" \
            "Back")

        case $action in
            "🧭 Help Me Choose"*)
                local request=$(gum input --placeholder "What do you want? (e.g., 'that new MF DOOM bootleg')")
                [ -z "$request" ] && continue

                gum style --foreground 245 "Picking the best lane..."
                local tool=$(ai_decide_tool "$request")
                local query=$(ai_craft_query "$request" "$tool")

                gum style --foreground 212 "Best lane: $tool"
                gum style --foreground 245 "Search: $query"
                echo ""

                case "$tool" in
                    soulseek) scavenge_soulseek "$query" ;;
                    ytdlp)    scavenge_ytdlp "$query" ;;
                    ia)       scavenge_ia "$query" ;;
                    aria2)    scavenge_aria2 "$query" ;;
                    *)        gum style --foreground 226 "Couldn't decide tool. Try manual search."; sleep 2 ;;
                esac
                ;;
            "🎵 Search Soulseek")
                local q=$(gum input --placeholder "Search Soulseek (e.g., 'Eddy Current Suppression Ring')")
                [ -n "$q" ] && scavenge_soulseek "$q"
                ;;
            "📹 Use yt-dlp")
                local q=$(gum input --placeholder "URL or search (e.g., 'https://youtube.com/...')")
                [ -n "$q" ] && scavenge_ytdlp "$q"
                ;;
            "📚 Search Internet Archive")
                local q=$(gum input --placeholder "Search IA (e.g., 'anarchist cookbook')")
                [ -n "$q" ] && scavenge_ia "$q"
                ;;
            "⬇️  Direct Download URL"*)
                local q=$(gum input --placeholder "Paste direct download URL...")
                [ -n "$q" ] && scavenge_aria2 "$q"
                ;;
            "Back") return ;;
        esac
    done
}

scavenge_oneshot() {
    local request="$*"
    [ -z "$request" ] && return 1

    local tool=$(ai_decide_tool "$request")
    local query=$(ai_craft_query "$request" "$tool")

    case "$tool" in
        soulseek) scavenge_soulseek "$query" ;;
        ytdlp)    scavenge_ytdlp "$query" ;;
        ia)       scavenge_ia "$query" ;;
        aria2)    scavenge_aria2 "$query" ;;
        *)        echo "Couldn't decide tool for: $request" ;;
    esac
}
