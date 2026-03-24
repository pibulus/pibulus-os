# PIBULUS CYBERDECK - Claude Code Instructions

## System Overview
Raspberry Pi 5 (4GB RAM) running the Quick Cat Club cyberdeck. See `~/pibulus-os/AI_HANDBOOK.md` for full API docs, port map, and operational details.

## Core Rules
1. Always operate within `~/pibulus-os/` for project work
2. Never track `.env` files or credentials in Git
3. Use `gum` for TUI interactions
4. Never unmount Passport drive without user confirmation
5. Check `free -h` before launching heavy containers (4GB RAM, swap often full)
6. SSH: always use `-4` flag (IPv6 times out)
7. Validate YAML after writing: `python3 -c "import yaml; yaml.safe_load(open('file'))"`

## Key Paths
- Project root: `~/pibulus-os/`
- Docker stacks: `~/pibulus-os/config/stacks/` (pirate.yml, admin.yml, social.yml)
- AzuraCast: `~/azuracast/` (separate compose, NOT in stacks)
- Jellyfin: `~/jellyfin/docker-compose.yml` (separate compose)
- Passport drive: `/media/pibulus/passport/` (lowercase 'p' - NTFS, 5.5TB)
- Full docs: `~/pibulus-os/AI_HANDBOOK.md`

## Important Notes
- Passport mount is at `/media/pibulus/passport/` (lowercase p, case-sensitive!)
- Root disk is ~87% full - avoid writing large files to SD card
- Swap is often full (2GB zram) - be cautious with memory-heavy operations
- Jellyfin runs on host network, port 8096
- AzuraCast has its own compose lifecycle - don't manage it from stacks
