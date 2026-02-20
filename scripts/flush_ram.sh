#!/bin/bash
# 🧹 QUICK CAT CLUB - RAM FLUSH

BEFORE=$(free -h | awk '/Mem:/ {print $4}')
echo "Flushing caches..."
sudo sync
echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
AFTER=$(free -h | awk '/Mem:/ {print $4}')

gum style --foreground 46 "✅ RAM FLUSHED: $BEFORE -> $AFTER free."
play_tone "confirm" 2>/dev/null
sleep 2
