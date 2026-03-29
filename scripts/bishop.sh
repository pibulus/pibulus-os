#!/bin/bash
# bishop — AI chat with style
# Named after the old OpenClaw agent, reborn as a lightweight CLI wrapper

export GEMINI_API_KEY="${GEMINI_API_KEY:-AIzaSyBAScrXEbuOKBbNpIog02_tpcXuYdPXeO0}"

YELLOW='\033[1;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

# Header
figlet -f small "BISHOP" 2>/dev/null | lolcat -f 2>/dev/null
echo -e "${DIM}pibulus AI · gemini free tier · type 'quit' to exit${RESET}"
echo ""

# Mode selection
MODE=$(gum choose \
  "💬 Chat — ask anything" \
  "🔧 Execute — run commands on the Pi" \
  "📄 Analyze — feed a file" \
  "🔍 Diagnose — check system health" \
  "🎲 Surprise — random fun fact")

case "$MODE" in
  *"Chat"*)
    echo ""
    while true; do
      PROMPT=$(gum input --placeholder "ask bishop anything..." --width 60 --char-limit 500)
      [ -z "$PROMPT" ] && continue
      [ "$PROMPT" = "quit" ] && break
      echo ""
      echo -e "${CYAN}bishop:${RESET}"
      aichat "$PROMPT" 2>/dev/null | gum format
      echo ""
    done
    ;;

  *"Execute"*)
    echo ""
    echo -e "${YELLOW}⚡ Execute mode — bishop will write and run shell commands${RESET}"
    echo -e "${DIM}Describe what you want done in plain English${RESET}"
    echo ""
    while true; do
      PROMPT=$(gum input --placeholder "what should I do on the Pi?..." --width 60 --char-limit 500)
      [ -z "$PROMPT" ] && continue
      [ "$PROMPT" = "quit" ] && break
      echo ""
      echo -e "${CYAN}bishop is thinking...${RESET}"
      aichat -e "$PROMPT" 2>&1
      echo ""
    done
    ;;

  *"Analyze"*)
    echo ""
    FILE=$(gum file --height 15 .)
    [ -z "$FILE" ] && exit 0
    echo -e "${DIM}Selected: $FILE${RESET}"
    PROMPT=$(gum input --placeholder "what should I look for?" --width 60)
    [ -z "$PROMPT" ] && PROMPT="analyze this file and summarize what it does"
    echo ""
    echo -e "${CYAN}bishop:${RESET}"
    aichat -f "$FILE" "$PROMPT" 2>/dev/null | gum format
    ;;

  *"Diagnose"*)
    echo ""
    echo -e "${CYAN}bishop is checking the system...${RESET}"
    HEALTH=$(free -h && echo "---" && df -h / /media/pibulus/passport && echo "---" && docker ps --format 'table {{.Names}}\t{{.Status}}' && echo "---" && uptime && echo "---" && vcgencmd measure_temp 2>/dev/null)
    echo "$HEALTH" | aichat "You are a sysadmin assistant for a Raspberry Pi 5 home server. Analyze this system health data and give a brief status report with any concerns. Be concise and friendly:" 2>/dev/null | gum format
    ;;

  *"Surprise"*)
    echo ""
    echo -e "${CYAN}bishop:${RESET}"
    aichat "Tell me one fascinating, obscure fact I've probably never heard. Make it weird and wonderful. One paragraph max." 2>/dev/null | gum format
    ;;
esac

echo ""
figlet -f small "later" 2>/dev/null | lolcat -f 2>/dev/null
