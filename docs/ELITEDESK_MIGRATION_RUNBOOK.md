# 🖥️ PIBULUS OS → EliteDesk 800 G4 Mini Migration Runbook

**Goal:** Move the whole PIBULUS OS server stack from the dying-SD Raspberry Pi 5 to the
HP EliteDesk 800 G4 Mini (i5-8500T, NVMe, → 32GB RAM). Debian 13 (trixie — matches the
Pi's current OS for near-zero config porting). Hybrid approach:
restore everything working, document into pibulus-os repo as we go.

**Why:** SD card rot (find/man-db/apt segfaulting), arm64 .NET bugs, weak transcode.
EliteDesk = NVMe (no rot), x86 (no arm bugs), Intel QuickSync (real HW transcode).

---

## Phase 0 — PREP (do while Pi still runs, no downtime)
- [ ] **Commit pibulus-os repo** — it has uncommitted changes (pirate.yml + ~15 files). Push to GitHub. This is the source of truth.
- [ ] Install 32GB RAM into the EliteDesk (pop the matched Samsung pair in; remove old 8GB).
- [ ] Download Debian 13 (trixie) netinst ISO, flash to a USB stick (Pablo, from Mac w/ balenaEtcher or `dd`).
- [ ] Note the EliteDesk has 256GB NVMe (plenty: OS 34G + appdata 0.4G + azuracast 2.6G).

## Phase 1 — SNAPSHOT the Pi (data to carry over)  [~1.3GB total, tiny]
Back these up to passport (`/media/pibulus/passport/Backups/elitedesk-migration/`):
- [ ] `~/.config/*` — app data, **Jellyfin DB is the crown jewel** (~360MB)
- [ ] `/etc/cloudflared/` — tunnel creds: `cert.pem`, `c79eb8a2-…json`, `config.yml` (CRITICAL)
- [ ] `crontab -l` → save to file (11 jobs)
- [ ] `/home/pibulus/apps/` — the Node/Deno apps (880MB, mostly Deno = portable)
- [ ] All `/etc/systemd/system/*.service` custom units (~30 app services) + `/etc/<app>.env` files
- [ ] AzuraCast: `azuracast backup` → produces a tarball (DON'T just copy the docker volume)
- [ ] `/etc/fstab` (for the drive mount UUIDs — passport/MEMBOT)
- [ ] List of installed apt packages: `dpkg --get-selections > pkgs.txt`

## Phase 2 — INSTALL Debian 13 (trixie) on EliteDesk
- [ ] Boot Debian USB, wipe Win11, install to NVMe. Hostname `pibulus` or similar.
- [ ] Same username `pibulus`, enable SSH, set up the network (static IP or .local mDNS).
- [ ] `apt install docker.io docker-compose-plugin cloudflared nodejs` + Deno + basics.
- [ ] Install Intel media drivers for QuickSync: `intel-media-va-driver-non-free` + `vainfo`.

## Phase 3 — RESTORE (the hybrid: restore + document each piece into repo)
- [ ] Plug passport + MEMBOT USB drives into EliteDesk. Mount (NTFS needs `ntfs-3g`; FAT32 native).
      → Update fstab. NOTE: consider reformatting MEMBOT off FAT32 eventually (it's flash, ext4 better).
- [ ] `git clone pibulus-os` repo onto the EliteDesk.
- [ ] Restore `~/.config/*` (Jellyfin DB etc).
- [ ] Restore `/etc/cloudflared/` creds → `systemctl enable --now cloudflared`. Tunnel reconnects, domains live.
- [ ] `docker compose -f pirate.yml up -d` — pulls x86 images fresh (Jellyfin x86 has QuickSync!).
      → In Jellyfin: enable HW transcoding (VAAPI/QSV) in dashboard — the big win.
- [ ] Restore AzuraCast from its backup tarball (not raw volume copy).
- [ ] Copy `/home/pibulus/apps/`, restore systemd units + .env files, `systemctl enable --now` each.
      → Deno apps: zero rebuild. Node apps w/ node_modules: `npm ci` to refetch x86 deps.
- [ ] Restore crontab.
- [ ] **Document as you go:** each manual step → script/note in pibulus-os repo so next rebuild is one command.

## Phase 3.5 — SECURITY HARDENING (from the 2026-06-23 DeepSeek audit, verified)
Carry forward the hardening already done on the Pi + the items deferred to here:
- [ ] **fail2ban** — install + same jail.local (5 retries/10min → 1h ban, escalating, backend=systemd).
      Already proven on Pi. Keeps password SSH working (Pablo wants to log in from any Mac) but nukes bots.
- [ ] **SSH** — keep PasswordAuthentication YES (intentional: login-from-anywhere use case).
      fail2ban is the mitigation, NOT key-only. ssh.quickcat.club tunnel hostname carries over.
      → OPTIONAL: stronger root password than 'meringue' for the internet-facing login (Pablo's call).
- [ ] **cloudflared cred** — chmod 600 the tunnel-creds .json (was 644 on Pi).
- [ ] **FIREWALL — do it RIGHT here (the reason we skipped ufw on the Pi):**
      ufw alone does NOT block Docker (Docker writes iptables ahead of ufw). Correct approach:
      default-deny INPUT + allow established/SSH/LAN, AND add rules in the DOCKER-USER chain to
      restrict container ports. OR bind sensitive services (ttyd :7682-4, qbittorrent, filebrowser)
      to 127.0.0.1 in compose so only the tunnel reaches them, not the LAN. Prefer localhost-binding —
      simpler + survives Docker restarts. Test SSH still works before closing the session.
- [ ] Verify secrets stay 600 + gitignored (they already are: pibulus-os.env, config/stacks/.env,
      azuracast/.env — all chmod 600 and in .gitignore. Audit FALSE-flagged these as "in git" — they're not).

## Phase 3.6 — PER-APP AUDIT FIXES (2026-06-23 DeepSeek per-app audit, VERIFIED)
Verification notes — what was REAL vs hallucinated:
- ❌ "Filebrowser exposes 5.5TB unauth" = FALSE. /api/resources/ returns 401, settings.json uses DB auth.
  Real residual risk = password strength only. (DeepSeek claimed /api/public 200 — that endpoint 401s.)
- ✅ "qBittorrent bareback, no VPN" = TRUE & VERIFIED (qbit exit IP == home IP 144.6.84.23, gluetun dead).
      → On Pi: STOPPED qbittorrent + restart=no (2026-06-23). MUST set up gluetun (PureVPN) properly on
        EliteDesk and route qbit through it (network_mode: service:gluetun) BEFORE re-enabling. Verify exit IP != home IP.
- ✅ ".env perms" — found qrbuddy/.env was 664 (world-readable); chmod 600'd it + all app .envs (done on Pi).
- ❌ "secrets in git" = FALSE (3rd confirmation). No .env tracked in pibulus-os; app .envs gitignored.
- 🔍 QRBuddy SERVICE_ROLE_KEY: investigated — runtime app uses ONLY anon key. service_role is referenced
      only in tests/ + supabase/functions/ (edge functions run on SUPABASE'S cloud, read the key from
      Supabase env, NOT the Pi). → SAFE TO REMOVE service_role from the Pi's local .env (keep in Supabase
      dashboard). Do during migration. Not externally exploitable as-is (600 + gitignored).
- button-studio GEMINI_API_KEY is old AIza format (600, gitignored) → migrate to fleet AQ. format +
      restrict in Google console. Per CLAUDE.md fleet rule: belongs in ~/.config/fleet/keys.env.
Other verified-real items to handle at migration (NOT urgent, behind tunnel+nginx):
- AzuraCast PROFILING_EXTENSION_HTTP_KEY=dev → change. MariaDB creds → env_file (already in gitignored .env).
- Jellyfin API key → regenerate post-migration (host networking makes it high-value).
- Memos public + no POST rate-limit → add nginx rate limit on POST /memos/.
- Kavita appsettings.json TokenKey → chmod 600 the config dir.
- nginx/Python body-size mismatch (dropzone 2GB vs nginx 500MB) → align.
- Calibre-web: prune test user accounts (testuser, testuser2).
- Dead stacks (immich/scummvm/admin/irc/slskd/gluetun-undeployed) → move to dormant/ dir, DON'T migrate.
- DeepSeek praised (carry forward): nginx hardening.conf, ttyd cgroup limits, archive-browser/SDR/dropzone
  input validation, claude-chat load guards, per-container resource limits. Genuinely good work.

## Phase 3.7 — THIRD-PASS FINDINGS (DeepSeek migration-focused audit, VERIFIED 2026-06-23)
This was the strongest pass — the migration failure modes are gold. Pre-captured to
/media/pibulus/passport/Backups/pi-system/migration-capture/ (the silently-lost stuff).

VERIFIED & CAPTURED (would have been silently lost):
- ✅ /etc/daysay.env /etc/talktype.env /etc/ziplist.env — live Gemini/Deepgram keys, referenced by
     systemd EnvironmentFile=, NOT in ~/.config or ~/apps → would vanish. CAPTURED. On new box: scp to /etc/.
- ✅ /etc/cloudflared/<tunnel-id>.json credential — nightly backup copies config.yml but NOT the .json.
     Tunnel won't auth without it. CAPTURED. On new box: place in /etc/cloudflared/.
- ✅ data/ runtime state (hearts.json, shortener.json, claude-chat/) — gitignored AND not in backup.
     ~5KB. (DeepSeek wrong that curator_list is lost — it IS backed up, line 105.) CAPTURED.
- ✅ ALL systemd units tarred (not just remembered ones). pibulus-startup is the only EXTRA active one;
     watchdog/deck-doctor/cloudflared-update/ttyd-public/samba are INACTIVE (DeepSeek overstated activity).

VERIFIED git-history leak (REAL but small): pibulus-os.env WAS committed to PUBLIC github in commits
ce53763 + d83b882. BUT only ONE secret was in it: PUREVPN_PASSWORD (value starts SLACK4...). The
azuracast.env / stacks/.env were NEVER committed (DeepSeek wrong on "all three"). No API keys in
history (current keys have different names → not the leaked ones). ACTION: rotate the PureVPN password
(low-moderate risk, commodity VPN account). Do NOT bother rewriting git history for one VPN pw unless
you want to — it's already exposed; rotation is the fix, not scrubbing.

MIGRATION FAILURE MODES to bake into the build (all verified plausible):
- 🔴 FM1 AzuraCast named volumes come up EMPTY on `compose up` (all 10 vols live in /var/lib/docker,
     NOT bind-mounted). Restore from: azuracast CLI backup zip (DB+uploads) + weekly station_data.tar.gz
     (the MEDIA — jingles/tracks, excluded from CLI backup). VERIFY new vol size >1MB after restore.
- 🔴 FM2 nginx hardcodes 172.17.0.1 in 55 proxy_pass lines; docker0 IS currently 172.17.0.1/16. If new
     box picks 172.18.x → all ~50 routes 502. FIX: add {"bip":"172.17.0.1/16"} to /etc/docker/daemon.json
     BEFORE first `docker compose up`.
- 🔴 FM3 pirate.yml passes /dev/video19 (Pi HEVC decoder) — doesn't exist on x86, Docker REFUSES to start
     Jellyfin. FIX: remove the /dev/video19 line; keep /dev/dri (QuickSync via renderD128 is better anyway).
- 🔴 FM4 tunnel race: STOP cloudflared on Pi FIRST (systemctl stop+disable cloudflared cloudflared-update)
     before starting on new box, or both flap. ~30-60s DNS window is fine.
- 🟡 FM5 the /etc/*.env (captured above). FM6 deno/ttyd are ARM ELFs → reinstall x86 versions, don't copy.
- 🟢 FM8/9 filebrowser DB is UID 911, romm-db is UID 999 → after restore chown 911/999, or let romm-db
     create fresh files then import the dump (don't copy raw mariadb files).

ALSO: Tailscale (tailscaled active but "Logged out") = dead weight. DON'T install on new box unless used.

## Phase 4 — CUTOVER & VERIFY
- [ ] Test every domain (watch/music/read/photos/deck/etc) through the tunnel from EliteDesk.
- [ ] Verify Jellyfin HW transcode works (play a file, check dashboard shows QSV).
- [ ] Once happy: power down Pi. EliteDesk is the server.
- [ ] Pi → retire or repurpose (could be a backup node / dev box / the new "snorlax" target).

## Gotchas / notes
- Pi OS = Debian Bookworm, so configs/units/scripts port near-1:1. Smoothest possible.
- Docker images are multi-arch → x86 just pulls the amd64 variant, no changes to compose.
- The arm64 .NET Jellyfin bug that started all this CANNOT happen on x86. Gone for good.
- cloudflared tunnel is tied to creds, NOT the machine — move creds, domains follow. No DNS changes.
- Keep the dying Pi SD intact until cutover verified (rollback safety).
- Power: EliteDesk i5-8500T idles ~10-15W, fine for 24/7. More than Pi (~5W) but negligible.
