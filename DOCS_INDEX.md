# Docs Index

This is the sane starting map for both humans and AI agents.

## Start Here

- [README.md](./README.md)
  Big-picture story, service overview, and the vibe.

- [FIELD_MANUAL.md](./FIELD_MANUAL.md)
  Operator cheatsheet: ports, drives, emergency commands, access tiers.

- [GLOSSARY.md](./GLOSSARY.md)
  Names, URLs, paths, repo layout, and the concept map.

## Operational Truth

- [docs/INGRESS_METRICS_MAP.md](./docs/INGRESS_METRICS_MAP.md)
  Public routing, nginx coverage, and what the live counters really mean.

- [docs/MEMORY_CPU_PROFILE.md](./docs/MEMORY_CPU_PROFILE.md)
  Current load, pressure points, and Pi capacity reality.

- [docs/BACKUP_REDUNDANCY_PLAN.md](./docs/BACKUP_REDUNDANCY_PLAN.md)
  Recovery posture now and the Pi vs EliteDesk split.

- [docs/ELITEDESK_MIGRATION.md](./docs/ELITEDESK_MIGRATION.md)
  The shortest sane path from Pi + Passport to the new EliteDesk.

- [docs/DECK_MAP.md](./docs/DECK_MAP.md)
  Reverse-engineering guide for the Pi control surface.

## Context / Archaeology

- [docs/ELI.md](./docs/ELI.md)
  High-level explanation of the system and why it exists.

- [docs/SHIP_LOG.md](./docs/SHIP_LOG.md)
  Historical session notes. Useful for archaeology, not as the main source of truth.

- [CLAUDE.md](./CLAUDE.md)
  Agent-facing project notes, port registry, emergency rules.

## Cheatsheets

- [docs/cheatsheets/](./docs/cheatsheets/)
  bettercap, gemini, lynis, netcat, nmap, rtl-sdr, scapy, sdf-tilde, tor-proxychains, tshark, weechat

## Working Rule

If docs disagree:

1. trust the live config and scripts first
2. trust the operational truth docs second
3. treat narrative docs and older logs as historical
