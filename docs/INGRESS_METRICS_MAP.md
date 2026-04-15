# Ingress + Metrics Truth Map

Snapshot: 2026-04-02

This is the "what is actually true" map for public traffic, deck numbers, and radio counts.

## The Short Version

- `web_host` on port `80` is the clean path.
- Anything that goes through `web_host` can share auth, headers, and one coherent visitor metric.
- Anything that bypasses `web_host` is still valid, but it does not contribute to the same truth.
- The deck's `WEB 10M` stat is only recent web visitors seen by `web_host`.
- KPAB listener counts come from AzuraCast and represent stream connections, not overall site activity.

## Current Cloudflare Ingress

### Through nginx (`localhost:80`)

- `quickcat.club`
- `www.kpab.fm`
- `kpab.fm`
- `deck.quickcat.club`
- `music.quickcat.club`
- `stream.quickcat.club`
- `madebypablo.app`
- `talktype.app`

These are the only hostnames guaranteed to pass through `web_host`.

### Direct to app ports

- `radio-admin.quickcat.club` -> `8500`
- `radio.quickcat.club` -> `8000`
- `watch.quickcat.club` -> `8096`
- `read.quickcat.club` -> `8083`
- `comics.quickcat.club` -> `5000`
- `memo.quickcat.club` -> `5230`
- `go.quickcat.club` -> `8088`
- `tv.quickcat.club` -> `3099`
- `slskd.quickcat.club` -> `5030`
- `vault.quickcat.club` -> `8091`
- `retro.quickcat.club` -> `3099`
- `games.quickcat.club` -> `8095`
- `photos.quickcat.club` -> `2283`
- `scummvm.quickcat.club` -> `3001`

These bypass nginx entirely, so they also bypass shared auth, shared logging, and shared visitor counting.

## nginx Coverage

### `quickcat.club`

Acts as the front door and proxies some subpaths:

- `/deck/` -> ttyd admin shell on `7683` with basic auth
- `/terminal/` -> ttyd terminal on `7682` with basic auth
- `/wiki/` -> Kiwix on `8084`
- `/wall/*` -> Wall backend on `8086`
- `/msg/*` -> shoutbox / drop backend on `8087`
- `/roms/` -> ROMM on `8080`
- `/drop/upload` -> drop zone on `8085`

### `deck.quickcat.club`

- static deck frontend
- protected by basic auth
- serves arcade/static assets
- no direct app proxying beyond deck assets

### `kpab.fm`

- `/api/` -> AzuraCast admin/API on `8500`
- `/public/` -> AzuraCast public pages on `8500`
- `/radio.mp3` -> Icecast on `8000`
- `/listen/` -> Icecast on `8000`
- `/mutiny/` -> mutiny service on `8090`
- `/msg/*` -> shoutbox / drop backend on `8087`

This is the good radio path because it can preserve request headers and keep KPAB under one hostname.

## Metrics Truth Table

### Deck: `WEB 10M`

Source:
- [status.sh](./scripts/status.sh)

How it works:
- tails `docker logs web_host --since 10m`
- extracts unique IPs from nginx's final quoted field

What it means:
- recent unique visitors seen by `web_host`

What it does **not** mean:
- total people using the Pi
- total people listening to KPAB
- direct-app traffic on Kavita, Jellyfin, Calibre-Web, Immich, ScummVM, etc.

Confidence:
- accurate for nginx-routed web traffic
- incomplete for overall system activity

### KPAB: `live / unique`

Source:
- AzuraCast now-playing API

What it means:
- `current`: active stream connections
- `unique`: deduped listeners, roughly "distinct listeners"
- `total`: currently equal to `current` in the observed payload

Why it differs from deck visitors:
- radio listeners can hit the raw stream without browsing the site
- one person can create multiple stream connections
- deck visitors and radio listeners are measuring different things

Confidence:
- good for live stream load
- less trustworthy for historical per-IP identity while direct stream bypass remains

### Historical listener IPs in AzuraCast

Current problem:
- `radio.quickcat.club` tunnels straight to `8000`
- that bypasses nginx
- earlier listener IP history flattened to Docker/internal IPs like `172.19.0.1`

Confidence:
- degraded until radio is consistently served through the nginx/KPAB path

## Why Numbers Drift

Example:

- `WEB 10M = 3`
- `KPAB live = 7`
- `KPAB unique = 4`

This can be perfectly normal because:

- some people are listening on raw stream URLs
- some listeners never touched a page that hit `web_host`
- one human can open multiple radio sessions
- some users are on direct app subdomains that bypass nginx

## 80/20 Cleanup Order

### Keep now

- `kpab.fm` through nginx
- `quickcat.club` through nginx
- `deck.quickcat.club` through nginx + basic auth
- direct app subdomains that are already working and not hurting anything

### Improve next

1. Prefer KPAB links that use `https://kpab.fm/radio.mp3` or `/listen/...` over `radio.quickcat.club`.
2. Relabel metrics honestly instead of pretending one number means everything.
3. Decide whether "overall activity" actually matters enough to build a second metric.

### Improve later

1. Route more public subdomains through nginx if shared auth/logging matters.
2. Move `radio.quickcat.club` behind nginx or retire it in favor of `kpab.fm`.
3. If needed, add a second deck metric:
   - `WEB 10M`
   - `RADIO LIVE`
   - instead of one fake "USERS" number

## Recommendation

Do not over-rationalize this yet.

The current best shape is:

- keep nginx as the clean front door
- keep direct subdomains where convenience wins
- be honest about which number means what
- consolidate KPAB around `kpab.fm` when you want truer radio analytics

That gets most of the value without a risky routing rewrite.
