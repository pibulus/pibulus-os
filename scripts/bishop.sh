#!/bin/bash
# ╔══════════════════════════════════════════╗
# ║  BISHOP — Pibulus AI Companion v3.2      ║
# ║  aichat + gum + scavenger + Pi toolkit   ║
# ║  hardened: no injection, no leaked keys  ║
# ╚══════════════════════════════════════════╝

export PATH="$HOME/.local/bin:$PATH"
PASSPORT="/media/pibulus/passport"

# API key from environment only — never hardcoded
if [ -z "$GEMINI_API_KEY" ]; then
    echo "GEMINI_API_KEY not set. Source ~/.config/api_keys first."
    echo "  Run: source ~/.config/api_keys"
    exit 1
fi

# Safe temp file with cleanup
BISHOP_TMP=$(mktemp /tmp/bishop_reply.XXXXXX)
trap 'rm -f "$BISHOP_TMP" /tmp/bishop_health.??????' EXIT

# Colors
Y='\033[1;33m'; C='\033[0;36m'; M='\033[0;35m'; D='\033[2m'; G='\033[0;32m'
R='\033[0;31m'; W='\033[1;37m'; RST='\033[0m'

# ═══════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════

_now_playing() {
    local np=$(curl -s 'http://localhost:8500/api/nowplaying/1' 2>/dev/null)
    local info=$(echo "$np" | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    s=d['now_playing']['song']
    print(s.get('artist','?') + '|||' + s.get('title','?'))
except: pass
" 2>/dev/null)
    if [ -n "$info" ]; then
        local artist="${info%%|||*}"
        local title="${info##*|||}"
        echo -e "${Y}♪ $artist — $title${RST}"
    else
        echo -e "${D}couldn't fetch now playing${RST}"
    fi
}

header() {
    clear
    figlet -f small "BISHOP" 2>/dev/null | lolcat -f 2>/dev/null
    echo -e "${D}pibulus AI companion · gemini · type 'quit' to exit${RST}"
    local mem=$(free -m | awk '/^Mem:/{printf "%d/%dMB", $3, $2}')
    local temp=$(vcgencmd measure_temp 2>/dev/null | cut -d= -f2 || echo "?")
    local containers=$(docker ps -q 2>/dev/null | wc -l)
    echo -e "${D}RAM: ${mem} · Temp: ${temp} · Containers: ${containers}${RST}"
    echo ""
}

# ═══════════════════════════════════════
# CORE MODES
# ═══════════════════════════════════════

chat_loop() {
    echo -e "${C}Chat mode — ask anything. Type 'quit' to return.${RST}"
    echo ""
    while true; do
        local prompt=$(gum input --placeholder "ask bishop..." --width 60 --char-limit 500 \
            --prompt "▸ " --prompt.foreground 212)
        [ -z "$prompt" ] && continue
        [ "$prompt" = "quit" ] && return
        echo ""
        gum spin --spinner dot --title "thinking..." -- \
            aichat -- "$prompt" > "$BISHOP_TMP" 2>&1
        echo -e "${C}bishop:${RST}"
        gum format < "$BISHOP_TMP"
        echo ""
    done
}

execute_mode() {
    echo -e "${Y}⚡ Execute mode — describe tasks in plain English${RST}"
    echo -e "${D}bishop will write and run shell commands for you${RST}"
    echo -e "${R}(commands run as your user — be careful)${RST}"
    echo ""
    while true; do
        local prompt=$(gum input --placeholder "what should I do?..." --width 60 --char-limit 500 \
            --prompt "⚡ " --prompt.foreground 214)
        [ -z "$prompt" ] && continue
        [ "$prompt" = "quit" ] && return
        echo ""
        aichat -e -- "$prompt" 2>&1
        echo ""
    done
}

analyze_file() {
    echo -e "${C}Pick a file to analyze${RST}"
    local file=$(gum file --height 15 .)
    [ -z "$file" ] && return
    echo -e "${D}Selected: $file${RST}"
    local prompt=$(gum input --placeholder "what should I look for? (or Enter for summary)" --width 60)
    [ -z "$prompt" ] && prompt="analyze this file, explain what it does, flag any issues"
    echo ""
    gum spin --spinner dot --title "analyzing..." -- \
        aichat -f "$file" -- "$prompt" > "$BISHOP_TMP" 2>&1
    echo -e "${C}bishop:${RST}"
    gum format < "$BISHOP_TMP"
}

diagnose() {
    echo -e "${G}Running system diagnostics...${RST}"
    echo ""
    local health_tmp=$(mktemp /tmp/bishop_health.XXXXXX)
    {
        echo "=== MEMORY ===" && free -h
        echo "=== DISK ===" && df -h / /media/pibulus/passport /media/pibulus/MEMBOT 2>/dev/null
        echo "=== TEMP ===" && vcgencmd measure_temp 2>/dev/null
        echo "=== UPTIME ===" && uptime
        echo "=== DOCKER ===" && docker ps --format 'table {{.Names}}\t{{.Status}}'
        echo "=== SWAP ===" && cat /proc/swaps
        echo "=== TOP RAM ===" && ps aux --sort=-%mem | head -8
    } > "$health_tmp" 2>&1
    gum spin --spinner dot --title "bishop is interpreting..." -- \
        aichat "You are the sysadmin AI for a Raspberry Pi 5 home server called PIBULUS. Give a brief, friendly system health report. Flag anything concerning. Use emoji sparingly. Be concise." < "$health_tmp" > "$BISHOP_TMP" 2>&1
    echo -e "${C}bishop:${RST}"
    gum format < "$BISHOP_TMP"
    rm -f "$health_tmp"
}

# ═══════════════════════════════════════
# DOCKER OPS
# ═══════════════════════════════════════

docker_ops() {
    echo -e "${M}Docker Operations${RST}"
    echo ""
    local action=$(gum choose \
        "Container status" \
        "Restart a service" \
        "View logs" \
        "Clean up (safe prune)" \
        "Memory per container" \
        "Back")
    case "$action" in
        *"status"*)
            docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | gum format
            ;;
        *"Restart"*)
            local svc=$(docker ps --format '{{.Names}}' | gum choose --header "pick a container:")
            [ -n "$svc" ] && docker restart "$svc" && echo -e "${G}$svc restarted${RST}"
            ;;
        *"logs"*)
            local svc=$(docker ps --format '{{.Names}}' | gum choose --header "pick a container:")
            [ -n "$svc" ] && docker logs --tail 30 "$svc" 2>&1 | gum pager
            ;;
        *"Clean"*)
            echo -e "${D}Preview:${RST}"
            docker system df
            echo ""
            gum confirm "Run safe prune? (removes dangling images, stopped containers)" && \
                docker system prune -f && echo -e "${G}Cleaned${RST}"
            ;;
        *"Memory"*)
            for c in $(docker ps --format '{{.Names}}'); do
                local pid=$(docker inspect --format '{{.State.Pid}}' "$c" 2>/dev/null)
                if [ -n "$pid" ] && [ "$pid" -gt 0 ] 2>/dev/null; then
                    local rss=$(grep VmRSS /proc/$pid/status 2>/dev/null | awk '{printf "%.0f", $2/1024}')
                    printf "%-15s %sMB\n" "$c" "${rss:-?}"
                fi
            done | sort -t'M' -k2 -rn | gum format
            ;;
    esac
}

# ═══════════════════════════════════════
# RADIO
# ═══════════════════════════════════════

radio_ops() {
    echo -e "${M}KPAB.FM${RST}"
    echo ""
    local action=$(gum choose \
        "Station status" \
        "Skip current track (mutiny)" \
        "Now playing" \
        "Restart AzuraCast" \
        "Back")
    case "$action" in
        *"status"*)
            docker ps --filter "name=azuracast" --format 'table {{.Names}}\t{{.Status}}'
            echo -e "${D}Stream: https://radio.quickcat.club${RST}"
            echo -e "${D}Admin:  https://kpab.fm/login${RST}"
            ;;
        *"Skip"*|*"mutiny"*)
            curl -s http://localhost:8090/skip 2>/dev/null && echo -e "${G}Track skipped!${RST}" || echo -e "${R}Skip failed${RST}"
            ;;
        *"Now playing"*)
            _now_playing
            ;;
        *"Restart"*)
            gum confirm "Restart AzuraCast?" && docker restart azuracast && echo -e "${G}Restarted${RST}"
            ;;
    esac
}

# ═══════════════════════════════════════
# MEDIA TOOLS
# ═══════════════════════════════════════

media_tools() {
    echo -e "${M}Media Tools${RST}"
    echo ""
    local action=$(gum choose \
        "Download URL (aria2/wget)" \
        "Internet Archive download" \
        "Add torrent" \
        "Disk usage (Passport)" \
        "Convert video (ffmpeg)" \
        "Back")
    case "$action" in
        *"Download URL"*)
            local url=$(gum input --placeholder "paste URL..." --width 70)
            [ -z "$url" ] && return
            local dest=$(gum choose "$PASSPORT/Downloads" "$PASSPORT/Music" "$PASSPORT/Movies" "/tmp")
            mkdir -p "$dest"
            if command -v aria2c &>/dev/null; then
                aria2c -x 16 -s 16 -d "$dest" -- "$url" && echo -e "${G}Downloaded to $dest${RST}" || echo -e "${R}Download failed${RST}"
            else
                wget -P "$dest" -- "$url" && echo -e "${G}Downloaded to $dest${RST}" || echo -e "${R}Download failed${RST}"
            fi
            ;;
        *"Internet Archive"*)
            local item=$(gum input --placeholder "archive.org item ID or URL..." --width 60)
            [ -z "$item" ] && return
            item=$(echo "$item" | sed 's|.*/details/||' | sed 's|/.*||')
            local dest="$PASSPORT/Downloads/archive"
            mkdir -p "$dest"
            echo -e "${D}Downloading $item to $dest...${RST}"
            ~/.local/bin/ia download "$item" --destdir="$dest" 2>&1 | tail -5
            echo -e "${G}Done${RST}"
            ;;
        *"torrent"*)
            local file=$(gum input --placeholder "path to .torrent file or magnet link..." --width 70)
            [ -z "$file" ] && return
            transmission-cli "$file" -w "$PASSPORT/Downloads" 2>&1
            ;;
        *"Disk usage"*)
            echo -e "${Y}Passport Drive:${RST}"
            df -h /media/pibulus/passport
            echo ""
            echo -e "${Y}Top folders:${RST}"
            du -sh /media/pibulus/passport/*/ 2>/dev/null | sort -rh | head -15
            ;;
        *"Convert"*)
            local src=$(gum file --height 15 /media/pibulus/passport)
            [ -z "$src" ] && return
            local fmt=$(gum choose "mp4 (H.264)" "mkv" "mp3 (audio only)" "wav")
            case "$fmt" in
                *mp4*) ffmpeg -i "$src" -c:v libx264 -crf 23 -c:a aac "${src%.*}.mp4" ;;
                *mkv*) ffmpeg -i "$src" -c copy "${src%.*}.mkv" ;;
                *mp3*) ffmpeg -i "$src" -vn -acodec libmp3lame -q:a 2 "${src%.*}.mp3" ;;
                *wav*) ffmpeg -i "$src" -vn "${src%.*}.wav" ;;
            esac
            echo -e "${G}Converted${RST}"
            ;;
    esac
}

# ═══════════════════════════════════════
# NOTES
# ═══════════════════════════════════════

quick_note() {
    echo -e "${M}Quick Note (saved to ~/notes/)${RST}"
    mkdir -p ~/notes
    local note=$(gum write --placeholder "write your note... (Ctrl+D to save)" --width 60 --height 8)
    [ -z "$note" ] && return
    local timestamp=$(date +%Y-%m-%d_%H%M)
    local title=$(gum input --placeholder "title (optional, Enter to skip)" --width 40)
    [ -z "$title" ] && title="note"
    # Sanitize title: only keep alphanumeric, spaces, hyphens
    local safe_title=$(echo "$title" | tr -cd '[:alnum:] -' | tr ' ' '-')
    local filename="$HOME/notes/${timestamp}_${safe_title}.md"
    echo "$note" > "$filename" && echo -e "${G}Saved: $filename${RST}" || echo -e "${R}Failed to save${RST}"
}

# ═══════════════════════════════════════
# FUN ZONE
# ═══════════════════════════════════════

fun_zone() {
    echo -e "${M}Fun Zone${RST}"
    echo ""
    local action=$(gum choose \
        "Random fact" \
        "Ask the oracle" \
        "What's playing on KPAB?" \
        "Cowsay wisdom" \
        "Matrix rain" \
        "Back")
    case "$action" in
        *"Random"*)
            gum spin --spinner dot --title "consulting the cosmos..." -- \
                aichat -- "Tell me one truly bizarre, obscure fact. Make it weird and wonderful. Max 3 sentences." > "$BISHOP_TMP" 2>&1
            gum format < "$BISHOP_TMP"
            ;;
        *"oracle"*)
            local q=$(gum input --placeholder "ask your question..." --width 50)
            [ -z "$q" ] && return
            gum spin --spinner dot --title "the oracle ponders..." -- \
                aichat --prompt "You are a mystical oracle. Answer questions cryptically but helpfully in 2-3 sentences." -- "$q" > "$BISHOP_TMP" 2>&1
            echo ""
            echo -e "${M}The oracle speaks:${RST}"
            gum format < "$BISHOP_TMP"
            ;;
        *"playing"*)
            _now_playing
            ;;
        *"Cowsay"*)
            if command -v cowsay &>/dev/null; then
                aichat -- "Give me a one-line piece of absurd wisdom, no quotes" 2>/dev/null | cowsay | lolcat -f
            else
                aichat -- "Give me a one-line piece of absurd wisdom" 2>/dev/null | figlet -f small | lolcat -f
            fi
            ;;
        *"Matrix"*)
            echo -e "${D}Press Ctrl+C to exit${RST}"
            if command -v cmatrix &>/dev/null; then
                cmatrix -b
            else
                while true; do printf "\033[32m%$((RANDOM % ${COLUMNS:-80}))s%s\n" "" "$((RANDOM % 2))"; sleep 0.02; done
            fi
            ;;
    esac
}

# ═══════════════════════════════════════
# SCAVENGER
# ═══════════════════════════════════════

scavenger() {
    echo -e "${M}SCAVENGER — Tell me what you want. I'll find it.${RST}"
    echo -e "${D}Uses AI to pick the right tool: Soulseek, yt-dlp, Internet Archive, torrents${RST}"
    echo ""

    local action=$(gum choose \
        "Smart search (AI picks the tool)" \
        "Soulseek search" \
        "yt-dlp (YouTube/audio)" \
        "Internet Archive" \
        "Pirate grab (movies/shows)" \
        "Back")

    case "$action" in
        *"Smart"*)
            local request=$(gum input --placeholder "what do you want? (e.g., 'Jung - Red Book', 'Laws of the Sun movie')" --width 70)
            [ -z "$request" ] && return

            echo -e "${D}thinking about the best approach...${RST}"
            local tool query
            if command -v claude &>/dev/null; then
                tool=$(claude -p --model haiku --no-session-persistence --max-budget-usd 0.02 \
                    --append-system-prompt "You are a tool selector. Respond with ONLY one word: soulseek, ytdlp, ia, pirate, or aria2. Rules: Music/albums/songs = soulseek. YouTube/video URLs = ytdlp. Books/ebooks/academic/PDF = ia. Movies/TV shows = pirate. Direct URLs = aria2." \
                    -- "$request" 2>/dev/null | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
                # Validate tool is one of the expected values
                case "$tool" in
                    soulseek|ytdlp|ia|pirate|aria2) ;;
                    *) tool="" ;;
                esac
                if [ -n "$tool" ]; then
                    query=$(claude -p --model haiku --no-session-persistence --max-budget-usd 0.02 \
                        --append-system-prompt "You craft search queries. Output ONLY the optimal search query — no explanation, no quotes." \
                        -- "Request: $request | Tool: $tool" 2>/dev/null)
                fi
            fi

            # Fallback: keyword heuristics
            if [ -z "$tool" ]; then
                case "$request" in
                    *youtube*|*youtu.be*|*soundcloud*|*http*) tool="ytdlp" ;;
                    *book*|*pdf*|*epub*|*ebook*|*archive*) tool="ia" ;;
                    *movie*|*film*|*season*|*episode*|*show*) tool="pirate" ;;
                    *) tool="soulseek" ;;
                esac
                query="$request"
            fi
            [ -z "$query" ] && query="$request"

            echo -e "${Y}Strategy: ${tool}${RST}"
            echo -e "${D}Query: ${query}${RST}"
            echo ""

            case "$tool" in
                soulseek) _scav_soulseek "$query" ;;
                ytdlp)    _scav_ytdlp "$query" ;;
                ia)       _scav_ia "$query" ;;
                pirate)   _scav_pirate "$query" ;;
                aria2)    _scav_aria2 "$query" ;;
            esac
            ;;

        *"Soulseek"*)
            local q=$(gum input --placeholder "search Soulseek..." --width 60)
            [ -n "$q" ] && _scav_soulseek "$q"
            ;;
        *"yt-dlp"*)
            local q=$(gum input --placeholder "YouTube URL or search..." --width 70)
            [ -n "$q" ] && _scav_ytdlp "$q"
            ;;
        *"Internet Archive"*)
            local q=$(gum input --placeholder "search Internet Archive..." --width 60)
            [ -n "$q" ] && _scav_ia "$q"
            ;;
        *"Pirate"*)
            local q=$(gum input --placeholder "movie or show name..." --width 60)
            [ -n "$q" ] && _scav_pirate "$q"
            ;;
    esac
}

_scav_soulseek() {
    local query="$1"
    echo -e "${C}Searching Soulseek: $query${RST}"

    local token=$(curl -s -X POST "http://localhost:5030/api/v0/session" \
        -H "Content-Type: application/json" \
        -d '{"username":"slskd","password":"slskd"}' 2>/dev/null \
        | python3 -c "import sys,json; print(json.load(sys.stdin).get('token',''))" 2>/dev/null)

    if [ -z "$token" ]; then
        echo -e "${R}slskd not responding. Is it running? (docker ps | grep slskd)${RST}"
        return
    fi

    # Build JSON safely with jq
    local payload
    if command -v jq &>/dev/null; then
        payload=$(jq -n --arg q "$query" '{"searchText": $q}')
    else
        payload="{\"searchText\":\"$(echo "$query" | sed 's/["\]/\\&/g')\"}"
    fi

    local search_id=$(curl -s -X POST "http://localhost:5030/api/v0/searches" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "$payload" 2>/dev/null \
        | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)

    if [ -z "$search_id" ]; then
        echo -e "${R}Search failed to start. slskd may be restarting.${RST}"
        return
    fi

    echo -e "${D}Searching the network (~12s)...${RST}"
    sleep 12

    # Use tab delimiter (safe for filenames) instead of |||
    local results=$(curl -s "http://localhost:5030/api/v0/searches/$search_id/responses" \
        -H "Authorization: Bearer $token" 2>/dev/null \
        | python3 -c "
import sys, json
data = json.load(sys.stdin)
for resp in data[:10]:
    user = resp.get('username', '?')
    for f in resp.get('files', [])[:3]:
        name = f.get('filename', '').split('\\\\')[-1]
        size = f.get('size', 0)
        size_mb = f'{size/1024/1024:.1f}MB' if size else '?'
        print(f'{name} ({size_mb}) from {user}\t{user}\t{f.get(\"filename\",\"\")}')
" 2>/dev/null)

    if [ -z "$results" ]; then
        echo -e "${Y}No results. Try different terms.${RST}"
        return
    fi

    local display=$(echo "$results" | cut -f1)
    local pick=$(echo "$display" | gum choose --height 15 --header "pick a file:")
    [ -z "$pick" ] && return

    # Find matching line with fixed-string grep
    local match=$(echo "$results" | grep -F "$pick" | head -1)
    local username=$(echo "$match" | cut -f2)
    local filepath=$(echo "$match" | cut -f3)

    if [ -n "$username" ] && [ -n "$filepath" ]; then
        # Build download JSON safely
        local dl_payload
        if command -v jq &>/dev/null; then
            dl_payload=$(jq -n --arg f "$filepath" '[{"filename": $f}]')
        else
            dl_payload="[{\"filename\":\"$(echo "$filepath" | sed 's/["\]/\\&/g')\"}]"
        fi
        curl -s -X POST "http://localhost:5030/api/v0/transfers/downloads/$username" \
            -H "Authorization: Bearer $token" \
            -H "Content-Type: application/json" \
            -d "$dl_payload" &>/dev/null
        echo -e "${G}Download queued! Check slskd at pibulus.local:5030${RST}"
        echo -e "${D}Downloads land in: $PASSPORT/Soulseek/${RST}"
    fi
}

_scav_ytdlp() {
    local query="$1"
    echo -e "${C}yt-dlp: $query${RST}"

    if ! command -v yt-dlp &>/dev/null; then
        echo -e "${R}yt-dlp not found${RST}"
        return
    fi

    local format=$(gum choose "Audio (mp3)" "Video (mp4)")
    local dest=$(gum choose "Music" "Movies" "Downloads")
    local DEST="$PASSPORT/$dest"
    mkdir -p "$DEST"

    case "$format" in
        *Audio*)
            echo -e "${D}Extracting audio...${RST}"
            yt-dlp -x --audio-format mp3 --audio-quality 0 -o "$DEST/%(title)s.%(ext)s" -- "$query" 2>&1 | tail -3
            ;;
        *Video*)
            echo -e "${D}Downloading video...${RST}"
            yt-dlp -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best' \
                -o "$DEST/%(title)s.%(ext)s" -- "$query" 2>&1 | tail -3
            ;;
    esac
    echo -e "${G}Saved to $DEST${RST}"
}

_scav_ia() {
    local query="$1"
    echo -e "${C}Searching Internet Archive: $query${RST}"

    local results=$(~/.local/bin/ia search "$query" --itemlist 2>/dev/null | head -15)
    if [ -z "$results" ]; then
        echo -e "${Y}No results on IA.${RST}"
        return
    fi

    local pick=$(echo "$results" | gum choose --height 15 --header "pick an item:")
    [ -z "$pick" ] && return

    ~/.local/bin/ia metadata "$pick" 2>/dev/null | python3 -c "
import sys, json
m = json.load(sys.stdin).get('metadata', {})
print(f\"Title: {m.get('title', '?')}\")
print(f\"Size: {int(m.get('item_size', 0))/1024/1024:.0f}MB\")
print(f\"Type: {m.get('mediatype', '?')}\")
" 2>/dev/null

    local dest=$(gum choose "Ebooks" "Music" "Movies" "Downloads")
    local DEST="$PASSPORT/$dest"
    mkdir -p "$DEST"

    if gum confirm "Download '$pick' to $dest?"; then
        echo -e "${D}Downloading...${RST}"
        ~/.local/bin/ia download "$pick" --destdir="$DEST" --no-directories 2>&1 | tail -5
        echo -e "${G}Downloaded to $DEST${RST}"
    fi
}

_scav_pirate() {
    local query="$1"
    echo -e "${C}Pirate grab: $query${RST}"

    local type=$(gum choose "Movie" "TV Show")
    case "$type" in
        *Movie*)
            python3 ~/pibulus-os/scripts/pirate_grab.py -- "$query" --movie --dry-run 2>&1 | gum format
            gum confirm "Download?" && python3 ~/pibulus-os/scripts/pirate_grab.py -- "$query" --movie 2>&1 | tail -5
            ;;
        *TV*)
            local season=$(gum input --placeholder "season number (e.g., 2)")
            [[ ! "$season" =~ ^[0-9]+$ ]] && echo -e "${R}Invalid season number.${RST}" && return
            python3 ~/pibulus-os/scripts/pirate_grab.py -- "$query" --season "$season" --dry-run 2>&1 | gum format
            gum confirm "Download?" && python3 ~/pibulus-os/scripts/pirate_grab.py -- "$query" --season "$season" 2>&1 | tail -5
            ;;
    esac
}

_scav_aria2() {
    local url="$1"
    echo -e "${C}Direct download: $url${RST}"
    local dest=$(gum choose "Downloads" "Music" "Movies" "Ebooks")
    local DEST="$PASSPORT/$dest"
    mkdir -p "$DEST"
    aria2c -x 16 -s 16 -d "$DEST" -- "$url" 2>&1 | tail -5
    echo -e "${G}Downloaded to $DEST${RST}"
}

# ═══════════════════════════════════════
# MAIN LOOP
# ═══════════════════════════════════════

while true; do
    header
    ACTION=$(gum choose --cursor.foreground 212 --header.foreground 214 \
        --header "what do you need?" \
        "Chat with Bishop" \
        "Execute commands" \
        "Analyze a file" \
        "System diagnostics" \
        "Docker operations" \
        "KPAB.FM radio" \
        "Scavenger (smart search)" \
        "Media & downloads" \
        "Quick note" \
        "Fun zone" \
        "Exit")

    case "$ACTION" in
        *"Chat"*)       chat_loop ;;
        *"Execute"*)    execute_mode ;;
        *"Analyze"*)    analyze_file ;;
        *"diagnostics"*)diagnose ;;
        *"Docker"*)     docker_ops ;;
        *"KPAB"*)       radio_ops ;;
        *"Scavenger"*)  scavenger ;;
        *"Media"*)      media_tools ;;
        *"note"*)       quick_note ;;
        *"Fun"*)        fun_zone ;;
        *"Exit"*)       break ;;
        "")             break ;;
    esac

    echo ""
    gum input --placeholder "Press Enter to continue..." > /dev/null 2>&1
done

echo ""
figlet -f small "later" 2>/dev/null | lolcat -f 2>/dev/null
