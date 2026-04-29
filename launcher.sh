#!/bin/bash

# Normalize terminal for Pi compatibility
case "$TERM" in
  xterm-ghostty|xterm-kitty) export TERM=xterm-256color ;;
  '') export TERM=xterm-256color ;;
esac

command -v gum >/dev/null 2>&1 || { echo "gum not found. Install: https://github.com/charmbracelet/gum"; exit 1; }

DECK_ROOT="$(cd "$(dirname "$0")" && pwd)"
SERVICE_REGISTRY="${SERVICE_REGISTRY:-$DECK_ROOT/config/service-registry.json}"
PASSPORT_ROOT="${PASSPORT_ROOT:-/media/pibulus/passport}"

# Local-only credentials live in gitignored env files.
# shellcheck disable=SC1091
[ -f "$DECK_ROOT/scripts/load_pibulus_env.sh" ] && . "$DECK_ROOT/scripts/load_pibulus_env.sh"

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
  local name="$1"
  local port="$2"
  local active="🔴"
  if [ "$name" = "cloudflared" ]; then
    systemctl is-active --quiet cloudflared 2>/dev/null && active="🟢"
  elif docker ps --format {{.Names}} | grep -qx "$name"; then
    active="🟢"
  fi
  # Ghost detection: container running but port not responding
  if [ "$active" = "🟢" ] && [ -n "$port" ]; then
    if ! timeout 0.3 bash -c "</dev/tcp/localhost/$port" 2>/dev/null; then
       active="💀"
    fi
  fi
  echo "$active"
}

pause_screen() {
  echo
  gum style --foreground 240 "  ─── [ enter ] ───"
  read -rs
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
  local load_color=212
  if command -v bc >/dev/null 2>&1; then
    if (( $(echo "$load > 5.0" | bc -l 2>/dev/null) )); then load_color=196
    elif (( $(echo "$load > 3.0" | bc -l 2>/dev/null) )); then load_color=226; fi
  fi
  local mem="$(free -h | awk '/Mem:/ {print $7 " avail / " $2}')"

  if command -v vcgencmd >/dev/null 2>&1; then
    temp="$(vcgencmd measure_temp | cut -d'=' -f2)"
  fi

  print_logo
  print_statusline
  echo
  gum style --border rounded --border-foreground 212 --padding '0 1' --margin '0 0' \
    "🌡️ $temp  |  🧠 $mem  |  $(gum style --foreground $load_color "🧵 load $load")  |  💾 $(get_storage_bar)  |  🌐 $(get_status cloudflared) tunnel  |  📻 $(get_status azuracast) radio  |  🎮 $(get_status romm 8095) romm  |  📡 $(get_sdr_status) sdr"
  echo
}

tactile_choose() {
  gum choose --cursor "› " "$@"
}

deck_note_file() {
  echo "$HOME/pibulus-os/logs/field-notes.log"
}

tool_exists() {
  command -v "$1" >/dev/null 2>&1
}

sdr_lab_script() {
  echo "$HOME/pibulus-os/scripts/sdr_lab.sh"
}

get_sdr_status() {
  if lsusb 2>/dev/null | grep -Eiq 'NESDR|Nooelec|RTL2838|RTL2832|RTL-SDR|Realtek'; then
    echo "🟢"
  else
    echo "🔴"
  fi
}

run_sdr_lab() {
  local helper
  helper="$(sdr_lab_script)"
  if [ ! -x "$helper" ]; then
    echo "Missing helper: $helper"
    return 1
  fi
  "$helper" "$@"
}

show_sdr_snapshot() {
  run_sdr_lab status
}

sdr_fm_presets_menu() {
  local preset freq
  preset=$(printf '%s\n' \
    'PBS 106.7 — community radio' \
    'Triple R 102.7 — weird Melbourne gold' \
    'JOY 94.9 — queer radio' \
    'SYN 90.7 — youth/community signal' \
    'ABC Classic 105.9 — orchestral reset' \
    'Custom frequency…' \
    'Back' | gum choose --height 12)

  case "$preset" in
    'PBS 106.7 — community radio') freq='106.7' ;;
    'Triple R 102.7 — weird Melbourne gold') freq='102.7' ;;
    'JOY 94.9 — queer radio') freq='94.9' ;;
    'SYN 90.7 — youth/community signal') freq='90.7' ;;
    'ABC Classic 105.9 — orchestral reset') freq='105.9' ;;
    'Custom frequency…')
      freq=$(gum input --placeholder "FM frequency in MHz (e.g. 95.8)")
      ;;
    'Back'|'') return ;;
  esac

  [ -z "$freq" ] && return
  run_sdr_lab fm "$freq"
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

show_live_pulse() {
  
# ── DASHBOARD PANEL (side-by-side health + notes) ────────────────────────────
render_dashboard_panel() {
  local status_box
  status_box=$(gum style --border normal --border-foreground 240 --padding "0 1" --width 35 \
    "$(gum style --bold --foreground 212 "SERVICE HEALTH")" \
    "" \
    "web_host      $(get_status web_host 80)" \
    "navidrome     $(get_status navidrome 4533)" \
    "slskd         $(get_status slskd 5030)" \
    "memos         $(get_status memos 5230)" \
    "sdr dongle    $(get_sdr_status)" \
    "qbittorrent   $(get_status qbittorrent 8888)")

  local notes_box
  local last_note=$(tail -n 1 "$HOME/pibulus-os/logs/field-notes.log" 2>/dev/null | cut -c1-30)
  notes_box=$(gum style --border normal --border-foreground 240 --padding "0 1" --width 35 \
    "$(gum style --bold --foreground 212 "LAST FIELD NOTE")" \
    "" \
    "${last_note:-No notes yet...}" \
    "" \
    "$(gum style --italic --foreground 240 "$(roll_fascination)")")

  gum join --horizontal "$status_box" "$notes_box"
}

while true; do
    clear
    python3 ~/pibulus-os/scripts/pulse.py
    sleep 15 || break
  done
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
  echo "Recent service noise (errors/warnings only)"
  echo "============================================"
  echo
  printf '\n--- cloudflared ---\n'
  journalctl -u cloudflared -n 40 --no-pager 2>/dev/null \
    | grep -iE '\berr|\bwarn|\bcrit|\bfail|\bfatal' | tail -5 || echo "  (clean)"
  for name in web_host azuracast slskd memos qbittorrent; do
    docker ps --format '{{.Names}}' | grep -qx "$name" || continue
    printf '\n--- %s ---\n' "$name"
    docker logs --tail 60 "$name" 2>&1 \
      | grep -iE '\berr|\bwarn|\bcrit|\bfail|\bfatal' | tail -5 || echo "  (clean)"
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
  bash ~/pibulus-os/scripts/refresh_listeners.sh
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
  find /media/pibulus/passport -maxdepth 5 -type f -mtime -7 2>/dev/null | tail -40
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
  file=$(find /media/pibulus/passport -maxdepth 4 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | head -400 | fzf --prompt="pick image > " --height 20 --border 2>/dev/null || true)
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

search_field_notes() {
  local file query results
  file="$(deck_note_file)"
  if [ ! -f "$file" ]; then
    echo "No field notes yet."
    pause_screen
    return
  fi
  query=$(gum input --placeholder "Search notes...")
  [ -z "$query" ] && return
  results=$(grep -n -i "$query" "$file" 2>/dev/null)
  if [ -z "$results" ]; then
    echo "No matches for: $query"
  else
    echo "$results"
  fi
  pause_screen
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

  if [ ! -r "$src" ]; then
    return 1
  fi

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

  lane_file="$(build_newsboat_lane_file "$lane")" || {
    gum style --foreground 196 "newsboat feed file missing: $(newsboat_urls_file)"
    pause_screen
    return
  }
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

mediainfo_picker() {
  if ! tool_exists fzf; then echo "fzf not installed."; pause_screen; return; fi
  local file
  file=$(find /media/pibulus/passport -maxdepth 4 -type f \
    \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' -o -iname '*.mov' \
       -o -iname '*.mp3' -o -iname '*.flac' -o -iname '*.m4a' -o -iname '*.ogg' \
       -o -iname '*.opus' -o -iname '*.cbz' -o -iname '*.epub' \) \
    2>/dev/null | fzf --prompt="pick file > " --height 40 --border)
  [ -z "$file" ] && return
  mediainfo "$file" | bat --plain -l ini 2>/dev/null || mediainfo "$file" | less
}

inspect_stack() {
  if ! tool_exists fzf; then echo "fzf not installed."; pause_screen; return; fi
  local stacks_dir=~/pibulus-os/config/stacks
  local pick
  pick=$(ls "$stacks_dir"/*.yml 2>/dev/null | fzf --prompt="pick stack > " --height 15 --border)
  [ -z "$pick" ] && return
  bat -l yaml "$pick" 2>/dev/null || cat "$pick"
  pause_screen
}

tldr_lookup() {
  local cmd
  cmd=$(gum input --placeholder "command name (e.g. rsync, docker, yt-dlp)")
  [ -z "$cmd" ] && return
  tldr "$cmd" 2>/dev/null | bat --plain 2>/dev/null || tldr "$cmd" 2>/dev/null || echo "No page for: $cmd"
  pause_screen
}

entr_watch() {
  local dir pattern cmd
  dir=$(gum input --placeholder "dir to watch (default: ~/pibulus-os)")
  dir="${dir:-$HOME/pibulus-os}"
  pattern=$(gum input --placeholder "file pattern (e.g. *.py, *.sh, *.yml)")
  [ -z "$pattern" ] && return
  cmd=$(gum input --placeholder "command to run on change (e.g. bash deploy.sh)")
  [ -z "$cmd" ] && return
  echo "Watching $dir for $pattern changes → $cmd"
  echo "(Ctrl-C to stop)"
  find "$dir" -name "$pattern" | entr -c bash -c "$cmd"
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
    action=$(tactile_choose --height 12 \
      '📡 Network Status' \
      '🚀 Speed Test' \
      '📊 Bandwidth Usage' \
      '📈 Live Bandwidth' \
      '🔗 Live Connections' \
      '🏓 Ping Graph' \
      '🔍 Trace Route' \
      '🏠 Home Wi-Fi Mode' \
      '🧳 Hotspot / Away Mode' \
      'Back')
    case "$action" in
      '📡 Network Status') ~/pibulus-os/scripts/network_mode.sh status; pause_screen ;;
      '🚀 Speed Test')
        echo "Running speedtest... (takes ~30s)"
        speedtest-cli --simple
        pause_screen ;;
      '📊 Bandwidth Usage') vnstat -i eth0; pause_screen ;;
      '📈 Live Bandwidth') nload eth0 ;;
      '🔗 Live Connections') sudo iftop -i eth0 ;;
      '🏓 Ping Graph')
        local target
        target=$(gum input --placeholder "Host to ping (default: 1.1.1.1)")
        target="${target:-1.1.1.1}"
        gping "$target" ;;
      '🔍 Trace Route')
        local target
        target=$(gum input --placeholder "Host to trace (default: 1.1.1.1)")
        target="${target:-1.1.1.1}"
        mtr "$target" ;;
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
    action=$(tactile_choose --height 15 \
      '💓 Live Pulse' \
      '⚡ Live Monitor' \
      '🖥️ System Info' \
      '📊 System Snapshot' \
      '💽 Disk Overview' \
      '🚨 Critical Services' \
      '🌐 Tunnel + Edge' \
      '🪪 Public IP' \
      '🔗 Service Links' \
      '🪵 Log Navigator' \
      '🧾 Registry JSON' \
      '🧯 Recent Service Noise' \
      'Back')
    case "$action" in
      '💓 Live Pulse') show_live_pulse ;;
      '⚡ Live Monitor') open_system_monitor ;;
      '🖥️ System Info') fastfetch; pause_screen ;;
      '📊 System Snapshot') show_system_snapshot; pause_screen ;;
      '💽 Disk Overview') show_disk_overview; pause_screen ;;
      '🚨 Critical Services') show_critical_services; pause_screen ;;
      '🌐 Tunnel + Edge') show_tunnel_snapshot; pause_screen ;;
      '🪪 Public IP') show_public_ip; pause_screen ;;
      '🔗 Service Links') show_public_links; pause_screen ;;
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
    action=$(tactile_choose \
      '▶️  Wake' \
      '😴 Sleep' \
      '🔎 Status' \
      '🌐 Open UI' \
      'Back')
    case "$action" in
      '▶️  Wake') docker start slskd; pause_screen ;;
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
      '➕ Add Member')
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
    action=$(tactile_choose '📻 Now Playing' '📜 Recent Tracks' '👂 Recent Listeners' '🛰️ Service Status' '🎵 Visualizer' 'Back')
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
      '🎵 Visualizer') cava ;;
      'Back'|'') return ;;
    esac
  done
}

yt_download() {
  local helper="$HOME/pibulus-os/scripts/youtube_archive.py"
  if [[ ! -x "$helper" ]]; then
    echo "Missing helper: $helper"
    pause_screen
    return
  fi

  while true; do
    local action
    action=$(tactile_choose \
      '📥 Add URL' \
      '🔁 Sync subscriptions now' \
      '📜 List subscriptions' \
      'Back')

    case "$action" in
      '📥 Add URL')
        local url section_label section mode_label mode subscribe_label name subscribe_flag
        url=$(gum input --placeholder "YouTube video, playlist, channel, or tab URL...")
        [ -z "$url" ] && continue

        section_label=$(printf '%s\n' 'Forbidden / Conspiracy' 'Palestine' 'The Bucket' | gum choose --header "Where should this live?")
        [ -z "$section_label" ] && continue
        case "$section_label" in
          'Forbidden / Conspiracy') section='conspiracy' ;;
          'Palestine') section='palestine' ;;
          'The Bucket') section='bucket' ;;
        esac

        mode_label=$(printf '%s\n' 'One video only' 'Playlist / group' 'Whole channel' | gum choose --header "What should yt-dlp pull?")
        [ -z "$mode_label" ] && continue
        case "$mode_label" in
          'One video only') mode='video' ;;
          'Playlist / group') mode='playlist' ;;
          'Whole channel') mode='channel' ;;
        esac

        name=$(gum input --placeholder "Folder name (optional; Enter to auto-detect)")
        subscribe_flag=()
        if [[ "$mode" != "video" ]]; then
          subscribe_label=$(printf '%s\n' 'Yes — keep pulling new uploads weekly' 'No — just download once' | gum choose --header "Subscribe?")
          [ -z "$subscribe_label" ] && continue
          [[ "$subscribe_label" == Yes* ]] && subscribe_flag=(--subscribe)
        fi

        if [[ -n "$name" ]]; then
          python3 "$helper" add --url "$url" --section "$section" --mode "$mode" --name "$name" "${subscribe_flag[@]}"
        else
          python3 "$helper" add --url "$url" --section "$section" --mode "$mode" "${subscribe_flag[@]}"
        fi
        pause_screen ;;
      '🔁 Sync subscriptions now')
        python3 "$helper" sync
        pause_screen ;;
      '📜 List subscriptions')
        python3 "$helper" list
        pause_screen ;;
      'Back'|'') return ;;
    esac
  done
}

drop_magnet_or_url() {
  local link
  link=$(gum input --placeholder "Paste magnet link or HTTP URL...")
  [ -z "$link" ] && return

  if [[ "$link" == magnet:* ]]; then
    local dest
    dest=$(printf '%s\n' 'The Bucket (general)' 'Movies' 'Shows' | gum choose --header "Where should it go?")
    [ -z "$dest" ] && return
    local savepath
    case "$dest" in
      'The Bucket (general)') savepath="/downloads/" ;;
      'Movies')               savepath="/movies/" ;;
      'Shows')                savepath="/shows/" ;;
    esac
    curl -s -c /tmp/qb_cookies.txt -b /tmp/qb_cookies.txt \
      --data-urlencode "username=${QB_WEBUI_USERNAME:-admin}" \
      --data-urlencode "password=${QB_WEBUI_PASSWORD:?QB_WEBUI_PASSWORD not set}" \
      "${QB_WEBUI_URL:-http://localhost:8888}/api/v2/auth/login" > /dev/null
    local result
    result=$(curl -s -b /tmp/qb_cookies.txt \
      -F "urls=$link" \
      -F "savepath=$savepath" \
      "${QB_WEBUI_URL:-http://localhost:8888}/api/v2/torrents/add")
    echo "Magnet queued → $dest  ($result)"

  elif [[ "$link" == http* ]]; then
    local dest_dir="/media/pibulus/passport/The_Bucket"
    echo "Downloading via aria2c → $dest_dir"
    aria2c \
      --dir="$dest_dir" \
      --max-connection-per-server=4 \
      --split=4 \
      --console-log-level=warn \
      --summary-interval=10 \
      "$link"
    echo "Done."

  else
    echo "Unrecognised format — paste a magnet: link or an http(s):// URL."
  fi

  pause_screen
}

media_menu() {
  while true; do
    render_hud
    show_section_intro \
      'media' \
      'Grab new content or dig through the archive. Acquire first, browse second.'
    local action
    action=$(tactile_choose --height 16 \
      '🎬 Grab a Movie' \
      '🎞️ Grab a Show' \
      '🧲 Drop a Magnet / URL' \
      '▶️  YouTube Archive' \
      '🏴‍☠️ Pirate Grab' \
      '🧠 Scavenger Search' \
      '⬇️ Active Downloads' \
      '🔎 Find My Media' \
      '📂 Browse Passport Drive' \
      '🌲 Media Tree' \
      '🖼️ Cover Art Preview' \
      '📏 Biggest Media Dirs' \
      '🕰️ Recent File Activity' \
      'ℹ️ Media Info' \
      'Back')
    case "$action" in
      '🎬 Grab a Movie')
        title=$(gum input --placeholder "movie title (e.g. chopper 2000)")
        [ -n "$title" ] && python3 ~/pibulus-os/scripts/grab_movie.py "$title" --pick
        pause_screen ;;
      '🎞️ Grab a Show')
        title=$(gum input --placeholder "show name (e.g. joe pera talks with you)")
        [ -n "$title" ] && python3 ~/pibulus-os/scripts/grab_show.py "$title"
        pause_screen ;;
      '🧲 Drop a Magnet / URL') drop_magnet_or_url ;;
      '▶️  YouTube Archive') yt_download ;;
      '🏴‍☠️ Pirate Grab') manage_pirate_grab ;;
      '🧠 Scavenger Search') manage_scavenger ;;
      '⬇️ Active Downloads') bash ~/pibulus-os/scripts/dlwatch.sh ;;
      '🔎 Find My Media') media_finder_menu ;;
      '📂 Browse Passport Drive') nnn /media/pibulus/passport ;;
      '🌲 Media Tree') show_media_tree; pause_screen ;;
      '🖼️ Cover Art Preview') preview_cover_art; pause_screen ;;
      '📏 Biggest Media Dirs') show_top_media_dirs; pause_screen ;;
      '🕰️ Recent File Activity') show_recent_media; pause_screen ;;
      'ℹ️ Media Info') mediainfo_picker ;;
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
      '🔌 USB / Kernel Noise' \
      '🔼 Mount MEMBOT' \
      '⏏️ Unmount MEMBOT' \
      'Back')
    case "$action" in
      '💾 Drive Status') show_drive_status; pause_screen ;;
      '🔌 USB / Kernel Noise') show_usb_kernel_noise; pause_screen ;;
      '🔼 Mount MEMBOT') safe_mount_membot; pause_screen ;;
      '⏏️ Unmount MEMBOT') safe_unmount_membot; pause_screen ;;
      'Back'|'') return ;;
    esac
  done
}

stacks_menu() {
  while true; do
    render_hud
    show_section_intro \
      'stacks' \
      'Start, stop, or restart Docker stacks. Pirate stack (web, jellyfin, kavita...) excluded — too risky to toggle casually.'
    local stack
    stack=$(tactile_choose \
      '📸 immich' \
      '🕹️  scummvm' \
      '💬 social' \
      '🛠️  admin' \
      '🔧 utilities' \
      'Back')
    case "$stack" in 'Back'|'') return ;; esac

    local yml
    case "$stack" in
      '📸 immich')    yml=~/pibulus-os/config/stacks/immich.yml ;;
      '🕹️  scummvm')  yml=~/pibulus-os/config/stacks/scummvm.yml ;;
      '💬 social')    yml=~/pibulus-os/config/stacks/social.yml ;;
      '🛠️  admin')    yml=~/pibulus-os/config/stacks/admin.yml ;;
      '🔧 utilities') yml=~/pibulus-os/config/stacks/utilities.yml ;;
    esac

    local action
    action=$(tactile_choose '▶️  Start' '⏹️  Stop' '🔄 Restart' '📋 Status' 'Back')
    case "$action" in
      '▶️  Start')   docker compose -f "$yml" up -d; pause_screen ;;
      '⏹️  Stop')    docker compose -f "$yml" down; pause_screen ;;
      '🔄 Restart') docker compose -f "$yml" restart; pause_screen ;;
      '📋 Status')  docker compose -f "$yml" ps; pause_screen ;;
      'Back'|'') ;;
    esac
  done
}

# ── APPS ──────────────────────────────────────────────────────────────────────

# Discover apps: any dir in ~/apps/ that has a corresponding systemd service unit
_discover_apps() {
  local apps_root="/home/pibulus/apps"
  [ -d "$apps_root" ] || return
  for dir in "$apps_root"/*/; do
    local name; name=$(basename "$dir")
    systemctl list-units --type=service --all --no-legend 2>/dev/null \
      | grep -q "^  *${name}\.service" && echo "$name"
  done
}

# Read PORT= from systemd environment or ExecStart --port flag
_app_port() {
  local p
  p=$(systemctl show "$1" --property=Environment 2>/dev/null \
    | sed 's/^Environment=//' | tr ' ' '\n' | grep '^PORT=' | cut -d= -f2 | head -1)
  [ -z "$p" ] && p=$(systemctl show "$1" --property=ExecStart 2>/dev/null \
    | grep -oP '(?<=--port=)\d+' | head -1)
  echo "$p"
}

_app_status_line() {
  local name=$1
  local port; port=$(_app_port "$name")
  local state; state=$(systemctl is-active "$name" 2>/dev/null)
  local color=46; [ "$state" != "active" ] && color=196
  gum style --foreground $color \
    "$(printf '  ● %-18s %s  %s' "$name" "${port:+:$port}" "$state")"
}

app_redeploy() {
  local name=$1
  local dir="/home/pibulus/apps/$name"
  local meta="$dir/.pibulus-meta"
  local github_url=""
  [ -f "$meta" ] && github_url=$(grep '^GITHUB_URL=' "$meta" | head -1 | cut -d= -f2-)

  if [ -z "$github_url" ]; then
    github_url=$(gum input --placeholder "GitHub URL for $name")
    [ -z "$github_url" ] && return
    mkdir -p "$dir"
  else
    if ! gum confirm "Redeploy $name from $github_url?"; then return; fi
  fi

  local tmp="/tmp/$name-redeploy"
  rm -rf "$tmp"
  gum spin --spinner dot --title "Cloning $name..." -- git clone "$github_url" "$tmp" \
    || { gum style --foreground 196 "Clone failed."; pause_screen; return; }

  if [ -f "$tmp/deno.json" ]; then
    local has_build; has_build=$(python3 -c \
      "import json; d=json.load(open('$tmp/deno.json')); print('yes' if 'build' in d.get('tasks',{}) else '')" 2>/dev/null)
    if [ -n "$has_build" ]; then
      gum spin --spinner dot --title "deno task build..." -- \
        bash -c "cd '$tmp' && /home/pibulus/.deno/bin/deno task build 2>/dev/null" \
        || { gum style --foreground 196 "Build failed. Live app left untouched."; rm -rf "$tmp"; pause_screen; return; }
    fi
  elif [ -f "$tmp/package.json" ]; then
    gum spin --spinner dot --title "npm ci..." -- bash -c "cd '$tmp' && npm ci 2>/dev/null" \
      || { gum style --foreground 196 "npm ci failed. Live app left untouched."; rm -rf "$tmp"; pause_screen; return; }
    local has_build; has_build=$(python3 -c \
      "import json; d=json.load(open('$tmp/package.json')); print('yes' if 'build' in d.get('scripts',{}) else '')" 2>/dev/null)
    if [ -n "$has_build" ]; then
      gum spin --spinner dot --title "npm run build..." -- \
        bash -c "cd '$tmp' && npm run build 2>/dev/null" \
        || { gum style --foreground 196 "Build failed. Live app left untouched."; rm -rf "$tmp"; pause_screen; return; }
    fi
  fi

  gum spin --spinner moon --title "Stopping $name..." -- sudo systemctl stop "$name" \
    || { gum style --foreground 196 "Could not stop $name."; rm -rf "$tmp"; pause_screen; return; }
  gum spin --spinner dot --title "Swapping files..." -- \
    bash -c "rsync -a --delete --exclude='.pibulus-meta' --exclude='node_modules/.cache' '$tmp/' '$dir/'" \
    || { gum style --foreground 196 "File swap failed."; pause_screen; return; }
  if [ -f "$dir/package.json" ]; then
    gum spin --spinner dot --title "Installing prod deps..." -- \
      bash -c "cd '$dir' && npm ci --omit=dev 2>/dev/null" \
      || { gum style --foreground 196 "Prod dependency install failed."; pause_screen; return; }
  fi
  printf 'GITHUB_URL=%s\n' "$github_url" > "$dir/.pibulus-meta"

  gum spin --spinner moon --title "Starting $name..." -- sudo systemctl start "$name"
  sleep 1
  local state; state=$(systemctl is-active "$name" 2>/dev/null)
  if [ "$state" = "active" ]; then
    gum style --foreground 46 "✓ $name is live"
  else
    gum style --foreground 196 "✗ $name failed — check: journalctl -u $name -n 30"
  fi
  rm -rf "$tmp"
  pause_screen
}

app_submenu() {
  local name=$1
  while true; do
    render_hud
    local port; port=$(_app_port "$name")
    local state; state=$(systemctl is-active "$name" 2>/dev/null)
    local color=46; [ "$state" != "active" ] && color=196
    gum style --foreground $color --bold "  $name  ${port:+:$port}  [$state]"
    echo
    local action
    action=$(tactile_choose \
      '📋 Status' \
      '📜 Tail Logs' \
      '🔄 Restart' \
      '🌐 Health Ping' \
      '🚀 Redeploy from GitHub' \
      'Back')
    case "$action" in
      '📋 Status') sudo systemctl status "$name" --no-pager; pause_screen ;;
      '📜 Tail Logs') journalctl -u "$name" -n 60 --no-pager \
          | bat --language=log --paging=never 2>/dev/null \
          || journalctl -u "$name" -n 60 --no-pager
        pause_screen ;;
      '🔄 Restart') sudo systemctl restart "$name"; sleep 1
        gum style --foreground 46 "Restarted."; pause_screen ;;
      '🌐 Health Ping')
        local code; code=$(curl -s -o /dev/null -w "%{http_code}" \
          --connect-timeout 3 "http://localhost:${port:-80}" 2>/dev/null)
        if [[ "$code" =~ ^(200|301|302)$ ]]; then
          gum style --foreground 46 "✓ HTTP $code — $name is responding"
        else
          gum style --foreground 196 "✗ HTTP $code — $name not responding${port:+ on :$port}"
        fi
        pause_screen ;;
      '🚀 Redeploy from GitHub') app_redeploy "$name" ;;
      'Back'|'') return ;;
    esac
  done
}

apps_menu() {
  while true; do
    render_hud
    show_section_intro \
      'apps' \
      'Your live apps. All systemd, all on this box, all behind Cloudflare.'
    echo
    # Discover apps dynamically from ~/apps/ + systemd
    local discovered=()
    while IFS= read -r app; do
      discovered+=("$app")
      _app_status_line "$app"
    done < <(_discover_apps)
    echo
    if [ ${#discovered[@]} -eq 0 ]; then
      gum style --foreground 226 "  No apps found in ~/apps/ with a systemd service."
      pause_screen; return
    fi
    # Build the menu from discovered list
    local menu_items=()
    for app in "${discovered[@]}"; do menu_items+=("🗂️ $app"); done
    menu_items+=('Back')
    local action
    action=$(tactile_choose "${menu_items[@]}")
    case "$action" in
      'Back'|'') return ;;
      *) app_submenu "${action#🗂️ }" ;;
    esac
  done
}

# ── CLIP IT ───────────────────────────────────────────────────────────────────

clip_it() {
  local clips_dir="/media/pibulus/passport/clips"
  mkdir -p "$clips_dir"

  local url
  url=$(gum input --placeholder "Paste URL (YouTube or webpage)...")
  [ -z "$url" ] && return

  local ts; ts=$(date +%Y-%m-%d_%H%M)

  if echo "$url" | grep -qE "youtube\.com|youtu\.be"; then
    # YouTube → transcript via yt-dlp auto captions
    local tmpdir; tmpdir=$(mktemp -d)
    gum spin --spinner dot --title "Fetching transcript..." -- \
      yt-dlp --write-auto-sub --sub-lang en --skip-download \
        --sub-format vtt -o "$tmpdir/%(title)s" "$url" 2>/dev/null
    local vtt; vtt=$(ls "$tmpdir"/*.vtt 2>/dev/null | head -1)
    if [ -n "$vtt" ]; then
      local title; title=$(basename "$vtt" .en.vtt)
      local outfile="$clips_dir/${ts}_$(echo "$title" | tr ' /' '_-' | cut -c1-60).txt"
      # Strip VTT timestamps and deduplicate
      python3 -c "
import re, sys
text = open('$vtt').read()
lines = text.split('\n')
seen = set(); out = []
for line in lines:
    line = line.strip()
    if re.match(r'^[\d:.,\-> ]+$', line) or line.startswith('WEBVTT') or line.startswith('Kind:') or line.startswith('Language:'): continue
    if line and line not in seen:
        seen.add(line); out.append(line)
print('\n'.join(out))
" > "$outfile" 2>/dev/null
      rm -rf "$tmpdir"
      gum style --foreground 46 "✓ Saved: $(basename "$outfile")"
      if gum confirm "View it now?"; then
        bat "$outfile" 2>/dev/null || less "$outfile"
      fi
    else
      rm -rf "$tmpdir"
      gum style --foreground 226 "No auto-captions found for this video."
    fi
  else
    # Webpage → trafilatura
    gum spin --spinner dot --title "Extracting content..." -- sleep 0.2
    local outfile="$clips_dir/${ts}_clip.txt"
    python3 -c "
import trafilatura, sys
text = trafilatura.fetch_url('$url')
result = trafilatura.extract(text, include_comments=False, include_tables=False)
if result:
    print(result)
else:
    print('[trafilatura: no main content found]')
" > "$outfile" 2>/dev/null
    local lines; lines=$(wc -l < "$outfile" 2>/dev/null)
    if [ "${lines:-0}" -gt 2 ]; then
      gum style --foreground 46 "✓ Saved $lines lines → $(basename "$outfile")"
      if gum confirm "View it now?"; then
        bat "$outfile" 2>/dev/null || less "$outfile"
      fi
    else
      gum style --foreground 196 "✗ Nothing extracted. Try a different URL."
    fi
  fi
  pause_screen
}

# ── QUICK EDIT ────────────────────────────────────────────────────────────────

quick_edit() {
  if ! tool_exists fzf; then echo "fzf not installed."; pause_screen; return; fi
  if ! tool_exists micro; then echo "micro not installed."; pause_screen; return; fi
  local search_roots=(/home/pibulus/apps /home/pibulus/pibulus-os)
  local file
  file=$(find "${search_roots[@]}" -type f \
    \( -name "*.js" -o -name "*.ts" -o -name "*.svelte" -o -name "*.json" \
       -o -name "*.sh" -o -name "*.yml" -o -name "*.yaml" -o -name "*.env" \
       -o -name "*.md" -o -name "*.jsonc" \) \
    ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/_fresh/*" \
    2>/dev/null \
    | fzf --prompt="edit > " --preview='bat --color=always --line-range :80 {}' \
          --preview-window=right:60% --height=80%)
  [ -n "$file" ] && micro "$file"
}

ops_menu() {
  while true; do
    render_hud
    show_section_intro \
      'ops' \
      'Sharp tools for changing the box. Not vibes. Real interventions.'
    local action
    action=$(tactile_choose \
      '⚡ Staggered Startup' \
      '🚀 Deploy Something New' \
      '🧹 Flush RAM' \
      '📦 Stacks' \
      '🔍 Inspect Stack' \
      '💾 Drive Bay' \
      'Back')
    case "$action" in
      '⚡ Staggered Startup') ~/pibulus-os/scripts/startup.sh; pause_screen ;;
      '🚀 Deploy Something New') ~/pibulus-os/scripts/deploy.sh ;;
      '🧹 Flush RAM') ~/pibulus-os/scripts/flush_ram.sh; pause_screen ;;
      '📦 Stacks') stacks_menu ;;
      '🔍 Inspect Stack') inspect_stack ;;
      '💾 Drive Bay') drives_menu ;;
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
    action=$(tactile_choose --height 16 \
      '✍️ Write Field Note' \
      '📜 Recent Notes' \
      '🔍 Search Notes' \
      '✨ Pretty Viewer' \
      '📖 Field Manual' \
      '📰 Feed Reader' \
      '✂️ Clip It' \
      '📚 tldr' \
      '👁️ Watch & Run' \
      '✏️ Quick Edit' \
      '🧵 tmux' \
      '💬 Chat' \
      '📋 Cheatsheets' \
      '🎨 Eye Candy' \
      '🔮 Oracle' \
      'Back')
    case "$action" in
      '✍️ Write Field Note') write_field_note; pause_screen ;;
      '📜 Recent Notes') show_recent_notes; pause_screen ;;
      '🔍 Search Notes') search_field_notes ;;
      '✨ Pretty Viewer') open_notes_in_glow ;;
      '📖 Field Manual') open_field_manual_pretty ;;
      '📰 Feed Reader') open_feed_reader ;;
      '✂️ Clip It') clip_it ;;
      '📚 tldr') tldr_lookup ;;
      '👁️ Watch & Run') entr_watch ;;
      '✏️ Quick Edit') quick_edit ;;
      '🧵 tmux') open_tmux_shell ;;
      '💬 Chat') open_chat_client ;;
      '📋 Cheatsheets') open_cheatsheets ;;
      '🎨 Eye Candy') eye_candy ;;
      '🔮 Oracle') show_oracle ;;
      'Back'|'') return ;;
    esac
  done
}

ai_menu() {
  while true; do
    render_hud
    show_section_intro \
      'ai' \
      'Direct lines to the machines. Standard = confirmation prompts. Full autonomy = unsupervised execution. Handle accordingly.'
    local action
    action=$(tactile_choose \
      '🤖 Claude' \
      '🔓 Claude — full autonomy' \
      '💎 Gemini' \
      '🔓 Gemini — full autonomy' \
      '⚡ Codex' \
      '🔓 Codex — full autonomy' \
      'Back')
    case "$action" in
      '🤖 Claude') claude ;;
      '🔓 Claude — full autonomy') claude --dangerously-skip-permissions ;;
      '💎 Gemini') gemini ;;
      '🔓 Gemini — full autonomy') gemini --yolo ;;
      '⚡ Codex') codex ;;
      '🔓 Codex — full autonomy') codex --dangerously-bypass-approvals-and-sandbox ;;
      'Back'|'') return ;;
    esac
  done
}

# ── RECON ─────────────────────────────────────────────────────────────────────

recon_menu() {
  while true; do
    render_hud
    show_section_intro \
      'recon' \
      'Passive before active. Your own network first. Know the territory before you move.'
    local action
    action=$(tactile_choose --height 12 \
      '🗺️ LAN Map' \
      '👁️ Passive Scan' \
      '🌊 Live Traffic' \
      '🔍 Web Fingerprint' \
      '🌐 OSINT Harvest' \
      '🧅 Tor Status' \
      '🔐 Box Audit' \
      '📡 Wireless Watch' \
      '📖 Cheatsheets' \
      'Back')
    case "$action" in
      '🗺️ LAN Map')
        if tool_exists nmap; then
          local subnet
          subnet=$(ip -4 addr show eth0 2>/dev/null | awk '/inet / {print $2}' | head -1)
          subnet="${subnet:-192.168.1.0/24}"
          gum style --foreground 212 "  scanning $subnet ..."
          echo
          nmap -sn "$subnet"
          pause_screen
        else
          gum style --foreground 196 "  nmap not installed — sudo apt install nmap"
          pause_screen
        fi ;;
      '👁️ Passive Scan')
        if tool_exists bettercap; then
          gum style --foreground 212 "  running bettercap ARP probe — Ctrl-C to stop"
          echo
          sudo bettercap -eval "net.probe on; sleep 5; net.show; quit"
          pause_screen
        else
          gum style --foreground 196 "  bettercap not installed — sudo apt install bettercap"
          pause_screen
        fi ;;
      '🌊 Live Traffic')
        if tool_exists tshark; then
          local iface
          iface=$(ip -4 route show default 2>/dev/null | awk '/default/ {print $5}' | head -1)
          iface="${iface:-eth0}"
          gum style --foreground 212 "  capturing on $iface — Ctrl-C to stop"
          echo
          sudo tshark -i "$iface" 2>/dev/null
        else
          gum style --foreground 196 "  tshark not installed — sudo apt install tshark"
          pause_screen
        fi ;;
      '🔍 Web Fingerprint')
        if tool_exists whatweb; then
          local target
          target=$(gum input --placeholder "URL to fingerprint (e.g. https://example.com)")
          [ -z "$target" ] && continue
          echo
          whatweb --color=always "$target"
          pause_screen
        else
          gum style --foreground 196 "  whatweb not installed — sudo apt install whatweb"
          pause_screen
        fi ;;
      '🌐 OSINT Harvest')
        if tool_exists theHarvester; then
          local domain
          domain=$(gum input --placeholder "domain to harvest (e.g. example.com)")
          [ -z "$domain" ] && continue
          echo
          theHarvester -d "$domain" -b all 2>/dev/null | head -80
          pause_screen
        else
          gum style --foreground 196 "  theHarvester not installed — sudo apt install theharvester"
          pause_screen
        fi ;;
      '🧅 Tor Status')
        echo
        gum style --foreground 212 "  tor service:"
        systemctl is-active tor 2>/dev/null || echo "  not running"
        echo
        if tool_exists curl; then
          gum style --foreground 212 "  exit node IP:"
          torify curl -s https://check.torproject.org/api/ip 2>/dev/null && echo || echo "  torify unavailable"
          echo
          gum style --foreground 212 "  direct IP:"
          curl -fsS https://1.1.1.1/cdn-cgi/trace 2>/dev/null | grep '^ip=' | cut -d= -f2 || echo "  unreachable"
        fi
        pause_screen ;;
      '🔐 Box Audit')
        if tool_exists lynis; then
          gum confirm "Run full lynis audit? Takes ~2 minutes." && {
            echo
            sudo lynis audit system
            pause_screen
          }
        else
          gum style --foreground 196 "  lynis not installed — sudo apt install lynis"
          pause_screen
        fi ;;
      '📡 Wireless Watch')
        if tool_exists kismet; then
          local wiface
          wiface=$(gum input --placeholder "monitor-mode interface (e.g. wlan1)")
          [ -z "$wiface" ] && continue
          sudo kismet -c "$wiface"
        else
          gum style --foreground 196 "  kismet not installed — sudo apt install kismet"
          gum style --foreground 240 "  also needs a monitor-mode USB WiFi adapter (Alfa AWUS036ACM)"
          pause_screen
        fi ;;
      '📖 Cheatsheets') open_cheatsheets nmap tshark bettercap netcat tor-proxychains lynis scapy ;;
      'Back'|'') return ;;
    esac
  done
}

# ── SDR ───────────────────────────────────────────────────────────────────────

sdr_menu() {
  while true; do
    render_hud
    show_section_intro \
      'sdr' \
      'Airband, community radio, pager goblins, utility chatter, and 433MHz hauntings. Audio modes play from the Pi itself, not the SSH terminal.'
    local action
    action=$(tactile_choose \
      '🧭 SDR Snapshot' \
      '🧪 Self Test' \
      '🌐 Remote Stream' \
      '❓ Deck Help' \
      '📻 FM Presets' \
      '🎛️ Tune FM' \
      '🛫 Airband Listen' \
      '🚓 Utility / Public Safety Listen (Analog)' \
      '🌡️ 433MHz Hunt' \
      '📟 Pager Hunt' \
      '✈️ Plane Radar (ADS-B)' \
      '📖 Cheatsheets' \
      'Back')
    case "$action" in
      '🧭 SDR Snapshot')
        show_sdr_snapshot
        pause_screen ;;
      '🧪 Self Test')
        run_sdr_lab selftest
        pause_screen ;;
      '🌐 Remote Stream')
        run_sdr_lab remote-status || true
        pause_screen ;;
      '❓ Deck Help')
        open_local_browserish 'http://pibulus.local/deck/help.html' ;;
      '📻 FM Presets')
        sdr_fm_presets_menu ;;
      '🎛️ Tune FM')
        local freq
        freq=$(gum input --placeholder "FM frequency in MHz (e.g. 95.8)")
        [ -z "$freq" ] && continue
        run_sdr_lab fm "$freq" ;;
      '🛫 Airband Listen')
        local freq
        freq=$(gum input --placeholder "Airband frequency in MHz (default: 118.0)")
        freq="${freq:-118.0}"
        run_sdr_lab airband "$freq" ;;
      '🚓 Utility / Public Safety Listen (Analog)')
        local freq
        freq=$(gum input --placeholder "Narrowband FM frequency in MHz (e.g. 460.550)")
        [ -z "$freq" ] && continue
        run_sdr_lab nfm "$freq" ;;
      '🌡️ 433MHz Hunt')
        run_sdr_lab 433 ;;
      '📟 Pager Hunt')
        local freq
        freq=$(gum input --placeholder "Pager frequency in MHz (default: 152.25)")
        freq="${freq:-152.25}"
        run_sdr_lab pagers "$freq" ;;
      '✈️ Plane Radar (ADS-B)')
        run_sdr_lab planes
        pause_screen ;;
      '📖 Cheatsheets') open_cheatsheets rtl-sdr ;;
      'Back'|'') return ;;
    esac
  done
}

# ── UNDERGROUND ───────────────────────────────────────────────────────────────

underground_menu() {
  while true; do
    render_hud
    show_section_intro \
      'underground' \
      'The pre-web internet never died. Tilde communities, Gemini, Usenet, IRC — all still running.'
    local action
    action=$(tactile_choose --height 12 \
      '🕹️  Textworlds (BBS / MUD / Wonders)' \
      '🌌 Gemini Browser' \
      '🐚 SDF Public UNIX' \
      '🏘️ Tilde.town' \
      '📰 Usenet' \
      '💬 IRC' \
      '🎨 ANSI Art' \
      '🔮 Oracle' \
      '📖 Cheatsheets' \
      'Back')
    case "$action" in
      '🕹️  Textworlds (BBS / MUD / Wonders)')
        if [ -x "$HOME/pibulus-os/public-deck.sh" ]; then
          bash "$HOME/pibulus-os/public-deck.sh"
        else
          gum style --foreground 196 "  public-deck.sh not found"
          pause_screen
        fi ;;
      '🌌 Gemini Browser')
        if tool_exists amfora; then
          amfora
        elif tool_exists bombadillo; then
          bombadillo
        else
          gum style --foreground 196 "  no Gemini browser found"
          gum style --foreground 240 "  snap install amfora  OR  go install tildegit.org/sloum/bombadillo@latest"
          echo
          echo "  good starting capsules:"
          echo "  gemini://gemini.circumlunar.space"
          echo "  gemini://tilde.town"
          echo "  gemini://rawtext.club"
          pause_screen
        fi ;;
      '🐚 SDF Public UNIX')
        gum style --foreground 212 "  connecting to SDF (public UNIX since 1987)..."
        echo "  free account: https://sdf.org"
        echo
        ssh -4 sdf.org ;;
      '🏘️ Tilde.town')
        gum style --foreground 212 "  connecting to tilde.town..."
        echo "  part of the tildeverse — small public linux boxes run with care"
        echo
        ssh -4 tilde.town ;;
      '📰 Usenet')
        gum style --foreground 212 "  eternal-september.org — free text Usenet access"
        echo "  register: https://www.eternal-september.org"
        echo
        if tool_exists slrn; then
          NNTPSERVER=news.eternal-september.org slrn
        elif tool_exists tin; then
          tin -g news.eternal-september.org
        else
          gum style --foreground 196 "  no newsreader found"
          gum style --foreground 240 "  sudo apt install slrn"
          pause_screen
        fi ;;
      '💬 IRC')
        local pick
        pick=$(printf '%s\n' \
          'Libera.chat (open source / tech)' \
          'Hackint (hacker/security)' \
          'EFnet (the original)' \
          'IRCnet (old school EU)' \
          'Back' | gum choose)
        local server
        case "$pick" in
          'Libera.chat (open source / tech)') server='irc.libera.chat' ;;
          'Hackint (hacker/security)') server='irc.hackint.org' ;;
          'EFnet (the original)') server='irc.efnet.org' ;;
          'IRCnet (old school EU)') server='open.ircnet.net' ;;
          *) continue ;;
        esac
        if tool_exists weechat; then
          weechat
        elif tool_exists irssi; then
          irssi --connect "$server"
        else
          gum style --foreground 196 "  no IRC client — sudo apt install weechat"
          pause_screen
        fi ;;
      '🎨 ANSI Art')
        local pick
        pick=$(printf '%s\n' \
          'Local .ans / .nfo files' \
          'Cowsay gallery' \
          'figlet fonts showcase' \
          'Back' | gum choose)
        case "$pick" in
          'Local .ans / .nfo files')
            if tool_exists chafa && tool_exists fzf; then
              local file
              file=$(find ~ /media/pibulus/passport -name '*.ans' -o -name '*.nfo' -o -name '*.asc' 2>/dev/null \
                | head -200 | fzf --prompt="pick art > " --height 20 --border 2>/dev/null || true)
              [ -n "$file" ] && { chafa "$file" 2>/dev/null || cat "$file"; pause_screen; }
            else
              gum style --foreground 196 "  needs chafa + fzf"
              pause_screen
            fi ;;
          'Cowsay gallery')
            if tool_exists cowsay; then
              cowsay -l | tail -n +2 | tr ' ' '\n' | while read -r cow; do
                clear
                printf '  %s\n\n' "$cow"
                cowsay -f "$cow" "Quick Cat Club" 2>/dev/null | rainbow
                sleep 1
              done
            else
              gum style --foreground 196 "  cowsay not installed — sudo apt install cowsay"
              pause_screen
            fi ;;
          'figlet fonts showcase')
            if tool_exists figlet; then
              figlet -l | head -20 | while read -r font; do
                clear
                figlet -f "$font" "QUICK CAT" 2>/dev/null | rainbow
                gum style --foreground 240 "  font: $font"
                sleep 1.2
              done
            else
              gum style --foreground 196 "  figlet not installed — sudo apt install figlet"
              pause_screen
            fi ;;
        esac ;;
      '🔮 Oracle') show_oracle ;;
      '📖 Cheatsheets') open_cheatsheets gemini weechat sdf-tilde ;;
      'Back'|'') return ;;
    esac
  done
}

# ── ORACLE ────────────────────────────────────────────────────────────────────

show_oracle() {
  clear
  echo
  if tool_exists fortune; then
    fortune | rainbow
  else
    local wisdoms=(
      "The map is not the territory."
      "Complexity is the enemy of security."
      "Every packet is a postcard."
      "Root access is a responsibility, not a trophy."
      "The best firewall is understanding why you need one."
      "There are no backdoors that only the good guys can use."
      "Security through obscurity is not security."
      "If you can't explain it simply, you don't understand it well enough."
      "The network is the computer. You are on the network."
      "Real power is not needing anyone to see it."
    )
    local idx=$(( RANDOM % ${#wisdoms[@]} ))
    echo "  ${wisdoms[$idx]}" | rainbow
  fi
  echo
  if tool_exists cowsay && tool_exists fortune; then
    echo
    fortune | cowsay -f $(cowsay -l | tail -n +2 | tr ' ' '\n' | shuf | head -1) 2>/dev/null | rainbow
  fi
  echo
  pause_screen
}

# ── EYE CANDY ─────────────────────────────────────────────────────────────────

eye_candy() {
  while true; do
    render_hud
    show_section_intro \
      'eye candy' \
      'Decorative computation. Justified purely on aesthetic grounds.'
    local pick
    pick=$(tactile_choose \
      '🌧️ Matrix Rain' \
      '🚂 Steam Locomotive' \
      '🐟 Aquarium' \
      '🌿 Bonsai Loop' \
      '🕐 Terminal Clock' \
      '🐮 Cowsay' \
      '🌈 figlet Rainbow' \
      '🔮 Oracle' \
      'Back')
    case "$pick" in
      '🌧️ Matrix Rain')
        tool_exists cmatrix && cmatrix \
          || { gum style --foreground 196 "  sudo apt install cmatrix"; pause_screen; } ;;
      '🚂 Steam Locomotive')
        tool_exists sl && sl \
          || { gum style --foreground 196 "  sudo apt install sl"; pause_screen; } ;;
      '🐟 Aquarium')
        tool_exists asciiquarium && asciiquarium \
          || { gum style --foreground 196 "  sudo apt install asciiquarium"; pause_screen; } ;;
      '🌿 Bonsai Loop')
        tool_exists cbonsai && cbonsai -l -t 0.08 \
          || { gum style --foreground 196 "  cbonsai not found"; pause_screen; } ;;
      '🕐 Terminal Clock')
        tool_exists tty-clock && tty-clock -c -C 5 \
          || { gum style --foreground 196 "  sudo apt install tty-clock"; pause_screen; } ;;
      '🐮 Cowsay')
        if tool_exists cowsay; then
          local msg
          msg=$(gum input --placeholder "say what?")
          [ -n "$msg" ] && echo "$msg" | cowsay | rainbow
          pause_screen
        else
          gum style --foreground 196 "  sudo apt install cowsay"
          pause_screen
        fi ;;
      '🌈 figlet Rainbow')
        if tool_exists figlet; then
          local txt
          txt=$(gum input --placeholder "text to render")
          [ -n "$txt" ] && figlet -f big "$txt" | rainbow
          pause_screen
        else
          gum style --foreground 196 "  sudo apt install figlet"
          pause_screen
        fi ;;
      '🔮 Oracle') show_oracle ;;
      'Back'|'') return ;;
    esac
  done
}

# ── CHEATSHEETS ───────────────────────────────────────────────────────────────

open_cheatsheets() {
  # Args: optional list of sheet names (without .md) to scope the menu.
  # No args = show everything.
  local dir="$HOME/pibulus-os/docs/cheatsheets"
  if [ ! -d "$dir" ]; then
    gum style --foreground 196 "  no cheatsheets found at $dir"
    pause_screen
    return
  fi
  local names=()
  if [ $# -gt 0 ]; then
    for name in "$@"; do
      [ -f "$dir/$name.md" ] && names+=("$name")
    done
  else
    while IFS= read -r f; do
      names+=("$(basename "$f" .md)")
    done < <(ls "$dir"/*.md 2>/dev/null)
  fi
  if [ ${#names[@]} -eq 0 ]; then
    gum style --foreground 196 "  no matching cheatsheets found"
    pause_screen
    return
  fi
  local pick
  pick=$(printf '%s\n' "${names[@]}" | gum choose --height 14 --header "  pick a tool")
  [ -z "$pick" ] && return
  if tool_exists glow; then
    glow -p "$dir/$pick.md"
  else
    bat --language markdown "$dir/$pick.md" 2>/dev/null || less "$dir/$pick.md"
  fi
}

_first_run=1
while true; do
  render_hud
  render_dashboard_panel
  if [ "$_first_run" = "1" ]; then
    echo "$(roll_fascination)" | rainbow
    _first_run=0
  fi
  choice=$(tactile_choose --height 16 \
    '🔭 sigint' \
    '🕵️ recon' \
    '🎛️ sdr' \
    '📻 radio' \
    '🎬 media' \
    '🎵 soulseek' \
    '📝 desk' \
    '🤖 ai' \
    '🕸️ underground' \
    '📡 network' \
    '🛠️ ops' \
    '⚙️ apps' \
    '🐱 club' \
    '🚪 shell')

  case "$choice" in
    '🔭 sigint') sigint_menu ;;
    '🕵️ recon') recon_menu ;;
    '🎛️ sdr') sdr_menu ;;
    '📻 radio') radio_menu ;;
    '🎬 media') media_menu ;;
    '🎵 soulseek') slskd_menu ;;
    '📝 desk') desk_menu ;;
    '🤖 ai') ai_menu ;;
    '🕸️ underground') underground_menu ;;
    '📡 network') network_menu ;;
    '🛠️ ops') ops_menu ;;
    '⚙️ apps') apps_menu ;;
    '🐱 club') club_menu ;;
    '🚪 shell'|'') clear; echo 'Neural link suspended. Dropping to shell. Run launcher.sh to return.'; exec bash -l ;;
  esac
done
