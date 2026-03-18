#!/bin/bash
set -euo pipefail

HOTSPOT_CONN="KPAB-Hotspot"
HOME_WIFI_CONN="netplan-wlan0-praise.bob"
WIFI_DEV="wlan0"
ETH_DEV="eth0"

has_conn() {
  nmcli -t -f NAME connection show | grep -Fxq "$1"
}

active_conn_for() {
  nmcli -t -f DEVICE,CONNECTION device status | awk -F: -v dev="$1" '$1 == dev { print $2 }'
}

show_status() {
  echo "== network mode =="
  printf "eth0: %s\n" "$(active_conn_for "$ETH_DEV")"
  printf "wlan0: %s\n" "$(active_conn_for "$WIFI_DEV")"
  echo
  nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status
  echo
  ip -brief addr show "$ETH_DEV" "$WIFI_DEV" 2>/dev/null || true
}

away_mode() {
  echo "Bringing up hotspot on $WIFI_DEV..."
  sudo nmcli connection up "$HOTSPOT_CONN"
  echo "Away mode active. SSID: pibulus-deck"
}

home_mode() {
  local current
  current="$(active_conn_for "$WIFI_DEV")"

  if [ "$current" = "$HOTSPOT_CONN" ]; then
    echo "Bringing hotspot down..."
    sudo nmcli connection down "$HOTSPOT_CONN" || true
  fi

  if has_conn "$HOME_WIFI_CONN"; then
    echo "Bringing home Wi-Fi up..."
    sudo nmcli connection up "$HOME_WIFI_CONN" || true
  else
    echo "Home Wi-Fi profile not found; leaving wlan0 idle."
  fi

  echo "Home mode active."
}

case "${1:-status}" in
  status)
    show_status
    ;;
  away|hotspot-on)
    away_mode
    show_status
    ;;
  home|hotspot-off)
    home_mode
    show_status
    ;;
  *)
    echo "Usage: $0 [status|away|home|hotspot-on|hotspot-off]"
    exit 1
    ;;
esac
