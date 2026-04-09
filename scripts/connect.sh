#!/usr/bin/env bash
# pibulus connect — ssh into the Quick Cat Club Pi from any Mac
# Usage: bash <(curl -fsSL https://gist.github.com/YOUR_GIST_URL/raw/connect.sh)
# Or via shortener: bash <(curl -fsSL https://go.quickcat.club/pi)

set -e

HOST="ssh.quickcat.club"
USER="pibulus"
CF_TMP="/tmp/cf-pibulus"

# Detect arch
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
  CF_BIN="cloudflared-darwin-arm64"
else
  CF_BIN="cloudflared-darwin-amd64"
fi

# Check for Tailscale first (preferred, no proxy needed)
if command -v tailscale &>/dev/null && tailscale status &>/dev/null 2>&1; then
  echo "  Tailscale detected — connecting directly..."
  exec ssh -4 "${USER}@pibulus"
fi

# Fall back to Cloudflare tunnel proxy
echo "  Fetching cloudflared..."
curl -fsSL --progress-bar \
  "https://github.com/cloudflare/cloudflared/releases/latest/download/${CF_BIN}" \
  -o "$CF_TMP"
chmod +x "$CF_TMP"

echo "  Connecting via Cloudflare tunnel..."
exec ssh \
  -o "ProxyCommand=${CF_TMP} access ssh --hostname ${HOST}" \
  -o "StrictHostKeyChecking=accept-new" \
  "${USER}@${HOST}"
