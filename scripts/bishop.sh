#!/bin/bash
# ╔══════════════════════════════════════════╗
# ║  BISHOP — Pibulus AI Companion v3        ║
# ║  aichat + gum + scavenger + Pi toolkit   ║
# ╚══════════════════════════════════════════╝

export GEMINI_API_KEY="${GEMINI_API_KEY:-AIzaSyBAScrXEbuOKBbNpIog02_tpcXuYdPXeO0}"
export PATH="$HOME/.local/bin:$PATH"
PASSPORT="/media/pibulus/passport"

# Colors
Y='\033[1;33m'; C='\033[0;36m'; M='\033[0;35m'; D='\033[2m'; G='\033[0;32m'
R='\033[0;31m'; W='\033[1;37m'; RST='\033[0m'

header() {
    clear
    figlet -f small "BISHOP" 2>/dev/null | lolcat -f 2>/dev/null
    echo -e "${D}pibulus AI companion · gemini · type 'quit' to exit${RST}"
    # Quick system pulse
    local mem=$(free -m | awk '/^Mem:/{printf "%d/%dMB", $3, $2}')
    local temp=$(vcgencmd measure_temp 2>/dev/null | cut -d= -f2 || echo "?")
    local containers=$(docker ps -q 2>/dev/null | wc -l)
    echo -e "${D}RAM: ${mem} · Temp: ${temp} · Containers: ${containers}${RST}"
    echo ""
}

chat_loop() {
    echo -e "${C}Chat mode — ask anything. Type 'quit' to return.${RST}"
    echo ""
    while true; do
        PROMPT=$(gum input --placeholder "ask bishop..." --width 60 --char-limit 500 \
            --prompt "▸ " --prompt.foreground 212)
        [ -z "$PROMPT" ] && continue
        [ "$PROMPT" = "quit" ] && return
        echo ""
        gum spin --spinner dot --title "thinking..." -- \
            bash -c "aichat '$PROMPT' > /tmp/bishop_reply.txt 2>&1"
        echo -e "${C}bishop:${RST}"
        cat /tmp/bishop_reply.txt | gum format
        echo ""
    done
}

execute_mode() {
    echo -e "${Y}⚡ Execute mode — describe tasks in plain English${RST}"
    echo -e "${D}bishop will write and run shell commands for you${RST}"
    echo ""
    while true; do
        PROMPT=$(gum input --placeholder "what should I do?..." --width 60 --char-limit 500 \
            --prompt "⚡ " --prompt.foreground 214)
        [ -z "$PROMPT" ] && continue
        [ "$PROMPT" = "quit" ] && return
        echo ""
        aichat -e "$PROMPT" 2>&1
        echo ""
    done
}

analyze_file() {
    echo -e "${C}📄 Pick a file to analyze${RST}"
    FILE=$(gum file --height 15 .)
    [ -z "$FILE" ] && return
    echo -e "${D}Selected: $FILE${RST}"
    PROMPT=$(gum input --placeholder "what should I look for? (or Enter for summary)" --width 60)
    [ -z "$PROMPT" ] && PROMPT="analyze this file, explain what it does, flag any issues"
    echo ""
    gum spin --spinner dot --title "analyzing..." -- \
        bash -c "aichat -f '$FILE' '$PROMPT' > /tmp/bishop_reply.txt 2>&1"
    echo -e "${C}bishop:${RST}"
    cat /tmp/bishop_reply.txt | gum format
}

diagnose() {
    echo -e "${G}🔍 Running system diagnostics...${RST}"
    echo ""
    HEALTH=$(
        echo "=== MEMORY ===" && free -h
        echo "=== DISK ===" && df -h / /media/pibulus/passport /media/pibulus/MEMBOT 2>/dev/null
        echo "=== TEMP ===" && vcgencmd measure_temp 2>/dev/null
        echo "=== UPTIME ===" && uptime
        echo "=== DOCKER ===" && docker ps --format 'table {{.Names}}\t{{.Status}}'
        echo "=== SWAP ===" && cat /proc/swaps
        echo "=== TOP RAM ===" && ps aux --sort=-%mem | head -8
    )
    gum spin --spinner dot --title "bishop is interpreting..." -- \
        bash -c "echo '$HEALTH' | aichat 'You are the sysadmin AI for a Raspberry Pi 5 home server called PIBULUS. Give a brief, friendly system health report. Flag anything concerning. Use emoji sparingly. Be concise.' > /tmp/bishop_reply.txt 2>&1"
    echo -e "${C}bishop:${RST}"
    cat /tmp/bishop_reply.txt | gum format
}

docker_ops() {
    echo -e "${M}🐳 Docker Operations${RST}"
    echo ""
    ACTION=$(gum choose \
        "📊 Container status" \
        "🔄 Restart a service" \
        "📋 View logs" \
        "🧹 Clean up (safe prune)" \
        "💾 Memory per container" \
        "Back")
    case "$ACTION" in
        *"status"*)
            docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | gum format
            ;;
        *"Restart"*)
            SVC=$(docker ps --format '{{.Names}}' | gum choose --header "pick a container:")
            [ -n "$SVC" ] && docker restart "$SVC" && echo -e "${G}✅ $SVC restarted${RST}"
            ;;
        *"logs"*)
            SVC=$(docker ps --format '{{.Names}}' | gum choose --header "pick a container:")
            [ -n "$SVC" ] && docker logs --tail 30 "$SVC" 2>&1 | gum pager
            ;;
        *"Clean"*)
            echo -e "${D}Preview:${RST}"
            docker system df
            echo ""
            gum confirm "Run safe prune? (removes dangling images, stopped containers)" && \
                docker system prune -f && echo -e "${G}✅ Cleaned${RST}"
            ;;
        *"Memory"*)
            for c in $(docker ps --format '{{.Names}}'); do
                pid=$(docker inspect --format '{{.State.Pid}}' "$c" 2>/dev/null)
                if [ -n "$pid" ] && [ "$pid" != "0" ]; then
                    rss=$(cat /proc/$pid/status 2>/dev/null | grep VmRSS | awk '{printf "%.0f", $2/1024}')
                    printf "%-15s %sMB\n" "$c" "${rss:-?}"
                fi
            done | sort -t'M' -k2 -rn | gum format
            ;;
    esac
}

radio_ops() {
    echo -e "${M}📻 KPAB.FM${RST}"
    echo ""
    ACTION=$(gum choose \
        "📊 Station status" \
        "⏭️  Skip current track (mutiny)" \
        "🎵 Now playing" \
        "🔄 Restart AzuraCast" \
        "Back")
    case "$ACTION" in
        *"status"*)
            docker ps --filter "name=azuracast" --format 'table {{.Names}}\t{{.Status}}'
            echo -e "${D}Stream: https://radio.quickcat.club${RST}"
            echo -e "${D}Admin:  https://kpab.fm/login${RST}"
            ;;
        *"Skip"*|*"mutiny"*)
            curl -s http://localhost:8090/skip 2>/dev/null && echo -e "${G}✅ Track skipped!${RST}" || echo -e "${R}❌ Skip failed${RST}"
            ;;
        *"Now playing"*)
            NP=$(curl -s 'http://localhost:8500/api/nowplaying/1' 2>/dev/null)
            TITLE=$(echo "$NP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['now_playing']['song']['title'])" 2>/dev/null)
            ARTIST=$(echo "$NP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['now_playing']['song']['artist'])" 2>/dev/null)
            [ -n "$TITLE" ] && echo -e "${Y}♪ $ARTIST — $TITLE${RST}" || echo -e "${D}couldn't fetch now playing${RST}"
            ;;
        *"Restart"*)
            gum confirm "Restart AzuraCast?" && docker restart azuracast && echo -e "${G}✅ Restarted${RST}"
            ;;
    esac
}

media_tools() {
    echo -e "${M}📥 Media Tools${RST}"
    echo ""
    ACTION=$(gum choose \
        "🔗 Download URL (aria2/wget)" \
        "📚 Internet Archive download" \
        "🧲 Add torrent" \
        "📁 Disk usage (Passport)" \
        "🎬 Convert video (ffmpeg)" \
        "Back")
    case "$ACTION" in
        *"Download URL"*)
            URL=$(gum input --placeholder "paste URL..." --width 70)
            [ -z "$URL" ] && return
            DEST=$(gum choose "/media/pibulus/passport/Downloads" "/media/pibulus/passport/Music" "/media/pibulus/passport/Movies" "/tmp")
            mkdir -p "$DEST"
            if command -v aria2c &>/dev/null; then
                aria2c -x 16 -s 16 -d "$DEST" "$URL"
            else
                wget -P "$DEST" "$URL"
            fi
            echo -e "${G}✅ Downloaded to $DEST${RST}"
            ;;
        *"Internet Archive"*)
            ITEM=$(gum input --placeholder "archive.org item ID or URL..." --width 60)
            [ -z "$ITEM" ] && return
            # Extract item ID from URL if needed
            ITEM=$(echo "$ITEM" | sed 's|.*/details/||' | sed 's|/.*||')
            DEST="/media/pibulus/passport/Downloads/archive"
            mkdir -p "$DEST"
            echo -e "${D}Downloading $ITEM to $DEST...${RST}"
            ~/.local/bin/ia download "$ITEM" --destdir="$DEST" 2>&1 | tail -5
            echo -e "${G}✅ Done${RST}"
            ;;
        *"torrent"*)
            FILE=$(gum input --placeholder "path to .torrent file or magnet link..." --width 70)
            [ -z "$FILE" ] && return
            DEST="/media/pibulus/passport/Downloads"
            transmission-cli "$FILE" -w "$DEST" 2>&1
            ;;
        *"Disk usage"*)
            echo -e "${Y}Passport Drive:${RST}"
            df -h /media/pibulus/passport
            echo ""
            echo -e "${Y}Top folders:${RST}"
            du -sh /media/pibulus/passport/*/ 2>/dev/null | sort -rh | head -15
            ;;
        *"Convert"*)
            SRC=$(gum file --height 15 /media/pibulus/passport)
            [ -z "$SRC" ] && return
            FORMAT=$(gum choose "mp4 (H.264)" "mkv" "mp3 (audio only)" "wav")
            case "$FORMAT" in
                *mp4*) ffmpeg -i "$SRC" -c:v libx264 -crf 23 -c:a aac "${SRC%.*}.mp4" ;;
                *mkv*) ffmpeg -i "$SRC" -c copy "${SRC%.*}.mkv" ;;
                *mp3*) ffmpeg -i "$SRC" -vn -acodec libmp3lame -q:a 2 "${SRC%.*}.mp3" ;;
                *wav*) ffmpeg -i "$SRC" -vn "${SRC%.*}.wav" ;;
            esac
            echo -e "${G}✅ Converted${RST}"
            ;;
    esac
}

quick_note() {
    echo -e "${M}📝 Quick Note (saved to ~/notes/)${RST}"
    mkdir -p ~/notes
    NOTE=$(gum write --placeholder "write your note... (Ctrl+D to save)" --width 60 --height 8)
    [ -z "$NOTE" ] && return
    TIMESTAMP=$(date +%Y-%m-%d_%H%M)
    TITLE=$(gum input --placeholder "title (optional, Enter to skip)" --width 40)
    [ -z "$TITLE" ] && TITLE="note"
    FILENAME="$HOME/notes/${TIMESTAMP}_${TITLE// /-}.md"
    echo "$NOTE" > "$FILENAME"
    echo -e "${G}✅ Saved: $FILENAME${RST}"
}

fun_zone() {
    echo -e "${M}🎲 Fun Zone${RST}"
    echo ""
    ACTION=$(gum choose \
        "🎲 Random fact" \
        "🔮 Ask the oracle" \
        "🎵 What's playing on KPAB?" \
        "🐄 Cowsay wisdom" \
        "🌧️ Matrix rain" \
        "Back")
    case "$ACTION" in
        *"Random"*)
            gum spin --spinner dot --title "consulting the cosmos..." -- \
                bash -c "aichat 'Tell me one truly bizarre, obscure fact. Make it weird and wonderful. Max 3 sentences.' > /tmp/bishop_reply.txt 2>&1"
            cat /tmp/bishop_reply.txt | gum format
            ;;
        *"oracle"*)
            Q=$(gum input --placeholder "ask your question..." --width 50)
            [ -z "$Q" ] && return
            gum spin --spinner dot --title "the oracle ponders..." -- \
                bash -c "aichat 'You are a mystical oracle. Answer this question cryptically but helpfully in 2-3 sentences: $Q' > /tmp/bishop_reply.txt 2>&1"
            echo ""
            echo -e "${M}The oracle speaks:${RST}"
            cat /tmp/bishop_reply.txt | gum format
            ;;
        *"playing"*)
            NP=$(curl -s 'http://localhost:8500/api/nowplaying/1' 2>/dev/null)
            TITLE=$(echo "$NP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['now_playing']['song']['title'])" 2>/dev/null)
            ARTIST=$(echo "$NP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['now_playing']['song']['artist'])" 2>/dev/null)
            [ -n "$TITLE" ] && echo -e "${Y}♪ $ARTIST — $TITLE${RST}" || echo "couldn't fetch"
            ;;
        *"Cowsay"*)
            if command -v cowsay &>/dev/null; then
                aichat "Give me a one-line piece of absurd wisdom, no quotes" 2>/dev/null | cowsay | lolcat -f
            else
                aichat "Give me a one-line piece of absurd wisdom" 2>/dev/null | figlet -f small | lolcat -f
            fi
            ;;
        *"Matrix"*)
            echo -e "${D}Press Ctrl+C to exit${RST}"
            if command -v cmatrix &>/dev/null; then
                cmatrix -b
            else
                # Poor man's matrix
                while true; do printf "\033[32m%$((RANDOM % COLUMNS))s%s\n" "" "$((RANDOM % 2))"; sleep 0.02; done
            fi
            ;;
    esac
}

scavenger() {
    echo -e "${M}🤖 SCAVENGER — Tell me what you want. I'll find it.${RST}"
    echo -e "${D}Uses AI to pick the right tool: Soulseek, yt-dlp, Internet Archive, torrents${RST}"
    echo ""

    ACTION=$(gum choose \
        "🧠 Smart search (AI picks the tool)" \
        "🎵 Soulseek search" \
        "📹 yt-dlp (YouTube/audio)" \
        "📚 Internet Archive" \
        "🏴 Pirate grab (movies/shows)" \
        "Back")

    case "$ACTION" in
        *"Smart"*)
            REQUEST=$(gum input --placeholder "what do you want? (e.g., 'Jung - Red Book', 'Laws of the Sun movie')" --width 70)
            [ -z "$REQUEST" ] && return

            # AI decides tool
            echo -e "${D}thinking about the best approach...${RST}"
            if command -v claude &>/dev/null; then
                TOOL=$(claude -p --model haiku --no-session-persistence --max-budget-usd 0.02 \
                    --append-system-prompt "You are a tool selector. Respond with ONLY one word: soulseek, ytdlp, ia, pirate, or aria2. Rules: Music/albums/songs = soulseek. YouTube/video URLs = ytdlp. Books/ebooks/academic/PDF = ia. Movies/TV shows = pirate. Direct URLs = aria2." \
                    "$REQUEST" 2>/dev/null | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
                QUERY=$(claude -p --model haiku --no-session-persistence --max-budget-usd 0.02 \
                    --append-system-prompt "You craft search queries. Output ONLY the optimal search query — no explanation, no quotes." \
                    "Request: $REQUEST | Tool: $TOOL" 2>/dev/null)
            else
                # Fallback: keyword heuristics
                case "$REQUEST" in
                    *youtube*|*youtu.be*|*soundcloud*|*http*) TOOL="ytdlp" ;;
                    *book*|*pdf*|*epub*|*ebook*|*archive*) TOOL="ia" ;;
                    *movie*|*film*|*season*|*episode*|*show*) TOOL="pirate" ;;
                    *) TOOL="soulseek" ;;
                esac
                QUERY="$REQUEST"
            fi

            echo -e "${Y}Strategy: ${TOOL}${RST}"
            echo -e "${D}Query: ${QUERY}${RST}"
            echo ""

            case "$TOOL" in
                soulseek)
                    _scav_soulseek "$QUERY" ;;
                ytdlp)
                    _scav_ytdlp "$QUERY" ;;
                ia)
                    _scav_ia "$QUERY" ;;
                pirate)
                    _scav_pirate "$QUERY" ;;
                aria2)
                    _scav_aria2 "$QUERY" ;;
                *)
                    echo -e "${R}Couldn't decide. Try a direct search.${RST}" ;;
            esac
            ;;

        *"Soulseek"*)
            Q=$(gum input --placeholder "search Soulseek..." --width 60)
            [ -n "$Q" ] && _scav_soulseek "$Q"
            ;;
        *"yt-dlp"*)
            Q=$(gum input --placeholder "YouTube URL or search..." --width 70)
            [ -n "$Q" ] && _scav_ytdlp "$Q"
            ;;
        *"Internet Archive"*)
            Q=$(gum input --placeholder "search Internet Archive..." --width 60)
            [ -n "$Q" ] && _scav_ia "$Q"
            ;;
        *"Pirate"*)
            Q=$(gum input --placeholder "movie or show name..." --width 60)
            [ -n "$Q" ] && _scav_pirate "$Q"
            ;;
    esac
}

_scav_soulseek() {
    local query="$1"
    echo -e "${C}🎵 Searching Soulseek: $query${RST}"

    # Auth with slskd
    local token=$(curl -s -X POST "http://localhost:5030/api/v0/session" \
        -H "Content-Type: application/json" \
        -d '{"username":"slskd","password":"slskd"}' 2>/dev/null \
        | python3 -c "import sys,json; print(json.load(sys.stdin).get('token',''))" 2>/dev/null)

    if [ -z "$token" ]; then
        echo -e "${R}slskd not responding. Is it running? (docker ps | grep slskd)${RST}"
        return
    fi

    # Start search
    local search_id=$(curl -s -X POST "http://localhost:5030/api/v0/searches" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "{\"searchText\":\"$query\"}" 2>/dev/null \
        | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)

    echo -e "${D}Searching the network (~12s)...${RST}"
    sleep 12

    # Get results
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
        print(f'{name} ({size_mb}) from {user}|||{user}|||{f.get(\"filename\",\"\")}')
" 2>/dev/null)

    if [ -z "$results" ]; then
        echo -e "${Y}No results. Try different terms.${RST}"
        return
    fi

    # Show display names for picking
    local display=$(echo "$results" | cut -d'|' -f1)
    local pick=$(echo "$display" | gum choose --height 15 --header "pick a file:")
    [ -z "$pick" ] && return

    # Find matching line and download
    local match=$(echo "$results" | grep "^${pick}|||" | head -1)
    local username=$(echo "$match" | cut -d'|' -f4)
    local filepath=$(echo "$match" | cut -d'|' -f7)

    if [ -n "$username" ] && [ -n "$filepath" ]; then
        curl -s -X POST "http://localhost:5030/api/v0/transfers/downloads/$username" \
            -H "Authorization: Bearer $token" \
            -H "Content-Type: application/json" \
            -d "[{\"filename\":\"$filepath\"}]" &>/dev/null
        echo -e "${G}✅ Download queued! Check slskd at pibulus.local:5030${RST}"
        echo -e "${D}Downloads land in: $PASSPORT/Soulseek/${RST}"
    fi
}

_scav_ytdlp() {
    local query="$1"
    echo -e "${C}📹 yt-dlp: $query${RST}"

    if ! command -v yt-dlp &>/dev/null; then
        echo -e "${R}yt-dlp not found${RST}"
        return
    fi

    local format=$(gum choose "🎵 Audio (mp3)" "📹 Video (mp4)")
    local dest=$(gum choose "Music" "Movies" "Downloads")
    local DEST="$PASSPORT/$dest"
    mkdir -p "$DEST"

    case "$format" in
        *Audio*)
            echo -e "${D}Extracting audio...${RST}"
            yt-dlp -x --audio-format mp3 --audio-quality 0 -o "$DEST/%(title)s.%(ext)s" "$query" 2>&1 | tail -3
            ;;
        *Video*)
            echo -e "${D}Downloading video...${RST}"
            yt-dlp -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best' \
                -o "$DEST/%(title)s.%(ext)s" "$query" 2>&1 | tail -3
            ;;
    esac
    echo -e "${G}✅ Saved to $DEST${RST}"
}

_scav_ia() {
    local query="$1"
    echo -e "${C}📚 Searching Internet Archive: $query${RST}"

    local results=$(~/.local/bin/ia search "$query" --itemlist 2>/dev/null | head -15)
    if [ -z "$results" ]; then
        echo -e "${Y}No results on IA.${RST}"
        return
    fi

    local pick=$(echo "$results" | gum choose --height 15 --header "pick an item:")
    [ -z "$pick" ] && return

    # Show details
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
        echo -e "${G}✅ Downloaded to $DEST${RST}"
    fi
}

_scav_pirate() {
    local query="$1"
    echo -e "${C}🏴 Pirate grab: $query${RST}"

    local type=$(gum choose "🎬 Movie" "📺 TV Show")
    case "$type" in
        *Movie*)
            python3 ~/pibulus-os/scripts/pirate_grab.py "$query" --movie --dry-run 2>&1 | gum format
            gum confirm "Download?" && python3 ~/pibulus-os/scripts/pirate_grab.py "$query" --movie 2>&1 | tail -5
            ;;
        *TV*)
            local season=$(gum input --placeholder "season number (e.g., 2)")
            [ -z "$season" ] && return
            python3 ~/pibulus-os/scripts/pirate_grab.py "$query" --season "$season" --dry-run 2>&1 | gum format
            gum confirm "Download?" && python3 ~/pibulus-os/scripts/pirate_grab.py "$query" --season "$season" 2>&1 | tail -5
            ;;
    esac
}

_scav_aria2() {
    local url="$1"
    echo -e "${C}⬇️ Direct download: $url${RST}"
    local dest=$(gum choose "Downloads" "Music" "Movies" "Ebooks")
    local DEST="$PASSPORT/$dest"
    mkdir -p "$DEST"
    aria2c -x 16 -s 16 -d "$DEST" "$url" 2>&1 | tail -5
    echo -e "${G}✅ Downloaded to $DEST${RST}"
}

# ═══════════════════════════════════════
# MAIN LOOP
# ═══════════════════════════════════════

while true; do
    header
    ACTION=$(gum choose --cursor.foreground 212 --header.foreground 214 \
        --header "what do you need?" \
        "💬 Chat with Bishop" \
        "⚡ Execute commands" \
        "📄 Analyze a file" \
        "🔍 System diagnostics" \
        "🐳 Docker operations" \
        "📻 KPAB.FM radio" \
        "🤖 Scavenger (smart search)" \
        "📥 Media & downloads" \
        "📝 Quick note" \
        "🎲 Fun zone" \
        "👋 Exit")

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
