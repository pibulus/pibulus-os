# 📟 PIBULUS FIELD MANUAL

### 🚪 ACCESS TIERS
| User | Method | Password | Target |
|------|--------|----------|--------|
| **pibulus** | SSH | local secret | Full Admin Shell |
| **deck** | SSH | local secret | Cyberdeck TUI |
| **guest** | Web | local secret | Library Access |
| **deck.quickcat.club** | Basic Auth | host-local secret | Admin Dashboard |

### 📟 COMMANDS
- `deck` — Launches the main Cyberdeck menu
- `btop` — System monitor with graphs
- `dust` — Visual disk usage
- `docker ps` — Running containers
- `docker restart web_host` — Fix nginx issues

### 🌐 NETWORK PORTS (internal)
| Port | Service | Notes |
|------|---------|-------|
| 80 | Nginx (web_host) | Main frontend, reverse proxy |
| 4533 | Navidrome | Music streaming |
| 5000 | Kavita | Comics/manga |
| 5230 | Memos | Personal notes |
| 7682 | ttyd | Admin web terminal (authenticated) |
| 7683 | Cyberdeck | Read-only terminal |
| 8000 | AzuraCast (Icecast) | Radio stream |
| 8083 | Calibre-Web | Books |
| 8084 | Kiwix | Offline Wikipedia |
| 8085 | Dropzone | File upload |
| 8086 | Wall server | Pixel wall + shoutbox |
| 8087 | Message drop | Anonymous messages |
| 8088 | URL shortener | /go/ redirects |
| 8090 | Mutiny | Song request system |
| 8096 | Jellyfin | Movies & TV |
| 8500 | AzuraCast (web) | Radio admin & API |

### 💾 DRIVES
| Device | Mount | Type | Size | Notes |
|--------|-------|------|------|-------|
| SD Card | `/` | ext4 | 32GB | OS + Docker volumes |
| Passport | `/media/pibulus/passport` | NTFS | 5.5TB | Media, backups, pibulus-os repo |
| MEMBOT | `/media/pibulus/MEMBOT` | FAT32 | 1TB | Retro ROMs, conspiracy files |

### 🆘 EMERGENCY
- **OOM / SSH hangs**: Power cycle the Pi (pull USB-C)
- **High temp**: Check fan, `vcgencmd measure_temp`
- **Drive disconnect**: Check USB-C power to Passport
- **Nginx down**: `docker restart web_host`
- **All services down**: `sudo systemctl restart kpab-services`
- **SD card corruption**: Reflash from golden image at `/media/pibulus/passport/Backups/Golden_Images/`, restore configs from git repo
- **Tunnel down**: `sudo systemctl restart cloudflared`
