# Deck Map

Quick reverse-engineering guide for the Pi control surface.

## Front Doors

- `launcher.sh`
  Admin launcher for the `deck` alias. This is the main control surface for SSH/TTY use.
- `public-deck.sh`
  Public-facing textworld gateway used by the public terminal flow.
- `FIELD_MANUAL.md`
  Fast operational reference: passwords, ports, mounts, and emergency moves.
- `DOCS_INDEX.md`
  Broader repo/documentation router.

## Mental Model

There are two decks:

- Admin deck: `launcher.sh`
  For you. System ops, radio, media, drives, notes, Soulseek, feed reader, textworlds.
- Public deck: `public-deck.sh`
  For friends/visitors. Curated terminal gateway into MUDs, MOOs, BBSs, and local text toys.

## Admin Deck Structure

`launcher.sh` is organized by top-level domains:

- `SIGINT`
  Machine health, tunnel status, logs, service state, public IP.
- `RADIO`
  KPAB now playing, listeners, service health, public links.
- `MEDIA`
  Search and browse the Passport drive.
- `TEXTWORLDS`
  Curated MUD/BBS/MOO gateway from the admin side.
- `NETWORK`
  Home/away mode helpers and network status.
- `DRIVES`
  Mount state, USB noise, safe unmount actions.
- `OPS`
  Higher-impact actions like deploy, scavenger, and media grab.
- `SOULSEEK`
  `slskd` lifecycle and local UI access.
- `CLUB`
  Club account/member utilities.
- `NOTES`
  Field notes, field manual, feed reader, tmux shell.
- `CHAT`
  Terminal chat client entry point.

## Modules

Modules live in `modules/` and are sourced by `launcher.sh` when present.

- `modules/scavenger_module.sh`
  Guided downloader flow. Picks between Soulseek, `yt-dlp`, Internet Archive, and direct download.
- `modules/pirate_grab_module.sh`
  TV/movie-oriented “grab the top result” flow via `scripts/pirate_grab.py`.
- `modules/audio_feedback.sh`
  Optional tones/feedback sugar.

There are more modules in the repo, but the three above are the ones directly touching the current launcher UX.

## Scripts That Matter Most

- `scripts/network_mode.sh`
  Home/away network mode helper.
- `scripts/find_media.py`
  Search helper for local media browsing.
- `scripts/pirate_grab.py`
  TV/movie grab engine behind pirate-grab.
- `scripts/deploy.sh`
  Main deploy entry point used from the launcher.
- `scripts/flush_ram.sh`
  One-shot maintenance helper.
- `scripts/account_parity_audit.py`
  Club account sanity check.
- `scripts/add_club_member.py`
  Add a club member.

## Important Runtime Paths

- Repo: `/home/pibulus/pibulus-os`
- Backup of old messy repo: `/home/pibulus/pibulus-os.backup-20260403-001233`
- Main media drive: `/media/pibulus/passport`
- Newsboat config: `/home/pibulus/.newsboat`
- Field notes log: `/home/pibulus/pibulus-os/logs/field-notes.log`

## External / Service Expectations

- `cloudflared` runs as a systemd service, not a Docker container.
- `slskd` is the Soulseek container and should expose `http://localhost:5030`.
- `newsboat`, `w3m`, `urlscan`, `weechat`, `yt-dlp`, `aria2c`, and `ia` are installed as part of the current deck toolchain.

## Safe Editing Rules

- Change `launcher.sh` when you want to change the admin deck flow.
- Change `public-deck.sh` when you want to change the public textworld experience.
- Treat `FIELD_MANUAL.md` as ops reference, not philosophy.
- If the live Pi is working and Git gets weird again, back up the folder and fresh-clone instead of trying to heroically untangle cursed history.
