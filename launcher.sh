#!/bin/bash

# Normalize terminal for Pi compatibility
case "$TERM" in
  xterm-ghostty|xterm-kitty) export TERM=xterm-256color ;;
  '') export TERM=xterm-256color ;;
esac

command -v gum >/dev/null 2>&1 || { echo "gum not found. Install: https://github.com/charmbracelet/gum"; exit 1; }

# Source modules for availability
[ -f ~/pibulus-os/modules/pirate_grab_module.sh ] && source ~/pibulus-os/modules/pirate_grab_module.sh
[ -f ~/pibulus-os/modules/scavenger_module.sh ] && source ~/pibulus-os/modules/scavenger_module.sh

get_status() {
  if docker ps --format '{{.Names}}' | grep -qx "$1"; then
    echo "🟢"
  else
    echo "🔴"
  fi
}

get_storage_bar() {
  local usage=$(df -h /media/pibulus/passport 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//')
  usage="${usage:-0}"
  local filled=$((usage / 10))
  local empty=$((10 - filled))
  local bar="["
  for ((i=0; i<filled; i++)); do bar+="■"; done
  for ((i=0; i<empty; i++)); do bar+="□"; done
  bar+="] $usage%"
  echo "$bar"
}

roll_fascination() {
  local roll=$(( ( RANDOM % 20 )  + 1 ))
  local interests=(
    "Amiga Demoscene Aesthetics" "Pastel-Punk Interface Design" "Palestine Solidarity Tech"
    "The Church of the SubGenius" "80/20 Compression Logic" "Vampire Coding Hours"
    "Garage Punk Energy" "Weaponized Simplicity" "Non-Scalable Software"
    "Retro BBS Culture" "Cyberdeck Hardware" "Low-Fi Social Networks"
    "The Magic of SQLite" "Deno vs Node Drama" "Utility-First CSS"
    "The Joy of Small Tools" "ADHD Project Hopping" "Mexican-Australian Fusion"
    "Analog Synth Patches" "The Mystery of the Nat 20"
  )
  echo "🎲 Roll: $roll | Today's Fascination: ${interests[$((roll-1))]}"
}

render_hud() {
  clear
  local temp="n/a"
  local load="$(uptime | awk -F'load average:' '{print $2}' | cut -d',' -f1 | xargs)"
  local mem="$(free -h | awk '/Mem:/ {print $7 " avail / " $2}')"

  if command -v vcgencmd >/dev/null 2>&1; then
    temp="$(vcgencmd measure_temp | cut -d'=' -f2)"
  fi

  gum style --border rounded --border-foreground 212 --padding '0 2' --margin '1 0' \
    "🌡️ $temp  |  🧠 $mem  |  🧵 load $load  |  💾 $(get_storage_bar)  |  📻 $(get_status azuracast) azuracast"
}

tactile_choose() {
  gum choose "$@"
}

radio_status() {
  docker ps --filter 'name=azuracast' --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
  echo
  docker logs --tail 20 azuracast 2>/dev/null || true
}

network_menu() {
  while true; do
    render_hud
    local action
    action=$(tactile_choose '📡 Status' '🏠 Home Mode' '🧳 Away Mode' 'Back')
    case "$action" in
      '📡 Status') ~/pibulus-os/scripts/network_mode.sh status; gum input --placeholder 'Enter...' >/dev/null ;;
      '🏠 Home Mode') ~/pibulus-os/scripts/network_mode.sh home; gum input --placeholder 'Enter...' >/dev/null ;;
      '🧳 Away Mode') ~/pibulus-os/scripts/network_mode.sh away; gum input --placeholder 'Enter...' >/dev/null ;;
      'Back'|'') return ;;
    esac
  done
}

slskd_menu() {
  while true; do
    render_hud
    local action
    action=$(tactile_choose '🎵 Start slskd' '😴 Stop slskd' '🔎 Status' 'Back')
    case "$action" in
      '🎵 Start slskd') docker start slskd; gum input --placeholder 'Enter...' >/dev/null ;;
      '😴 Stop slskd') docker stop slskd; gum input --placeholder 'Enter...' >/dev/null ;;
      '🔎 Status') docker ps --filter 'name=slskd' --format 'table {{.Names}}\t{{.Status}}'; gum input --placeholder 'Enter...' >/dev/null ;;
      'Back'|'') return ;;
    esac
  done
}

club_menu() {
  while true; do
    render_hud
    local action
    action=$(tactile_choose '➕ Add Club Member' '🔎 Check Counts' 'Back')
    case "$action" in
      '➕ Add Club Member')
        local name=$(gum input --placeholder 'Username...')
        [ -n "$name" ] && sudo python3 ~/pibulus-os/scripts/add_club_member.py "$name" && gum input --placeholder 'Enter...' >/dev/null ;;
      '🔎 Check Counts')
        echo 'Account Parity:'
        echo '  Jellyfin:    ' $(sudo sqlite3 /home/pibulus/.config/jellyfin/data/jellyfin.db 'SELECT COUNT(*) FROM Users')
        echo '  Calibre-web: ' $(sudo sqlite3 /home/pibulus/.config/calibre-web/app.db 'SELECT COUNT(*) FROM user')
        echo '  Kavita:      ' $(sudo sqlite3 /home/pibulus/.config/kavita/kavita.db 'SELECT COUNT(*) FROM AspNetUsers')
        echo '  Navidrome:   ' $(sudo sqlite3 /home/pibulus/.config/navidrome/navidrome.db 'SELECT COUNT(*) FROM user')
        gum input --placeholder 'Enter...' >/dev/null ;;
      'Back'|'') return ;;
    esac
  done
}

# STARTUP ROLL
render_hud
gum style --foreground 212 "$(roll_fascination)"
sleep 1.5

while true; do
  render_hud
  choice=$(tactile_choose \
    '📻 Radio Status' \
    '📡 Network Mode' \
    '🎵 Soulseek Wake/Sleep' \
    '🐱 Quick Cat Club (Identity)' \
    '🏴‍☠️ Pirate Grab (Media)' \
    '📂 Passport Navigator (Files)' \
    '🚀 Deploy App' \
    '🌐 Activate Domain' \
    '🧹 Flush RAM' \
    '🧠 Scavenger (AI Search)' \
    '🐉 Red Dragon BBS' \
    '📟 BBS: Dura-Europos' \
    '🎲 Roguelike (NetHack)' \
    '💬 Chat (IRC)' \
    '📖 Cheat Sheet' \
    '🚪 Exit')

  case "$choice" in
    '📻 Radio Status') radio_status; gum input --placeholder 'Enter...' >/dev/null ;;
    '📡 Network Mode') network_menu ;;
    '🎵 Soulseek Wake/Sleep') slskd_menu ;;
    '🐱 Quick Cat Club (Identity)') club_menu ;;
    '🏴‍☠️ Pirate Grab (Media)') manage_pirate_grab ;;
    '📂 Passport Navigator (Files)') nnn /media/pibulus/passport ;;
    '🚀 Deploy App') ~/pibulus-os/scripts/deploy.sh ;;
    '🌐 Activate Domain') ~/pibulus-os/scripts/deploy.sh ;;
    '🧹 Flush RAM') ~/pibulus-os/scripts/flush_ram.sh; gum input --placeholder 'RAM Purged. Enter...' >/dev/null ;;
    '🧠 Scavenger (AI Search)') manage_scavenger ;;
    '🐉 Red Dragon BBS') telnet darkrealms.ca ;;
    '📟 BBS: Dura-Europos') telnet dura-europos.org ;;
    '🎲 Roguelike (NetHack)') nethack || echo 'NetHack not installed.'; gum input --placeholder 'Enter...' >/dev/null ;;
    '💬 Chat (IRC)') irssi ;;
    '📖 Cheat Sheet') gum pager < ~/pibulus-os/FIELD_MANUAL.md ;;
    '🚪 Exit'|'') clear; echo 'Neural link severed.'; exit 0 ;;
  esac
done
