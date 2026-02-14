# ð¾ PIBULUS CYBERDECK v3.0
### Mexi-Australian Cyberdeck Architecture

Welcome to the Pibulus Cyberdeck. This is a modular, Docker-based self-hosting environment running on a Raspberry Pi.

## ð§ QUICKSTART
Run the control deck from anywhere:
```bash
deck
```

## ð Architecture Overview
- **Core Engine:** Docker & Docker Compose
- **Launcher:** `~/pibulus-os/launcher.sh` (aliased to `deck`)
- **Stacks:**
  - **Pirate Station:** Jellyfin, Navidrome, Kavita, Slskd, Filebrowser, Web Host.
  - **Immich Vault:** AI-powered Photo Gallery + iCloud Sync.
- **Storage:** Primary media is stored on the 5.5TB Passport drive at `/media/pibulus/passport/`.

## ð¹ Core Commands
- `deck`: Opens the interactive management menu.
- `docker ps`: Shows all running services and their status.
- `docker logs -f <service_name>`: Follow logs (useful for debugging).
- `lsblk`: List all connected drives and partitions.

## ðª Common Tasks
### Adding New Photos from iCloud
1. Run `docker exec -it icloudpd sync-icloud.sh --Initialise`.
2. Follow the 2FA prompts on your Apple device.
3. Photos will automatically sync to your Immich vault.

### Adding Music/Movies
Drop your files into the corresponding folders on the Passport drive (`/media/pibulus/passport/Music` or `Movies`). Navidrome and Jellyfin will scan them automatically.

## 🛠️ Maintenance
The system is designed to be "infrastructure-as-code". All configurations live in `~/pibulus-os/config/stacks/`. If you want to change a service, edit its `.yml` file and run `deck` -> `(U)p/Start` to apply changes.
