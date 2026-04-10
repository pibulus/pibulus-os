# KPAB.FM Player

Single-file radio player for AzuraCast. **All logic is inline in `index.html`** — one file, no build step, no external JS or CSS.

## Source of truth

`/home/pibulus/pibulus-os/www/html/kpab/` — this is what nginx serves.
`/media/pibulus/passport/www/html/kpab` — symlink to the above, not a separate copy.

**Edit `index.html` directly.** There are no separate JS or CSS files to worry about.

## Files

```
index.html      ← the whole player (HTML + CSS + JS, all inline)
offline.html    ← shown when Pi is unreachable
sw.js           ← service worker (PWA caching)
manifest.json   ← PWA manifest
catalog.json    ← song catalog (auto-regenerated every 6h by cron)
icon-*.png      ← PWA icons
```

## Key constants (top of the inline <script> in index.html)

```js
const API_URL    = '/api/nowplaying/kpab.fm';
const STREAM_URL = '/radio.mp3';
const POLL_MS    = 5000;
```

## Backend services

- **Mutiny (skip)**: `scripts/mutiny.py` → systemd `mutiny.service` (port 8090, auto-starts on boot)
- **Catalog**: `scripts/gen_request_catalog.py` → cron every 6h → writes `catalog.json`
- **Messages**: `scripts/kpab_shoutbox.py`
- **Hearts**: `scripts/kpab_hearts.py`

## Nginx routing (hardening.conf)

- `/radio.mp3` → Icecast port 8000
- `/api/` → AzuraCast port 8500
- `/mutiny/` → mutiny.py port 8090
- `/msg/` → shoutbox
