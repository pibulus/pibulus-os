# Pi AI Collective Context

This is shared orientation for Claude Code, Codex CLI, Gemini CLI, DeepSeek/OpenCode, and any other agent launched from the PIBULUS Deck.

## Where You Are

- Host: Raspberry Pi 5, 4GB RAM, Debian Bookworm, in Melbourne.
- Human: Pablo, Mexican-Australian builder, aesthetics-first, anti-scale, human-first.
- Project root: `/home/pibulus/pibulus-os`.
- Live apps: `/home/pibulus/apps`.
- Deck web files: `/home/pibulus/pibulus-os/www/html`.
- Passport drive: `/media/pibulus/passport`, 5.5TB NTFS, lowercase `passport`.
- Root SD card is precious. Avoid large writes on root; stage builds on Passport when possible.

## How To Be Useful Here

- Talk like a smart friend. Be direct, concrete, and phone-readable.
- Prefer the next smallest useful move. 80/20 beats heroic sprawl.
- Keep the weirdness, but make it work.
- Pablo likes tools with personality, utility, and soul. No corporate filler.
- Ask before irreversible operations. If something smells risky, say why.
- If you inspect, summarize what matters first. If you edit, state what changed and how you verified it.

## Hard Guardrails

- Never print or commit secrets.
- Never track `.env` files or credential files.
- Never unmount Passport without Pablo explicitly saying yes.
- Never run `docker compose pull`, AzuraCast update scripts, or change image tags without explicit approval.
- Never run `docker system prune -a`.
- Never run compose from `/home/pibulus/pibulus-os/azuracast`; live AzuraCast is `/home/pibulus/azuracast`.
- Check `free -h` before heavy containers, model downloads, builds, or scans.
- Validate YAML after edits with `python3 -c "import yaml; yaml.safe_load(open('file'))"`.
- If nginx is 502/504, check `docker ps`; `web_host` may need a narrow restart.

## Deck Modes

- Plan: inspect and propose. Do not edit files.
- Ask: answer and inspect. Avoid edits unless the CLI mode explicitly permits them safely.
- Act: Claude's normal action path.
- Full: Pablo held the browser safety button for this one run. You may edit inside the selected workspace, but still respect the hard guardrails above.

## Local Design Taste

- Terminal/BBS/ASCII is part of the house language.
- Use amber/green/cream on dark as a base, with small accent colors for state.
- Interfaces should feel private, useful, and alive, not like SaaS marketing.
- Dense is fine when it is organized. Motion should help the operator, not show off.

## Important Services

- `claude-chat.service`: local Deck AI gateway, bound to `172.17.0.1:9016`.
- Public deck route: `https://deck.quickcat.club/deck/claude/`, basic-auth protected.
- Main reverse proxy: Docker `web_host` on port 80.
- AzuraCast: live compose in `/home/pibulus/azuracast`, stream/admin ports around 8000/8500.
- Cloudflared tunnel exposes public QuickCat routes.

## Operator Tools Available

Scripts live in `/home/pibulus/pibulus-os/scripts`. Prefer `--dry-run`, `--list`, or read-only status commands first. Many tools write to Passport media folders or talk to local services; do not run large downloads, broad scans, Docker starts, or queue-changing actions from Plan mode.

### System And Deck

- `status.sh`: writes live deck status JSON to Passport-backed web state.
- `pulse.py`: terminal live panel for system, downloads, radio, Jellyfin, and Navidrome.
- `deploy_app.sh <talktype|ziplist|stargram|ghostnote>`: guarded app deploy with lock, capacity checks, Passport-backed staging, backup, smoke test, and rollback metadata.
- `refresh_deck_ai_env.sh`: validates Deck AI environment, especially Gemini. It should be used after Pablo provides fresh API keys.
- `cloudflare-watchdog.sh`, `pibulus-watchdog.sh`, `startup.sh`: service recovery scripts. Read before running; `startup.sh` starts containers in tiers.
- `vault-open.sh` / `vault-close.sh`: vault lifecycle helpers. Ask Pablo before changing vault state unless explicitly requested.

### Media Search And Library

- `find_media.py "query"`: safe local media search across Passport libraries.
- `counts.sh`: refreshes public count JSON for media/library totals.
- `jellyfin_merge.py`: organizes split show seasons for Jellyfin. Use `--scan --dry-run` first.
- `sync_arcade_roms.py`: refreshes arcade/retro game manifests from Passport/MEMBOT ROM folders.
- `archive_browser.py`, `zipbrowser.py`: lightweight file browsing helpers for static/archive areas.

### Torrents And qBittorrent

- `grab_movie.py "title" --dry-run` and `grab_show.py "title" --dry-run`: preferred qBittorrent grabbers for movies/shows; they use local qBittorrent credentials from env and save into Passport media paths.
- `curator.py --status` / `curator.py --dry-run`: themed batch acquisition planner. `--apply` queues torrents and should only be used when Pablo clearly asks.
- `dlwatch.sh [filter]`: read-only live qBittorrent progress view.
- `qb_unstick.sh`: pauses torrents stuck in metadata/stalled states; it changes qBittorrent state but is narrow.
- `pirate_grab.py`: older broad torrent grabber. Prefer the qBittorrent-specific grabbers above unless the older flow is requested.
- `simpsons_grab.py`: queues curated Simpsons episodes/seasons; default is dry run, `--go` queues downloads.

### Soulseek And KPAB

- `kpab-grab "artist" ["album"] --dry-run`: searches `slskd`, picks a music result, and can queue it to Soulseek. It may start the `slskd` container.
- `kpab_downloader.py --list` / `--dry-run --batch <name>`: curated KPAB Soulseek batch downloader.
- `soulseek_organize.py`: default dry-run hardlink organizer from raw Soulseek downloads to `/media/pibulus/passport/Soulseek Organized`; `--apply` creates hardlinks only.
- `kpab-drop URL --dry-run`: downloads audio from SoundCloud/YouTube/Bandcamp via `yt-dlp` into Passport music intake. Running without `--dry-run` can download large media.
- `gen_request_catalog.py`: refreshes KPAB request catalog from AzuraCast API.
- `refresh_listeners.sh`: samples recent AzuraCast listener rows into `/tmp/kpab_recent_listeners.tsv`.
- `kpab_hearts.py`, `kpab_shoutbox.py`, `mutiny.py`: KPAB microservices. Prefer service status/log inspection before restarting.

### YouTube, Archives, And Knowledge

- `youtube_archive.py`: subscription/archive helper for YouTube pulls into Passport folders.
- `knowledge-vault-downloader.sh`: large autonomous knowledge downloader. Do not run casually; check disk/network intent first.
- `dropzone.py`, `msgdrop.py`, `wall_server.py`, `shortener.py`: small local web services behind QuickCat routes.

## Shared Memory

- Claude diary may exist at `/home/pibulus/.claude/claude_diary.md`.
- Trust live config and scripts before older docs.
- When docs disagree, prefer current systemd units, nginx config, compose files, and running services.
