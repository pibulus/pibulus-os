# What To Bunny

Short version: cache public files, not apps with feelings.

## Yes, Try This

### Quick Cat / KPAB Static Stuff

Best first target.

Examples:

- images
- station artwork
- CSS/JS
- public audio files
- fonts

Low risk, easy to test, easy to delete.

### Custom App Static Assets

Good later target.

Apps:

- TalkType
- ZipList
- QRBuddy
- RiffRap
- ProMapper
- ButtonSpa
- Hexbloop
- Spellbreak
- Stargram
- Is It Going To Rain

Cache:

```text
/_app/immutable/*
/assets/*
*.css
*.js
*.png
*.jpg
*.webp
*.svg
*.woff2
```

Bypass:

```text
/api/*
/auth/*
/login*
/logout*
/upload*
/webhook*
POST / PUT / PATCH / DELETE
```

## Maybe, After Testing

### AzuraCast Public Stream

Worth trying on a test hostname.

Keep admin out of it.

Check:

- listener startup
- metadata
- reconnects
- whether Pi traffic actually drops

### Kavita / Calibre / Audiobookshelf

Maybe useful for repeated media reads.

Only try media/static paths. Do not cache logged-in pages.

Kavita was restarting during the last check, so fix that before CDN testing.

### Navidrome

Maybe later. It is a personal music library, so auth/private behavior matters.

## Not First

### Jellyfin

Leave it alone for now.

Jellyfin has auth, watched state, private media, range requests, and transcoding.
Bunny might help direct-play files later, but this is not the first move.

## No

Do not Bunny these:

- SSH
- terminals
- File Browser
- admin dashboards
- databases
- upload flows
- private libraries
- random APIs

## Rule Of Thumb

Would you be fine if this exact response was served again later to a stranger?

If yes, maybe cache it.

If no, bypass it.
