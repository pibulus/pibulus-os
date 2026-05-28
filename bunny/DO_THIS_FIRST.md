# Do This First

Start with one Bunny pull zone:

```text
cdn.quickcat.club
```

Origin:

```text
https://quickcat.club
```

Keep using the existing Cloudflare Tunnel hostname as the origin. Do not point
Bunny at the home IP.

## Why This One?

It is low stakes.

If it works, we have a fast public cache for Quick Cat/KPAB/static stuff.

If it is annoying, delete it.

## Bunny Settings

In Bunny:

- create a Pull Zone
- origin URL: `https://quickcat.club`
- custom hostname: `cdn.quickcat.club`
- SSL: on
- Origin Shield: on if available
- bandwidth/overage protection: on

In DNS:

- add the CNAME Bunny asks for
- do not change the existing root domains yet

## Cache This

Long cache:

```text
*.css
*.js
*.mjs
*.woff
*.woff2
*.png
*.jpg
*.jpeg
*.webp
*.gif
*.svg
*.ico
*.mp3
*.m4a
*.ogg
*.mp4
/_app/immutable/*
/assets/*
```

## Do Not Cache This

Bypass:

```text
/api/*
/admin/*
/auth/*
/login*
/logout*
/upload*
/uploads*
/webhook*
/settings*
/terminal*
```

Also bypass:

```text
POST
PUT
PATCH
DELETE
```

For HTML pages, start boring: bypass or very short cache.

## Test

Run:

```bash
curl -I https://cdn.quickcat.club/
curl -I https://cdn.quickcat.club/some-image-or-js-file
curl -I https://cdn.quickcat.club/some-image-or-js-file
```

What we want:

- static file: first request MISS, second request HIT
- HTML: bypass or short cache
- private/admin/API paths: not cached

On the Pi:

```bash
journalctl -u cloudflared --since "15 minutes ago"
docker stats --no-stream
```

## Rollback

If anything feels off:

1. stop using `cdn.quickcat.club`
2. purge the Bunny zone
3. remove the CNAME if needed
4. delete the pull zone

Nothing important should depend on this.
