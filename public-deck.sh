#!/bin/bash
# PUBLIC DECK — sandboxed game launcher for web visitors
export TERM=xterm-256color
export ZCODE_PATH=/usr/share/games/zcode

trap '' INT TSTP

show_banner() {
  clear
  gum style --border double --border-foreground 212 --padding '1 3' --margin '1 0' --align center     '📟 THE CYBERDECK'     ''     'BBS • MUDs • Roguelikes • Text Adventures'     'quickcat.club'
  echo
}

while true; do
  show_banner
  choice=$(gum choose --cursor.foreground 212 --selected.foreground 51     '🎲 NetHack — classic dungeon crawler'     '📖 Text Adventures — interactive fiction'     '🐉 Genesis MUD — multiplayer fantasy RPG'     '📟 Fozz BBS (Retro) — retro computing board'     '⭐ Star Wars — ASCII movie (telnet)'     '🚪 Disconnect')

  case "$choice" in
    *'NetHack'*)
      clear
      gum style --foreground 51 '=== NETHACK ==='
      echo 'Arrow keys to move. ? for help. q to save+quit.'
      echo
      gum confirm 'Ready to enter the dungeon?' && nethack
      ;;
    *'Text Adventures'*)
      clear
      GAMES_DIR=/usr/share/games/zcode
      gum style --foreground 51 '=== TEXT ADVENTURES ==='
      echo
      GAME=$(ls $GAMES_DIR/*.z* 2>/dev/null | while read f; do
        name=$(basename "$f" | sed 's/\.[^.]*$//')
        echo "$name"
      done | gum choose --cursor.foreground 212)
      if [ -n "$GAME" ]; then
        FILE=$(ls $GAMES_DIR/$GAME.* 2>/dev/null | head -1)
        if [ -n "$FILE" ]; then
          frotz "$FILE"
        fi
      fi
      ;;
    *'Genesis MUD'*)
      clear
      gum style --foreground 51 '=== GENESIS MUD ==='
      echo 'Type "quit" to disconnect'
      echo
      telnet genesismud.org 3030
      ;;
    *'Fozz'*)
      clear
      gum style --foreground 51 '=== FOZZ BBS ==='
      echo
      TERM=ansi telnet bbs.fozztexx.com
      ;;
    *'Star Wars'*)
      clear
      gum style --foreground 51 '=== STAR WARS — ASCII EDITION ==='
      echo 'Ctrl+] then "quit" to disconnect'
      echo
      telnet towel.blinkenlights.nl
      ;;
    *'Disconnect'*|'')
      clear
      gum style --foreground 212 'Neural link severed. Come back anytime.'
      sleep 2
      exit 0
      ;;
  esac
done
