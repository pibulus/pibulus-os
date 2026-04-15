# Memory + CPU Profile

Snapshot: 2026-04-02

This is the current pressure map for the Pi after the cleanup/hardening pass.

## Host Summary

- RAM: `4.0 GiB total`
- RAM used: `~2.7 GiB`
- Available RAM: `~1.3 GiB`
- Swap: `4.0 GiB total`
- Swap used: `~3.7 GiB`
- Load average sample: `5.45, 5.13, 3.95`

Interpretation:

- The box is stable.
- The box is not relaxed.
- It is still living in permanent swap country.

## Disk Pressure

- root (`/`): `63%`
- Passport: `84%`
- MEMBOT: `90%`

Interpretation:

- root is fine
- Passport is okay but getting real
- MEMBOT is now properly "needs a plan soon"

## Biggest Containers

Sample docker stats:

- `azuracast`: `~131% CPU`, `~576 MiB`
- `kavita`: `~692 MiB`, capped at `1 GiB`
- `slskd`: `~101 MiB`
- `immich_server`: `~115 MiB`
- `jellyfin`: `~50 MiB`
- `calibre-web`: `~50 MiB`
- `web_host`: tiny

Interpretation:

- AzuraCast is the loudest steady worker.
- Kavita is the single biggest memory resident in the regular stack.
- The cleanup pass helped, but these two still define the box.

## Hottest Host Processes

Sample host processes:

- `php backend/bin/console azu...`: `~66% CPU`
- `liquidsoap`: `~25% CPU`
- `valkey-server`: `~8.6% CPU`
- `slskd`: `~3.7% CPU`
- `Kavita`: `~16.8% MEM`

Interpretation:

- Radio is the main CPU story.
- Kavita is the main memory story.
- Soulseek is not catastrophic now, but still not free.

## What Changed Already

Already in place:

- `vm.swappiness=10`
- `vm.vfs_cache_pressure=50`
- `vm.dirty_background_ratio=5`
- `vm.dirty_ratio=20`
- `slskd` deprioritized
- `scummvm` parked
- CPU/memory limits added for `kavita` and `slskd`
- AzuraCast web service given higher relative CPU share

Files:

- [config/sysctl/99-pi-tuning.conf](./config/sysctl/99-pi-tuning.conf)
- [config/stacks/pirate.yml](./config/stacks/pirate.yml)
- [azuracast/docker-compose.override.yml](./azuracast/docker-compose.override.yml)

## Honest Read

The Pi is now in the "surprisingly usable" zone, not the "comfortably provisioned" zone.

That matters because:

- one bursty service can still cause a brownout
- radio plus Kavita plus a side quest can still push the box hard
- swap is not a panic signal anymore, but it is still a tax

## 80/20 Recommendations

### Keep

- current swappiness / cache tuning
- `scummvm` as opt-in, not always-on
- `kavita` memory cap
- `slskd` lower priority

### Next

1. Keep radio-first as an operating rule.
2. Treat ScummVM and other novelty loads as background toys, not core residents.
3. Watch AzuraCast's periodic worker behavior before doing anything invasive.

### Later

1. Move heavier stateful services to the EliteDesk.
2. Let the Pi keep:
   - public static/front-door duties
   - deck
   - lightweight control services
   - maybe radio, if you want the Pi to stay the mythic core

## Working Rule

If you want the Pi to stay magical, do not make it prove masculinity by running every service at full blast forever.

It is best when:

- radio is sacred
- deck is quick
- weird extras are opt-in

