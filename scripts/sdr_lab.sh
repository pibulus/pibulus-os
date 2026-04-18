#!/bin/bash
set -euo pipefail

have() {
  command -v "$1" >/dev/null 2>&1
}

tool_path() {
  local candidate
  for candidate in "$@"; do
    [ -n "$candidate" ] || continue
    if command -v "$candidate" >/dev/null 2>&1; then
      command -v "$candidate"
      return 0
    fi
    if [ -x "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

rainbow() {
  if have lolcat; then
    lolcat
  else
    cat
  fi
}

banner() {
  if have figlet; then
    figlet -f small "SDR LAB" | rainbow
  else
    printf 'SDR LAB\n' | rainbow
  fi
}

RTL_HINT_PATTERN='NESDR|Nooelec|RTL2838|RTL2832|RTL-SDR|Realtek'
RTL_MODULES=(
  rtl2832_sdr
  rtl2832
  r820t
  dvb_usb_rtl28xxu
  dvb_usb_v2
)
RTL_RESTORE_NEEDED=0
SDR_REMOTE_BASE="${SDR_REMOTE_BASE:-http://127.0.0.1:8097}"

find_dongle() {
  lsusb 2>/dev/null | grep -Ei "$RTL_HINT_PATTERN" || true
}

dongle_present() {
  find_dongle | grep -q .
}

kernel_claimed() {
  ls /dev/swradio* /dev/dvb/adapter0/* >/dev/null 2>&1
}

tool_mark() {
  local label="$1"
  shift
  if tool_path "$@" >/dev/null 2>&1; then
    printf '🟢 %-12s\n' "$label"
  else
    printf '🔴 %-12s\n' "$label"
  fi
}

find_plane_radar_bin() {
  if tool_path /usr/local/bin/readsb-rtl /home/pibulus/pibulus-os/bin/readsb-rtl; then
    return 0
  fi

  if have readsb && readsb --help 2>/dev/null | grep -q 'rtlsdr'; then
    command -v readsb
    return 0
  fi

  return 1
}

audio_route_line() {
  local sink="unknown"
  if have aplay; then
    sink=$(aplay -L 2>/dev/null | awk '/^default$/{getline; gsub(/^[[:space:]]+/, "", $0); print; exit}')
  fi
  printf '%s\n' "${sink:-unknown}"
}

remote_payload() {
  python3 - "$@" <<'PY'
import json
import sys

mode = sys.argv[1]
freq = sys.argv[2]
print(json.dumps({"mode": mode, "freq": freq}))
PY
}

remote_request() {
  local method="$1"
  local path="$2"
  local body="${3:-}"
  if [ -n "$body" ]; then
    curl -fsS -X "$method" -H 'Content-Type: application/json' -d "$body" "${SDR_REMOTE_BASE}${path}"
  else
    curl -fsS -X "$method" "${SDR_REMOTE_BASE}${path}"
  fi
}

show_remote_urls() {
  echo "Remote SDR page:"
  echo "  https://deck.quickcat.club/sdr/"
  echo "  http://pibulus.local/sdr/"
  echo
  echo "Direct stream URL (when live):"
  echo "  https://deck.quickcat.club/sdr/stream.mp3"
}

show_remote_status() {
  local raw
  if ! raw=$(remote_request GET /status 2>/dev/null); then
    echo "Remote SDR service is down."
    echo "Expected local endpoint: ${SDR_REMOTE_BASE}"
    return 1
  fi
  python3 - <<'PY' "$raw"
import json
import sys

data = json.loads(sys.argv[1])
print("Remote stream")
print("=============")
print(f"Active: {'yes' if data.get('active') else 'no'}")
print(f"Mode: {data.get('mode') or '--'}")
print(f"Frequency: {(data.get('frequency_mhz') or '--')}")
print(f"Listeners: {data.get('listeners', 0)}")
print(f"Idle timeout: {data.get('idle_timeout_seconds', 0)}s")
if data.get('uptime_seconds'):
    print(f"Uptime: {data['uptime_seconds']}s")
if data.get('last_error'):
    print(f"Last error: {data['last_error']}")
PY
  echo
  show_remote_urls
}

show_status() {
  banner
  echo
  echo "Dongle"
  echo "======"
  if dongle_present; then
    find_dongle
  else
    echo "No RTL-ish dongle detected on USB."
  fi
  echo
  echo "Device nodes"
  echo "============"
  if kernel_claimed; then
    ls -1 /dev/swradio* /dev/dvb/adapter0/* 2>/dev/null
  else
    echo "No kernel-owned SDR/DVB nodes right now."
  fi
  echo
  echo "Mode"
  echo "===="
  if kernel_claimed; then
    echo "Kernel DVB/SDR drivers are attached."
    echo "The helper will temporarily release them before rtl_* tools run."
  else
    echo "Userspace mode looks free for rtl_* tools."
  fi
  echo
  echo "Toolchain"
  echo "========="
  tool_mark rtl_test rtl_test
  tool_mark rtl_fm rtl_fm
  tool_mark rtl_433 rtl_433
  tool_mark multimon-ng multimon-ng
  tool_mark sox sox
  tool_mark ffplay ffplay
  tool_mark readsb-rtl /usr/local/bin/readsb-rtl readsb
  tool_mark direwolf direwolf
  tool_mark gqrx gqrx
  tool_mark CubicSDR CubicSDR
  tool_mark inspectrum inspectrum
  tool_mark dsdccx dsdccx
  echo
  echo "Audio route"
  echo "==========="
  echo "Default ALSA sink: $(audio_route_line)"
  if [ -n "${SSH_CONNECTION:-}" ]; then
    echo "You are on SSH, so audio stays on the Pi's local output."
  fi
  echo
  echo "Recent kernel chatter"
  echo "====================="
  dmesg | tail -n 12 | sed 's/^/  /'
}

release_kernel_drivers() {
  local mod
  for mod in "${RTL_MODULES[@]}"; do
    if lsmod | awk '{print $1}' | grep -qx "$mod"; then
      sudo modprobe -r "$mod" >/dev/null 2>&1 || true
    fi
  done
}

restore_kernel_drivers() {
  sudo modprobe dvb_usb_rtl28xxu >/dev/null 2>&1 || true
  sudo modprobe rtl2832 >/dev/null 2>&1 || true
  sudo modprobe rtl2832_sdr >/dev/null 2>&1 || true
  sudo modprobe r820t >/dev/null 2>&1 || true
}

cleanup_rtl() {
  if [ "${RTL_RESTORE_NEEDED:-0}" -eq 1 ]; then
    restore_kernel_drivers
    RTL_RESTORE_NEEDED=0
  fi
}

run_with_rtl() {
  RTL_RESTORE_NEEDED=0
  if kernel_claimed; then
    release_kernel_drivers
    RTL_RESTORE_NEEDED=1
  fi

  trap cleanup_rtl EXIT INT TERM
  "$@"
  local code=$?
  trap - EXIT INT TERM
  cleanup_rtl
  return "$code"
}

need_bin() {
  local bin="$1"
  local hint="$2"
  if ! have "$bin"; then
    echo "Missing $bin."
    echo "$hint"
    exit 1
  fi
}

announce_audio_route() {
  echo "Audio sink: $(audio_route_line)"
  if [ -n "${SSH_CONNECTION:-}" ]; then
    echo "This is SSH, so you will not hear audio in the terminal itself."
    echo "Sound comes out of the Pi's local ALSA output instead."
  fi
}

run_selftest() {
  need_bin rtl_test "Install with: sudo apt install rtl-sdr"
  run_with_rtl rtl_test -t
}

run_fm() {
  local freq="${1:-}"
  if [ -z "$freq" ]; then
    echo "Usage: $0 fm <freq-mhz>"
    exit 1
  fi

  need_bin rtl_fm "Install with: sudo apt install rtl-sdr"
  if ! have sox && ! have ffplay; then
    echo "Need an audio sink: sox or ffplay."
    echo "Install with: sudo apt install sox"
    exit 1
  fi

  echo "Tuning ${freq} MHz. Ctrl-C to stop."
  announce_audio_route
  if have sox; then
    run_with_rtl bash -lc "rtl_fm -f '${freq}M' -M wbfm -s 200000 -r 48000 - | sox -q -t raw -r 48k -e signed -b 16 -c 1 - -d"
  else
    run_with_rtl bash -lc "rtl_fm -f '${freq}M' -M wbfm -s 200000 -r 48000 - | ffplay -nodisp -autoexit -f s16le -ar 48000 -ac 1 -"
  fi
}

run_airband() {
  local freq="${1:-118.0}"
  need_bin rtl_fm "Install with: sudo apt install rtl-sdr"
  if ! have sox && ! have ffplay; then
    echo "Need an audio sink: sox or ffplay."
    echo "Install with: sudo apt install sox"
    exit 1
  fi

  echo "Monitoring airband ${freq} MHz AM. Ctrl-C to stop."
  announce_audio_route
  if have sox; then
    run_with_rtl bash -lc "rtl_fm -f '${freq}M' -M am -s 12k -r 24k -A fast - | sox -q -t raw -r 24k -e signed -b 16 -c 1 - -d"
  else
    run_with_rtl bash -lc "rtl_fm -f '${freq}M' -M am -s 12k -r 24k -A fast - | ffplay -nodisp -autoexit -f s16le -ar 24000 -ac 1 -"
  fi
}

run_nfm() {
  local freq="${1:-}"
  if [ -z "$freq" ]; then
    echo "Usage: $0 nfm <freq-mhz>"
    exit 1
  fi

  need_bin rtl_fm "Install with: sudo apt install rtl-sdr"
  if ! have sox && ! have ffplay; then
    echo "Need an audio sink: sox or ffplay."
    echo "Install with: sudo apt install sox"
    exit 1
  fi

  echo "Monitoring utility/public-safety style narrowband FM at ${freq} MHz. Ctrl-C to stop."
  announce_audio_route
  if have sox; then
    run_with_rtl bash -lc "rtl_fm -f '${freq}M' -M fm -s 24k -r 24k -A fast -E dc - | sox -q -t raw -r 24k -e signed -b 16 -c 1 - -d"
  else
    run_with_rtl bash -lc "rtl_fm -f '${freq}M' -M fm -s 24k -r 24k -A fast -E dc - | ffplay -nodisp -autoexit -f s16le -ar 24000 -ac 1 -"
  fi
}

run_433() {
  need_bin rtl_433 "Install with: sudo apt install rtl-433"
  echo "Listening for 433 MHz mischief. Ctrl-C to stop."
  run_with_rtl rtl_433 -M time:iso -M level
}

run_pagers() {
  local freq="${1:-152.25}"
  need_bin rtl_fm "Install with: sudo apt install rtl-sdr"
  need_bin multimon-ng "Install with: sudo apt install multimon-ng"
  echo "Decoding pagers around ${freq} MHz. Ctrl-C to stop."
  run_with_rtl bash -lc "rtl_fm -f '${freq}M' -M fm -s 22050 - | multimon-ng -t raw -a POCSAG512 -a POCSAG1200 -a POCSAG2400 -f alpha /dev/stdin"
}

run_planes() {
  local plane_bin
  plane_bin=$(find_plane_radar_bin) || {
    echo "No RTL-capable ADS-B decoder found."
    echo "Build readsb with RTLSDR support or install a compatible plane-radar binary."
    exit 1
  }

  echo "Launching ADS-B plane radar with $(basename "$plane_bin"). Ctrl-C to stop."
  run_with_rtl env TERM=xterm "$plane_bin" --interactive --device-type rtlsdr --gain auto
}

run_remote_start() {
  local mode="${1:-}"
  local freq="${2:-}"
  if [ -z "$mode" ] || [ -z "$freq" ]; then
    echo "Usage: $0 remote-start <fm|airband|nfm> <freq-mhz>"
    exit 1
  fi

  remote_request POST /start "$(remote_payload "$mode" "$freq")"
  echo
  show_remote_urls
}

run_remote_stop() {
  remote_request POST /stop
}

usage() {
  cat <<'EOF'
Usage: sdr_lab.sh <command> [args]

Commands:
  status           Show dongle state, nodes, and installed SDR tools
  selftest         Run rtl_test against the dongle
  fm <mhz>         Listen to an FM station
  airband [mhz]    Listen to AM airband (default: 118.0 MHz)
  nfm <mhz>        Listen to narrowband FM utility/public-safety audio
  433              Hunt 433 MHz sensors
  pagers [mhz]     Decode POCSAG pager traffic (default: 152.25 MHz)
  planes           Run live ADS-B plane radar
  remote-status    Show remote stream state + URLs
  remote-start     Start remote stream (mode + freq)
  remote-stop      Stop the remote stream
  remote-url       Print the remote SDR URLs
  release          Unload kernel DVB/SDR drivers
  restore          Reload kernel DVB/SDR drivers
EOF
}

main() {
  local cmd="${1:-status}"
  shift || true
  case "$cmd" in
    status) show_status ;;
    selftest) run_selftest ;;
    fm) run_fm "${1:-}" ;;
    airband) run_airband "${1:-118.0}" ;;
    nfm) run_nfm "${1:-}" ;;
    433) run_433 ;;
    pagers) run_pagers "${1:-152.25}" ;;
    planes) run_planes ;;
    remote-status) show_remote_status ;;
    remote-start) run_remote_start "${1:-}" "${2:-}" ;;
    remote-stop) run_remote_stop ;;
    remote-url) show_remote_urls ;;
    release) release_kernel_drivers ;;
    restore) restore_kernel_drivers ;;
    *) usage; exit 1 ;;
  esac
}

main "$@"
