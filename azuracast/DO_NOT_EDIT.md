# ⛔ DO NOT EDIT FILES IN THIS DIRECTORY

The **LIVE** AzuraCast config is at `~/azuracast/` (NOT here).

This directory (`~/pibulus-os/azuracast/`) is the git-tracked reference copy.
The live AzuraCast instance reads from `~/azuracast/`.

## Rules
- **NEVER** run `docker compose` from this directory
- **NEVER** edit docker-compose.yml or docker-compose.override.yml here expecting it to affect the running AzuraCast
- **NEVER** sync from here → ~/azuracast/ without explicit user confirmation
- If you need to change AzuraCast config, edit `~/azuracast/docker-compose.override.yml`

## Why two copies exist
The git copy preserves the override customizations in version control.
The live copy at ~/azuracast/ was installed by AzuraCast's own installer and has runtime state.

Last updated: 2026-04-15
