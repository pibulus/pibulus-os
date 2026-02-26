# 🐾 QUICK CAT CLUB - FIELD MANUAL
### You are the Captain. This is your ship.

Type `deck` to launch the mainframe. Type `halp` if lost.

---

## 🗺️ THE MAP (What Runs Where)

| Port | Service | Public URL | Notes |
|------|---------|-----------|-------|
| 80 | Homepage | quickcat.club / deck.quickcat.club | deck requires basic auth |
| 2283 | Immich | — | AI photo vault (local only) |
| 3001 | Gitea | — | Local Git server |
| 4533 | Navidrome | music.quickcat.club | Hi-fi music streaming |
| 5000 | Kavita | read.quickcat.club | Comics & graphic novels |
| 5030 | slskd | — | Soulseek P2P (local only) |
| 5055 | Overseerr | — | Media requests |
| 5230 | Memos | — | Private microblogging |
| 7681 | Cyber Arcade | — | Terminal games |
| 7682 | Web Terminal | — | Browser shell |
| 8000 | AzuraCast (stream) | radio.quickcat.club | Icecast audio stream |
| 8080 | Filebrowser | — | Passport drive browser |
| 8081 | Homepage Admin | — | Admin dashboard |
| 8083 | Calibre-Web | — | Book library (local only) |
| 8096 | Jellyfin | watch.quickcat.club | Movies & shows |
| 8500 | AzuraCast (UI) | kpab.fm | Radio admin |
| 9000 | IRC (The Lounge) | — | Chat client |

---

## 🔐 ACCESS

| Thing | How |
|-------|-----|
| SSH | `ssh pibulus@pibulus.local` (pw: meringue) |
| deck.quickcat.club | user: `pibulus` / pw: `Church0fTheSubgeniu5!` |
| Web terminal | user: `user` / pw: `Church0fTheSubgeniu5!` |
| Navidrome guest | guest / quickcat |
| Calibre-Web | admin / admin123 (change this!) |

---

## ⌨️ TERMINAL POWERS

```bash
deck          # Launch the mainframe TUI
halp          # You're lost
free -h       # Check RAM (swap at 1.8/2GB = danger zone)
docker ps     # What's running
df -h /media/pibulus/passport   # Passport space
```

**Key tools:** `fzf` (fuzzy find), `glow` (markdown viewer), `bat` (syntax highlight), `dust` (disk usage), `btop` (system monitor)

---

## 🚨 EMERGENCY PROTOCOLS

**Pi won't SSH in:**
1. Power cycle (pull USB-C, wait 5s, replug)
2. SSH in: `ssh pibulus@pibulus.local` (pw: meringue)
3. Check RAM: `free -h` — if swap full, stop heavy containers:
   `docker stop immich_machine_learning romm ersatztv`
4. Restart services:
   `cd ~/pibulus-os/config/stacks && docker compose -f pirate.yml up -d`

**Cloudflare tunnel down:**
```bash
sudo systemctl restart cloudflared
curl -I https://quickcat.club
```

**AzuraCast not streaming:**
```bash
cd ~/azuracast && docker compose up -d
```

**Golden Image (backup):**
Run via `deck` → Vault Ops → Golden Image
Recovery: Fresh OS → clone pibulus-os repo → extract golden image from Passport

---

## 📦 STACK OVERVIEW

5 compose stacks in `~/pibulus-os/config/stacks/`:
- **pirate.yml** — Jellyfin, Navidrome, Kavita, Calibre-Web, slskd, Overseerr, Filebrowser, ErsatzTV, Gluetun
- **social.yml** — Gitea, Memos, IRC
- **admin.yml** — Homepage + Web Terminal
- **immich.yml** — Photos + ML
- **~/azuracast/** — Radio (its own compose)

---

## ⚠️ RAM BUDGET (4GB total)

| Container | RAM |
|-----------|-----|
| System + kernel | ~800MB |
| OpenClaw gateway | ~420MB |
| Jellyfin | ~300-500MB |
| AzuraCast | ~300-400MB |
| Navidrome | ~100MB |
| Kavita | ~100MB |
| Everything else | ~200-400MB |
| Swap | 2GB safety net |

**DO NOT** run `immich_machine_learning` + full stack simultaneously = OOM death spiral.

---

*Stay modular. Stay redundant. Stay hidden.*
