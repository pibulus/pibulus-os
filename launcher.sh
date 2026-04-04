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

rainbow() {
  if command -v lolcat >/dev/null 2>&1; then
    lolcat
  else
    cat
  fi
}

print_logo() {
  if command -v figlet >/dev/null 2>&1; then
    figlet -f small "QUICK CAT DECK" | rainbow
  else
    printf 'QUICK CAT DECK\n' | rainbow
  fi
}

print_statusline() {
  printf '%s\n' ':: quick cat club :: admin node ::' | rainbow
}

print_header() {
  local title="$1"
  gum style --foreground 212 --bold "$title"
  echo
}


show_section_intro() {
  local title="$1"
  local body="$2"
  gum style --border normal --border-foreground 240 --padding '0 1' --margin '0 0' \
    "$title" \
    "$body"
  echo
}

get_status() {
  if [ "$1" = "cloudflared" ]; then
    if systemctl is-active --quiet cloudflared 2>/dev/null; then
      echo "🟢"
    else
      echo "🔴"
    fi
    return
  fi
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

  print_logo
  print_statusline
  echo
  gum style --border rounded --border-foreground 212 --padding '0 1' --margin '0 0' \
    "🌡️ $temp  |  🧠 $mem  |  🧵 load $load  |  💾 $(get_storage_bar)  |  📻 $(get_status azuracast) azuracast"
  echo
}

tactile_choose() {
  gum choose "$@"
}

deck_note_file() {
  echo "$HOME/pibulus-os/logs/field-notes.log"
}

tool_exists() {
  command -v "$1" >/dev/null 2>&1
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

show_system_snapshot() {
  echo "System snapshot"
  echo "==============="
  echo
  uptime
  echo
  free -h
  echo
  df -h / /media/pibulus/passport 2>/dev/null
  echo
  docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
}

show_disk_overview() {
  if tool_exists duf; then
    duf
  else
    df -h
  fi
}

show_json_services() {
  if tool_exists jq; then
    jq '.services[] | {name, category, url, description}' "$SERVICE_REGISTRY"
  else
    cat "$SERVICE_REGISTRY"
  fi
}

show_tunnel_snapshot() {
  echo "Tunnel + edge"
  echo "============="
  echo
  systemctl --no-pager --full status cloudflared 2>/dev/null | sed -n '1,20p' || true
  echo
  echo "Recent cloudflared logs:"
  journalctl -u cloudflared -n 20 --no-pager 2>/dev/null || true
}

show_critical_services() {
  echo "Critical services"
  echo "================="
  for name in web_host azuracast slskd memos cloudflared; do
    printf '%-14s %s\n' "$name" "$(get_status "$name")"
  done
  echo
  docker ps --filter 'name=web_host|azuracast|slskd|memos' --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
}

show_recent_errors() {
  echo "Recent service noise"
  echo "===================="
  echo
  printf '\n--- %s ---\n' "cloudflared"
  journalctl -u cloudflared -n 8 --no-pager 2>/dev/null || true
  docker ps --format '{{.Names}}' | while read -r name; do
    [ -z "$name" ] && continue
    printf '\n--- %s ---\n' "$name"
    docker logs --tail 5 "$name" 2>&1 | tail -5
  done
}

open_log_navigator() {
  if tool_exists lnav; then
    lnav /var/log/syslog /var/log/auth.log 2>/dev/null || lnav 2>/dev/null
  else
    echo "lnav not installed."
    pause_screen
  fi
}

open_system_monitor() {
  if tool_exists btop; then
    btop
  else
    top
  fi
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
now_playing_block = data.get("now_playing", {})
playing_next = data.get("playing_next", {}).get("song", {})
station = data.get("station", {})
mounts = station.get("mounts", [])

print("Now playing:")
print(f"  {now_playing.get('artist', 'Unknown')} — {now_playing.get('title', 'Unknown')}")
print(f"  {now_playing_block.get('elapsed', 0)}s elapsed / {now_playing_block.get('remaining', 0)}s remaining")
print("Next up:")
print(f"  {playing_next.get('artist', 'Unknown')} — {playing_next.get('title', 'Unknown')}")
print("Listeners:")
print(f"  {listeners.get('current', 0)} live / {listeners.get('unique', 0)} unique")
if mounts:
    mount = mounts[0]
    mount_listeners = mount.get("listeners", {})
    print("Mount:")
    print(f"  {mount.get('name', mount.get('path', 'Unknown'))}")
    print(f"  {mount_listeners.get('current', 0)} current / {mount_listeners.get('unique', 0)} unique")
print("Player:")
print(f"  {station.get('public_player_url', 'Unknown')}")
print("Stream:")
print(f"  {station.get('listen_url', 'Unknown')}")
PY
}

show_recent_tracks() {
  python3 - <<'PY'
import json, urllib.request

try:
    data = json.load(urllib.request.urlopen("http://localhost:8500/api/nowplaying/kpab.fm", timeout=3))
except Exception as exc:
    print(f"Could not reach AzuraCast API: {exc}")
    raise SystemExit(0)

history = data.get("song_history", [])
if not history:
    print("No recent track history.")
    raise SystemExit(0)

print("Recently played:")
for idx, item in enumerate(history[:8], start=1):
    song = item.get("song", {})
    duration = int(item.get("duration") or 0)
    mins, secs = divmod(duration, 60)
    print(f"  {idx}. {song.get('artist', 'Unknown')} — {song.get('title', 'Unknown')} [{mins}:{secs:02d}]")
PY
}

show_recent_listeners() {
  python3 - <<'PY'
import os
import re
from collections import Counter
from datetime import datetime
from pathlib import Path

listener_db = Path("/tmp/kpab_recent_listeners.tsv")
if not listener_db.exists():
    print("No recent listener snapshot available.")
    raise SystemExit(0)

rows = []
for line in listener_db.read_text().splitlines():
    parts = line.split("\t")
    if len(parts) != 3:
        continue
    ip, ua, ts = parts
    device = "Unknown"
    if "iPhone" in ua or "iOS" in ua:
        device = "iPhone"
    elif "Macintosh" in ua or "Mac OS X" in ua:
        device = "Mac"
    elif "Android" in ua:
        device = "Android"
    browser = "Unknown"
    if "CriOS" in ua or "Chrome/" in ua:
        browser = "Chrome"
    elif "Safari/" in ua:
        browser = "Safari"
    elif "Firefox/" in ua:
        browser = "Firefox"
    rows.append((ip, browser, device, ts))

if not rows:
    print("No recent listener rows.")
    raise SystemExit(0)

counts = Counter(ip for ip, *_ in rows)
print("Recent listener rows:")
for ip, browser, device, ts in rows[:8]:
    stamp = ts.replace("T", " ") if "T" in ts else ts
    extra = f"{counts[ip]} recent rows" if counts[ip] > 1 else "1 recent row"
    print(f"  {ip:<15} {browser:<7} {device:<8} {stamp}  ({extra})")
PY
}

refresh_recent_listeners_cache() {
  python3 - <<'PY'
import subprocess
import textwrap
from pathlib import Path

script = textwrap.dedent('''
docker exec -i azuracast sh <<'INNER'
cat >/tmp/kpab_listener_sample.php <<'PHP'
<?php
$dsn = sprintf('mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4', '127.0.0.1', getenv('MYSQL_PORT'), getenv('MYSQL_DATABASE'));
$pdo = new PDO($dsn, getenv('MYSQL_USER'), getenv('MYSQL_PASSWORD'));
$sql = "SELECT listener_ip, listener_user_agent, timestamp_start FROM listener ORDER BY id DESC LIMIT 8";
foreach ($pdo->query($sql) as $row) {
    echo implode("\\t", [
        $row['listener_ip'],
        preg_replace('/\\s+/', ' ', (string)$row['listener_user_agent']),
        $row['timestamp_start']
    ]), PHP_EOL;
}
PHP
php /tmp/kpab_listener_sample.php
INNER
''').strip()

result = subprocess.run(["bash", "-lc", script], capture_output=True, text=True)
output = result.stdout.strip()
if not output:
    print("Could not fetch recent listener rows.")
    if result.stderr.strip():
        print(result.stderr.strip())
    raise SystemExit(0)

Path("/tmp/kpab_recent_listeners.tsv").write_text(output + "\n")
print("Listener snapshot refreshed.")
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

show_top_media_dirs() {
  echo "Top media directories"
  echo "====================="
  echo
  du -xh --max-depth=2 /media/pibulus/passport 2>/dev/null | sort -hr | head -30
}

show_recent_media() {
  echo "Recent file activity"
  echo "===================="
  echo
  find /media/pibulus/passport -type f -mtime -7 2>/dev/null | tail -60
}

show_media_tree() {
  if tool_exists tree; then
    tree -L 2 /media/pibulus/passport 2>/dev/null | sed -n '1,220p'
  else
    find /media/pibulus/passport -maxdepth 2 -type d 2>/dev/null | sed -n '1,220p'
  fi
}

preview_cover_art() {
  if ! tool_exists chafa; then
    echo "chafa not installed."
    pause_screen
    return
  fi
  local file
  file=$(find /media/pibulus/passport -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | head -200 | gum choose --height 20)
  [ -z "$file" ] && return
  chafa -f symbols -s 80x40 "$file"
}

show_drive_status() {
  echo "Drive bay"
  echo "========="
  echo
  lsblk -o NAME,MODEL,SIZE,FSTYPE,MOUNTPOINTS
  echo
  echo "/etc/fstab mounts:"
  grep -v '^\s*#' /etc/fstab | sed '/^\s*$/d'
}

show_usb_kernel_noise() {
  echo "Recent USB / disk noise"
  echo "======================="
  echo
  journalctl -k -n 80 --no-pager 2>/dev/null | rg -i 'usb|sd[a-z]|fat-fs|ntfs|i/o error|disconnect|reset' || true
}

safe_unmount_membot() {
  local target="/media/pibulus/MEMBOT"
  if findmnt -rn -T "$target" >/dev/null 2>&1; then
    sync
    sudo umount "$target" && echo "MEMBOT unmounted cleanly." || echo "Unmount failed."
  else
    echo "MEMBOT is not currently mounted."
  fi
}

safe_mount_membot() {
  local target="/media/pibulus/MEMBOT"
  if findmnt -rn -T "$target" >/dev/null 2>&1; then
    echo "MEMBOT is already mounted."
    findmnt -rn -T "$target"
    return
  fi

  mkdir -p "$target"
  if sudo mount "$target"; then
    echo "MEMBOT mounted cleanly."
    findmnt -rn -T "$target"
  else
    echo "Mount failed. Check that the MEMBOT stick is plugged in."
  fi
}

write_field_note() {
  local note
  note=$(gum write --placeholder 'Field note, idea, bug, weird discovery...')
  [ -z "$note" ] && return
  mkdir -p "$(dirname "$(deck_note_file)")"
  {
    printf '\n[%s]\n' "$(date '+%Y-%m-%d %H:%M:%S')"
    printf '%s\n' "$note"
  } >> "$(deck_note_file)"
  echo "Saved to $(deck_note_file)"
}

show_recent_notes() {
  local file
  file="$(deck_note_file)"
  if [ ! -f "$file" ]; then
    echo "No field notes yet."
    return
  fi
  tail -n 80 "$file"
}

open_notes_in_glow() {
  local file
  file="$(deck_note_file)"
  if [ ! -f "$file" ]; then
    echo "No field notes yet."
    pause_screen
    return
  fi
  if tool_exists glow; then
    glow -p "$file"
  else
    less "$file"
  fi
}

open_field_manual_pretty() {
  if tool_exists glow; then
    glow -p ~/pibulus-os/FIELD_MANUAL.md
  else
    gum pager < ~/pibulus-os/FIELD_MANUAL.md
  fi
}

newsboat_urls_file() {
  echo "$HOME/.newsboat/urls"
}

build_newsboat_lane_file() {
  local lane="$1"
  local src
  local tmp="/tmp/newsboat-lane-${USER}.urls"
  src="$(newsboat_urls_file)"

  case "$lane" in
    ground)
      awk '/^https?:/ && $0 ~ /(^| )ground( |$)/ { print }' "$src" > "$tmp"
      ;;
    hacker)
      awk '/^https?:/ && $0 ~ /(^| )hacker( |$)/ { print }' "$src" > "$tmp"
      ;;
    art)
      awk '/^https?:/ && $0 ~ /(^| )art( |$)/ { print }' "$src" > "$tmp"
      ;;
    all)
      cp "$src" "$tmp"
      ;;
  esac

  echo "$tmp"
}

show_feed_lane_guide() {
  clear
  print_header "SIGNAL LANES"
  gum style --border rounded --border-foreground 212 --padding '0 2' --margin '1 0' \
    "✊ GROUND SIGNAL\nAnti-empire politics, rights, Palestine, resistance reporting.\n\n⌨️ HACKER BRAIN\nUnderground hacker culture, DIY hardware, privacy, cheat-code energy.\n\n🎨 ART + WEIRD\nSubversive art, counterculture, weird internet texture."
  pause_screen
}

run_newsboat_lane() {
  local lane="$1"
  local lane_file

  if [ "$lane" = "all" ]; then
    newsboat
    return
  fi

  lane_file="$(build_newsboat_lane_file "$lane")"
  newsboat -u "$lane_file"
}

open_feed_reader() {
  if tool_exists newsboat; then
    while true; do
      clear
      print_header "SIGNAL FEEDS"
      gum style --border rounded --border-foreground 212 --padding '0 2' --margin '1 0' \
        "Pick a lane instead of raw-dogging the whole internet.\n\nEnter=open  o=browser  r=reload  q=back out"

      local pick
      pick=$(printf '%s\n' \
        '⚡ Full Signal Mix' \
        '✊ Ground Signal' \
        '⌨️ Hacker Brain' \
        '🎨 Art + Weird' \
        '🧭 Lane Guide' \
        '← Back' | gum choose --height 12)

      case "$pick" in
        '⚡ Full Signal Mix') run_newsboat_lane all; break ;;
        '✊ Ground Signal') run_newsboat_lane ground; break ;;
        '⌨️ Hacker Brain') run_newsboat_lane hacker; break ;;
        '🎨 Art + Weird') run_newsboat_lane art; break ;;
        '🧭 Lane Guide') show_feed_lane_guide ;;
        ''|'← Back') break ;;
      esac
    done
  else
    echo "newsboat not installed."
    pause_screen
  fi
}

open_chat_client() {
  if tool_exists weechat; then
    weechat
  elif tool_exists irssi; then
    irssi
  else
    echo "No chat client installed."
    pause_screen
  fi
}

open_local_browserish() {
  local url="$1"
  if tool_exists w3m; then
    w3m "$url"
  else
    echo "$url"
    pause_screen
  fi
}

open_tmux_shell() {
  if tool_exists tmux; then
    tmux new-session -A -s deck
  else
    echo "tmux not installed."
    pause_screen
  fi
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

network_menu() {
  while true; do
    render_hud
    show_section_intro \
      'network' \
      'Switch between home and away modes, or inspect the current state before blaming the tunnel.'
    local action
    action=$(tactile_choose '📡 Network Status' '🏠 Home Wi-Fi Mode' '🧳 Hotspot / Away Mode' 'Back')
    case "$action" in
      '📡 Network Status') ~/pibulus-os/scripts/network_mode.sh status; pause_screen ;;
      '🏠 Home Wi-Fi Mode') ~/pibulus-os/scripts/network_mode.sh home; pause_screen ;;
      '🧳 Hotspot / Away Mode') ~/pibulus-os/scripts/network_mode.sh away; pause_screen ;;
      'Back'|'') return ;;
    esac
  done
}

sigint_menu() {
  while true; do
    render_hud
    show_section_intro \
      'sigint' \
      'Fast state of the machine: health, tunnel, service status, public edge, and recent noise.'
    local action
    action=$(tactile_choose \
      '📊 System Snapshot' \
      '📈 Live Monitor' \
      '💽 Disk Overview' \
      '🚨 Critical Services' \
      '🌐 Tunnel + Edge' \
      '🪪 Public IP' \
      '🪵 Log Navigator' \
      '🧾 Registry JSON' \
      '🧯 Recent Service Noise' \
      'Back')
    case "$action" in
      '📊 System Snapshot') show_system_snapshot; pause_screen ;;
      '📈 Live Monitor') open_system_monitor ;;
      '💽 Disk Overview') show_disk_overview; pause_screen ;;
      '🚨 Critical Services') show_critical_services; pause_screen ;;
      '🌐 Tunnel + Edge') show_tunnel_snapshot; pause_screen ;;
      '🪪 Public IP') show_public_ip; pause_screen ;;
      '🪵 Log Navigator') open_log_navigator ;;
      '🧾 Registry JSON') show_json_services; pause_screen ;;
      '🧯 Recent Service Noise') show_recent_errors; pause_screen ;;
      'Back'|'') return ;;
    esac
  done
}

slskd_menu() {
  while true; do
    render_hud
    show_section_intro \
      'soulseek' \
      'Peer-to-peer intake control: wake it, inspect it, or jump into the local UI without leaving the deck.'
    local action
    action=$(tactile_choose '🎵 Wake' '😴 Sleep' '🔎 Status' '🌐 Open UI' 'Back')
    case "$action" in
      '🎵 Wake') docker start slskd; pause_screen ;;
      '😴 Sleep') docker stop slskd; pause_screen ;;
      '🔎 Status') docker ps --filter 'name=slskd' --format 'table {{.Names}}\t{{.Status}}'; pause_screen ;;
      '🌐 Open UI') open_local_browserish 'http://localhost:5030' ;;
      'Back'|'') return ;;
    esac
  done
}

club_menu() {
  while true; do
    render_hud
    show_section_intro \
      'club' \
      'Account and membership utilities for the local node.'
    local action
    action=$(tactile_choose '➕ Add Member' '🔎 Audit Account Parity' 'Back')
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
    show_section_intro \
      'radio' \
      'Check what KPAB is doing right now: current track, listeners, service health, and public links.'
    local action
    action=$(tactile_choose '📻 Now Playing' '📜 Recent Tracks' '👂 Recent Listeners' '🛰️ Service Status' '🌐 Public Links' 'Back')
    case "$action" in
      '📻 Now Playing')
        show_radio_snapshot
        pause_screen ;;
      '📜 Recent Tracks')
        show_recent_tracks
        pause_screen ;;
      '👂 Recent Listeners')
        refresh_recent_listeners_cache
        show_recent_listeners
        pause_screen ;;
      '🛰️ Service Status')
        radio_status
        pause_screen ;;
      '🌐 Public Links')
        show_public_links
        pause_screen ;;
      'Back'|'') return ;;
    esac
  done
}

media_menu() {
  while true; do
    render_hud
    show_section_intro \
      'media' \
      'Search, browse, and inspect the archive. Less clicking around, more seeing what is actually on disk.'
    local action
    action=$(tactile_choose \
      '🔎 Find My Media' \
      '📂 Browse Passport Drive' \
      '📦 Biggest Media Dirs' \
      '🌲 Media Tree' \
      '🖼️ Cover Art Preview' \
      '🕰️ Recent File Activity' \
      'Back')
    case "$action" in
      '🔎 Find My Media') media_finder_menu ;;
      '📂 Browse Passport Drive') nnn /media/pibulus/passport ;;
      '📦 Biggest Media Dirs') show_top_media_dirs; pause_screen ;;
      '🌲 Media Tree') show_media_tree; pause_screen ;;
      '🖼️ Cover Art Preview') preview_cover_art; pause_screen ;;
      '🕰️ Recent File Activity') show_recent_media; pause_screen ;;
      'Back'|'') return ;;
    esac
  done
}

drives_menu() {
  while true; do
    render_hud
    show_section_intro \
      'drives' \
      'Mount status, USB weirdness, and safe actions for external media. The opposite of yanking cables blind.'
    local action
    action=$(tactile_choose \
      '💾 Drive Status' \
      '🔼 Mount MEMBOT' \
      '🔌 USB / Kernel Noise' \
      '⏏️ Unmount MEMBOT' \
      'Back')
    case "$action" in
      '💾 Drive Status') show_drive_status; pause_screen ;;
      '🔼 Mount MEMBOT') safe_mount_membot; pause_screen ;;
      '🔌 USB / Kernel Noise') show_usb_kernel_noise; pause_screen ;;
      '⏏️ Unmount MEMBOT') safe_unmount_membot; pause_screen ;;
      'Back'|'') return ;;
    esac
  done
}

ops_menu() {
  while true; do
    render_hud
    show_section_intro \
      'ops' \
      'Sharp tools for changing the box. Not vibes. Real interventions.'
    local action
    action=$(tactile_choose \
      '🚀 Deploy Something New' \
      '🧹 Flush RAM' \
      '🧠 Scavenger Search' \
      '🏴‍☠️ Media Grab' \
      'Back')
    case "$action" in
      '🚀 Deploy Something New') ~/pibulus-os/scripts/deploy.sh ;;
      '🧹 Flush RAM') ~/pibulus-os/scripts/flush_ram.sh; pause_screen ;;
      '🧠 Scavenger Search') manage_scavenger ;;
      '🏴‍☠️ Media Grab') manage_pirate_grab ;;
      'Back'|'') return ;;
    esac
  done
}

desk_menu() {
  while true; do
    render_hud
    show_section_intro \
      'desk' \
      'Capture, read, browse feeds, and get a shell. The quiet end of the deck.'
    local action
    action=$(tactile_choose \
      '✍️ Write Field Note' \
      '📜 Recent Notes' \
      '✨ Pretty Viewer' \
      '📖 Field Manual' \
      '📰 Feed Reader' \
      '🧵 tmux' \
      '💬 Chat' \
      'Back')
    case "$action" in
      '✍️ Write Field Note') write_field_note; pause_screen ;;
      '📜 Recent Notes') show_recent_notes; pause_screen ;;
      '✨ Pretty Viewer') open_notes_in_glow ;;
      '📖 Field Manual') open_field_manual_pretty ;;
      '📰 Feed Reader') open_feed_reader ;;
      '🧵 tmux') open_tmux_shell ;;
      '💬 Chat') open_chat_client ;;
      'Back'|'') return ;;
    esac
  done
}

_first_run=1
while true; do
  render_hud
  if [ "$_first_run" = "1" ]; then
    gum style --foreground 212 "$(roll_fascination)"
    _first_run=0
  fi
choice=$(tactile_choose --height 15 \
    '🚨 sigint' \
    '📻 radio' \
    '🎬 media' \
    '📡 network' \
    '💾 drives' \
    '🛠️ ops' \
    '🎵 soulseek' \
    '🐱 club' \
    '📝 desk' \
    '🚪 exit')

  case "$choice" in
    '🚨 sigint') sigint_menu ;;
    '📻 radio') radio_menu ;;
    '🎬 media') media_menu ;;
    '📡 network') network_menu ;;
    '💾 drives') drives_menu ;;
    '🛠️ ops') ops_menu ;;
    '🎵 soulseek') slskd_menu ;;
    '🐱 club') club_menu ;;
    '📝 desk') desk_menu ;;
    '🚪 exit'|'') clear; echo 'Neural link severed.'; exit 0 ;;
  esac
done
