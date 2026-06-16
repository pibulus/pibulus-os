#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: deploy_app.sh <talktype|ziplist|stargram|ghostnote> [--force]

Deploys one Pi-hosted app at a time. This script is intentionally sequential:
it takes a lock, checks memory/disk, builds in Passport-backed staging by
default, smoke tests before swapping, backs up the live dir, writes
.pibulus-meta, then restarts the systemd service.
EOF
}

APP="${1:-}"
FORCE="${2:-}"
if [[ -z "$APP" || "$APP" == "-h" || "$APP" == "--help" ]]; then
  usage
  exit 0
fi

if [[ "$FORCE" != "" && "$FORCE" != "--force" ]]; then
  usage >&2
  exit 2
fi

LOCK="/tmp/pibulus-app-deploy.lock"
exec 9>"$LOCK"
if ! flock -n 9; then
  echo "Another app deploy is already running. Refusing to run in parallel." >&2
  exit 1
fi

case "$APP" in
  talktype)
    REPO="https://github.com/pibulus/talktype.git"
    SERVICE="talktype"
    LIVE_DIR="/home/pibulus/apps/talktype"
    PORT="9002"
    SMOKE_PORT="19002"
    KIND="node-build"
    ;;
  ziplist)
    REPO="https://github.com/pibulus/ziplist.git"
    SERVICE="ziplist"
    LIVE_DIR="/home/pibulus/apps/ziplist"
    PORT="9003"
    SMOKE_PORT="19003"
    KIND="node-build"
    ;;
  stargram)
    REPO="https://github.com/pibulus/stargram.git"
    SERVICE="stargram"
    LIVE_DIR="/home/pibulus/apps/stargram"
    PORT="9012"
    SMOKE_PORT=""
    KIND="deno-checkout"
    ;;
  ghostnote)
    REPO="https://github.com/pibulus/ouija.git"
    SERVICE="ghostnote"
    LIVE_DIR="/home/pibulus/apps/ghostnote"
    PORT="9013"
    SMOKE_PORT=""
    KIND="deno-checkout"
    ;;
  *)
    echo "Unknown app: $APP" >&2
    usage >&2
    exit 2
    ;;
esac

STAGING_ROOT="${PIBULUS_APP_STAGING_ROOT:-/home/pibulus/apps-staging}"
BACKUP_ROOT="/media/pibulus/passport/app-data/apps-backups"
NPM_CACHE_DIR="${PIBULUS_NPM_CACHE:-/home/pibulus/.cache/pibulus-npm}"
STAMP="$(date +%Y%m%d-%H%M%S)"
SRC_DIR="$STAGING_ROOT/${APP}-src-$STAMP"
STAGE_DIR="$STAGING_ROOT/${APP}-stage-$STAMP"
BACKUP_DIR="$BACKUP_ROOT/${APP}-$STAMP"
PREVIOUS_DIR="${LIVE_DIR}.previous-$STAMP"
META_FILE="$LIVE_DIR/.pibulus-meta"

need_cmd() {
  command -v "$1" >/dev/null || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

require_safe_path() {
  case "${1:-}" in
    "" | "/" | "/home" | "/home/pibulus" | "/home/pibulus/apps" | "/home/pibulus/apps-staging")
      echo "Unsafe path: $1" >&2
      exit 1
      ;;
  esac
}

validate_staging_root() {
  case "$STAGING_ROOT" in
    "" | "/" | "/home" | "/home/pibulus" | "/home/pibulus/apps" | "/media" | "/media/pibulus" | "/media/pibulus/passport" | "/media/pibulus/passport/app-data")
      echo "Unsafe staging root: $STAGING_ROOT" >&2
      exit 1
      ;;
  esac

  if [[ "$STAGING_ROOT" == /media/pibulus/passport/* ]] && ! mountpoint -q /media/pibulus/passport; then
    echo "Passport is not mounted; refusing to stage on root-backed /media." >&2
    exit 1
  fi
}

check_capacity() {
  local available_kb tmp_free_kb root_free_kb
  available_kb="$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)"
  tmp_free_kb="$(df -Pk "$STAGING_ROOT" | awk 'NR==2 {print $4}')"
  root_free_kb="$(df -Pk / | awk 'NR==2 {print $4}')"

  if (( available_kb < 900000 )); then
    echo "Only $((available_kb / 1024)) MiB RAM available; refusing to build on the Pi." >&2
    exit 1
  fi
  if (( tmp_free_kb < 2500000 && FORCE != "--force" )); then
    echo "Only $((tmp_free_kb / 1024)) MiB free in $STAGING_ROOT; use --force only if you checked it." >&2
    exit 1
  fi
  if (( root_free_kb < 5000000 && FORCE != "--force" )); then
    echo "Only $((root_free_kb / 1024)) MiB free on /; use --force only if you checked it." >&2
    exit 1
  fi
}

write_meta() {
  local commit="$1"
  cat > "$META_FILE" <<EOF
GITHUB_URL=$REPO
DEPLOYED_COMMIT=$commit
DEPLOYED_AT=$(date -Iseconds)
DEPLOYED_BY=deploy_app.sh
EOF
}

smoke_node_stage() {
  local smoke_log="$STAGE_DIR/.smoke.log"
  (
    cd "$STAGE_DIR"
    PORT="$SMOKE_PORT" HOST=127.0.0.1 ORIGIN="http://127.0.0.1:$SMOKE_PORT" \
      node index.js >"$smoke_log" 2>&1 &
    echo $! > "$STAGE_DIR/.smoke.pid"
  )
  local smoke_pid
  smoke_pid="$(cat "$STAGE_DIR/.smoke.pid")"
  trap 'kill "$smoke_pid" >/dev/null 2>&1 || true' RETURN

  for _ in $(seq 1 30); do
    if curl -fsS "http://127.0.0.1:$SMOKE_PORT/" >/dev/null; then
      kill "$smoke_pid" >/dev/null 2>&1 || true
      trap - RETURN
      return 0
    fi
    if ! kill -0 "$smoke_pid" >/dev/null 2>&1; then
      cat "$smoke_log" >&2
      return 1
    fi
    sleep 1
  done
  cat "$smoke_log" >&2
  return 1
}

swap_and_restart() {
  local commit="$1"
  require_safe_path "$LIVE_DIR"
  require_safe_path "$STAGE_DIR"
  require_safe_path "$BACKUP_DIR"
  require_safe_path "$PREVIOUS_DIR"

  mkdir -p "$BACKUP_DIR"

  rollback() {
    local status=$?
    if [[ "$status" -ne 0 && -d "$PREVIOUS_DIR" ]]; then
      echo "Deploy failed; rolling back $APP" >&2
      rm -rf "$LIVE_DIR"
      mv "$PREVIOUS_DIR" "$LIVE_DIR"
      sudo -n systemctl restart "$SERVICE" || true
    fi
    exit "$status"
  }
  trap rollback EXIT

  if [[ -d "$LIVE_DIR" ]]; then
    rsync -a --delete "$LIVE_DIR/" "$BACKUP_DIR/"
    mv "$LIVE_DIR" "$PREVIOUS_DIR"
  fi

  mv "$STAGE_DIR" "$LIVE_DIR"
  write_meta "$commit"
  sudo -n systemctl restart "$SERVICE"
  systemctl is-active "$SERVICE"

  for _ in $(seq 1 20); do
    if curl -fsS "http://127.0.0.1:$PORT/" >/dev/null; then
      rm -rf "$PREVIOUS_DIR"
      trap - EXIT
      echo "backup=$BACKUP_DIR"
      echo "deployed=$LIVE_DIR"
      echo "commit=$commit"
      return 0
    fi
    sleep 1
  done

  echo "Live smoke failed: http://127.0.0.1:$PORT/" >&2
  exit 1
}

deploy_node_build() {
  need_cmd git
  need_cmd npm
  need_cmd node
  need_cmd rsync
  check_capacity

  rm -rf "$SRC_DIR" "$STAGE_DIR"
  git clone --depth 1 "$REPO" "$SRC_DIR"
  local commit
  commit="$(git -C "$SRC_DIR" rev-parse HEAD)"

  if [[ -f "$META_FILE" ]] && grep -qx "DEPLOYED_COMMIT=$commit" "$META_FILE" && [[ "$FORCE" != "--force" ]]; then
    echo "$APP already deployed at $commit"
    rm -rf "$SRC_DIR"
    exit 0
  fi

  (cd "$SRC_DIR" && npm ci --cache "$NPM_CACHE_DIR" && npm run build)
  mkdir -p "$STAGE_DIR"
  rsync -a --delete "$SRC_DIR/build/" "$STAGE_DIR/"
  cp "$SRC_DIR/package.json" "$SRC_DIR/package-lock.json" "$STAGE_DIR/"

  if [[ -d "$LIVE_DIR" ]]; then
    find "$LIVE_DIR" -maxdepth 1 -type f \( -name ".env" -o -name ".env.*" \) -exec cp -p {} "$STAGE_DIR/" \;
  fi

  (cd "$STAGE_DIR" && npm ci --omit=dev --ignore-scripts --no-audit --no-fund --cache "$NPM_CACHE_DIR")
  test -s "$STAGE_DIR/index.js"
  local zero_file=""
  zero_file="$(find "$STAGE_DIR/client" "$STAGE_DIR/server" -type f -size 0 -print -quit 2>/dev/null || true)"
  if [[ -n "$zero_file" ]]; then
    echo "Zero-byte build file: $zero_file" >&2
    exit 1
  fi
  smoke_node_stage
  rm -rf "$SRC_DIR"
  swap_and_restart "$commit"
}

deploy_deno_checkout() {
  need_cmd git
  need_cmd curl
  check_capacity
  require_safe_path "$LIVE_DIR"

  local fresh_clone=0
  if [[ ! -d "$LIVE_DIR/.git" ]]; then
    if [[ -e "$LIVE_DIR" ]]; then
      echo "$LIVE_DIR exists but is not a git checkout; refusing deploy." >&2
      exit 1
    fi
    mkdir -p "$(dirname "$LIVE_DIR")"
    git clone "$REPO" "$LIVE_DIR"
    fresh_clone=1
  fi

  grep -qxF ".pibulus-meta" "$LIVE_DIR/.git/info/exclude" 2>/dev/null ||
    printf "\n.pibulus-meta\n" >> "$LIVE_DIR/.git/info/exclude"

  git -C "$LIVE_DIR" fetch origin main
  if [[ -n "$(git -C "$LIVE_DIR" status --short)" && "$FORCE" != "--force" ]]; then
    echo "$LIVE_DIR has local changes; refusing to pull without --force." >&2
    git -C "$LIVE_DIR" status --short >&2
    exit 1
  fi
  local before after
  before="$(git -C "$LIVE_DIR" rev-parse HEAD)"
  after="$(git -C "$LIVE_DIR" rev-parse origin/main)"
  if [[ "$before" == "$after" && "$fresh_clone" -eq 0 && "$FORCE" != "--force" ]]; then
    echo "$APP already deployed at $after"
    write_meta "$after"
    exit 0
  fi
  if [[ "$before" != "$after" ]]; then
    git -C "$LIVE_DIR" pull --ff-only origin main
  fi
  (cd "$LIVE_DIR" && /home/pibulus/.deno/bin/deno task build)
  write_meta "$after"
  sudo -n systemctl restart "$SERVICE"
  systemctl is-active "$SERVICE"
  for _ in $(seq 1 20); do
    if curl -fsS "http://127.0.0.1:$PORT/" >/dev/null; then
      echo "deployed=$LIVE_DIR"
      echo "commit=$after"
      return 0
    fi
    sleep 1
  done

  echo "Live smoke failed: http://127.0.0.1:$PORT/" >&2
  exit 1
}

validate_staging_root
mkdir -p "$STAGING_ROOT" "$BACKUP_ROOT" "$NPM_CACHE_DIR"

case "$KIND" in
  node-build) deploy_node_build ;;
  deno-checkout) deploy_deno_checkout ;;
esac
