#!/bin/bash
# 🤖 BISHOP - CYBERDECK GREETING v4.2 (DYNAMIC)

clear
# Main Banner
figlet -f slant "PIBULUS" | lolcat
echo -e "$(gum style --foreground 212 "[ SYNTHETIC OPERATIVE BISHOP ACTIVE ]")"
echo ""

# Data Gathering
TEMP=$(vcgencmd measure_temp | cut -d'=' -f2)
DISK=$(df -h /media/pibulus/passport | awk 'NR==2 {print $5}')
RAM=$(free -h | awk '/Mem:/ {print $3 " / " $2}')
IP=$(hostname -I | awk '{print $1}')
UP=$(uptime -p | sed 's/up //')
TIME=$(date '+%H:%M:%S')

# Horizontal Stats Strip
gum join --horizontal \
    "$(gum style --border normal --padding "0 2" --border-foreground 46 --foreground 46 "🌡️ $TEMP")" \
    "$(gum style --border normal --padding "0 2" --border-foreground 51 --foreground 51 "📼 DISK $DISK")" \
    "$(gum style --border normal --padding "0 2" --border-foreground 226 --foreground 226 "🧠 RAM $RAM")" \
    "$(gum style --border normal --padding "0 2" --border-foreground 212 --foreground 212 "⏲️  $TIME")"

echo ""
echo -e "🐾 $(gum style --foreground 46 "STATUS: SYSTEM NOMINAL")  |  📡 IP: $IP  |  🆙 UP: $UP"
echo "----------------------------------------------------------------------"

# Port overrides for services where auto-detect picks wrong port
# (AzuraCast grabs SFTP 2022 instead of web 8500, Jellyfin binds oddly)
declare -A PORT_OVERRIDE=(
    ["azuracast"]="8500"
    ["jellyfin"]="8096"
)

# Services to hide (not web-facing or not useful to show)
HIDE_PATTERN="updater|_db|icloudpd"

# Service Map (Multi-column)
echo -e "🌐 $(gum style --foreground 51 "Live Service Map:")"
count=0
docker ps --format "{{.Names}}\t{{.Ports}}" | grep -v "NAMES" | grep -vE "$HIDE_PATTERN" | while read line; do
    name=$(echo $line | awk '{print $1}')

    # Check for port override first
    if [[ -n "${PORT_OVERRIDE[$name]}" ]]; then
        port="${PORT_OVERRIDE[$name]}"
    else
        # Extract the public-facing port (e.g., the 8090 in 0.0.0.0:8090->80/tcp)
        port=$(echo $line | grep -oE '0\.0\.0\.0:[0-9]+->' | cut -d':' -f2 | cut -d'-' -f1 | head -n 1)
    fi

    if [ ! -z "$port" ]; then
        printf "   %-15s -> http://%s:%-5s  " "$name" "$IP" "$port"
        ((count++))
        if (( count % 2 == 0 )); then echo ""; fi
    fi
done
echo ""

echo ""
# Command Bar
gum style --foreground 212 --bold "COMMANDS:"
echo -e "  $(gum style --foreground 46 "deck") (Console)  |  $(gum style --foreground 51 "help") (Field Manual)  |  $(gum style --foreground 196 "bunker") (Lockdown)"
echo ""
