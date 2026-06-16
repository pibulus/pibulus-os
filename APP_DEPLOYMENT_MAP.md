# App Deployment Map

Read this first for `talktype.app`, `ziplist.app`, `stargram.app`,
`ghostnote.rip`, and other custom web apps on the Pi.

## Rules

1. Live apps are systemd services, not Docker containers.
2. Live app directories are under `/home/pibulus/apps`.
3. Public routing is in `/home/pibulus/pibulus-os/config/system/cloudflared-config.yml`.
4. Service definitions are in `/home/pibulus/pibulus-os/config/systemd/*.service` and installed at `/etc/systemd/system/*.service`.
5. For SvelteKit Node apps, the live directory is usually adapter-node build output, not a git checkout. Do not assume `git pull` works in the live directory.
6. Do not use `/home/pibulus/pibulus-os/deploy.sh` for these live systemd apps unless it has been updated. That script is historical and mentions an older PM2/static deploy model.
7. Never build multiple Node apps in parallel on the Pi. It can exhaust RAM/swap and make SSH appear dead.
8. Prefer `/home/pibulus/pibulus-os/scripts/deploy_app.sh <app>` for local Pi deploys. It has a lock, capacity checks, Passport-backed staging, backup, smoke test, rollback, and metadata.

## App Map

| App | Domain | Port | Service | Live path | Runtime | Source |
| --- | --- | ---: | --- | --- | --- | --- |
| TalkType | `talktype.app` | 9002 | `talktype.service` | `/home/pibulus/apps/talktype` | Node/SvelteKit adapter-node build output | `https://github.com/pibulus/talktype` |
| ZipList | `ziplist.app` | 9003 | `ziplist.service` | `/home/pibulus/apps/ziplist` | Node/SvelteKit adapter-node build output | `https://github.com/pibulus/ziplist` |
| Stargram | `stargram.app` | 9012 | `stargram.service` | `/home/pibulus/apps/stargram` | Deno/Fresh source checkout | `https://github.com/pibulus/stargram` |
| Ghost Note | `ghostnote.rip` | 9013 | `ghostnote.service` | `/home/pibulus/apps/ghostnote` | Deno/Fresh source checkout | `https://github.com/pibulus/ouija` |

## Fast Orientation

```bash
cd /home/pibulus/pibulus-os
sed -n '1,160p' CLAUDE.md
sed -n '1210,1365p' launcher.sh
systemctl status talktype ziplist stargram --no-pager
```

## Check Whether Remote Main Changed

TalkType and ZipList live dirs are not git checkouts, so compare remote refs:

```bash
git ls-remote https://github.com/pibulus/talktype.git refs/heads/main
git ls-remote https://github.com/pibulus/ziplist.git refs/heads/main
```

Stargram is a git checkout:

```bash
cd /home/pibulus/apps/stargram
git fetch origin main
git status --short
git log --oneline HEAD..origin/main
```

## Deploy Shape

Use the helper first:

```bash
/home/pibulus/pibulus-os/scripts/deploy_app.sh talktype
/home/pibulus/pibulus-os/scripts/deploy_app.sh ziplist
/home/pibulus/pibulus-os/scripts/deploy_app.sh stargram
/home/pibulus/pibulus-os/scripts/deploy_app.sh ghostnote
```

It writes `.pibulus-meta` in the live app directory with `GITHUB_URL`,
`DEPLOYED_COMMIT`, and `DEPLOYED_AT`.

### TalkType / ZipList

These should be deployed from a fresh source clone, built, then the adapter-node
build output should replace the live directory.

General shape:

```bash
tmp=/tmp/talktype-deploy
rm -rf "$tmp"
git clone https://github.com/pibulus/talktype.git "$tmp"
cd "$tmp"
npm ci
npm run build
sudo systemctl stop talktype
rsync -a --delete build/ /home/pibulus/apps/talktype/
cd /home/pibulus/apps/talktype
npm ci --omit=dev
sudo systemctl start talktype
curl -I http://127.0.0.1:9002/
```

Use the same shape for ZipList, with:

- repo: `https://github.com/pibulus/ziplist.git`
- service: `ziplist`
- live path: `/home/pibulus/apps/ziplist`
- health URL: `http://127.0.0.1:9003/`

### Stargram

Stargram is already a source checkout.

```bash
cd /home/pibulus/apps/stargram
git fetch origin main
git status --short
git pull --ff-only origin main
/home/pibulus/.deno/bin/deno task build 2>/dev/null || true
sudo systemctl restart stargram
curl -I http://127.0.0.1:9012/
```

### Ghost Note

Ghost Note uses the same Deno/Fresh checkout shape as Stargram.

```bash
/home/pibulus/pibulus-os/scripts/deploy_app.sh ghostnote
curl -I http://127.0.0.1:9013/
```

## Verify Public Routes

```bash
curl -I https://talktype.app
curl -I https://ziplist.app
curl -I https://stargram.app
curl -I https://ghostnote.rip
```

## Useful Logs

```bash
journalctl -u talktype -n 80 --no-pager
journalctl -u ziplist -n 80 --no-pager
journalctl -u stargram -n 80 --no-pager
journalctl -u ghostnote -n 80 --no-pager
```

---

## ⚡ Fast Deploy Notes (updated 2026-06-16)

### TL;DR — how to deploy without the grind

```bash
# ALWAYS run detached so a dropped SSH connection can't choke the build:
LOG=/home/pibulus/deploy-talktype-$(date +%s).log
nohup /home/pibulus/pibulus-os/scripts/deploy_app.sh talktype > "$LOG" 2>&1 &
# then poll:  tail -f "$LOG"
```

`deploy_app.sh` was sped up from **~12 min → ~3.5 min** for SvelteKit apps.

### What was slow and what changed

The build itself was always fast (~15s-1m40s). The grind came from staging on the
**Passport USB HDD** (`/dev/sdc1`), which forced:
- the build to run on slow spinning USB storage, and
- the final `mv stage → live` to be a **cross-filesystem copy** of node_modules
  (Passport → SD card), ~4 min of file-by-file USB I/O.

**Fix (in `deploy_app.sh`):**
- `STAGING_ROOT` now defaults to `/home/pibulus/apps-staging` — **same filesystem as
  the live dir** (`/dev/mmcblk0p2`). The swap is now an instant atomic rename.
- Persistent npm cache at `/home/pibulus/.cache/pibulus-npm` (`NPM_CACHE_DIR`), so
  `npm ci` reuses downloaded packages across deploys.
- **Backups still go to the Passport** (`apps-backups`) — correct, keeps the backup
  history off the boot SD card.
- Overrides if ever needed: `PIBULUS_APP_STAGING_ROOT`, `PIBULUS_NPM_CACHE`.
- Original script saved as `deploy_app.sh.bak-20260616-143510`.

Measured (talktype --force, 2026-06-16): vite build 15s, npm ci --omit=dev 11s,
swap instant, total 219s (the remaining time is the safety backup to Passport).

### Why detach matters (the SSH-choke gotcha)

`deploy_app.sh` builds **synchronously**. If an interactive SSH session holds the
deploy and the connection is interrupted, the build keeps grinding but on a 4GB Pi it
can spike RAM/load until SSH "appears dead" (banner-exchange timeouts). It self-recovers
(watchdog every 5min; the deploy is atomic so the live app is never left half-swapped),
but it wastes time. **Always `nohup ... &` and poll the log.**

### A `curl: (7) ... port 90xx` line in the log is usually harmless

The post-restart health check fires its first retry the instant before the service binds
the port. The loop retries for ~20s. If the deploy ends with `EXIT=0` /
`commit=<sha>`, it succeeded.

---

## 📋 Full Live App Roster (2026-06-16)

The original map above documents only 4 apps. The Pi actually runs **11 live app
services**. Full list (all systemd services under `/home/pibulus/apps`):

| App | Service | Port | Runtime | Branch | Repo |
| --- | --- | ---: | --- | --- | --- |
| TalkType | talktype | 9002 | Node/SvelteKit build | main | pibulus/talktype |
| ZipList | ziplist | 9003 | Node/SvelteKit build | main | pibulus/ziplist |
| RiffRap | riffrap | — | Node/SvelteKit build | **master** | pibulus/riffrap |
| QRBuddy | qrbuddy | — | Deno/Fresh checkout | main | pibulus/qrbuddy |
| Stargram | stargram | 9012 | Deno/Fresh checkout | main | pibulus/stargram |
| Ghost Note | ghostnote | 9013 | Deno/Fresh checkout | main | pibulus/ouija |
| Button Studio | button-studio | — | Deno/Fresh checkout | main | pibulus/button-studio |
| Hexbloop Site | hexbloop-site | — | Deno/Fresh checkout | main | pibulus/hexbloop-site |
| Is It Going To Rain | isitgoingtorain | — | static checkout | main | pibulus/isitgoingtorain |
| Spellbreak Site | spellbreak-site | — | Deno/Fresh checkout | main | pibulus/spellbreak-site |
| Plenum Engine | plenum-engine | — | Deno/Fresh build | — | (no remote/meta on Pi) |

Notes:
- **RiffRap uses `master`, not `main`** — `git ls-remote ... refs/heads/main` returns
  empty for it. Use `refs/heads/master`.
- `project-mapper.service` runs but its dir shows inactive deploy state — minor drift.
- To check if an app is behind: read `.pibulus-meta` (DEPLOYED_COMMIT) or `git rev-parse
  HEAD` for checkouts, vs `git ls-remote <repo> refs/heads/<branch>`.
- Several live checkouts have been `git pull`'d in place since their last
  `deploy_app.sh` run, so their `.pibulus-meta` can be stale — trust git HEAD for those.
