# PIBULUS CYBERDECK - FIELD MANUAL
### You are the Captain. This is your ship.

> If you are reading this, you probably forgot how everything works.
> That is fine. This document has your back.

Type `deck` to launch the mainframe. Type `halp` if lost.
Run `deck --audit` to check if everything is healthy.

---

## THE MAP (What Runs Where)

| Port | Name | What It Does | Stack |
|------|------|-------------|-------|
| 80 | Homepage | Public dashboard (guest view) | admin.yml |
| 2283 | Immich | AI photo vault + iCloud sync | immich.yml |
| 4533 | Navidrome | Hi-fi music streaming | pirate.yml |
| 5000 | Kavita | Book & comic library | pirate.yml |
| 5030-31 | Slskd | Soulseek P2P music client | pirate.yml |
| 7681 | Cyber Arcade | Text adventures in browser | pirate.yml |
| 8000 | ErsatzTV | KPAB-TV 24/7 broadcast | pirate.yml |
| 8080 | Filebrowser | Upload/manage files on Passport | pirate.yml |
| 8081 | Homepage Admin | Captain's dashboard | admin.yml |
| 8086 | RomM | Retro game ROM manager | pirate.yml |
| 8090 | Web Host | Nginx static site hosting | pirate.yml |
| 8096 | Jellyfin | Movies, shows, music streaming | pirate.yml |
| 5055 | Overseerr | Media request management | pirate.yml |

**Access:** `http://pibulus.local:PORT` from your LAN.
**Remote:** Via Tailscale at `http://100.115.240.57:PORT`

---

## THE LOCKS (Security)

Run `deck --audit` for automated checks. Manual verification:

**SSH (key-only, no passwords):**
```bash
sudo sshd -T | grep passwordauthentication
# Should say: passwordauthentication no
```

**Firewall (LAN + Tailscale only):**
```bash
sudo ufw status
# Should show: Status: active, rules for 192.168.0.0/24 and tailscale0
```

**Secrets not in git:**
```bash
cd ~/pibulus-os && git ls-files | grep '\.env$'
# Should return nothing
```

**Adding a new SSH key (e.g., new laptop):**
From the new machine: `ssh-copy-id pibulus@pibulus.local`
(Requires physical access or Tailscale connection from an already-trusted device)

**Credentials location:** `~/.credentials/pibulus-secrets.txt`

---

## THE STACKS (Start/Stop/Fix)

All stack configs live in `~/pibulus-os/config/stacks/`.

### Pirate Station (pirate.yml) - The Media Empire
```bash
cd ~/pibulus-os/config/stacks

# Start everything
docker compose -f pirate.yml up -d

# Restart one service
docker compose -f pirate.yml restart jellyfin

# View logs
docker compose -f pirate.yml logs -f navidrome

# Stop everything
docker compose -f pirate.yml down
```

**Common fixes:**
- **Navidrome empty library:** Check `/media/pibulus/passport/music` has files
- **Filebrowser unhealthy:** Remove `user:` line from pirate.yml, restart
- **Jellyfin won't start:** Check Passport is mounted: `df -h | grep passport`

### Immich Vault (immich.yml) - Photo Intelligence
```bash
cd ~/pibulus-os/config/stacks

docker compose -f immich.yml up -d
docker compose -f immich.yml logs -f immich_server
```

**CRITICAL:** Postgres data lives on the SD card at `/var/lib/immich/postgres`,
NOT on the Passport drive. NTFS can't do Unix permissions = postgres won't start.

**Common fixes:**
- **Postgres won't start:** `sudo chown -R 999:999 /var/lib/immich/postgres`
- **iCloudPD needs 2FA:** `docker exec -it icloudpd sh` then authenticate
- **Full rescan:** Log into Immich web UI > Administration > Jobs > Start

### Dashboard (admin.yml)
```bash
cd ~/pibulus-os/config/stacks
docker compose -f admin.yml up -d
```

**Switch theme:** Use `deck` > Dashboard Ops > Switch Theme
**Edit services:** `nano ~/pibulus-os/config/homepage/services.yaml` then restart

---

## THE PIPELINE (How Content Flows)

### YouTube/SoundCloud -> Radio Station
```
deck > Media Puller > paste URL > pick destination
  |
  v
yt-dlp extracts audio as MP3
  |
  v
/media/pibulus/passport/Radio/
  Tunes/        Music tracks
  Rants/        Podcasts, spoken word
  Jingles/      Station IDs, bumpers
  The_Bucket/   Random rotation filler
  |
  v
AzuraCast (KPAB.fm) auto-imports on schedule
```

### iCloud -> Photo Vault
```
iCloudPD container (runs daily)
  |
  v
/media/pibulus/passport/immich/icloud_backup/
  |
  v
Immich auto-scans, runs ML classification
  |
  v
http://pibulus.local:2283 (browse with AI search)
```

### GitHub -> Live Website
```
deck > Deploy New App > paste GitHub URL
  |
  v
git clone to /tmp > detect type (Static/Node/Deno)
  |
  v
Build if needed (npm run build)
  |
  v
Copy to /media/pibulus/passport/www/html/APP_NAME
  |
  v
Nginx serves at http://pibulus.local:8090/APP_NAME
  |
  v
(Optional) Add to Cloudflare tunnel for public domain
  DNS: CNAME your-domain -> TUNNEL_ID.cfargotunnel.com
```

---

## THE PASSPORT (5.5TB Drive)

**Mount point:** `/media/pibulus/passport`
**Format:** NTFS (via fuseblk)
**Limitation:** No chmod/chown. Never put databases here.

### Directory Layout
```
/media/pibulus/passport/
  Backups/            System snapshots (deck > Bunker Lockdown)
    System_Snapshots/
  Books/              Kavita library (874MB)
  Games/              Game collection (604GB)
  immich/             Photo vault
    icloud_backup/    Auto-synced from iCloud
    upload/           Immich uploads
  Movies/             Jellyfin movies (271GB)
  Music/              Navidrome library (288GB)
  Radio/              KPAB.fm source material
    Tunes/
    Rants/
    Jingles/
    The_Bucket/
  roms/               RomM game files
  Shows/              Jellyfin TV (343GB)
  Soulseek/           Slskd downloads
  www/html/           Nginx web apps
```

### What's Sacred (back this up)
- `immich/` - Your photos. Irreplaceable.
- `Backups/` - System configs. Your safety net.
- `Radio/` - Curated content for KPAB.fm.

### What's Replaceable
- `Movies/`, `Shows/`, `Games/` - Re-downloadable media.
- `www/html/` - Rebuilt from git repos via deploy wizard.

---

## THE TUNNELS (Networking)

### Local Network
Everything runs on `pibulus.local` via mDNS.
If mDNS fails, use direct IP: `192.168.0.109`

### Tailscale (Private Remote Access)
```bash
# Check status
tailscale status

# Pi IP on Tailscale
100.115.240.57

# SSH from anywhere
ssh pibulus@100.115.240.57
```
Tailscale gives you access to ALL services from anywhere,
as if you were on your home LAN.

### Cloudflare Tunnel (Public Domains)
**Config:** `/etc/cloudflared/config.yml`
**Currently mapped:**
- `quickcat.club` -> Homepage (port 80)
- `hexbloop.app` -> port 3000

**Add a new public domain:**
1. Edit: `sudo nano /etc/cloudflared/config.yml`
2. Add BEFORE the `http_status:404` line:
```yaml
  - hostname: newapp.quickcat.club
    service: http://localhost:PORT
```
3. Restart: `sudo systemctl restart cloudflared`
4. DNS (Porkbun): Add CNAME record pointing to `TUNNEL_ID.cfargotunnel.com`

Or use: `deck > Deploy New App` which does this automatically.

---

## EMERGENCY

### "I can't SSH in"
Password auth is disabled. You need your SSH key.
**Physical access fix:**
```bash
# At Pi keyboard/monitor
sudo nano /etc/ssh/sshd_config
# Change: PasswordAuthentication yes
sudo nano /etc/ssh/sshd_config.d/50-cloud-init.conf
# Change: PasswordAuthentication yes
sudo systemctl restart ssh
# SSH in, fix your keys, then re-disable passwords
```

### "Passport drive not showing up"
```bash
lsblk                              # Is /dev/sda1 there?
sudo mount /dev/sda1 /media/pibulus/passport   # Manual mount
df -h | grep passport              # Verify
```
If the drive isn't in `lsblk`, check the USB cable and try a different port.

### "Docker service won't start"
```bash
docker logs CONTAINER_NAME          # Check what's wrong
docker compose -f STACK.yml restart SERVICE
docker compose -f STACK.yml down && docker compose -f STACK.yml up -d  # Nuclear
```

### "Disk full (SD card)"
```bash
df -h /                             # How full?
docker system prune -a              # Remove unused images (reclaims GBs)
sudo journalctl --vacuum-size=100M  # Trim system logs
```

### "Temperature over 70C"
```bash
vcgencmd measure_temp               # Check current temp
docker stop immich_machine_learning  # Stop the heaviest service
# Check fan, move Pi to cooler spot, consider a heatsink
```

---

## MAINTENANCE

### Weekly
- Run `deck --audit`
- Glance at `docker ps` for unhealthy containers
- Check `df -h /` - SD card under 85%?

### Monthly
- Run Bunker Lockdown: `deck` > Bunker Lockdown
- Update containers:
```bash
cd ~/pibulus-os/config/stacks
docker compose -f pirate.yml pull && docker compose -f pirate.yml up -d
docker compose -f immich.yml pull && docker compose -f immich.yml up -d
```
- Check `sudo ufw status` still active

### Quarterly
- `sudo apt update && sudo apt upgrade`
- Test backup restore (untar a snapshot, verify configs)
- Review Cloudflare tunnel routes - still need all of them?

---

## QUICK REFERENCE

**Launch deck:** `deck`
**Help:** `halp`
**Security audit:** `deck --audit`
**All containers:** `docker ps`
**Temperature:** `vcgencmd measure_temp`
**Disk usage:** `df -h`
**Passport contents:** `du -sh /media/pibulus/passport/*/`

---

*"A ship is only as good as its logbook."*
