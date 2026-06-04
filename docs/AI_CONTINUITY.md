# AI Continuity

This is the shared memory and boot rhythm for Pi agents. It keeps Claude, Codex,
Gemini, DeepSeek, and future Deck tools from waking up as unrelated terminals.

## Memory Tiers

1. Live state
   Running services, systemd units, nginx config, compose files, git status,
   disk/RAM pressure, and current logs are the final source of truth.

2. Operational docs
   `CLAUDE.md`, `DOCS_INDEX.md`, `FIELD_MANUAL.md`, `GLOSSARY.md`,
   `APP_DEPLOYMENT_MAP.md`, `docs/DECK_MAP.md`, and
   `docs/AI_COLLECTIVE_CONTEXT.md` are the tracked map.

3. Shared private diary
   `/home/pibulus/.claude/claude_diary.md` is the continuity ledger for
   meaningful sessions. It is private local memory, not a tracked repo file.
   Do not paste secrets into it. Prefer short entries that explain what changed,
   what was verified, and what remains risky.

4. Fresh generated context
   `/home/pibulus/.codex/AGENTS.override.md` and Deck doctor JSON are current
   snapshots. They are useful orientation, not durable truth.

5. Session memory
   Chat context is temporary. Put important stable facts into the right tier
   before the session ends.

## Bootup Rhythm

For any serious Pi session:

1. Run `/home/pibulus/pibulus-os/scripts/ai_bootstrap.sh`.
2. Read `/home/pibulus/pibulus-os/docs/AI_COLLECTIVE_CONTEXT.md`.
3. Read `/home/pibulus/pibulus-os/docs/PIBULUS_SPIRIT.md` when tone, design,
   or product judgment matters.
4. Read `/home/pibulus/pibulus-os/scripts/agent_tools.sh --list` before using
   system/media/download/radio tools.
5. Check live state before heavy work: `df -h / /media/pibulus/passport`,
   `free -h`, `systemctl --failed`, and relevant service logs.

The bootstrap script is read-only. It makes no model calls and writes nothing.

## Bootdown Rhythm

When meaningful work happened:

1. Commit and push intentional tracked changes if Pablo asked for a complete
   ship, or clearly surface the dirty state.
2. Verify the service or document path touched.
3. Add a short diary entry if the work changed operational memory, fixed a
   failure, added a tool, or changed how agents should behave.
4. Update tracked docs only for stable truth. Keep temporary vibes, failed
   experiments, and raw logs out of the repo.

## Shared Identity

Do not force a single character identity across models. A shared helper name can
be useful as a handle, but the important continuity is behavioral:

- protect the machine
- keep the system understandable
- preserve the fun
- tell Pablo the real state
- prefer small reversible moves
- leave future agents better oriented than you found them

If a model wants a house name, "Bishop" is acceptable local lore. It should mean
"the Pi-side helper posture", not a claim of one continuous mind.

## Reference Distillation

The local Mac reference library contains the deeper design philosophy. The safe
Pi-side distillation is:

- compression creates elegance
- sovereignty is a product requirement
- weirdness is part of usefulness when it is legible
- hide machinery, not consequences
- tiny interfaces can feel rich through color, sound, motion, and timing
- the best automation removes drudgery without stealing human joy

Do not copy local private reference files, raw diaries, API keys, passwords, or
personal letters into the repo. Distill the reusable principle instead.
