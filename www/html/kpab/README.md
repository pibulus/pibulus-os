# KPAB.FM — Forkable Pirate Radio Player

A modular web player for internet radio stations running [AzuraCast](https://azuracast.com/). No build tools, no frameworks, no dependencies — just static files you can host anywhere.

Fork it. Change `js/config.js`. You have a radio station.

## Quick Start

1. **Set up AzuraCast** — self-hosted or cloud. Get your station running and streaming.
2. **Fork this repo**
3. **Edit `js/config.js`** — point it at your AzuraCast instance (see Config Reference below)
4. **Edit `index.html`** — replace the KPAB.FM branding, FAQ copy, and about section with your own
5. **Edit `offline.html`** — replace the station name and flavor text
6. **Edit `css/style.css` `:root` block** — swap the color tokens to retheme (see Theming below)
7. **Serve it** — any static file host works (nginx, Caddy, GitHub Pages, Netlify). HTTPS required for the service worker and PWA features.

## Config Reference

All station-specific values live in `js/config.js`:

```js
const STATION = {
  name:            // Station display name (used in UI, Media Session, share text)
  tagline:         // Short tagline shown when no track metadata
  subtitle:        // Shown in header area
  url:             // Public URL of your station (used by share feature)
  streamUrl:       // Direct MP3 stream URL (AzuraCast: /radio.mp3 or /listen/your_mount/radio.mp3)
  apiUrl:          // AzuraCast now-playing API (e.g. /api/nowplaying/your_station_shortcode)
  catalogUrl:      // URL to your catalog JSON (see Catalog section below)
  mutinyEndpoint:  // OPTIONAL — vote-to-skip backend (set to null to hide the feature)
  msgEndpoint:     // OPTIONAL — listener message drop backend (set to null to hide the feature)
  pollInterval:    // How often to poll for now-playing data in ms (10000 = 10s is sensible)
};
```

### Finding your AzuraCast values

- **streamUrl**: AzuraCast Admin > Station > Mount Points. The default is usually `/radio.mp3`
- **apiUrl**: `https://your-azuracast-domain/api/nowplaying/your_station_shortcode` — the shortcode is in Station > Profile > URL Stub
- **catalogUrl**: This is a custom JSON file you generate (see below), not a built-in AzuraCast endpoint

### Optional features (Mutiny & Messages)

`mutinyEndpoint` and `msgEndpoint` are **not** AzuraCast routes — they're custom microservices. If you don't have these backends, the buttons still appear but will show a network error. To properly disable them, set the values to `null` in config and remove the corresponding `<section>` blocks from `index.html`.

## Catalog (Song Request Search)

The request panel lets listeners search and request songs. It needs a JSON file at your `catalogUrl` with this schema:

```json
[
  { "a": "Artist Name", "t": "Track Title", "b": "Album Name", "art": "/art/path.jpg", "id": "azuracast_unique_id" },
  { "a": "Another Artist", "t": "Another Track", "b": "", "art": null, "url": "/api/station/1/request/abc123" }
]
```

| Field | Required | Description |
|-------|----------|-------------|
| `a`   | yes      | Artist name |
| `t`   | yes      | Track title |
| `b`   | no       | Album name |
| `art` | no       | Album art URL (absolute or relative) |
| `id`  | yes*     | AzuraCast unique song ID (used to build request URL) |
| `url` | yes*     | OR a full request URL path (takes priority over `id`) |

*One of `id` or `url` is required per track.

The catalog is cached in IndexedDB on the client and refreshed every 6 hours. See `catalog.example.json` for a sample.

### Generating your catalog

AzuraCast doesn't expose a single "all songs" endpoint. Common approaches:
- Export from AzuraCast's media manager and transform with a script
- Query AzuraCast's API station media endpoints
- Build a cron job that regenerates the JSON periodically

## Theming

All colors, spacing, and component sizes are CSS custom properties in the `:root` block of `css/style.css`. Swap these to retheme — zero hardcoded values exist outside `:root`.

```css
:root {
  --bg: #060608;        /* Page background */
  --cyan: #00ffea;      /* Primary accent */
  --magenta: #ff00ff;   /* Secondary accent */
  --text: #d8d8dc;      /* Body text */
  --dim: #5a5a66;       /* Muted text */
  --panel: #0c0c10;     /* Panel backgrounds */
  --border: #1c1c24;    /* Panel borders */
  /* ...plus surface, danger, spacing, and size tokens */
}
```

## Architecture

```
index.html          — markup (edit branding and copy here)
offline.html        — shown when service worker can't reach the server
manifest.json       — PWA manifest (update name, icons, colors)
sw.js               — service worker (network-first JS/CSS, cache-first icons)
css/style.css       — all styles, fully tokenized via :root custom properties
js/
  config.js         — single config file (START HERE when forking)
  utils.js          — shared helpers (fmtTime, fixArtUrl, escHtml)
  player.js         — core player: streaming, now-playing, progress, history, visualizer
  request.js        — song catalog search with IndexedDB caching
  mutiny.js         — vote-to-skip feature (optional, needs backend)
  messages.js       — listener message drop (optional, needs backend)
  about.js          — FAQ panel toggle
  share.js          — Web Share / clipboard share
deploy.sh           — deployment script (configure for your server)
```

All JS modules are IIFE-wrapped — no globals leak except `STATION` (config) and `shareStation` (share helper).

## Deployment

The included `deploy.sh` is configured for KPAB's Pi server. The canonical production path is `/home/pibulus/pibulus-os/www/html/kpab`.

To use it for your setup:

1. Set `PI_HOST` env var to your `user@host`
2. Update the `DEST` path in the script to your web root
3. Ensure SSH key auth is configured (no passwords in the script)

Legacy note: an older passport-drive path existed during Pi migration work. Do not use it as a second live copy. Keep one live path and use git or timestamped backups for rollback.

Or just copy the files to any static host. No build step required.

## Browser Support

Works in all modern browsers. Key features and their fallbacks:
- **IndexedDB** (catalog cache): falls back to in-memory array
- **BroadcastChannel** (cross-tab polling): gracefully ignored if unavailable
- **Media Session API** (lock screen controls): ignored if unavailable
- **Service Worker** (offline/caching): site works without it, just no offline support

## License

MIT
