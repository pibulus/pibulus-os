# 🛡️ CYBERDECK SECURITY AUDIT
### Quick Cat Club - Defensive Posture v1.0

## 1. NETWORK DEFENSE
- **MAC Randomization:** NetworkManager is configured to randomize hardware IDs for every new connection. Prevents physical tracking.
- **Private DNS:** All queries routed through Quad9 (Encrypted/Swiss-based). Bypasses ISP logging.
- **VPN Shield:** Critical P2P traffic (Soulseek) is gated through a Gluetun VPN tunnel.
- **Hotspot Security:** WPA2-PSK enabled on 'pibulus-deck' node.

## 2. SYSTEM HARDENING
- **Fail2Ban:** Monitoring SSH logs. 3 failed attempts = 24hr IP ban.
- **Nginx Gatekeeper:** Rate limiting (1 request/sec) and connection limits (10 per IP) to prevent DDoS/Brute-force.
- **Stealth Mode:** System-wide toggle to switch between Key-only (Bunker) and Password (Travel) access.

## 3. DATA PRIVACY
- **Digital Hygiene:** Periodic purges of APT cache, Docker orphans, and installer logs.
- **Secrets Management:** .env files are blacklisted from Git tracking.

## ⚠️ POTENTIAL LEAKS / FUTURE RISKS
- **Disk Encryption:** The Passport drive is not yet LUKS-encrypted. If physically stolen, data is accessible.
- **Local Git:** Gitea needs 2FA enabled for the 'pibulus' user.
- **SDR Leakage:** Passive sniffing is safe, but FM broadcasting (TR508) is a physical beacon. Use 'Stealth Frequencies' found via scan_fm.sh.
