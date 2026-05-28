# 80/20 Bunny Plan

## What We Are Doing

Add a cheap cache layer for public files.

That is it.

The Pi still runs the show. Bunny just takes repeat public requests when it can.

```text
Visitor -> Bunny -> Cloudflare Tunnel -> Pi
```

## Step 1: One Tiny Pilot

Make `cdn.quickcat.club`.

Point it at `https://quickcat.club`.

Cache images, JS, CSS, fonts, and public media.

Do not move app root domains yet.

Do not touch Jellyfin.

## Step 2: If It Feels Good

Use Bunny for more public/static stuff:

- KPAB artwork/audio/static files
- Quick Cat public assets
- app build assets like `/_app/immutable/*`

Keep APIs and HTML boring until proven otherwise.

## Step 3: Maybe Later

Try a test URL for public radio streams.

This could reduce strain if radio gets busy, but test it like a real listener:

- does it start quickly?
- does metadata behave?
- does reconnect work?
- does the Pi send less repeated traffic?

Keep `radio-admin.quickcat.club` out of Bunny.

## Step 4: Not Yet

Do not start with:

- Jellyfin
- File Browser
- SSH
- terminals
- private libraries
- upload/download flows

Those can be revisited if there is an actual problem to solve.

## The Rule

If it is public and file-like, Bunny can probably help.

If it is private, logged-in, stateful, or mutating, bypass it.

## Success Looks Like

- static assets get HIT after warmup
- the Pi still works if Bunny is deleted
- deploys do not get stale
- the home IP stays hidden
- the setup still feels like ours

## Stop Conditions

Stop or roll back if:

- private content appears through the CDN
- app pages get stale after deploys
- auth gets weird
- debugging becomes annoying

This is supposed to make the Pi calmer, not create a new job.
