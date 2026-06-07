# Emoji App Icons

Use emoji icons as the default favicon and home-screen identity for Quick Cat pages and small apps.

## Default Pattern

For static pages, keep the icon source simple: one emoji in an SVG favicon.

```html
<meta name="theme-color" content="#0D0F14">
<meta name="application-name" content="Quick Cat">
<meta name="apple-mobile-web-app-title" content="Quick Cat">
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
```

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <text y=".9em" x="50" text-anchor="middle" font-size="88">🐱</text>
</svg>
```

If a page uses `emoji-favicon.js`, add or update its route rule instead of creating a new icon system.

## Names

Use the home-screen labels Pablo expects:

- public Quick Cat page: `Quick Cat`
- personal deck page: `Quick Deck`
- small one-off apps: short, readable names that fit under an iOS icon

Set both `application-name` and `apple-mobile-web-app-title` when the page is meant to be saved.

## PWA Manifests

Do not add a manifest or `apple-touch-icon` just to satisfy a checklist. If the page already saves correctly with the emoji favicon, keep it that way.

For apps that truly need a manifest because they use offline caching, standalone display, shortcuts, or install prompts, treat the emoji as the source of truth. Generate manifest PNGs from that emoji only when the platform requires PNG icons. Do not replace the emoji with a bespoke drawn icon unless Pablo asks for a branded icon pass.

## Quick Rule

Emoji first. Custom icon later only if there is a real product reason.
