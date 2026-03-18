#!/bin/bash
export TERM=xterm-256color

case "$TERM" in
  xterm-ghostty|xterm-kitty) export TERM=xterm-256color ;;
esac

get_status() {
  if docker ps --format '{{.Names}}' | grep -qx "$1"; then
    echo "🟢"
  else
    echo "🔴"
  fi
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
    "🌡️ $temp  |  🧠 $mem  |  🧵 load $load  |  📻 $(get_status azuracast) azuracast  |  🎵 $(get_status slskd) slskd"
}

tactile_choose() {
  gum choose "$@"
}

show_status() {
  vcgencmd measure_temp 2>/dev/null || true
  free -h
  df -h / /media/pibulus/passport 2>/dev/null || true
  echo
  docker ps --format 'table {{.Names}}\t{{.Status}}' | sed -n '1,25p'
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
    action=$(tactile_choose \
      '📡 Status' \
      '🏠 Home Mode' \
      '🧳 Away Mode' \
      'Back')

    case "$action" in
      '📡 Status') ~/pibulus-os/scripts/network_mode.sh status; gum input --placeholder 'Press Enter...' >/dev/null ;;
      '🏠 Home Mode') ~/pibulus-os/scripts/network_mode.sh home; gum input --placeholder 'Press Enter...' >/dev/null ;;
      '🧳 Away Mode') ~/pibulus-os/scripts/network_mode.sh away; gum input --placeholder 'Press Enter...' >/dev/null ;;
      'Back'|'') return ;;
    esac
  done
}

slskd_menu() {
  while true; do
    render_hud
    local action
    action=$(tactile_choose \
      '🎵 Start slskd' \
      '😴 Stop slskd' \
      '🔎 Status' \
      'Back')

    case "$action" in
      '🎵 Start slskd') docker start slskd; gum input --placeholder 'Press Enter...' >/dev/null ;;
      '😴 Stop slskd') docker stop slskd; gum input --placeholder 'Press Enter...' >/dev/null ;;
      '🔎 Status') docker ps --filter 'name=slskd' --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'; gum input --placeholder 'Press Enter...' >/dev/null ;;
      'Back'|'') return ;;
    esac
  done
}

if [[ "${1:-}" =~ ^(-h|--help|help)$ ]]; then
  cat <<'HELP'
PIBULUS DECK
Usage: deck [command]

  status        System status snapshot
  radio-status  AzuraCast status + recent logs
  network       Show network status
  away          Enable hotspot mode
  home          Disable hotspot and join home Wi-Fi
  slskd-on      Start slskd
  slskd-off     Stop slskd
  flush-ram     Drop caches
  deploy        Launch app deploy wizard
HELP
  exit 0
fi

case "${1:-}" in
  status) show_status; exit 0 ;;
  radio-status) radio_status; exit 0 ;;
  network) ~/pibulus-os/scripts/network_mode.sh status; exit 0 ;;
  away) ~/pibulus-os/scripts/network_mode.sh away; exit 0 ;;
  home) ~/pibulus-os/scripts/network_mode.sh home; exit 0 ;;
  slskd-on) docker start slskd; exit 0 ;;
  slskd-off) docker stop slskd; exit 0 ;;
  flush-ram) ~/pibulus-os/scripts/flush_ram.sh; exit 0 ;;
  deploy) ~/pibulus-os/scripts/deploy.sh; exit 0 ;;
esac

while true; do
  render_hud
  choice=$(tactile_choose \
    '📻 Radio Status' \
    '📡 Network Mode' \
    '🎵 Soulseek Wake/Sleep' \
    '🚀 Deploy App' \
    '🧠 Scavenger (AI Search)' \
    '🎲 Roguelike (NetHack)' \
    '🐉 MUD (Genesis)' \
    '📟 BBS (Dura-Europos)' \
    '💬 Chat (IRC)' \
    '🚪 Exit')

  case "$choice" in
    '📻 Radio Status') radio_status; gum input --placeholder 'Press Enter...' >/dev/null ;;
    '📡 Network Mode') network_menu ;;
    '🎵 Soulseek Wake/Sleep') slskd_menu ;;
    '🚀 Deploy App') ~/pibulus-os/scripts/deploy.sh ;;
    '🧠 Scavenger (AI Search)') source ~/pibulus-os/modules/scavenger_module.sh; manage_scavenger ;;
    '🎲 Roguelike (NetHack)') nethack || echo 'NetHack not installed.'; read -n 1 -s -r -p 'Press any key to return...' ;;
    '🐉 MUD (Genesis)') telnet genesismud.org 3030 ;;
    '📟 BBS (Dura-Europos)') telnet dura-europos.org ;;
    '💬 Chat (IRC)') irssi ;;
    '🚪 Exit'|'') clear; echo 'Neural link severed.'; exit 0 ;;
  esac

done
