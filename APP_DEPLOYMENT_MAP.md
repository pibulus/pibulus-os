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

## App Map — verified 2026-06-21 (all 19 services `active`)

Ports/domains/runtime pulled live from unit files + cloudflared ingress. Live path is `/home/pibulus/apps/<dir>` (dir = service name unless noted).

| App | Domain | Port | Service | Runtime | Source / Branch |
| --- | --- | ---: | --- | --- | --- |
| Plenum Engine | `madebypablo.app` | 9001 | `plenum-engine` | Deno/Fresh build | (no remote/meta on Pi) |
| TalkType | `talktype.app` | 9002 | `talktype` | Node build-output | pibulus/talktype · main |
| ZipList | `ziplist.app` | 9003 | `ziplist` | Node build-output | pibulus/ziplist · main |
| RiffRap | `riffrap.app` | 9004 | `riffrap` | Node build-output | pibulus/riffrap · **master** |
| Project/ProMapper | `promapper.app` | 9005 | `project-mapper` | Node build-output | pibulus/**project_mapper** · main (dir=`project_mapper`; NOT the `promapper` repo) |
| Button Studio | `buttonspa.app` | 9006 | `button-studio` | Deno/Fresh checkout | pibulus/button-studio · main |
| Hexbloop Site | `hexbloop.app` | 9010 | `hexbloop-site` | Deno/Fresh checkout | pibulus/hexbloop-site · main |
| Spellbreak Site | `spellbreak.app` | 9011 | `spellbreak-site` | Deno/Fresh checkout | pibulus/spellbreak-site · main |
| Stargram | `stargram.app` | 9012 | `stargram` | Deno/Fresh checkout | pibulus/stargram · main |
| Ghost Note | `ghostnote.rip` | 9013 | `ghostnote` | Deno/Fresh checkout | pibulus/**ouija** · main |
| Dr Shrink | `drshrink.app` | 9017 | `drshrink` | Node build-output | pibulus/**dr_shrink** · main |
| Icon Make It | `iconmakeit.app` | 9018 | `iconmakeit` | Node build-output | pibulus/iconmakeit · main |
| DaySay | `daysay.app` | 9019 | `daysay` | Node build-output | pibulus/daysay · main (NOT in deploy_app.sh case block) |
| Cryptkeep | `cryptkeep.app` | 9020 | `cryptkeep` | Node build-output | pibulus/cryptkeep · main |
| Metasplash | `metasplash.app` | 9021 | `metasplash` | Node build-output | pibulus/metasplash · main |
| Metaflush | `metaflush.app` | 9022 | `metaflush` | Node build-output | pibulus/metaflush · main |
| Corruptor | `corruptor.app` | 9023 | `corruptor` | Node build-output | pibulus/corruptor · main |
| QRBuddy | `qrbuddy.app` | **8004** | `qrbuddy` | Deno/Fresh checkout | pibulus/qrbuddy · main |
| Is It Going To Rain | `isitgoingtorain.app` | static | `isitgoingtorain` | static checkout | pibulus/isitgoingtorain · main |

**Port gotchas:** QRBuddy is on **8004**, not a 90xx port. Plenum/IsItGoingToRain have no `PORT=` env (static/self-assigned). Node build-output apps run `node index.js` from the live-dir root (adapter-node `build/` rsync'd to root). Deno checkouts run via `~/.deno/bin/deno`.

**Restart policy (set 2026-06-21):** all app units are now `Restart=always` + `RestartSec=5` (were `on-failure`, which ignored clean exits → apps silently stayed dead after the boot load-storm; see [[pi_app_restart_policy]]).

**RiffRap adapter fix (2026-06-21):** riffrap's repo shipped `adapter-cloudflare` (no `build/` dir → deploy_app.sh failed). Committed adapter-node to master (e27fc0e); now deploys normally. **All Pi node apps must use default adapter-node.**

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

## 📋 Full Live App Roster

**→ See the [App Map](#app-map--verified-2026-06-21-all-19-services-active) table at the top of this doc — that is the canonical, verified roster (19 apps, 2026-06-21).** The old 11-app table that lived here was superseded; do not maintain two lists.

History: this map originally documented 4 apps; a 2026-06-16 pass found 11; the 2026-06-21 audit found 19 (added drshrink, iconmakeit, cryptkeep, metasplash, metaflush, corruptor, daysay, project-mapper to the tracked set) and verified every port/domain live.

Notes:
- **RiffRap uses `master`, not `main`** — `git ls-remote ... refs/heads/main` returns
  empty for it. (`git clone --depth 1` grabs the default branch = master, so deploy_app.sh needs no override.)
- **project-mapper** serves `promapper.app` but builds from the `pibulus/project_mapper` repo — NOT the divergent abandoned `pibulus/promapper` repo. Live dir is `apps/project_mapper`.
- **deploy_app.sh case block** covers: talktype, ziplist, iconmakeit, drshrink, stargram, ghostnote, cryptkeep, metasplash, metaflush, corruptor, riffrap. **NOT yet added:** project_mapper, daysay (still manual).
- To check if an app is behind: read `.pibulus-meta` (DEPLOYED_COMMIT) or `git rev-parse
  HEAD` for checkouts, vs `git ls-remote <repo> refs/heads/<branch>`.
- Several live checkouts have been `git pull`'d in place since their last
  `deploy_app.sh` run, so their `.pibulus-meta` can be stale — trust git HEAD for those.
