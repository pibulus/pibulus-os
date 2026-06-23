#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="${PIBULUS_ROOT:-/home/pibulus/pibulus-os}"
PASSPORT="${PASSPORT_ROOT:-/media/pibulus/passport}"
OUT_JSON="${DECK_DOCTOR_JSON:-$PASSPORT/www/html/deck-doctor.json}"
LOG_FILE="${DECK_DOCTOR_LOG:-$PASSPORT/Backups/pi-system/logs/deck-doctor.log}"
QUIET=0

usage() {
  cat <<'EOF'
Usage: deck_doctor.sh [--quiet] [--json PATH]

Read-only health pass for the QuickCat Deck and Pi operator surface.
Writes a compact JSON status to Passport by default.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --quiet) QUIET=1 ;;
    --json)
      shift
      OUT_JSON="${1:-}"
      ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

tmp_checks="$(mktemp)"
tmp_bootstrap="$(mktemp)"
tmp_pulse="$(mktemp)"
cleanup() {
  rm -f "$tmp_checks" "$tmp_bootstrap" "$tmp_pulse"
}
trap cleanup EXIT

EXIT_STATUS=0

add_check() {
  local key="$1" status="$2" summary="$3" detail="${4:-}"
  printf '%s\t%s\t%s\t%s\n' "$key" "$status" "$summary" "$detail" >> "$tmp_checks"
  if [[ "$status" == "fail" ]]; then
    EXIT_STATUS=1
  fi
}

percent_used() {
  df -P "$1" 2>/dev/null | busybox awk 'NR==2 {gsub(/%/,"",$5); print $5}'
}

check_disk() {
  local key="$1" path="$2" warn="$3" fail="$4" used
  used="$(percent_used "$path" || true)"
  if [[ -z "$used" ]]; then
    add_check "$key" fail "disk usage unavailable" "$path"
  elif (( used >= fail )); then
    add_check "$key" fail "${used}% used" "threshold=${fail}%"
  elif (( used >= warn )); then
    add_check "$key" warn "${used}% used" "threshold=${warn}%"
  else
    add_check "$key" ok "${used}% used" "$path"
  fi
}

check_unit() {
  local unit="$1" required="${2:-1}" state
  state="$(systemctl is-active "$unit" 2>/dev/null || true)"
  if [[ "$state" == "active" ]]; then
    add_check "unit:$unit" ok "active" ""
  elif [[ "$required" == "1" ]]; then
    add_check "unit:$unit" fail "${state:-missing}" ""
  else
    add_check "unit:$unit" warn "${state:-missing}" ""
  fi
}

check_container() {
  local name="$1"
  if docker inspect -f '{{.State.Running}}' "$name" 2>/dev/null | grep -qx true; then
    add_check "container:$name" ok "running" ""
  else
    add_check "container:$name" fail "not running" ""
  fi
}

curl_code() {
  curl -sS -o "$1" -w '%{http_code}' --connect-timeout 3 --max-time 8 "${@:2}" 2>/dev/null || true
}

if findmnt -rn -T "$PASSPORT" >/dev/null 2>&1; then
  mount_line="$(findmnt -rn -T "$PASSPORT" -o SOURCE,FSTYPE,TARGET 2>/dev/null | head -1)"
  add_check passport_mount ok "$mount_line" ""
else
  add_check passport_mount fail "Passport is not mounted" "$PASSPORT"
fi

check_disk root_disk / 80 92
if [[ -d "$PASSPORT" ]]; then
  check_disk passport_disk "$PASSPORT" 95 98
else
  add_check passport_disk fail "Passport path missing" "$PASSPORT"
fi

# Memory pressure (mirrors the claude-chat gateway launch gate thresholds)
check_memory() {
  local avail swapfree swaptotal
  avail=$(awk "/^MemAvailable:/{print int(\$2/1024)}" /proc/meminfo 2>/dev/null)
  swapfree=$(awk "/^SwapFree:/{print int(\$2/1024)}" /proc/meminfo 2>/dev/null)
  swaptotal=$(awk "/^SwapTotal:/{print int(\$2/1024)}" /proc/meminfo 2>/dev/null)
  if [[ -z "$avail" ]]; then
    add_check memory warn "meminfo unavailable" ""
    return
  fi
  if (( avail < 500 )); then
    add_check memory warn "only ${avail}MB RAM available" "floor=500MB"
  elif [[ -n "$swaptotal" && "$swaptotal" -gt 0 && -n "$swapfree" ]] && (( swapfree < 300 )); then
    add_check memory warn "only ${swapfree}MB swap free" "floor=300MB"
  else
    add_check memory ok "${avail}MB RAM / ${swapfree:-0}MB swap free" ""
  fi
}
check_memory

check_unit docker.service
check_unit cloudflared.service
check_unit claude-chat.service
check_unit pibulus-watchdog.timer 0
check_unit deck-doctor.timer 0

for name in web_host azuracast; do
  check_container "$name"
done

restarts="$(systemctl show claude-chat.service -p NRestarts --value 2>/dev/null || echo 0)"
if [[ "$restarts" =~ ^[0-9]+$ && "$restarts" -le 1 ]]; then
  add_check claude_chat_restarts ok "NRestarts=$restarts" ""
elif [[ "$restarts" =~ ^[0-9]+$ ]]; then
  add_check claude_chat_restarts warn "NRestarts=$restarts" ""
else
  add_check claude_chat_restarts warn "restart count unavailable" ""
fi

bootstrap_code="$(curl_code "$tmp_bootstrap" http://172.17.0.1:9016/api/bootstrap)"
if [[ "$bootstrap_code" == "200" ]] && python3 - "$tmp_bootstrap" <<'PY' >/dev/null 2>&1
import json, sys
data = json.load(open(sys.argv[1]))
assert data.get("ok") is True
assert data.get("pulse", {}).get("seed")
assert any(m.get("enabled") for m in data.get("models", []))
PY
then
  model_summary="$(python3 - "$tmp_bootstrap" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
print(",".join(f"{m.get('key')}={'on' if m.get('enabled') else 'off'}" for m in data.get("models", [])))
PY
)"
  add_check gateway_bootstrap ok "$model_summary" "pulse included"
else
  add_check gateway_bootstrap fail "bootstrap failed" "http=$bootstrap_code"
fi

pulse_code="$(curl_code "$tmp_pulse" http://172.17.0.1:9016/api/pulse)"
if [[ "$pulse_code" == "200" ]] && python3 - "$tmp_pulse" <<'PY' >/dev/null 2>&1
import json, sys
data = json.load(open(sys.argv[1]))
assert data.get("ok") is True
assert data.get("seed")
PY
then
  add_check gateway_pulse ok "pulse ok" ""
else
  add_check gateway_pulse warn "pulse failed" "http=$pulse_code"
fi

nginx_code="$(curl -sS -o /dev/null -w '%{http_code}' --connect-timeout 3 --max-time 8 -H 'Host: deck.quickcat.club' http://127.0.0.1/deck/claude/ 2>/dev/null || true)"
case "$nginx_code" in
  200|401) add_check nginx_deck_route ok "HTTP $nginx_code" "200/401 both mean route reached" ;;
  429|503) add_check nginx_deck_route warn "HTTP $nginx_code" "rate limit or temporary upstream pressure" ;;
  *) add_check nginx_deck_route fail "HTTP ${nginx_code:-none}" "" ;;
esac

status_json="$PASSPORT/www/html/status.json"
if [[ -f "$status_json" ]]; then
  age="$(( $(date +%s) - $(stat -c %Y "$status_json") ))"
  if (( age <= 1800 )); then
    add_check status_json ok "fresh ${age}s" "$status_json"
  elif (( age <= 7200 )); then
    add_check status_json warn "stale ${age}s" "$status_json"
  else
    add_check status_json fail "stale ${age}s" "$status_json"
  fi
else
  add_check status_json warn "missing" "$status_json"
fi

core_pattern="$(cat /proc/sys/kernel/core_pattern 2>/dev/null || true)"
if [[ "$core_pattern" == "/dev/null" ]]; then
  add_check sd_core_dump_guard ok "core dumps disabled" ""
else
  add_check sd_core_dump_guard warn "core_pattern=$core_pattern" "expected /dev/null"
fi

if grep -q 'app-data/apps-staging' "$ROOT/scripts/deploy_app.sh" 2>/dev/null; then
  add_check app_staging_guard ok "deploy staging points at Passport app-data" ""
else
  add_check app_staging_guard warn "deploy staging guard not detected" "$ROOT/scripts/deploy_app.sh"
fi

if command -v vcgencmd >/dev/null 2>&1; then
  throttle="$(vcgencmd get_throttled 2>/dev/null | cut -d= -f2 || true)"
  if [[ "$throttle" == "0x0" ]]; then
    add_check pi_power ok "not throttled" "$throttle"
  elif [[ -n "$throttle" ]]; then
    add_check pi_power warn "throttled flags $throttle" ""
  fi
fi

repo_state="$(git -C "$ROOT" status --short 2>/dev/null || true)"
if [[ -z "$repo_state" ]]; then
  add_check repo_state ok "clean" "$ROOT"
else
  add_check repo_state warn "working tree has changes" "$(printf '%s' "$repo_state" | head -5 | tr '\n' ';')"
fi

if [[ "$OUT_JSON" == "$PASSPORT/"* ]] && ! findmnt -rn -T "$PASSPORT" >/dev/null 2>&1; then
  OUT_JSON="/tmp/deck-doctor.json"
fi

summary_json="$(python3 - "$tmp_checks" "$OUT_JSON" <<'PY'
import json
import os
import sys
from datetime import datetime, timezone

checks = []
rank = {"ok": 0, "warn": 1, "fail": 2}
worst = "ok"
for raw in open(sys.argv[1], encoding="utf-8"):
    parts = raw.rstrip("\n").split("\t")
    if len(parts) < 3:
        continue
    key, status, summary = parts[:3]
    detail = " ".join(parts[3:])
    checks.append({"key": key, "status": status, "summary": summary, "detail": detail})
    if rank.get(status, 1) > rank[worst]:
        worst = status

payload = {
    "ok": worst != "fail",
    "status": worst,
    "checked_at": datetime.now(timezone.utc).isoformat(),
    "checks": checks,
}
out = sys.argv[2]
os.makedirs(os.path.dirname(out), exist_ok=True)
tmp = f"{out}.tmp"
with open(tmp, "w", encoding="utf-8") as fh:
    json.dump(payload, fh, separators=(",", ":"))
    fh.write("\n")
os.replace(tmp, out)
print(json.dumps({"status": worst, "checks": len(checks), "output": out}, separators=(",", ":")))
PY
)"

log_target="$LOG_FILE"
if [[ "$log_target" == "$PASSPORT/"* ]] && ! findmnt -rn -T "$PASSPORT" >/dev/null 2>&1; then
  log_target="/tmp/deck-doctor.log"
fi
mkdir -p "$(dirname "$log_target")"
printf '%s %s\n' "$(date --iso-8601=seconds)" "$summary_json" >> "$log_target"

if [[ "$QUIET" != "1" ]]; then
  python3 - "$OUT_JSON" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
print(f"deck doctor: {data['status']}")
for check in data["checks"]:
    print(f"  {check['status']:<4} {check['key']:<24} {check['summary']}")
print(f"wrote {sys.argv[1]}")
PY
fi

exit "$EXIT_STATUS"
