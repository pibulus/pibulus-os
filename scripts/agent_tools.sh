#!/usr/bin/env bash
set -euo pipefail

ROOT="${PIBULUS_ROOT:-/home/pibulus/pibulus-os}"

usage() {
  cat <<'EOF'
Usage: agent_tools.sh [--list|--json|--verify] [--grep QUERY]

Read-only toolbox map for Pi agents. This is orientation, not permission.
Prefer dry-run/list/status commands before any tool that queues downloads,
starts containers, changes services, or writes into Passport libraries.
EOF
}

tool_rows() {
  cat <<'EOF'
Human Deck	deck	deck	interactive	/home/pibulus/pibulus-os/launcher.sh	Human terminal deck alias. Main SSH/TTY control surface for SIGINT, radio, media, drives, ops, notes, and Soulseek.
Human Deck	launcher	/home/pibulus/pibulus-os/launcher.sh	interactive	/home/pibulus/pibulus-os/launcher.sh	Same surface behind the deck alias; inspect before changing launcher flow.
System And Deck	agent_tools	/home/pibulus/pibulus-os/scripts/agent_tools.sh --list	read-only	/home/pibulus/pibulus-os/scripts/agent_tools.sh	This inventory. Use --json for structured context and --verify for path availability.
System And Deck	deck_doctor	/home/pibulus/pibulus-os/scripts/deck_doctor.sh	read-only	/home/pibulus/pibulus-os/scripts/deck_doctor.sh	Checks Deck gateway, service health, disk pressure, Passport mount, timers, and SD guardrails.
System And Deck	status	/home/pibulus/pibulus-os/scripts/status.sh	writes-status	/home/pibulus/pibulus-os/scripts/status.sh	Refreshes Passport-backed public status.json and heartbeat log.
System And Deck	pulse	python3 /home/pibulus/pibulus-os/scripts/pulse.py	read-only	/home/pibulus/pibulus-os/scripts/pulse.py	Terminal live panel for radio, Jellyfin, Navidrome, qBittorrent, network, and disks.
System And Deck	deploy_app	/home/pibulus/pibulus-os/scripts/deploy_app.sh <app>	guarded-write	/home/pibulus/pibulus-os/scripts/deploy_app.sh	Sequential app deploy with lock, capacity checks, Passport staging, backup, smoke test, and rollback metadata.
System And Deck	refresh_deck_ai_env	/home/pibulus/pibulus-os/scripts/refresh_deck_ai_env.sh [--include-gemini] [--restart]	secret-adjacent	/home/pibulus/pibulus-os/scripts/refresh_deck_ai_env.sh	Writes private claude-chat EnvironmentFile from local keys; validates Gemini before enabling it.
System And Deck	pibulus_watchdog	/home/pibulus/pibulus-os/scripts/pibulus-watchdog.sh	changes-service	/home/pibulus/pibulus-os/scripts/pibulus-watchdog.sh	Narrow recovery pass for cloudflared, Docker, web_host, and Jellyfin.
System And Deck	cloudflare_watchdog	/home/pibulus/pibulus-os/scripts/cloudflare-watchdog.sh	changes-service	/home/pibulus/pibulus-os/scripts/cloudflare-watchdog.sh	Cloudflared tunnel recovery helper.
System And Deck	startup	/home/pibulus/pibulus-os/scripts/startup.sh	changes-service	/home/pibulus/pibulus-os/scripts/startup.sh	Starts containers/services in tiers. Read before running.
System And Deck	vault_open	/home/pibulus/pibulus-os/scripts/vault-open.sh	guarded-write	/home/pibulus/pibulus-os/scripts/vault-open.sh	Encrypted vault lifecycle helper; ask Pablo before changing vault state.
System And Deck	vault_close	/home/pibulus/pibulus-os/scripts/vault-close.sh	guarded-write	/home/pibulus/pibulus-os/scripts/vault-close.sh	Encrypted vault lifecycle helper; ask Pablo before changing vault state.
Media Search And Library	find_media	/home/pibulus/pibulus-os/scripts/find_media.py "query"	read-only	/home/pibulus/pibulus-os/scripts/find_media.py	Safe local media search across Passport libraries.
Media Search And Library	counts	/home/pibulus/pibulus-os/scripts/counts.sh	writes-status	/home/pibulus/pibulus-os/scripts/counts.sh	Refreshes media/library count JSON.
Media Search And Library	jellyfin_merge	/home/pibulus/pibulus-os/scripts/jellyfin_merge.py --scan --dry-run	dry-run-first	/home/pibulus/pibulus-os/scripts/jellyfin_merge.py	Organizes split show seasons for Jellyfin; apply only after dry-run review.
Media Search And Library	sync_arcade_roms	/home/pibulus/pibulus-os/scripts/sync_arcade_roms.py	dry-run-first	/home/pibulus/pibulus-os/scripts/sync_arcade_roms.py	Refreshes arcade/retro manifests from Passport/MEMBOT ROM folders.
Media Search And Library	archive_browser	/home/pibulus/pibulus-os/scripts/archive_browser.py	read-only	/home/pibulus/pibulus-os/scripts/archive_browser.py	Lightweight static/archive file browser helper.
Media Search And Library	zipbrowser	/home/pibulus/pibulus-os/scripts/zipbrowser.py	read-only	/home/pibulus/pibulus-os/scripts/zipbrowser.py	Lightweight ZIP/file browsing helper.
Torrents And qBittorrent	grab_movie	/home/pibulus/pibulus-os/scripts/grab_movie.py "title" --dry-run	dry-run-first	/home/pibulus/pibulus-os/scripts/grab_movie.py	Preferred movie grabber; queues into qBittorrent only without --dry-run.
Torrents And qBittorrent	grab_show	/home/pibulus/pibulus-os/scripts/grab_show.py "title" --dry-run	dry-run-first	/home/pibulus/pibulus-os/scripts/grab_show.py	Preferred show grabber; queues into qBittorrent only without --dry-run.
Torrents And qBittorrent	curator	/home/pibulus/pibulus-os/scripts/curator.py --status	read-mostly	/home/pibulus/pibulus-os/scripts/curator.py	Themed batch acquisition planner. --apply queues torrents and needs clear intent.
Torrents And qBittorrent	dlwatch	/home/pibulus/pibulus-os/scripts/dlwatch.sh [filter]	read-only	/home/pibulus/pibulus-os/scripts/dlwatch.sh	Live qBittorrent progress view.
Torrents And qBittorrent	qb_unstick	/home/pibulus/pibulus-os/scripts/qb_unstick.sh	changes-service	/home/pibulus/pibulus-os/scripts/qb_unstick.sh	Narrow qBittorrent state fixer for stuck/stalled torrents.
Torrents And qBittorrent	pirate_grab	/home/pibulus/pibulus-os/scripts/pirate_grab.py "query"	dry-run-first	/home/pibulus/pibulus-os/scripts/pirate_grab.py	Older broad grabber; prefer grab_movie/grab_show where possible.
Torrents And qBittorrent	simpsons_grab	/home/pibulus/pibulus-os/scripts/simpsons_grab.py	dry-run-first	/home/pibulus/pibulus-os/scripts/simpsons_grab.py	Curated Simpsons queue helper; --go queues downloads.
Soulseek And KPAB	kpab_grab	/home/pibulus/pibulus-os/scripts/kpab-grab "artist" ["album"] --dry-run	dry-run-first	/home/pibulus/pibulus-os/scripts/kpab-grab	Searches slskd and can queue music to Soulseek. May start slskd.
Soulseek And KPAB	kpab_downloader	/home/pibulus/pibulus-os/scripts/kpab_downloader.py --list	read-mostly	/home/pibulus/pibulus-os/scripts/kpab_downloader.py	Curated KPAB Soulseek batch downloader; use --dry-run before batch.
Soulseek And KPAB	soulseek_organize	/home/pibulus/pibulus-os/scripts/soulseek_organize.py	dry-run-first	/home/pibulus/pibulus-os/scripts/soulseek_organize.py	Dry-run hardlink organizer from raw Soulseek downloads to organized Passport library.
Soulseek And KPAB	kpab_drop	/home/pibulus/pibulus-os/scripts/kpab-drop URL --dry-run	dry-run-first	/home/pibulus/pibulus-os/scripts/kpab-drop	Downloads audio from SoundCloud/YouTube/Bandcamp into Passport intake.
Soulseek And KPAB	gen_request_catalog	/home/pibulus/pibulus-os/scripts/gen_request_catalog.py	writes-status	/home/pibulus/pibulus-os/scripts/gen_request_catalog.py	Refreshes KPAB request catalog from AzuraCast API.
Soulseek And KPAB	refresh_listeners	/home/pibulus/pibulus-os/scripts/refresh_listeners.sh	read-only	/home/pibulus/pibulus-os/scripts/refresh_listeners.sh	Samples recent AzuraCast listener rows into /tmp.
Soulseek And KPAB	kpab_hearts	/home/pibulus/pibulus-os/scripts/kpab_hearts.py	service-code	/home/pibulus/pibulus-os/scripts/kpab_hearts.py	KPAB hearts microservice; inspect status/logs before restarting.
Soulseek And KPAB	kpab_shoutbox	/home/pibulus/pibulus-os/scripts/kpab_shoutbox.py	service-code	/home/pibulus/pibulus-os/scripts/kpab_shoutbox.py	KPAB shoutbox microservice; inspect status/logs before restarting.
Soulseek And KPAB	mutiny	/home/pibulus/pibulus-os/scripts/mutiny.py	service-code	/home/pibulus/pibulus-os/scripts/mutiny.py	KPAB skip-vote microservice; inspect status/logs before restarting.
YouTube Archives Knowledge	youtube_archive	/home/pibulus/pibulus-os/scripts/youtube_archive.py sync	dry-run-first	/home/pibulus/pibulus-os/scripts/youtube_archive.py	Subscription/archive helper for YouTube pulls into Passport folders.
YouTube Archives Knowledge	knowledge_vault_downloader	/home/pibulus/pibulus-os/scripts/knowledge-vault-downloader.sh	heavy-write	/home/pibulus/pibulus-os/scripts/knowledge-vault-downloader.sh	Large autonomous knowledge downloader. Do not run casually.
YouTube Archives Knowledge	dropzone	/home/pibulus/pibulus-os/scripts/dropzone.py	service-code	/home/pibulus/pibulus-os/scripts/dropzone.py	Local dropzone web service behind QuickCat routes.
YouTube Archives Knowledge	msgdrop	/home/pibulus/pibulus-os/scripts/msgdrop.py	service-code	/home/pibulus/pibulus-os/scripts/msgdrop.py	Local message drop service behind QuickCat routes.
YouTube Archives Knowledge	wall_server	/home/pibulus/pibulus-os/scripts/wall_server.py	service-code	/home/pibulus/pibulus-os/scripts/wall_server.py	Local wall service behind QuickCat routes.
YouTube Archives Knowledge	shortener	/home/pibulus/pibulus-os/scripts/shortener.py	service-code	/home/pibulus/pibulus-os/scripts/shortener.py	Local URL shortener service.
Signal Network SDR	network_mode	/home/pibulus/pibulus-os/scripts/network_mode.sh status	changes-network	/home/pibulus/pibulus-os/scripts/network_mode.sh	Home/away network helper. Inspect status before switching modes.
Signal Network SDR	sdr_lab	/home/pibulus/pibulus-os/scripts/sdr_lab.sh status	read-mostly	/home/pibulus/pibulus-os/scripts/sdr_lab.sh	RTL-SDR lab helper for dongle state, FM presets, and installed SDR tools.
Signal Network SDR	sdr_remote	/home/pibulus/pibulus-os/scripts/sdr_remote.py	service-code	/home/pibulus/pibulus-os/scripts/sdr_remote.py	Web SDR helper.
Signal Network SDR	newsboat	newsboat	interactive	/usr/bin/newsboat	Terminal feed reader used by the deck launcher.
Signal Network SDR	weechat	weechat	interactive	/usr/bin/weechat	Terminal chat client entry point from the launcher.
EOF
}

availability() {
  local command="$1" path="$2" first
  if [[ -n "$path" && -e "$path" ]]; then
    printf 'ok'
    return
  fi
  first="${command%% *}"
  if [[ "$first" == "deck" ]]; then
    if grep -qs 'alias deck=' /home/pibulus/.bashrc; then printf 'ok'; else printf 'missing'; fi
    return
  fi
  if [[ "$first" == /* && -e "$first" ]]; then
    printf 'ok'
  elif command -v "$first" >/dev/null 2>&1; then
    printf 'ok'
  else
    printf 'missing'
  fi
}

filter_rows() {
  local query="${1:-}"
  if [[ -z "$query" ]]; then
    tool_rows
  else
    tool_rows | grep -i -- "$query" || true
  fi
}

print_list() {
  local query="$1" current="" category key command access path summary status
  filter_rows "$query" | while IFS=$'\t' read -r category key command access path summary; do
    [[ -z "${category:-}" ]] && continue
    if [[ "$category" != "$current" ]]; then
      [[ -n "$current" ]] && echo
      printf '%s\n' "$category"
      current="$category"
    fi
    status="$(availability "$command" "$path")"
    printf '  %-24s %-13s [%s]\n' "$key" "$status" "$access"
    printf '    %s\n' "$summary"
    printf '    %s\n' "$command"
  done
}

print_json() {
  local query="$1" tmp_rows
  tmp_rows="$(mktemp)"
  filter_rows "$query" > "$tmp_rows"
  python3 - "$ROOT" "$tmp_rows" <<'PY'
import json
import os
import shlex
import shutil
import sys

root = sys.argv[1]
rows_path = sys.argv[2]
items = []
for raw in open(rows_path, encoding="utf-8"):
    raw = raw.rstrip("\n")
    if not raw:
        continue
    category, key, command, access, path, summary = raw.split("\t", 5)
    first = shlex.split(command)[0] if command else ""
    available = False
    if path:
        available = os.path.exists(path)
    elif first == "deck":
        try:
            available = "alias deck=" in open("/home/pibulus/.bashrc", encoding="utf-8", errors="ignore").read()
        except OSError:
            available = False
    elif first:
        available = (first.startswith("/") and os.path.exists(first)) or shutil.which(first) is not None
    items.append({
        "category": category,
        "key": key,
        "command": command,
        "access": access,
        "path": path,
        "available": available,
        "summary": summary,
    })

print(json.dumps({
    "ok": True,
    "root": root,
    "count": len(items),
    "items": items,
}, indent=2))
PY
  rm -f "$tmp_rows"
}

verify() {
  local query="$1" missing=0 category key command access path summary status
  while IFS=$'\t' read -r category key command access path summary; do
    status="$(availability "$command" "$path")"
    printf '%-28s %s\n' "$key" "$status"
    [[ "$status" == "missing" ]] && missing=1
  done < <(filter_rows "$query")
  return "$missing"
}

mode="--list"
query=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --list|--json|--verify) mode="$1" ;;
    --grep)
      shift
      query="${1:-}"
      ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

case "$mode" in
  --list) print_list "$query" ;;
  --json) print_json "$query" ;;
  --verify) verify "$query" ;;
esac
