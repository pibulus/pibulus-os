# 📟 PIBULUS FIELD MANUAL

### 🚪 ACCESS TIERS
| User | Method | Password | Target |
|------|--------|----------|--------|
| **pibulus** | SSH | [PRIVATE] | Full Admin Shell |
| **deck** | SSH | meringue | Cyberdeck TUI |
| **guest** | Web | quickcat | Library Access |

### 📟 COMMANDS
- `deck` — Launches the main Cyberdeck menu.
- `status` — Shows system health (temp, RAM, disk).
- `selfcare` — Runs maintenance scripts manually.

### 🌐 NETWORK PORTS
- **80**: Nginx (Main Frontend)
- **7682**: Admin Web Terminal (Authenticated)
- **7683**: Public Cyberdeck (Read-Only)
- **8086**: Wall & Shoutbox Backend

### 🆘 EMERGENCY
- **High Temp**: Turn off the Pi and check the fan.
- **Drive Disconnect**: Check USB-C power to the Passport drive.
- **Nginx Down**: `docker restart web_host`
