# Backup + Redundancy Plan

Snapshot: 2026-04-02

This is the actual current state, not the aspirational one.

## Current Reality

### What exists now

- nightly backup via [scripts/nightly-backup.sh](./scripts/nightly-backup.sh)
- quick snapshot backup via [scripts/backup.sh](./scripts/backup.sh)
- golden image script via [scripts/golden_image.sh](./scripts/golden_image.sh)
- repo mirror and config copies on Passport

### What gets backed up

- Jellyfin config
- Navidrome config
- Kavita config
- Calibre-Web config
- AzuraCast MariaDB dump
- Memos DB copy
- system files:
  - `fstab`
  - `cloudflared` config
  - `crontab`
  - Docker service inventory
- `pibulus-os` repo mirror with obvious secrets/junk excluded

### Where it goes

- `/media/pibulus/passport/Backups/pi-system`
- `/media/pibulus/passport/Backups/pi-config-*`
- golden images also live on Passport

## What this protects against

- config corruption
- bad local edits
- repo drift
- DB mistakes
- SD card weirdness if Passport survives

## What this does not protect against

- Passport dying
- the whole Pi setup disappearing physically
- theft / power event / enclosure disaster
- "both the live media and the backup copy were on the same box"

So the current setup is:

- recovery: yes
- redundancy: not really

## Why this is still fine for now

Because it is an honest 80/20 home-server backup:

- small configs matter more than re-copying terabytes
- media is bulky and mostly replaceable
- the repo + DB + service configs are the real soul

That is a sane approach.

## EliteDesk Opportunity

The EliteDesk is the first real chance to turn this into proper redundancy without getting corporate about it.

### Best use of the new box

- second host for critical configs and service state
- migration rehearsal target
- restore target for the cleaned repo
- future destination for heavier apps

### Best first redundancy shape

1. Keep Passport as the primary media store.
2. Keep the Pi as the weird original machine.
3. Use the EliteDesk to receive:
   - repo mirror
   - config backups
   - DB dumps
   - maybe selected app data

That instantly makes the backup story less fake.

## Cloneable-Repo Goal

If the long-term dream is:

- clone repo
- plug in drive
- Bob's your uncle

then the backup story should separate into:

### Portable source of truth

- scripts
- nginx config
- stack files
- systemd units
- docs
- templates

### Local-only state

- secrets
- auth files
- tunnel credentials
- live service DBs
- user/password inventories

That boundary is already improving.

## 80/20 Plan

### Right now

- keep the nightly backup
- keep the quick snapshots
- keep secrets local-only
- keep using Passport as the practical recovery target

### Next

1. Mirror `pi-system` backup output to the EliteDesk.
2. Mirror the private repo there too.
3. Test one real restore on the EliteDesk using the cleaned branch.

### Later

1. Decide which services belong on Pi versus EliteDesk.
2. Keep the repo install path as close as possible to what a future clone-user would do.
3. Only after that, split public/private repo concerns cleanly.

## Recommendation

Do not overbuild backup infrastructure on the Pi.

The smart move is:

- Pi keeps being the goblin forge
- EliteDesk becomes the first proper second place your important state exists

That is the real step from "homebrew survival" to "actually redundant enough."
