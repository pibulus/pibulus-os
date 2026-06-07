#!/usr/bin/env bash
set -euo pipefail

CONTAINER="${CONTAINER:-azuracast}"
STATION="${STATION:-kpab.fm}"
AZ_DIR="${AZ_DIR:-/home/pibulus/azuracast}"
MOUNT_URL="http://127.0.0.1:8000/radio.mp3"
PUBLIC_STREAM="https://kpab.fm/radio.mp3"
PUBLIC_API="https://kpab.fm/api/nowplaying/kpab.fm"
LIQ_CONFIG="/var/azuracast/stations/kpab.fm/config/liquidsoap.liq"

usage() {
  cat <<'EOF'
Usage: kpab_azuracast_recovery.sh <command>

Commands:
  status           Show the narrow KPAB/AzuraCast state.
  apply-safe-mode  Apply the known-good 2026-06-07 recovery settings.
  seed-feedback    Seed AzuraCast's current-song row from Icecast metadata.
  verify           Check stream/API/backend after recovery.

Run on pibulus, not from a laptop.
EOF
}

require_container() {
  docker inspect "$CONTAINER" >/dev/null
}

feedback_bridge_b64() {
  cat <<'LIQ' | base64 | tr -d '\n'
def azuracast.send_feedback(m) =
    if (m["is_error_file"] != "true") then
        if (m["title"] != azuracast.last_title() or m["artist"] != azuracast.last_artist()) then
            azuracast.last_title := m["title"]
            azuracast.last_artist := m["artist"]

            j = json()
            j.add("artist", m["artist"])
            j.add("title", m["title"])

            payload = json.stringify(compact=true, j)
            cmd = "curl -sS --max-time 5 -o /dev/null -w '%{http_code}' -H 'Content-Type: application/json' -H 'User-Agent: Liquidsoap AzuraCast curl bridge' -H 'X-Liquidsoap-Api-Key: #{settings.azuracast.api_key()}' --data-binary \"$KPAB_FEEDBACK_PAYLOAD\" '#{settings.azuracast.api_url()}/feedback'"
            p = process.run(timeout=7., network=true, env=[("KPAB_FEEDBACK_PAYLOAD", payload)], cmd)
            log(label="azuracast.feedback.curl", "feedback curl status #{p.stdout} exit #{p.status.code}")
        end
    end
end
LIQ
}

status() {
  require_container
  echo "== station =="
  docker exec "$CONTAINER" supervisorctl status station_1:* || true
  echo
  echo "== memory =="
  docker inspect "$CONTAINER" --format 'Memory={{.HostConfig.Memory}} MemorySwap={{.HostConfig.MemorySwap}} Status={{.State.Status}} OOMKilled={{.State.OOMKilled}}'
  docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.PIDs}}' "$CONTAINER" || true
  echo
  echo "== stream =="
  docker exec "$CONTAINER" curl -sS -I --max-time 8 "$MOUNT_URL" | sed -n '1,12p' || true
}

apply_safe_mode() {
  require_container

  cd "$AZ_DIR"
  cp docker-compose.override.yml "docker-compose.override.yml.bak-$(date +%Y%m%d-%H%M%S)-kpab-recovery"
  perl -0pi -e 's/mem_reservation:\s*\S+/mem_reservation: 768m/; if (s/mem_limit:\s*\S+/mem_limit: 1536m/) {} else { s/(mem_reservation: 768m\n)/$1    mem_limit: 1536m\n/ }' docker-compose.override.yml
  docker update --memory 1536m --memory-swap 2g "$CONTAINER" >/dev/null

  docker exec "$CONTAINER" supervisorctl stop station_1:station_1_backend || true

  docker exec "$CONTAINER" sh -lc 'set -eu
ts=$(date +%Y%m%d%H%M%S)
for d in /tmp/liquidsoap_cache /var/azuracast/www_tmp/liquidsoap_cache; do
  if [ -e "$d" ]; then
    mv "$d" "${d}.bak_${ts}"
  fi
done
install -d -o azuracast -g azuracast -m 755 /tmp/liquidsoap_cache
install -d -o azuracast -g azuracast -m 700 /var/azuracast/www_tmp/liquidsoap_cache'

  bridge_b64=$(feedback_bridge_b64)
  docker exec "$CONTAINER" azuracast_cli dbal:run-sql "UPDATE station SET backend_config = JSON_SET(backend_config, '$.audio_processing_method', 'none', '$.enable_auto_cue', false, '$.write_playlists_to_liquidsoap', true, '$.use_manual_autodj', true, '$.crossfade', 0, '$.custom_config_pre_fade', CAST(FROM_BASE64('$bridge_b64') AS CHAR CHARACTER SET utf8mb4)), needs_restart = 1 WHERE id = 1;"

  docker exec "$CONTAINER" azuracast_cli azuracast:radio:restart "$STATION" || true
  docker exec "$CONTAINER" supervisorctl start station_1:station_1_backend || true
}

seed_feedback() {
  require_container
  docker exec "$CONTAINER" sh -lc "set -eu
key=\$(sed -n 's/^settings.azuracast.api_key := \"\\(.*\\)\"/\\1/p' '$LIQ_CONFIG')
if [ -z \"\$key\" ]; then
  echo 'Liquidsoap API key not found' >&2
  exit 1
fi
payload=\$(curl -sS --max-time 8 http://127.0.0.1:8000/status-json.xsl | python3 -c 'import json,sys; j=json.load(sys.stdin); s=j.get(\"icestats\",{}).get(\"source\",{}); import json as jj; print(jj.dumps({\"artist\":s.get(\"artist\",\"\"),\"title\":s.get(\"title\",\"\")}))')
echo \"payload=\$payload\"
curl -sS --max-time 8 -w '\nfeedback_http=%{http_code}\n' \\
  -H 'Content-Type: application/json' \\
  -H 'User-Agent: KPAB Recovery' \\
  -H \"X-Liquidsoap-Api-Key: \${key}\" \\
  -d \"\$payload\" \\
  http://127.0.0.1:6010/api/internal/1/liquidsoap/feedback"
}

verify() {
  require_container
  echo "== supervisor =="
  docker exec "$CONTAINER" supervisorctl status station_1:*
  echo
  echo "== local stream =="
  docker exec "$CONTAINER" curl -sS -I --max-time 8 "$MOUNT_URL" | sed -n '1,14p'
  echo
  echo "== public stream =="
  curl -sS -I --max-time 12 "$PUBLIC_STREAM" | sed -n '1,14p'
  echo
  echo "== public api =="
  curl -sS --max-time 12 "$PUBLIC_API" | python3 -c 'import json,sys; j=json.load(sys.stdin); print("is_online=", j.get("is_online")); print("now_playing=", j.get("now_playing",{}).get("song",{}).get("text"))'
}

case "${1:-}" in
  status) status ;;
  apply-safe-mode) apply_safe_mode ;;
  seed-feedback) seed_feedback ;;
  verify) verify ;;
  -h|--help|help|"") usage ;;
  *)
    usage >&2
    exit 2
    ;;
esac
