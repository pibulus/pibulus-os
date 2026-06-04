#!/usr/bin/env bash
set -euo pipefail

KEY_FILE="${PIBULUS_API_KEYS:-/home/pibulus/.config/api_keys}"
ENV_FILE="${CLAUDE_CHAT_ENV_FILE:-/home/pibulus/.config/claude-chat.env}"
INCLUDE_GEMINI=0
RESTART=0

usage() {
  cat <<'EOF'
Usage: refresh_deck_ai_env.sh [--include-gemini] [--restart]

Writes the private claude-chat.service EnvironmentFile from ~/.config/api_keys.
It never writes GOOGLE_API_KEY because Gemini CLI gives that precedence over
GEMINI_API_KEY, and one stale Google key can break the deck Gemini route.

Use --include-gemini after replacing GEMINI_API_KEY with a valid Google AI
Studio/Gemini API key.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --include-gemini) INCLUDE_GEMINI=1 ;;
    --restart) RESTART=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [[ ! -r "$KEY_FILE" ]]; then
  echo "Cannot read $KEY_FILE" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
. "$KEY_FILE"
set +a

validate_gemini_key() {
  local key="$1" tmp code ok
  tmp="$(mktemp)"
  code="$(curl -sS -o "$tmp" -w '%{http_code}' --max-time 20 \
    "https://generativelanguage.googleapis.com/v1beta/models?key=$key" || true)"
  ok="$(python3 - "$tmp" <<'PY'
import json, sys
try:
    data = json.load(open(sys.argv[1]))
except Exception:
    print("bad-json")
    raise SystemExit(1)
if "models" in data:
    print("ok")
    raise SystemExit(0)
err = data.get("error", {})
print(err.get("status") or err.get("message") or "invalid")
raise SystemExit(1)
PY
  )"
  rm -f "$tmp"
  [[ "$code" == 2* && "$ok" == "ok" ]]
}

tmp="$(mktemp)"
cleanup() {
  rm -f "$tmp"
}
trap cleanup EXIT

umask 077
{
  for name in ANTHROPIC_API_KEY OPENAI_API_KEY DEEPSEEK_API_KEY; do
    value="${!name-}"
    if [[ -n "$value" ]]; then
      printf "%s=%q\n" "$name" "$value"
    fi
  done

  if [[ "$INCLUDE_GEMINI" == "1" ]]; then
    if [[ -z "${GEMINI_API_KEY-}" ]]; then
      echo "GEMINI_API_KEY is missing; not writing Gemini to $ENV_FILE" >&2
      exit 1
    fi
    if ! validate_gemini_key "$GEMINI_API_KEY"; then
      echo "GEMINI_API_KEY did not validate; not writing Gemini to $ENV_FILE" >&2
      exit 1
    fi
    printf "GEMINI_API_KEY=%q\n" "$GEMINI_API_KEY"
  fi
} > "$tmp"

install -m 600 "$tmp" "$ENV_FILE"

printf "wrote %s with vars: " "$ENV_FILE"
sed -n 's/^\([A-Z0-9_]*API_KEY\)=.*/\1/p' "$ENV_FILE" | paste -sd, -

if [[ "$RESTART" == "1" ]]; then
  sudo -n systemctl restart claude-chat.service
  systemctl is-active claude-chat.service
fi
