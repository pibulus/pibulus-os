# Quick Cat TV Transfer Kit

Status: dormant. These files are examples and scaffolding only. They are not included by any live compose stack, nginx config, cloudflared config, or web root.

## Recommendation

Use this as the base when Quick Cat TV moves to a bigger node:

1. Tunarr owns the channels.
   - Best fit because the surviving PIBULUS state is already Tunarr: database, settings, four channels, and lineups.
   - Run it on a stronger box with hardware acceleration if possible.

2. Television Simulator '99 owns the vibe.
   - Keep it as the CRT/guide/scanline shell.
   - Feed it Tunarr HLS URLs rather than asking it to manage media.

3. The static HLS player stays as fallback.
   - The rescued `../static-player/index.html` is useful when TVS is too much or when debugging stream URLs.

4. PartyKit owns the couch room.
   - Chat, presence, simple bookings, reactions, and "who is on the couch" belong outside the Pi.
   - Keep it light and disposable; the TV stream should keep working if chat is offline.

## Why Not The Alternatives As The Base

- ErsatzTV is good, and it was part of the early PIBULUS stack, but it does not preserve the existing Tunarr lineups. Keep it as a fallback if we want to rebuild the channels cleanly.
- FieldStation42 is compelling for a full broadcast simulator, but it is heavier and less aligned with the recovered web/HLS shape.
- dizqueTV is conceptually similar and was starred, but there is no direct PIBULUS usage evidence from the repo history or surviving app data.

## Files

- `docker-compose.dormant.yml` - example new-server stack for Tunarr and TVS99. Services are behind the `manual` profile.
- `.env.example` - values to copy into a real `.env` on the new server.
- `nginx.stream-proxy.example.conf` - example reverse proxy only, not active.
- `tunarr-restore-checklist.md` - what to copy and what to change when moving existing Tunarr state.
- `tvs99/config.tvs.yml` - transfer-ready TVS config based on the recovered channel names.
- `partykit-couch/` - tiny room server skeleton for chat/presence/bookings.
- `alternates/ersatztv-compose.example.yml` - fallback backend option.
- `DECISION.md` - source-backed architecture notes.

## Dormant Rules

- Do not run `docker compose up` from this directory on the Pi.
- Do not point public DNS at these examples before the backend is on stronger hardware.
- Do not expose Tunarr/ErsatzTV admin ports publicly.
- Do not use Passport-wide searches to rediscover media; use known app-data paths and known library mounts.

## Activation Shape Later

On the new server:

1. Copy Tunarr data from the Pi Passport app-data path into the new server's Tunarr data mount.
2. Start Tunarr privately and confirm channels 1-4 load locally.
3. Update the Jellyfin media source URL from the old Docker bridge address to the new server's reachable Jellyfin URL.
4. Confirm one HLS URL works in the static player.
5. Start TVS and point it at the same stream host.
6. Deploy PartyKit chat separately and configure the couch page to connect to that host.
7. Only then add public ingress.

The Pi can stay as the quiet front porch later, but it should not do the transcoding.
