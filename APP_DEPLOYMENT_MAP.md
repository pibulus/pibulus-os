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
