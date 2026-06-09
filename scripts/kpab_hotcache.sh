#!/usr/bin/env bash
set -euo pipefail

CONTAINER="${CONTAINER:-azuracast}"
STATION="${STATION:-kpab.fm}"
CACHE_GIB="${CACHE_GIB:-4}"
CACHE_TRACKS="${CACHE_TRACKS:-120}"
PLAYLIST="/var/azuracast/stations/${STATION}/playlists/playlist_default.m3u"
CACHE_ROOT="/var/azuracast/stations/${STATION}/kpab_hotcache"
CACHE_PLAYLIST="${CACHE_ROOT}/playlist_default.m3u"
STREAM_URL="http://127.0.0.1:8000/radio.mp3"

usage() {
  cat <<USAGE
Usage: kpab_hotcache.sh <build|activate|verify|status>

Environment:
  CACHE_GIB     Max cache size in GiB, default ${CACHE_GIB}
  CACHE_TRACKS  Max tracks, default ${CACHE_TRACKS}

Run on pibulus. This builds a small ext4-backed KPAB playlist cache so
Liquidsoap does not need to read every transition from the Passport NTFS mount.
USAGE
}

require_container() {
  docker inspect "$CONTAINER" >/dev/null
}

build() {
  require_container
  docker exec -i "$CONTAINER" sh -s -- "$STATION" "$CACHE_GIB" "$CACHE_TRACKS" <<'SCRIPT'
set -euo pipefail
station="$1"
cache_gib="$2"
cache_tracks="$3"
cat > /tmp/build_kpab_hotcache.py <<'PY'
import random
import shutil
import sys
from pathlib import Path

station = sys.argv[1]
cache_gib = float(sys.argv[2])
max_tracks = int(sys.argv[3])
playlist = Path(f'/var/azuracast/stations/{station}/playlists/playlist_default.m3u')
media_root = Path(f'/var/azuracast/stations/{station}/media')
cache_root = Path(f'/var/azuracast/stations/{station}/kpab_hotcache')
cache_media = cache_root / 'media'
cache_playlist = cache_root / 'playlist_default.m3u'
max_bytes = int(cache_gib * 1024 * 1024 * 1024)

cache_media.mkdir(parents=True, exist_ok=True)
for old in cache_media.iterdir():
    if old.is_file():
        old.unlink()

lines = [line.rstrip('\n') for line in playlist.read_text(errors='replace').splitlines() if line.strip()]
random.SystemRandom().shuffle(lines)

out = []
total = 0
count = 0
skipped = 0
for line in lines:
    if ':media:' not in line:
        skipped += 1
        continue
    prefix, rel = line.split(':media:', 1)
    src = media_root / rel
    try:
        size = src.stat().st_size
    except OSError:
        skipped += 1
        continue
    if count > 0 and (total + size > max_bytes or count >= max_tracks):
        break
    suffix = Path(rel).suffix or '.audio'
    dest = cache_media / f'{count+1:05d}{suffix}'
    try:
        shutil.copy2(src, dest)
    except OSError as exc:
        print(f'skip copy failed: {src}: {exc}', file=sys.stderr)
        skipped += 1
        continue
    out.append(f'{prefix}:{dest}')
    total += size
    count += 1
    if count % 10 == 0:
        print(f'cached {count} tracks, {total/1024/1024:.1f} MiB', flush=True)

if count == 0:
    raise SystemExit('no tracks cached')
cache_playlist.write_text('\n'.join(out) + '\n')
print(f'DONE cached_tracks={count} cached_mib={total/1024/1024:.1f} skipped={skipped} playlist={cache_playlist}')
PY
ionice -c3 nice -n 19 python3 /tmp/build_kpab_hotcache.py "$station" "$cache_gib" "$cache_tracks"
SCRIPT
}

activate() {
  require_container
  docker exec "$CONTAINER" sh -lc "set -eu; test -s '$CACHE_PLAYLIST'; ts=\$(date +%Y%m%d%H%M%S); cp '$PLAYLIST' '$PLAYLIST.pre-hotcache-'\$ts; cp '$CACHE_PLAYLIST' '$PLAYLIST'; wc -l '$PLAYLIST'; grep -vc kpab_hotcache '$PLAYLIST' || true"
  docker exec "$CONTAINER" supervisorctl restart station_1:station_1_backend || true
}

verify() {
  require_container
  docker exec "$CONTAINER" supervisorctl status station_1:*
  docker exec "$CONTAINER" sh -lc "wc -l '$PLAYLIST'; grep -vc kpab_hotcache '$PLAYLIST' || true; du -sh '$CACHE_ROOT'"
  curl -sS -I --max-time 8 "$STREAM_URL" | sed -n '1,10p'
  docker logs --since 5m "$CONTAINER" 2>&1 | grep -E 'kpab_hotcache|Latency is too high|Nothing received|Disconnecting /radio.mp3|EPIPE' | tail -80 || true
}

status() {
  require_container
  docker exec "$CONTAINER" sh -lc "du -sh '$CACHE_ROOT' 2>/dev/null || true; test -f '$PLAYLIST' && { wc -l '$PLAYLIST'; grep -vc kpab_hotcache '$PLAYLIST' || true; }"
  df -h /
}

case "${1:-}" in
  build) build ;;
  activate) activate ;;
  verify) verify ;;
  status) status ;;
  -h|--help|help|"") usage ;;
  *) usage >&2; exit 2 ;;
esac
