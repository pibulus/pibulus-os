# KPAB AzuraCast Recovery

Purpose: get `kpab.fm` back on air quickly when AzuraCast is up but `/radio.mp3` is missing.

This documents the 2026-06-07 outage. The public web/proxy layer was healthy, Icecast could start, but `station_1_backend` repeatedly crashed inside Liquidsoap. The first visible failure was `SIGSEGV`; after clearing caches and switching modes, Docker also confirmed earlier `oom_kill` events under the old `1g` AzuraCast memory cap.

## Known Good Emergency Shape

The current safe recovery mode is:

- AzuraCast container memory cap: `1536m`
- station backend config:
  - `audio_processing_method = none`
  - `enable_auto_cue = false`
  - `write_playlists_to_liquidsoap = true`
  - `use_manual_autodj = true`
  - `crossfade = 0`
  - `custom_config_pre_fade` replaces AzuraCast's native feedback callback with a `process.run` + `curl` bridge

Why: Liquidsoap 2.4.3 snapshot in the current AzuraCast image segfaulted when using its native HTTP client for AzuraCast callbacks (`nextsong` and `feedback`). Static playlist/manual AutoDJ avoids `nextsong`. The feedback bridge avoids Liquidsoap's native `http.post` by shelling out to `curl`, so AzuraCast can still update now-playing metadata.

AutoDJ is still running. It is using AzuraCast's generated playlist file at `/var/azuracast/stations/kpab.fm/playlists/playlist_default.m3u` instead of asking AzuraCast for the next track through the dynamic `nextsong` API. Existing playlists are intact; do not recreate them during recovery.

Observed-good on 2026-06-07: stream `200`, backend `RUNNING`, feedback callback `200`, public API `is_online=True`, and now-playing advanced after a forced `radio.skip`.

## Guardrails

Do not run these during recovery unless Pablo explicitly asks:

- `~/azuracast/docker.sh`
- `docker compose pull`
- `docker system prune -a`
- compose commands from `/home/pibulus/pibulus-os/azuracast`

Live AzuraCast is `/home/pibulus/azuracast`. The git copy at `/home/pibulus/pibulus-os/azuracast` is reference only.

## Fast Status

```bash
ssh -4 pibulus@192.168.0.40

/home/pibulus/pibulus-os/scripts/kpab_azuracast_recovery.sh status
/home/pibulus/pibulus-os/scripts/kpab_azuracast_recovery.sh verify
```

Manual checks:

```bash
docker exec azuracast supervisorctl status station_1:*
docker stats --no-stream azuracast
docker inspect azuracast --format 'Memory={{.HostConfig.Memory}} OOMKilled={{.State.OOMKilled}}'
curl -I https://kpab.fm/radio.mp3
curl -sS https://kpab.fm/api/nowplaying/kpab.fm | python3 -m json.tool | sed -n '1,80p'
```

If Icecast is live but AzuraCast says offline:

```bash
docker exec azuracast curl -sS http://127.0.0.1:8000/status-json.xsl | python3 -m json.tool | sed -n '1,100p'
```

If this shows a `source` for `/radio.mp3`, streaming is working and only AzuraCast bookkeeping is stale.

## One-Command Recovery

Use this when the station backend is down or looping:

```bash
cd /home/pibulus/pibulus-os
scripts/kpab_azuracast_recovery.sh apply-safe-mode
scripts/kpab_azuracast_recovery.sh verify
```

What `apply-safe-mode` does:

- backs up `/home/pibulus/azuracast/docker-compose.override.yml`
- sets the live AzuraCast memory cap to `1536m`
- applies the same cap to the running Docker container
- stops the KPAB backend
- moves Liquidsoap cache dirs aside and recreates empty ones
- writes the safe station backend JSON settings, including the curl feedback bridge
- regenerates/restarts KPAB
- starts `station_1_backend` directly if AzuraCast leaves it stopped

What `seed-feedback` does:

- reads the Liquidsoap API key from the generated station config without printing it
- reads current title/artist from Icecast
- sends a single `feedback` request with `curl`
- lets AzuraCast create a current-song row so the public API can show `is_online=true`

Use `seed-feedback` only if the stream is live but AzuraCast still says offline after the next metadata event.

## Manual Recovery Commands

Use these if the helper script is unavailable.

```bash
cd /home/pibulus/azuracast
cp docker-compose.override.yml docker-compose.override.yml.bak-$(date +%Y%m%d-%H%M%S)-kpab-recovery
perl -0pi -e 's/mem_reservation:\s*\S+/mem_reservation: 768m/; if (s/mem_limit:\s*\S+/mem_limit: 1536m/) {} else { s/(mem_reservation: 768m\n)/$1    mem_limit: 1536m\n/ }' docker-compose.override.yml
docker update --memory 1536m --memory-swap 2g azuracast

docker exec azuracast supervisorctl stop station_1:station_1_backend || true
docker exec azuracast sh -lc 'set -eu; ts=$(date +%Y%m%d%H%M%S); for d in /tmp/liquidsoap_cache /var/azuracast/www_tmp/liquidsoap_cache; do [ -e "$d" ] && mv "$d" "${d}.bak_${ts}"; done; install -d -o azuracast -g azuracast -m 755 /tmp/liquidsoap_cache; install -d -o azuracast -g azuracast -m 700 /var/azuracast/www_tmp/liquidsoap_cache'

bridge_b64=$(cat <<'LIQ' | base64 | tr -d '\n'
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
)
docker exec azuracast azuracast_cli dbal:run-sql "UPDATE station SET backend_config = JSON_SET(backend_config, '$.audio_processing_method', 'none', '$.enable_auto_cue', false, '$.write_playlists_to_liquidsoap', true, '$.use_manual_autodj', true, '$.crossfade', 0, '$.custom_config_pre_fade', CAST(FROM_BASE64('$bridge_b64') AS CHAR CHARACTER SET utf8mb4)), needs_restart = 1 WHERE id = 1;"
docker exec azuracast azuracast_cli azuracast:radio:restart kpab.fm || true
docker exec azuracast supervisorctl start station_1:station_1_backend || true
```

If AzuraCast still says offline after the next metadata event, seed the current-song row:

```bash
docker exec azuracast sh -lc 'set -eu
key=$(sed -n "s/^settings.azuracast.api_key := \"\(.*\)\"/\1/p" /var/azuracast/stations/kpab.fm/config/liquidsoap.liq)
payload=$(curl -sS --max-time 8 http://127.0.0.1:8000/status-json.xsl | python3 -c "import json,sys; j=json.load(sys.stdin); s=j.get(\"icestats\",{}).get(\"source\",{}); import json as jj; print(jj.dumps({\"artist\":s.get(\"artist\",\"\"),\"title\":s.get(\"title\",\"\")}))")
curl -sS --max-time 8 -w "\nfeedback_http=%{http_code}\n" -H "Content-Type: application/json" -H "User-Agent: KPAB Recovery" -H "X-Liquidsoap-Api-Key: ${key}" -d "$payload" http://127.0.0.1:6010/api/internal/1/liquidsoap/feedback'
```

## Confirmation Criteria

All of these should pass:

```bash
docker exec azuracast supervisorctl status station_1:*
curl -I https://kpab.fm/radio.mp3
curl -sS https://kpab.fm/api/nowplaying/kpab.fm | python3 -c 'import json,sys; j=json.load(sys.stdin); print(j.get("is_online"), j.get("now_playing",{}).get("song",{}).get("text"))'
docker stats --no-stream azuracast
```

Expected:

- backend and frontend are `RUNNING`
- `/radio.mp3` returns `200` and `Content-Type: audio/mpeg`
- API returns `is_online=True`
- Liquidsoap log shows `feedback curl status 200`
- AzuraCast memory sits below the `1.5GiB` cap

## Longer-Term Fix

The curl feedback bridge is an operational workaround for this AzuraCast/Liquidsoap image on the Pi. The cleaner long-term fix is moving to an AzuraCast/Liquidsoap build where native `http.post` no longer segfaults, then testing native feedback and dynamic AutoDJ one feature at a time. Do not re-enable dynamic AutoDJ, native feedback, MasterMe, AutoCue, or crossfade all at once; reintroduce one feature at a time and keep `/radio.mp3`, `station_1_backend`, and now-playing under watch.

Last-resort fallback if feedback itself starts crashing the backend again:

```bash
docker exec azuracast azuracast_cli dbal:run-sql "UPDATE station SET backend_config = JSON_SET(backend_config, '$.custom_config_pre_fade', 'def azuracast.send_feedback(m) = () end'), needs_restart = 1 WHERE id = 1;"
docker exec azuracast azuracast_cli azuracast:radio:restart kpab.fm
```

This keeps the audio stream up but may make AzuraCast now-playing stale until feedback is restored.
