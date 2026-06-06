# Quick Cat TV Dormant Architecture Decision

## Decision

Use **Tunarr + Television Simulator '99 + PartyKit** as the transfer base.

The stack should be split:

- **Media/channel backend:** Tunarr on the new server.
- **Visual TV shell:** Television Simulator '99, with the static HLS player as fallback.
- **Community/couch layer:** PartyKit room service for presence, chat, bookings, and lightweight reactions.
- **Pi role:** optional static/frontend/proxy host only.

## Evidence From PIBULUS

- Tunarr has surviving app data at `/media/pibulus/passport/app-data/tunarr`.
- The Tunarr database contains four existing channels: Quick Cat TV, PIBULUS PRIME, THE MARATHON, and CHANNEL Z.
- The old TVS config used HLS URLs like `https://stream.quickcat.club/stream/channels/2.m3u8`.
- The old static player used `hls.js` and `/stream/channels/{n}.m3u8`.
- ALF previously played through the retro TV setup with effects on the Pi, proving the basic TV experience worked.
- The old logs showed Pi CPU transcodes timing out or being killed, so the backend should move to stronger hardware.

## Upstream Notes Checked

- Tunarr supports Plex, Jellyfin, Emby, and local media sources, and its Docker image includes FFmpeg. It defaults to port `8000` and stores durable config in `/config/tunarr`.
- Tunarr always normalizes channel streams through FFmpeg because continuous IPTV stitched from differently encoded files needs matching stream parameters and keyframe boundaries.
- Tunarr backups include `db.db`, `settings.json`, `channel-lineups/`, images/cache, and XMLTV output. Search snapshots can be rebuilt and should not be treated as precious.
- ErsatzTV's current Docker docs use `ghcr.io/ersatztv/legacy`, port `8409`, a writable `/config`, read-only media mounts, and optional tmpfs `/transcode`.
- ErsatzTV can stream from Jellyfin paths directly if it has the same shares/mounts as Jellyfin, otherwise path replacements are required.
- TVS Docker exposes port `3000` and expects the config mounted at `/home/static/config.tvs.yml`.
- PartyKit remains a good fit for small realtime rooms: it provides WebSocket rooms, local dev, deploy tooling, and examples for chat/watch-party style apps.
- HLS.js still supports the classic `Hls.isSupported()`, `loadSource`, `attachMedia`, fatal error recovery/destroy, and native HLS fallback pattern.

## Why Tunarr Wins For This Pass

Tunarr preserves existing work. The recovered state already has channel names, lineups, Jellyfin source metadata, XMLTV artifacts, and logs. Starting with ErsatzTV or FieldStation42 means rebuilding curation rather than migrating it.

## Where ErsatzTV Still Fits

ErsatzTV is the best alternate if the old Tunarr DB proves too stale or if a fresh schedule-first rebuild feels better. It is not the default only because it does not directly restore the surviving lineups.

## Where FieldStation42 Fits

FieldStation42 is worth revisiting if the goal becomes a full local cable-box simulator with a web remote and broadcast-style scheduling. It is not the default for the current transfer kit because the recovered PIBULUS setup is web/HLS/proxy-shaped.

## Guardrails

- Keep public ingress off until stream playback is stable locally.
- Do not ask the Pi to do multiple FFmpeg channel transcodes.
- Treat the Pi ALF run as proof-of-life only; reactivation belongs on stronger hardware.
- Prefer one channel backend at a time.
- Keep chat/bookings independent from stream playback.
- Store channel config and room config in Git, but keep media/app data outside Git.
