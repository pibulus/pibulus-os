# Docs Index

This is the sane starting map for both humans and AI agents.

## Start Here

- [PIBULUS_QUICKSTART.md](./PIBULUS_QUICKSTART.md)
  Fast orientation for Codex/agents: access, routes, watchdog, backups, and guardrails.

- [README.md](./README.md)
  Big-picture story, service overview, and the vibe.

- [FIELD_MANUAL.md](./FIELD_MANUAL.md)
  Operator cheatsheet: ports, drives, emergency commands, access tiers.

- [GLOSSARY.md](./GLOSSARY.md)
  Names, URLs, paths, repo layout, and the concept map.

## Operational Truth

- [APP_DEPLOYMENT_MAP.md](./APP_DEPLOYMENT_MAP.md)
  Live custom app map: app dirs, domains, ports, systemd services, and deploy shape.

- [REGISTRY.md](./REGISTRY.md)
  Auto-generated app registry (port/domain/status) from `apps-registry.json` — the machine source of truth. Regenerate via `gen-registry.sh`.

- [docs/INGRESS_METRICS_MAP.md](./docs/INGRESS_METRICS_MAP.md)
  Public routing, nginx coverage, and what the live counters really mean.

- [docs/EMOJI_APP_ICONS.md](./docs/EMOJI_APP_ICONS.md)
  Default favicon/PWA identity pattern: emoji first, custom icon later only when there is a real product reason.

- [docs/MEMORY_CPU_PROFILE.md](./docs/MEMORY_CPU_PROFILE.md)
  Current load, pressure points, and Pi capacity reality.

- [docs/KPAB_AZURACAST_RECOVERY.md](./docs/KPAB_AZURACAST_RECOVERY.md)
  KPAB.FM/AzuraCast outage recovery: Liquidsoap crash symptoms, safe-mode settings, and copy-paste repair commands.

- [docs/ROMM_STYLING_EDITING.md](./docs/ROMM_STYLING_EDITING.md)
  RomM styling/editing map: custom CSS/JS injection, EmulatorJS player surface, safe workflow, and the known database startup race.

- [docs/BACKUP_REDUNDANCY_PLAN.md](./docs/BACKUP_REDUNDANCY_PLAN.md)
  Recovery posture now and the Pi vs EliteDesk split.

- [docs/ELITEDESK_MIGRATION.md](./docs/ELITEDESK_MIGRATION.md)
  The shortest sane path from Pi + Passport to the new EliteDesk.

- [docs/DECK_MAP.md](./docs/DECK_MAP.md)
  Reverse-engineering guide for the Pi control surface.

- [scripts/agent_tools.sh](./scripts/agent_tools.sh)
  Read-only toolbox map for Deck-launched agents.

- [scripts/ai_bootstrap.sh](./scripts/ai_bootstrap.sh)
  Read-only start-of-session context card for Claude, Codex, Gemini, DeepSeek, and future Deck agents.

- [scripts/deck_doctor.sh](./scripts/deck_doctor.sh)
  Compact health pass for the Deck gateway, services, disks, mount state, and timers.

## Context / Archaeology

- [docs/AI_COLLECTIVE_CONTEXT.md](./docs/AI_COLLECTIVE_CONTEXT.md)
  Shared boot context for Pi agents launched through the Deck.

- [docs/AI_CONTINUITY.md](./docs/AI_CONTINUITY.md)
  Shared memory tiers, bootup/bootdown rhythm, and diary protocol for Pi agents.

- [docs/PIBULUS_SPIRIT.md](./docs/PIBULUS_SPIRIT.md)
  Safe distillation of the local design/reference philosophy for Pi-side agents.

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
