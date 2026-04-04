#!/bin/bash
# PUBLIC DECK — sandboxed game launcher for web visitors
export TERM=xterm-256color
export ZCODE_PATH=/usr/share/games/zcode

trap '' INT TSTP

show_banner() {
  clear
  figlet -f small "TEXTWORLDS" | lolcat
  printf '  BBS  •  MUDs  •  Roguelikes  •  Text Adventures  \n' | lolcat
  printf '             quickcat.club\n\n' | lolcat
}

while true; do
  show_banner
  choice=$(gum choose \
    --cursor.foreground 212 \
    --selected.foreground 51 \
    '⚔️  NetHack — classic ASCII dungeon crawler' \
    '📖  Text Adventures — interactive fiction' \
    '🐉  Aardwolf MUD — one of the largest MUDs online' \
    '⚔️  Realms of Despair — classic DIKU MUD (1994)' \
    '📟  Fozz BBS — retro computing bulletin board' \
    '🐺  BatMUD — Finnish MUD, running since 1990' \
    '🚪  Disconnect')

  case "$choice" in
    *'NetHack'*)
      clear
      printf 'NETHACK\n' | figlet -f small | lolcat
      echo 'Arrow keys to move. ? for help. q to save+quit.'
      echo
      gum confirm 'Ready to enter the dungeon?' && nethack
      ;;
    *'Text Adventures'*)
      clear
      printf 'TEXT ADVENTURES\n' | figlet -f small | lolcat
      echo
      GAMES_DIR=/usr/share/games/zcode
      GAME=$(ls "$GAMES_DIR"/*.z* 2>/dev/null | while read -r f; do
        basename "$f" | sed 's/\.[^.]*$//'
      done | gum choose --cursor.foreground 212)
      if [ -n "$GAME" ]; then
        FILE=$(ls "$GAMES_DIR/$GAME".* 2>/dev/null | head -1)
        [ -n "$FILE" ] && frotz "$FILE"
      fi
      ;;
    *'Aardwolf'*)
      clear
      printf 'AARDWOLF MUD\n' | figlet -f small | lolcat
      echo 'Type "quit" to disconnect. New players: type "new" at the prompt.'
      echo
      telnet aardmud.org 4000
      ;;
    *'Realms of Despair'*)
      clear
      printf 'REALMS OF DESPAIR\n' | figlet -f small | lolcat
      echo 'Type "quit" to disconnect. Classic DIKU MUD since 1994.'
      echo
      telnet realmsofdespair.com 4000
      ;;
    *'Fozz'*)
      clear
      printf 'FOZZ BBS\n' | figlet -f small | lolcat
      echo
      TERM=ansi telnet bbs.fozztexx.com
      ;;
    *'BatMUD'*)
      clear
      printf 'BATMUD\n' | figlet -f small | lolcat
      echo 'Type "quit" to disconnect. New players: type "create" at the prompt.'
      echo
      telnet bat.org
      ;;
    *'Disconnect'*|'')
      clear
      printf 'NEURAL LINK SEVERED\n' | figlet -f small | lolcat
      echo
      gum style --foreground 212 --align center 'Come back anytime. =^..^='
      sleep 2
      exit 0
      ;;
  esac
done
