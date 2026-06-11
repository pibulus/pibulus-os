# Quick Cat App Skins

Shared media-app skin assets live in `www/html/quickcat-skins/` and are served from `https://quickcat.club/quickcat-skins/`.

Current wiring:

- `read.quickcat.club` uses Calibre-Web's mounted `config/calibre-web/caliBlur_override.css`.
- `comics.quickcat.club` passes through nginx, which injects `qcc-media.css` into Kavita HTML.
- `music.quickcat.club` must pass through nginx, which injects `qcc-media.css` into Navidrome HTML.

The live Cloudflare tunnel config is intentionally git-ignored. Keep the live ingress for `music.quickcat.club` pointed at `http://localhost:80`, not directly at `http://localhost:4533`, or the Navidrome skin injection is bypassed.
