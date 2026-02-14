#!/bin/bash
# 🦾 PIBULUS OS - WELCOME
# Greeting the human.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
[ -f "$SCRIPT_DIR/.env" ] && source "$SCRIPT_DIR/.env"

clear
if command -v figlet &> /dev/null; then
    figlet -f slant "PIBULUS" | lolcat
    echo "🦜 Welcome back, ${USER_NAME:-Captain}." | lolcat
    echo "🎮 Type 'deck' to take control."
    echo "🆘 Type 'halp' if you stuck."
    echo ""
fi
