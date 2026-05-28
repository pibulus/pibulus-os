# Current Pi Notes

Checked on 2026-05-18.

The Pi is already doing a lot:

- Docker media/services
- custom Node/Deno apps
- Cloudflare Tunnel public hostnames
- a bunch of little app domains

The important bit for Bunny:

```text
Public internet -> Cloudflare Tunnel -> Pi
```

So Bunny should sit in front of Cloudflare-hosted origins, not point straight at
the home IP.

## Good First Target

`cdn.quickcat.club`

Use it for public static assets first.

## App Domains Running From The Pi

- `talktype.app`
- `ziplist.app`
- `riffrap.app`
- `promapper.app`
- `qrbuddy.app`
- `buttonspa.app`
- `isitgoingtorain.app`
- `hexbloop.app`
- `spellbreak.app`
- `stargram.app`

For these, Bunny should only cache static build assets at first.

## Media/Admin Domains

- `radio.quickcat.club`
- `radio-admin.quickcat.club`
- `watch.quickcat.club`
- `music.quickcat.club`
- `read.quickcat.club`
- `audiobooks.quickcat.club`
- `comics.quickcat.club`
- `games.quickcat.club`

Use care here.

`radio.quickcat.club` public stream paths are worth testing.

`radio-admin.quickcat.club` is not.

`watch.quickcat.club` / Jellyfin is not a first move.

## Things Noticed

- Kavita was restarting during the check, so do not CDN it until fixed.
- App immutable assets already have good cache headers.
- Cloudflare already caches some static app assets.
- The biggest win is probably public static/media files, not app HTML.

## Next Move

Make one Bunny zone:

```text
cdn.quickcat.club -> https://quickcat.club
```

Then test whether static files HIT after warmup.
