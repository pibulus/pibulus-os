# Bunny Folder Index

Read this first:

1. `README.md` - the vibe and goal
2. `DO_THIS_FIRST.md` - first Bunny zone
3. `PLAN.md` - short 80/20 rollout

Reference:

- `SERVICES.md` - what to try / avoid
- `COSTS.md` - rough bandwidth math
- `FINDINGS.md` - current Pi notes
- `AUDIT.md` - commands for checking things later

## Current Recommendation

Try Bunny on `cdn.quickcat.club`.

Keep the origin as an existing Cloudflare Tunnel hostname.

Cache public static files.

Bypass private/dynamic stuff.

## Good Candidates

- Quick Cat / KPAB public assets
- images, audio files, fonts, CSS, JS
- app immutable assets
- maybe public radio stream paths after testing

## Bad First Candidates

- Jellyfin
- admin panels
- SSH / terminals
- File Browser
- APIs / uploads / webhooks
- private libraries

## Quick Test

```bash
curl -I https://cdn.quickcat.club/some-static-file
curl -I https://cdn.quickcat.club/some-static-file
```

Second request should be a cache HIT.

## Quick Rollback

Stop using the CDN hostname, purge/delete the Bunny zone, and carry on.
