#!/bin/bash
# ╔══════════════════════════════════════════╗
# ║  BISHOP — Pibulus AI Companion v2        ║
# ║  aichat + gum + the full Pi toolkit      ║
# ╚══════════════════════════════════════════╝

export GEMINI_API_KEY="${GEMINI_API_KEY:-AIzaSyBAScrXEbuOKBbNpIog02_tpcXuYdPXeO0}"

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
