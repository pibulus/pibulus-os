# 📜 THE CYBERDECK LEDGER
### A chronological record of modifications and deployments.

## [2026-02-18] - THE REBRAND & HARDENING SESSION
- **Identity:** Rebranded from 'Pibulus' to 'Quick Cat Club'.
- **Security:** Enabled MAC randomization, Quad9 Private DNS, and Fail2Ban.
- **Remote:** Enabled 'Stealth Mode' (password toggle) and Web-Terminal (Port 7682).
- **Social:** Deployed Gitea (Port 3001) and Memos (Port 5230).
- **Broadcast:** Integrated 80s Ads into ErsatzTV and mapped Music/Radio to AzuraCast.
- **AI:** Installed Claude Code and prepped Node v22 for OpenClaw.
- **Redundancy:** Created 'Golden Image' backup system.

## [2026-02-19] - MISSION CONTROL & AI UPGRADE SESSION
- **AI Upgrades:** Installed Homebrew, GCC, GH CLI, and UV.
- **OpenClaw:** Integrated ♊️ gemini, 🐙 github, 🧾 summarize, 🍌 nano-banana, and 🌊 songsee.
- **Mission Control:** Deployed 'Mission Control' UI (Web + Terminal) for task tracking.
- **Identity:** Rebranded login experience to 'PIBULUS' with 'BISHOP' operative.
- **UX:** Streamlined welcome dashboard with horizontal layout and live port map.
- **Stability:** Stopped RAM-heavy containers (Immich ML, etc.) to rescue Swap memory.

## [2026-02-22] - RADIO STATION INTEGRATION
- **Domain:** Configured Nginx to serve 'kpab.fm' alongside 'quickcat.club'.
- **Content:** Created dedicated Lush landing page for KPAB.fm with live audio player.
- **Redundancy:** Synchronized new configs with Passport drive.

## [2026-02-22] - THE BROADCAST ERA BEGINS
- **Domain Acquisition:** Purchased 'kpab.fm' - the permanent home for Brunswick Pirate Radio.
- **Nginx Multi-Site:** Configured the deck to host two separate worlds: 'quickcat.club' (Guest Home) and 'kpab.fm' (Radio Landing Page).
- **Lush Web UI:** Deployed a dedicated radio player page for KPAB.fm with live stream integration.
- **Radio Lab Expansion:** Created 'antenna_calc.sh' to prepare for physical FM transmission using the TR508 hardware.
- **Identity Lock:** Updated BISHOP welcome dashboard to proudly display the new broadcast identity.
- **Hardware Strategy:** Finalized specs for the 0.5W FM transmitter and Nooelec SDR integration.

## [2026-02-25] - SOULSEEK RESURRECTION & DOCS OVERHAUL
- **slskd:** Rebuilt standalone (removed VPN dependency). Updated to v0.24.4.
- **slskd API:** Confirmed full REST API access - search, download, transfer management all working via CLI.
- **AzuraCast Fix:** Recovered from SSL lockout (base_url was set to https, always_use_ssl=true). Reset via CLI.
- **Welcome Script:** v4.2 - added port override map (azuracast=8500, jellyfin=8096), hides noise containers.
- **PureVPN:** Credentials configured in .env but Gluetun TLS failing (stale server list). slskd runs direct for now.
- **AI Handbook:** Complete rewrite with full API docs, port map, path reference, and operational notes.
- **Music Downloads:** Queued first batch - King Gizzard, Butthole Surfers, Slayer, Cake (7 FLAC albums).
