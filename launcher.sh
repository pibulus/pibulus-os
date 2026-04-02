#!/bin/bash

# Normalize terminal for Pi compatibility
case "$TERM" in
  xterm-ghostty|xterm-kitty) export TERM=xterm-256color ;;
  '') export TERM=xterm-256color ;;
esac

command -v gum >/dev/null 2>&1 || { echo "gum not found. Install: https://github.com/charmbracelet/gum"; exit 1; }

SERVICE_REGISTRY="${SERVICE_REGISTRY:-$HOME/pibulus-os/config/service-registry.json}"
PASSPORT_ROOT="${PASSPORT_ROOT:-/media/pibulus/passport}"

# Source modules for availability
[ -f ~/pibulus-os/modules/pirate_grab_module.sh ] && source ~/pibulus-os/modules/pirate_grab_module.sh
[ -f ~/pibulus-os/modules/scavenger_module.sh ] && source ~/pibulus-os/modules/scavenger_module.sh
[ -f ~/pibulus-os/modules/audio_feedback.sh ] && source ~/pibulus-os/modules/audio_feedback.sh

get_status() {
  if docker ps --format '{{.Names}}' | grep -qx "$1"; then
    echo "🟢"
  else
    echo "🔴"
  fi
}

pause_screen() {
  gum input --placeholder 'Press Enter to continue...' >/dev/null
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
  echo "KPAB public:"
  service_line radio_site
  service_line radio_stream
  service_line radio_admin
  echo
  echo "Live stack:"
  docker ps --filter 'name=azuracast' --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
  echo
  echo "Recent AzuraCast log tail:"
  docker logs --tail 20 azuracast 2>/dev/null || true
}

service_line() {
  local key="$1"
  python3 - "$SERVICE_REGISTRY" "$key" <<'PY'
import json, sys

path, key = sys.argv[1], sys.argv[2]
data = json.load(open(path))
for service in data.get("services", []):
    if service.get("key") == key:
        print(f"  {service['name']:<14} -> {service['url']}")
        raise SystemExit(0)
print(f"  {key:<14} -> missing from registry")
PY
}

show_public_links() {
  python3 - "$SERVICE_REGISTRY" <<'PY'
import json, sys

data = json.load(open(sys.argv[1]))
print("Public front doors")
for service in data.get("services", []):
    if service.get("category") not in {"public", "admin", "private"}:
        continue
    name = service.get("name", "unknown")
    url = service.get("url", "")
    desc = service.get("description", "")
    print(f"  {name:<14} {url:<32} {desc}")
PY
}

show_radio_snapshot() {
  python3 - <<'PY'
import json, urllib.request

try:
    data = json.load(urllib.request.urlopen("http://localhost:8500/api/nowplaying/kpab.fm", timeout=3))
except Exception as exc:
    print(f"Could not reach AzuraCast API: {exc}")
    raise SystemExit(0)

listeners = data.get("listeners", {})
now_playing = data.get("now_playing", {}).get("song", {})
playing_next = data.get("playing_next", {}).get("song", {})

print("Now playing:")
print(f"  {now_playing.get('artist', 'Unknown')} — {now_playing.get('title', 'Unknown')}")
print("Next up:")
print(f"  {playing_next.get('artist', 'Unknown')} — {playing_next.get('title', 'Unknown')}")
print("Listeners:")
print(f"  {listeners.get('current', 0)} live / {listeners.get('unique', 0)} unique")
PY
}

show_public_ip() {
  local public_ip local_ips
  public_ip="$(curl -fsS https://1.1.1.1/cdn-cgi/trace 2>/dev/null | awk -F= '/^ip=/{print $2}')"
  local_ips="$(hostname -I 2>/dev/null | xargs)"

  echo "This box on the internet:"
  echo "  ${public_ip:-Could not detect public IP}"
  echo
  echo "Local network addresses:"
  echo "  ${local_ips:-Could not detect LAN IPs}"
  echo
  echo "Tip:"
  echo "  Start the stream, then match this public IP + your device/browser"
  echo "  against the newest listener row in AzuraCast."
}

media_finder_menu() {
  local query
  query=$(gum input --placeholder "Find local media (e.g. valis philip k dick)")
  [ -z "$query" ] && return

  local finder="$HOME/pibulus-os/scripts/find_media.py"
  if [ ! -f "$finder" ]; then
    echo "Media finder not installed."
    pause_screen
    return
  fi

  local json
  json=$(python3 "$finder" --json --limit 20 -- "$query" 2>/dev/null)
  if [ -z "$json" ]; then
    echo "No local matches."
    pause_screen
    return
  fi

  local count
  count=$(printf '%s' "$json" | python3 -c 'import sys,json; print(len(json.load(sys.stdin).get("results", [])))')
  if [ "$count" -eq 0 ]; then
    echo "No local matches."
    pause_screen
    return
  fi

  local options
  options=$(printf '%s' "$json" | python3 -c '
import sys, json
data = json.load(sys.stdin)
for item in data.get("results", []):
    print(f"[{item['label']}] {item['name']} :: {item['parent']}")
')

  local pick
  pick=$(printf '%s\n' "$options" | gum choose --height 18)
  [ -z "$pick" ] && return

  local target_dir
  target_dir=$(printf '%s\n' "$pick" | awk -F" :: " '{print $2}')
  [ -z "$target_dir" ] && return

  nnn "$target_dir"
}

connect_text_world() {
  local label="$1"
  local host="$2"
  local port="${3:-23}"

  clear
  echo "Connecting to $label..."
  echo "Host: $host:$port"
  echo "Terminal mode: vt100"
  echo "Exit telnet with Ctrl + ]"
  echo
  TERM=vt100 telnet "$host" "$port"
}

network_menu() {
  while true; do
    render_hud
    local action
    action=$(tactile_choose '📡 Show Network Status' '🏠 Home Wi-Fi Mode' '🧳 Hotspot / Away Mode' 'Back')
    case "$action" in
      '📡 Show Network Status') ~/pibulus-os/scripts/network_mode.sh status; pause_screen ;;
      '🏠 Home Wi-Fi Mode') ~/pibulus-os/scripts/network_mode.sh home; pause_screen ;;
      '🧳 Hotspot / Away Mode') ~/pibulus-os/scripts/network_mode.sh away; pause_screen ;;
      'Back'|'') return ;;
    esac
  done
}

slskd_menu() {
  while true; do
    render_hud
    local action
    action=$(tactile_choose '🎵 Wake Soulseek' '😴 Sleep Soulseek' '🔎 Show Soulseek Status' 'Back')
    case "$action" in
      '🎵 Wake Soulseek') docker start slskd; pause_screen ;;
      '😴 Sleep Soulseek') docker stop slskd; pause_screen ;;
      '🔎 Show Soulseek Status') docker ps --filter 'name=slskd' --format 'table {{.Names}}\t{{.Status}}'; pause_screen ;;
      'Back'|'') return ;;
    esac
  done
}

club_menu() {
  while true; do
    render_hud
    local action
    action=$(tactile_choose '➕ Add Club Member' '🔎 Audit Account Parity' 'Back')
    case "$action" in
      '➕ Add Club Member')
        local name=$(gum input --placeholder 'Username...')
        [ -n "$name" ] && sudo python3 ~/pibulus-os/scripts/add_club_member.py "$name" && pause_screen ;;
      '🔎 Audit Account Parity')
        python3 ~/pibulus-os/scripts/account_parity_audit.py
        pause_screen ;;
      'Back'|'') return ;;
    esac
  done
}

radio_menu() {
  while true; do
    render_hud
    local action
    action=$(tactile_choose '📻 Show Radio Snapshot' '🪪 Show My Public IP' '🛰️ Show Radio Service Status' '🌐 Show Public Links' 'Back')
    case "$action" in
      '📻 Show Radio Snapshot')
        show_radio_snapshot
        pause_screen ;;
      '🪪 Show My Public IP')
        show_public_ip
        pause_screen ;;
      '🛰️ Show Radio Service Status')
        radio_status
        pause_screen ;;
      '🌐 Show Public Links')
        show_public_links
        pause_screen ;;
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
  choice=$(tactile_choose --height 20 \
    '📻 KPAB Radio' \
    '🌐 Public Links' \
    '📡 Network Modes' \
    '🎵 Soulseek' \
    '🐱 Club Accounts' \
    '🔎 Find My Media' \
    '🏴‍☠️ Media Grab' \
    '📂 Browse Passport Drive' \
    '🚀 Deploy Something New' \
    '🧹 Flush RAM' \
    '🧠 Scavenger Search' \
    '🐉 Dark Realms MUD' \
    '📟 Fozz BBS' \
    '🎲 NetHack' \
    '💬 IRC Chat' \
    '📖 Field Manual' \
    '🚪 Exit')

  case "$choice" in
    '📻 KPAB Radio') radio_menu ;;
    '🌐 Public Links') show_public_links; pause_screen ;;
    '📡 Network Modes') network_menu ;;
    '🎵 Soulseek') slskd_menu ;;
    '🐱 Club Accounts') club_menu ;;
    '🔎 Find My Media') media_finder_menu ;;
    '🏴‍☠️ Media Grab') manage_pirate_grab ;;
    '📂 Browse Passport Drive') nnn /media/pibulus/passport ;;
    '🚀 Deploy Something New') ~/pibulus-os/scripts/deploy.sh ;;
    '🧹 Flush RAM') ~/pibulus-os/scripts/flush_ram.sh; pause_screen ;;
    '🧠 Scavenger Search') manage_scavenger ;;
    '🐉 Dark Realms MUD') connect_text_world 'Dark Realms' 'darkrealms.ca' '23' ;;
    '📟 Fozz BBS') connect_text_world 'Fozz BBS' 'bbs.fozztexx.com' '23' ;;
    '🎲 NetHack') nethack || { echo 'NetHack not installed.'; pause_screen; } ;;
    '💬 IRC Chat') irssi ;;
    '📖 Field Manual') gum pager < ~/pibulus-os/FIELD_MANUAL.md ;;
    '🚪 Exit'|'') clear; echo 'Neural link severed.'; exit 0 ;;
  esac
done
