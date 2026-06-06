# Quick Cat TV Recovery Notes

Status: archived only. These files are not wired into nginx, cloudflared, Docker, or the public web root.

## What Was Rescued

- `static-player/index.html`
  - Source: commit `20ef9d08fcd52ceaffb410cdcf1634c9f2cd7d23`
  - Original path: `www/html/tv/index.html`
  - Purpose: fullscreen retro HLS player for Quick Cat TV channels 2-4.
  - Stream pattern: `/stream/channels/{channel}.m3u8`

- `tvs99/config.tvs.yml`
  - Source: commit `20ef9d08fcd52ceaffb410cdcf1634c9f2cd7d23`
  - Original path: `television-simulator/config.tvs.yml`
  - Purpose: Television Simulator '99 style config with scanlines, shadow mask, guide split, and HLS channel inputs.

- `ersatztv-compose-from-history.yml`
  - Source: commits `3d83174` and `52ab727`
  - Purpose: the old tracked ErsatzTV service snippet before the stack moved on.

## Known-Good Proof

This was not only theoretical. ALF previously ran through the retro TV setup with the old-school effects on the Pi, so the basic playback/overlay idea worked. The problem was load: effects plus channel streaming/transcoding were too much for the Pi as a long-running host.

## Likely Stack

The recovered pieces point to a split system:

- Overlay/frontend: Television Simulator '99 / TVS launcher
  - Starred repo: `zshall/program-guide`
  - Repo description: "Television Simulator '99"
  - PIBULUS clue: the deleted `config.tvs.yml` uses TVS-style settings such as `defaultChannel`, `scanlines`, `noise`, `shadowMask`, `bezel`, `guide`, and HLS providers.

- Channel backend, later phase: Tunarr
  - Repo: `chrisbenincasa/tunarr`
  - PIBULUS clues: `tv.quickcat.club` was added "for Tunarr" on `2026-03-29`, the deck had a Tunarr card, README diagrams mention `tunarr`, and Passport app data survives at `/media/pibulus/passport/app-data/tunarr`.

- Channel backend, earlier phase: ErsatzTV
  - Repo: `ErsatzTV/legacy`
  - PIBULUS clues: `config/stacks/pirate.yml` added `ersatztv` on `2026-02-15`, and current admin homepage config still lists ErsatzTV as an offline/manual service on port `8001`.

- Reference-only candidate: dizqueTV
  - Starred repo: `vexorian/dizquetv`
  - PIBULUS clue: starred and conceptually similar, but no repo-history string or surviving app-data evidence found in this pass.

- Bigger alternate simulator: FieldStation42
  - Starred repo: `shane-mason/FieldStation42`
  - PIBULUS clue: conceptually matches the old-school TV idea, but the recovered PIBULUS config does not look like FieldStation42.

## Timeline

- `2026-02-15` - `3d83174` added ErsatzTV to `config/stacks/pirate.yml`.
- `2026-02-15` - `52ab727` fixed the ErsatzTV image from `jasonmcnew/ersatztv:latest-vaapi` to `jasongdove/ersatztv:latest`.
- `2026-03-29` - `7678267` added `tv.quickcat.club` tunnel route for Tunarr.
- `2026-03-31` - `20ef9d0` added the TVS config and static Quick Cat TV HLS player.
- `2026-04-01` - `b70ba7f` removed the Retro TV deck card with the note "temporarily offline".

## Surviving Tunarr State

Known surviving app data:

- Path: `/media/pibulus/passport/app-data/tunarr`
- Database: `db.db`
- Lineups: `channel-lineups/*.json`
- Stream/cache/log files also exist there.

Channels found in the Tunarr database:

| Number | Name | Programs |
| --- | --- | ---: |
| 1 | Quick Cat TV | 17 |
| 2 | PIBULUS PRIME | 47 |
| 3 | THE MARATHON | 39 |
| 4 | CHANNEL Z | 36 |

Tunarr source and transcode clues:

- Media source: Jellyfin at `http://172.17.0.1:8096`
- Stream mode: HLS
- Transcode config: `Default`, `h264`, `1280x720`, `3000k` video, `2` threads, no hardware acceleration, audio copy.
- Old logs showed HLS transcodes from `/media/shows/...` and `/media/movies/...`, plus timeouts and killed transcodes.

## Reactivation Shape Later

Do not restart this blindly on the Pi. The old logs and agent notes both suggest Pi CPU transcoding was fragile.

The cleaner future shape is:

- Pi: serves the retro frontend and lightweight proxy routes.
- Bigger node: runs Tunarr/ErsatzTV and any ffmpeg transcoding.
- TVS/static player: consumes stable HLS URLs from the backend.
- Couch/community layer: build separately around schedule/bookings/chat, then feed the selected stream URL into the TV frontend.

Before activation:

- Pick one backend: Tunarr if preserving the existing lineups matters, ErsatzTV if starting fresh with a fuller scheduler, FieldStation42 only if we want a heavier all-in simulator.
- Move or rebuild the stream backend on stronger hardware before public routing.
- Keep `stream.quickcat.club` and `/stream/channels/*.m3u8` behind a controlled proxy.
- Avoid multiple simultaneous Pi transcodes.
