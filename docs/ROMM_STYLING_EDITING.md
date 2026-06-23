# RomM Styling And Editing

This is the map for `games.quickcat.club`, the RomM library, and the embedded EmulatorJS player. Use it before changing the RomM presentation layer.

## Live Shape

- Public URL: `https://games.quickcat.club`
- Container: `romm`
- Database container: `romm-db`
- Compose file: `config/stacks/romm/docker-compose.yml`
- RomM image: `rommapp/romm:4.8.0`
- Public port path: Cloudflare tunnel to host port `8095`, which maps to container port `8080`
- Main RomM config: `config/stacks/romm/config.yml`
- Custom UI files: `config/stacks/romm/custom/`

`games.quickcat.club` is a direct tunnel target in `docs/INGRESS_METRICS_MAP.md`. Do not confuse it with the older `/roms/` nginx location or the separate static `/arcade/` pages.

## Startup Footgun

RomM was seen down on 2026-06-08 AEST after the Pi had crashed. The proxied public hostname returned Cloudflare `502` because the `romm` container had exited.

The root cause was a startup race after MariaDB crash recovery:

- `romm-db` began startup at `2026-06-07T13:30:17Z`.
- MariaDB was doing InnoDB crash recovery and did not report `ready for connections` until `2026-06-07T13:30:42Z`.
- `romm` started migrations at `2026-06-07T13:30:27Z` and failed at `2026-06-07T13:30:37Z` with `Can't connect to server on 'romm-db' (115)`.
- The compose file has `restart: "no"` for `romm`, so it stayed exited even though the database became healthy a few seconds later.

Quick recovery:

```sh
cd /home/pibulus/pibulus-os/config/stacks/romm
docker compose up -d romm-db
docker start romm
curl -sSI --max-time 10 http://127.0.0.1:8095/ | sed -n '1,12p'
curl -sSI --max-time 15 https://games.quickcat.club/ | sed -n '1,12p'
```

Possible future hardening: change RomM to a sane restart policy or add a small wait/retry wrapper around the migration boot step. Do that as a separate operational change, not mixed into a visual styling pass.

## Styling Injection Path

The custom presentation layer is injected by `config/stacks/romm/custom/default.conf.template`.

It does three important things:

- serves `/custom/` from `/romm/custom/`
- injects `romm-ui.js`, `emulator-touch.js`, and `theme.css` before `</head>`
- applies cross-origin isolation headers only on EmulatorJS launch routes so threaded cores can work without changing every RomM page

Current cache token: `rev=20260616g`. If a browser is holding stale styling, update the token in both `default.conf.template` and any matching asset override in `romm-ui.js`, then recreate the container.

## File Roles

`theme.css`

Main visual layer for RomM and most player-facing polish. It sets the QuickCat dark palette, card shape, cover-art handling, sidebar/topbar calmness, mobile density rules, hidden noisy chips, and EmulatorJS overlay styling.

Safe place for most visual edits:

- colors and contrast
- spacing and density
- card hover behavior
- sidebar/topbar restraint
- platform row presentation
- game-detail readability
- small EmulatorJS loading/resume visual overrides

`romm-ui.js`

DOM adaptation layer for the RomM Vue app. It hides noisy tabs and labels, tags platform sections for CSS, removes update nags, seeds emulator defaults, redirects EmulatorJS CSS paths, adds play/autoplay helpers, and simplifies details pages.

Use it when CSS selectors alone are too fragile or when the UI needs semantic tagging. Keep changes small because RomM can change its generated markup between versions.

`default.conf.template`

Container nginx template. It controls script/style injection, custom asset serving, EmulatorJS launch headers, SPA fallback, API proxying, and a few platform icon rewrites.

Edit this when adding/removing injected assets, changing cache tokens, or adjusting route-level headers. Avoid broad header changes without testing EmulatorJS.

`emulator-touch.js`

Mobile player helper. It adds a touch menu button, trims noisy EmulatorJS menu items, rewrites some loading/resume text, hooks `EJS_ready` and `EJS_onGameStart`, and closes the touch menu after use.

Use it for mobile player ergonomics rather than broad RomM library styling.

`emulator.css`

Mounted EmulatorJS stylesheet plus local overrides. This is a full stylesheet copy, so prefer appending targeted overrides or using `theme.css` unless the actual EmulatorJS chrome requires it.

`emulator.js`

Full copied EmulatorJS runtime. It has local core/default tweaks, including arcade core selection and per-system defaults. Treat this as high blast radius. Avoid editing it unless a core-loading behavior genuinely requires it.

`config.yml`

RomM configuration. Current useful presentation/player settings include:

- `disable_batch_bootup: true`
- hidden FPS by default
- browser save-state location
- one-minute save interval
- virtual gamepad enabled
- N64 keyboard mapping tuned for desktop play
- per-core/platform overrides for N64, PSX, and NDS
- metadata/media priorities and scan/exclude rules

This is where emulator behavior and scan metadata policy belong. It is not the best place for visual polish.

## Current Design Direction

The current RomM pass is aiming for the same QuickCat archive/readability vibe as the wiki and reader work:

- quiet dark shell
- tactile 8px-or-less surfaces
- cover art and screenshots carry the visual weight
- fewer chips, badges, tabs, and secondary labels
- dense but not cramped navigation
- mobile-first controls where a thumb actually lands
- no decorative gradients or ornamental UI noise

The page should feel like a calm personal game shelf and launch surface, not a busy admin catalogue.

## Safe Editing Workflow

1. Read the live config first:

```sh
cd /home/pibulus/pibulus-os
sed -n '1,180p' config/stacks/romm/docker-compose.yml
sed -n '1,220p' config/stacks/romm/custom/default.conf.template
sed -n '1,220p' config/stacks/romm/custom/theme.css
sed -n '1,220p' config/stacks/romm/custom/romm-ui.js
```

2. Make scoped edits in this order of preference:

- `theme.css` for normal visual work
- `romm-ui.js` for semantic tagging or hiding generated UI
- `emulator-touch.js` for mobile player controls
- `default.conf.template` for injection/cache/header behavior
- `emulator.css` only for targeted EmulatorJS chrome fixes
- `emulator.js` only for core/runtime behavior

3. Recreate RomM when mounted config/injection files change:

```sh
cd /home/pibulus/pibulus-os/config/stacks/romm
docker compose up -d --force-recreate romm
```

4. Verify local and public HTTP:

```sh
docker ps --filter name=romm --format 'table {{.Names}}	{{.Status}}	{{.Ports}}'
curl -sSI --max-time 10 http://127.0.0.1:8095/ | sed -n '1,12p'
curl -sSI --max-time 15 https://games.quickcat.club/ | sed -n '1,12p'
```

5. Browser-check at least:

- desktop library/home page
- mobile library/home page
- one game detail page
- one EmulatorJS launch page
- mobile touch menu
- loading/resume overlay
- console errors
- cross-origin isolation headers on `/rom/<id>/ejs/`

## Good Next Styling Targets

These are the likely high-value areas for the next pass:

- calm the home/platform strip and reduce repeated metadata
- make the game detail page center the play action and cover art more clearly
- tighten top spacing and search/filter chrome
- make loading and resume states feel deliberate rather than raw EmulatorJS
- review mobile player controls for reach, accidental taps, and hidden menu behavior
- check whether NDS should stay hidden on mobile or get a clearer unavailable state

## Avoid

- Do not edit secrets in `../.env` while styling.
- Do not expose RomM auth values in docs, commits, logs, screenshots, or browser scripts.
- Do not mix restart-policy hardening with visual tweaks unless the task is explicitly operational.
- Do not treat `/arcade/` static pages as RomM; they are a separate surface.
- Do not broaden COEP/COOP headers without testing login, API calls, asset loading, and threaded emulator cores.
