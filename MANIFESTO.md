# 🐾 QUICK CAT CLUB - CYBERDECK MANIFESTO

## THE VISION
This is a modular, high-redundancy digital command center. It is designed to be a pirate radio station, a media sanctuary, and an AI-powered development node that works both on and off the grid.

## ARCHITECTURE
- **Brain:** Raspberry Pi 5 (4GB) running Raspberry Pi OS (Bookworm).
- **Storage:** 2TB Passport Drive mounted at `/media/pibulus/passport`.
- **Identity:** Quick Cat Club (mDNS: `pibulus.local`, Hotspot: `pibulus-deck`).
- **Communication:** Telegram + OpenClaw (Bridge to i7/1080Ti AI PC).

## CORE CAPABILITIES
1. **Media Piracy:** Legally-owned media preservation via Soulseek (slskd) and Immich.
2. **Broadcasting:** KPAB.fm (Radio) and ErsatzTV (TV Channel).
3. **Anonymity:** Randomized MAC addresses, Quad9 Private DNS, and VPN Shielding.
4. **Resilience:** "Golden Image" system for instant recovery.

## EMERGENCY PROTOCOLS
- **Bunker Mode:** Kills all connections and clears traces. Use in high-threat environments.
- **Safe Eject:** Always unmount the Passport drive before removal to prevent database corruption.

## RECOVERY
If the system fails, install a fresh OS, clone the `pibulus-os` repo, and extract the latest Golden Image from the Passport drive back into `~/pibulus-os`.

---
*Stay modular. Stay redundant. Stay hidden.*
