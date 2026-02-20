#!/bin/bash
# 🔍 QUICK CAT CLUB - FM SILENCE FINDER

echo "Scanning FM Band (88MHz - 108MHz)..."
echo "[Plug in your Nooelec SDR now]"

# This uses rtl_power to sample the spectrum and find the lowest energy
# Note: This will only work once the hardware is plugged in.
rtl_power -f 88M:108M:125k -g 30 -i 10s fm_scan.csv

# Simple analysis to show the 5 quietest frequencies
echo "--- QUIETEST SPOTS (Best for Pirate Radio) ---"
sort -t, -k7 -n fm_scan.csv | head -n 5 | awk -F, '{print $3/1000000 " MHz"}'
