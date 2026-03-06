#!/bin/bash
# 🎸 PIBULUS DECK v1.1 - RAINBOW EDITION
export TERM=xterm-256color

# 🌈 Sick Intro
clear
if command -v figlet &>/dev/null && command -v lolcat &>/dev/null; then
    figlet -f slant "PIBULUS OS" | lolcat
    echo "----------------------------------------" | lolcat
else
    echo -e "\e[35mPIBULUS OS v4.2\e[0m"
fi

echo -e "\e[36mInitializing neural link...\e[0m"
sleep 1

while true; do
  clear
  echo -e "\e[35m"
  cat << "BANNER"
   ___ ___ ___ _   _ _    _   _ ___ 
  | _ \_ _| _ ) | | | |  | | | / __|
  |  _/| || _ \ |_| | |__| |_| \__   |_| |___|___/\___/|____|\___/|___/
          [ THE CYBERDECK ]
BANNER
  echo -e "\e[0m"

  CHOICE=$(gum choose --header "SELECT FREQUENCY" "[1] SCAVENGER (AI Search)" "[2] ROGUELIKE (NetHack)" "[3] MUD (Genesis)" "[4] BBS (Dura-Europos)" "[5] CHAT (IRC)" "[6] EXIT")

  case "$CHOICE" in
    *"SCAVENGER"*)
      echo "Activating Scavenger Bot..."
      source ~/pibulus-os/modules/scavenger_module.sh
      manage_scavenger
      ;;
    *"NetHack"*)
      echo "Loading dungeon..."
      nethack || echo "NetHack not installed."
      read -n 1 -s -r -p "Press any key to return..."
      ;;
    *"Genesis"*)
      echo "Connecting to Genesis MUD..."
      telnet genesismud.org 3030
      ;;
    *"BBS"*)
      echo "Connecting to Dura-Europos BBS..."
      telnet dura-europos.org
      ;;
    *"CHAT"*)
      echo "Connecting to IRC..."
      irssi
      ;;
    *"EXIT"*)
      clear
      echo "Neural link severed."
      exit 0
      ;;
  esac
done
