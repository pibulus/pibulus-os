# PIBULUS Recovery Checkpoints

This is the calm rollback pattern for the Pi. It is intentionally small: config,
manifests, and exact recovery context. It does not back up media, app data, or
Docker volumes.

## Current Stable Checkpoint

Created after the 2026-06-11 root filesystem corruption repair:

- Pi copy: `/media/pibulus/passport/Backups/pi-system/checkpoints/pibulus-stable-20260611-161034.tar.gz`
- Mac copy: `/Users/pabloalvarado/Documents/PIBULUS-checkpoints/pibulus-stable-20260611-161034.tar.gz`
- Git checkpoint: `fbc04f0 Harden Pi recovery guardrails`

Verify the Pi archive:

```sh
cd /media/pibulus/passport/Backups/pi-system/checkpoints
sha256sum -c pibulus-stable-20260611-161034.tar.gz.sha256
```

## What It Contains

- selected `pibulus-os` files and the hardening patch
- `/etc/systemd/system`
- `/etc/cloudflared`
- `/etc/fstab`
- `/etc/sysctl.d`
- nginx config from `config/nginx`
- Cloudflare tunnel route source config
- live AzuraCast override and patches
- Docker image/container manifests
- package list
- Deck/KPAB health snapshots

It intentionally excludes:

- media library
- app runtime data
- Docker volumes
- Passport-wide scans or copies

## Restore Shape

Use this as a surgical reference, not a blind restore script:

```sh
mkdir -p /tmp/pibulus-restore
cd /tmp/pibulus-restore
tar -xzf /media/pibulus/passport/Backups/pi-system/checkpoints/pibulus-stable-20260611-161034.tar.gz
```

Then inspect and copy back only the needed path. Examples:

```sh
sudo cp -a pibulus-stable-*/system/etc-systemd-system/claude-chat.service /etc/systemd/system/claude-chat.service
sudo systemctl daemon-reload
sudo systemctl restart claude-chat.service
```

For repo code/config, prefer Git first:

```sh
cd /home/pibulus/pibulus-os
git show fbc04f0
git checkout fbc04f0 -- scripts/claude_chat_gateway.py config/systemd/claude-chat.service
```

## Known Lessons

- Heavy Deck AI runs can be the trigger, but the damaging aftermath was root
  filesystem corruption: broken `mawk`, broken Liquidsoap image layer, and
  corrupted systemd/udev/dpkg files.
- Journald is core system logging, not the Memos app. Keep it alive.
- Swap/zram should be active. The Pi currently has zram around 2GB.
- Full Deck AI mode is disabled on the Pi until crash behavior is proven stable.
- DeepSeek/OpenCode is restricted to Plan mode on the Pi for now.
- Keep radio-first discipline: avoid builds, broad searches, or heavy AI runs
  while KPAB recovery or AzuraCast work is happening.

## Create The Next Manual Checkpoint

Only do this after a known-good repair/deploy. Keep it manual and boring.
Do not add hourly/daily media backups.

The checkpoint should include config and manifests only, then copy the final
small tarball to the Mac.
