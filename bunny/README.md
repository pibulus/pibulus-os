# Bunny CDN Notes for the Pi

This is not a scale-up plan.

This is a small, practical note for a Raspberry Pi sitting on a desk in
Melbourne, velcro'd to a hard drive, running a bunch of weird useful little
things.

The goal is simple:

- keep the Pi as the source of truth
- keep the home connection less stressed
- make public stuff feel faster
- avoid handing the whole setup to a platform
- keep rollback boring

Use Bunny like velcro, not concrete. Stick it to the parts where it helps. Peel
it off if it gets annoying.

## The 80/20 Idea

Put Bunny in front of public static stuff first:

- images
- CSS/JS
- fonts
- public audio/media files
- hashed app assets like `/_app/immutable/*`

Do not start with:

- Jellyfin
- admin panels
- SSH
- terminals
- uploads
- APIs
- private libraries

The nice shape is:

```text
Visitor -> Bunny -> Cloudflare Tunnel hostname -> Pi
```

That keeps the home IP hidden, keeps the Pi sovereign enough, and still uses a
cheap global cache where it makes sense.

## Philosophy

Sovereign where it matters:

- the files live here
- the apps deploy here
- the Pi can still run without Bunny
- no app should depend on Bunny existing

Use tools where they are useful:

- Bunny can cache public files
- Cloudflare Tunnel can keep the origin tucked away
- DNS can point at whichever layer is least annoying

No heroic architecture. No platform cosplay.

## First Move

Read `DO_THIS_FIRST.md`.

The first experiment should be `cdn.quickcat.club` pointing at public static
stuff. If that works and feels good, use it more. If not, delete the zone and
carry on.

## Folder Map

- `DO_THIS_FIRST.md` - the actual first move
- `PLAN.md` - short 80/20 rollout
- `SERVICES.md` - what to try / avoid
- `COSTS.md` - rough cost math
- `FINDINGS.md` - current Pi notes
- `AUDIT.md` - commands for checking the Pi
- `INDEX.md` - quick navigation

## One Rule

Cache public files. Bypass private/dynamic things.

That single rule gets most of the benefit without making the Pi weird.
