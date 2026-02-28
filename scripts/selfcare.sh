#!/bin/bash
# 🐾 PIBULUS SELF-CARE — system-wide maintenance
# Runs weekly (or on-demand via deck)
# Designed to keep a 4GB Pi with 58GB SD card alive and breathing

set -uo pipefail

# Load nvm for npm access
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
LOG="/tmp/selfcare-$(date +%Y%m%d).log"
exec > >(tee -a "$LOG") 2>&1

echo "═══════════════════════════════════════════"
echo "🐾 PIBULUS SELF-CARE — $(date '+%Y-%m-%d %H:%M')"
echo "═══════════════════════════════════════════"

FREED=0

# ── 1. DOCKER CLEANUP ──
echo ""
echo "▸ Docker cleanup..."
# Prune stopped containers (except immich which we stop intentionally)
PRUNED=$(docker container prune -f --filter "until=72h" 2>/dev/null | tail -1)
echo "  Containers: $PRUNED"

# Prune dangling images
PRUNED=$(docker image prune -f 2>/dev/null | tail -1)
echo "  Images: $PRUNED"

# Prune build cache
docker builder prune -f 2>/dev/null | tail -1

# ── 2. PACKAGE CACHE CLEANUP ──
echo ""
echo "▸ Package caches..."

# APT cache (132MB last check)
APT_BEFORE=$(du -sm /var/cache/apt/ 2>/dev/null | cut -f1)
sudo apt-get clean 2>/dev/null || true
APT_AFTER=$(du -sm /var/cache/apt/ 2>/dev/null | cut -f1)
APT_SAVED=$((APT_BEFORE - APT_AFTER))
echo "  APT cache: freed ${APT_SAVED}MB"
FREED=$((FREED + APT_SAVED))

# NPM cache (541MB last check)
NPM_BEFORE=$(du -sm ~/.npm/_cacache/ 2>/dev/null | cut -f1)
npm cache clean --force 2>/dev/null
NPM_AFTER=$(du -sm ~/.npm/_cacache/ 2>/dev/null | cut -f1 || echo "0")
NPM_SAVED=$((NPM_BEFORE - NPM_AFTER))
echo "  NPM cache: freed ${NPM_SAVED}MB"
FREED=$((FREED + NPM_SAVED))

# Homebrew cache (1.5GB!)
if [ -d "$HOME/.cache/Homebrew" ]; then
  BREW_SIZE=$(du -sm "$HOME/.cache/Homebrew" 2>/dev/null | cut -f1)
  sudo rm -rf "$HOME/.cache/Homebrew"/* 2>/dev/null
  echo "  Homebrew cache: freed ${BREW_SIZE}MB"
  FREED=$((FREED + BREW_SIZE))
fi

# node-gyp cache
if [ -d "$HOME/.cache/node-gyp" ]; then
  GYP_SIZE=$(du -sm "$HOME/.cache/node-gyp" 2>/dev/null | cut -f1)
  rm -rf "$HOME/.cache/node-gyp"
  echo "  node-gyp cache: freed ${GYP_SIZE}MB"
  FREED=$((FREED + GYP_SIZE))
fi

# ── 3. JOURNAL TRIM ──
echo ""
echo "▸ Journal trim..."
sudo journalctl --vacuum-time=7d --vacuum-size=10M 2>/dev/null | tail -1

# ── 4. TMP CLEANUP ──
echo ""
echo "▸ Temp files..."
TMP_BEFORE=$(du -sm /tmp/ 2>/dev/null | cut -f1)
find /tmp -type f -mtime +3 -not -name "selfcare*" -delete 2>/dev/null
TMP_AFTER=$(du -sm /tmp/ 2>/dev/null | cut -f1)
TMP_SAVED=$((TMP_BEFORE - TMP_AFTER))
echo "  /tmp: freed ${TMP_SAVED}MB"
FREED=$((FREED + TMP_SAVED))

# ── 5. RAM FLUSH ──
echo ""
echo "▸ RAM flush..."
RAM_BEFORE=$(free -m | awk '/^Mem:/{print $4}')
sudo sync
echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null 2>&1
RAM_AFTER=$(free -m | awk '/^Mem:/{print $4}')
echo "  Free RAM: ${RAM_BEFORE}MB → ${RAM_AFTER}MB"

# ── 6. HEALTH CHECKS ──
echo ""
echo "▸ Health checks..."

# Temperature
TEMP=$(vcgencmd measure_temp 2>/dev/null | grep -oP '[0-9.]+' || echo "?")
if (( $(echo "$TEMP > 75" | bc -l 2>/dev/null || echo 0) )); then
  echo "  ⚠️  CPU temp: ${TEMP}°C (HIGH)"
else
  echo "  ✅ CPU temp: ${TEMP}°C"
fi

# Root disk
ROOT_PCT=$(df / | awk 'NR==2{print $5}' | tr -d '%')
if [ "$ROOT_PCT" -gt 90 ]; then
  echo "  ⚠️  Root disk: ${ROOT_PCT}% (CRITICAL — run docker image prune -a)"
elif [ "$ROOT_PCT" -gt 85 ]; then
  echo "  ⚡ Root disk: ${ROOT_PCT}% (getting tight)"
else
  echo "  ✅ Root disk: ${ROOT_PCT}%"
fi

# Swap pressure
SWAP_USED=$(free -m | awk '/^Swap:/{print $3}')
SWAP_TOTAL=$(free -m | awk '/^Swap:/{print $2}')
if [ "$SWAP_USED" -gt 1800 ]; then
  echo "  ⚠️  Swap: ${SWAP_USED}/${SWAP_TOTAL}MB (DANGER — things will die)"
elif [ "$SWAP_USED" -gt 1200 ]; then
  echo "  ⚡ Swap: ${SWAP_USED}/${SWAP_TOTAL}MB (heavy)"
else
  echo "  ✅ Swap: ${SWAP_USED}/${SWAP_TOTAL}MB"
fi

# Passport drive
PASSPORT_PCT=$(df /media/pibulus/passport 2>/dev/null | awk 'NR==2{print $5}' | tr -d '%')
if [ -n "$PASSPORT_PCT" ]; then
  echo "  ✅ Passport: ${PASSPORT_PCT}%"
else
  echo "  ⚠️  Passport drive not mounted!"
fi

# Unhealthy containers
UNHEALTHY=$(docker ps --filter "health=unhealthy" --format "{{.Names}}" 2>/dev/null)
if [ -n "$UNHEALTHY" ]; then
  echo "  ⚠️  Unhealthy: $UNHEALTHY"
else
  echo "  ✅ All containers healthy"
fi

# Power throttling
THROTTLED=$(vcgencmd get_throttled 2>/dev/null | cut -d'=' -f2)
if [ "$THROTTLED" != "0x0" ]; then
  echo "  ⚠️  Power: throttled ($THROTTLED) — check USB-C supply"
else
  echo "  ✅ Power: clean"
fi

# ── 7. SUMMARY ──
echo ""
echo "═══════════════════════════════════════════"
echo "  Freed ~${FREED}MB disk space"
echo "  Free RAM: $(free -m | awk '/^Mem:/{print $7}')MB available"
echo "  Root disk: $(df -h / | awk 'NR==2{print $4}') free"
echo "  Log: $LOG"
echo "═══════════════════════════════════════════"
