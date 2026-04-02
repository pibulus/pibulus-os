```

  ██████╗ ██╗   ██╗██╗ ██████╗██╗  ██╗ ██████╗ █████╗ ████████╗     ██████╗ ███████╗
 ██╔═══██╗██║   ██║██║██╔════╝██║ ██╔╝██╔════╝██╔══██╗╚══██╔══╝    ██╔═══██╗██╔════╝
 ██║   ██║██║   ██║██║██║     █████╔╝ ██║     ███████║   ██║       ██║   ██║███████╗
 ██║▄▄ ██║██║   ██║██║██║     ██╔═██╗ ██║     ██╔══██║   ██║       ██║   ██║╚════██║
 ╚██████╔╝╚██████╔╝██║╚██████╗██║  ██╗╚██████╗██║  ██║   ██║       ╚██████╔╝███████║
  ╚══▀▀═╝  ╚═════╝ ╚═╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝        ╚═════╝ ╚══════╝

    q u i c k   c a t ' s   t h e   b e s t .   k i c k   o u t   t h e   r e s t .

  ──────────────────────────────────────────────────────────────────────────
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ██  A SOVEREIGN INTERNET ON A RASPBERRY PI 5  ██  MELBOURNE, AUSTRALIA ██
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ──────────────────────────────────────────────────────────────────────────
```

## WHAT IS THIS

A 4GB Raspberry Pi 5 and a 5.5TB hard drive under a desk in Melbourne
running 11 Docker containers, 13 domains, 39 scripts, and a 24/7 pirate
radio station. No cloud. No tracking. No subscriptions. No permission.

It replaces Netflix, Spotify, Kindle, and a dozen other subscriptions
with a single computer that costs less than one month of the services
it replaces. Every dollar or minute taken away from platforms that
exploit people is worth it.

If you want the practical map instead of the manifesto, start at
[DOCS_INDEX.md](./DOCS_INDEX.md).

If you specifically want the deck/admin reverse-engineering map, start at
[DECK_MAP.md](./DECK_MAP.md).

```
  ┌─────────────────────────────────────────────────────────────────┐
  │                                                                 │
  │   "The internet became a shopping mall. We wanted a park."      │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘
```

---

## THE STATS

```
  ╔═══════════════════════════════════════════════════════════════════╗
  ║                                                                   ║
  ║   ██ MEDIA VAULT ██████████████████████████████████████████████   ║
  ║                                                                   ║
  ║   13,989 .... music tracks                                        ║
  ║   10,345 .... books (epub/pdf/mobi)                               ║
  ║    2,192 .... comics & graphic novels                             ║
  ║      205 .... movies                                              ║
  ║      224 .... tv shows                                            ║
  ║       11 .... audiobooks                                          ║
  ║                                                                   ║
  ║   ██ GAMES ████████████████████████████████████████████████████   ║
  ║                                                                   ║
  ║      544 .... mega drive ROMs                                     ║
  ║   3,000+ .... PICO-8 carts                                       ║
  ║      NES .... Game Boy / GBA / SNES / N64 / TG-16                ║
  ║    + interactive fiction library                                   ║
  ║                                                                   ║
  ║   ██ KNOWLEDGE ████████████████████████████████████████████████   ║
  ║                                                                   ║
  ║    2,597 .... occult & esoterica files                            ║
  ║       60 .... palestine solidarity resources                      ║
  ║        1 .... complete offline wikipedia                          ║
  ║                                                                   ║
  ║   ██ INFRASTRUCTURE ███████████████████████████████████████████   ║
  ║                                                                   ║
  ║       11 .... docker containers                                   ║
  ║       13 .... tunneled domains                                    ║
  ║       39 .... shell & python scripts                              ║
  ║       20 .... HTML pages                                          ║
  ║      642 .... lines of nginx config                               ║
  ║      175 .... git commits                                         ║
  ║        0 .... dollars/month in hosting fees                       ║
  ║        0 .... dependencies on big tech                            ║
  ║                                                                   ║
  ╚═══════════════════════════════════════════════════════════════════╝
```

---

## THE SERVICES

```
  ┌──────────────────────────────────────────────────────────────┐
  │  PUBLIC -- no login, no tracking, no questions               │
  ├──────────────────────────────────────────────────────────────┤
  │  quickcat.club .............. the front door                 │
  │  kpab.fm ................... 24/7 pirate radio               │
  │  /arcade/ .................. retro game emulators            │
  │  /pico/ .................... 3000+ PICO-8 carts              │
  │  /fiction/ ................. interactive fiction              │
  │  /wall/ .................... pixel graffiti                   │
  │  /terminal/ ................ BBS & MUD gateway               │
  │  /drop/ .................... file uploads                     │
  │  /wiki/ .................... offline wikipedia               │
  │  /palestine/ ............... solidarity resources             │
  │  /conspiracy/ .............. occult & esoterica              │
  └──────────────────────────────────────────────────────────────┘
  ┌──────────────────────────────────────────────────────────────┐
  │  FRIENDS -- shared password, given in person                 │
  ├──────────────────────────────────────────────────────────────┤
  │  watch.quickcat.club ....... movies & shows (Jellyfin)       │
  │  music.quickcat.club ....... hi-fi streaming (Navidrome)     │
  │  read.quickcat.club ........ 10,345 ebooks (Calibre-Web)     │
  │  comics.quickcat.club ...... 2,192 comics (Kavita)           │
  └──────────────────────────────────────────────────────────────┘
  ┌──────────────────────────────────────────────────────────────┐
  │  ADMIN -- owner only                                         │
  ├──────────────────────────────────────────────────────────────┤
  │  deck.quickcat.club ........ cyberdeck command & control     │
  │  radio-admin ............... AzuraCast broadcast mgr         │
  │  vault ..................... full drive browser               │
  │  soulseek .................. P2P music network (LAN)         │
  └──────────────────────────────────────────────────────────────┘
```

---

## THE CUSTOM BUILDS

No frameworks. No npm install. VT323 monospace, CSS animations, vanilla JS.
Every page loads in under a second on a Pi because there is nothing to load.

```
  ┌─ KPAB.FM ──────────────────────────────────────────────────────┐
  │  Pirate radio station. 24/7 auto-DJ with taste but no format.  │
  │  Song requests. Heart voting. Live shoutbox. Now-playing API.  │
  │  13,989 tracks. No ads. No algorithm. No Spotify. Just music.  │
  └────────────────────────────────────────────────────────────────┘
  ┌─ THE DECK ─────────────────────────────────────────────────────┐
  │  Cyberdeck control panel with live telemetry: CPU temp, RAM,   │
  │  disk, uptime, active users, now playing. Floating radio       │
  │  widget with station switching. Message inbox. One-click       │
  │  access to every service. It looks like a movie prop and       │
  │  every number on it is real.                                   │
  └────────────────────────────────────────────────────────────────┘
  ┌─ QUICKCAT.CLUB ────────────────────────────────────────────────┐
  │  Neon glitch title with chromatic aberration. Card hover       │
  │  sounds. Intersection observer entrance animations. Scanline   │
  │  drift. Grid overlay. Theme toggle via cursor block. The       │
  │  whole aesthetic, running on a machine with less RAM than       │
  │  most browser tabs.                                            │
  └────────────────────────────────────────────────────────────────┘
  ┌─ TRANSMISSION WALL ────────────────────────────────────────────┐
  │  Anonymous shoutbox. Leave a signal. No accounts. No history.  │
  │  Messages appear in real time across quickcat.club & kpab.fm.  │
  └────────────────────────────────────────────────────────────────┘
  ┌─ THE WALL ─────────────────────────────────────────────────────┐
  │  Pixel graffiti canvas. Click to paint. Shared state across    │
  │  all visitors. Persistent. Digital bathroom stall energy.      │
  └────────────────────────────────────────────────────────────────┘
  ┌─ DROP ZONE ────────────────────────────────────────────────────┐
  │  Drag and drop file uploads. Friends contribute music, books,  │
  │  comics, ROMs directly to the collection. Community-fed.       │
  └────────────────────────────────────────────────────────────────┘
  ┌─ RETRO ARCADE ─────────────────────────────────────────────────┐
  │  Browser-based emulation. Mega Drive, SNES, N64, Game Boy,     │
  │  GBA, NES, TG-16. SharedArrayBuffer threading. PICO-8 carts.  │
  │  Interactive fiction engine. Zero install. Play now.            │
  └────────────────────────────────────────────────────────────────┘
```

---

## THE SECURITY

```
  ╔═══════════════════════════════════════════════════════════════════╗
  ║                                                                   ║
  ║   CLOUDFLARE TUNNEL .... real IP invisible to the internet       ║
  ║   RATE LIMITING ........ 1 req/sec on all server blocks          ║
  ║   BOT BLOCKING ......... 25+ scanner user-agents auto-blocked    ║
  ║   HONEYPOT TARPIT ...... probe paths return 410 + attitude       ║
  ║   SECURITY HEADERS ..... nosniff, frame deny, referrer, perms    ║
  ║   BASIC AUTH ........... deck protected, htpasswd hashed         ║
  ║   ROBOTS.TXT ........... politely telling crawlers to leave      ║
  ║   SECURITY.TXT ......... "there is no bug bounty. go away."     ║
  ║   SERVER TOKENS OFF .... nginx version hidden                    ║
  ║   UPLOAD LIMITS ........ 1KB on write endpoints                  ║
  ║   NO ANALYTICS ......... zero cookies, zero tracking pixels      ║
  ║   NO USER DATA ......... we don't know who you are. good.       ║
  ║                                                                   ║
  ║   bots that probe .env or wp-admin get this:                     ║
  ║                                                                   ║
  ║   "Gone. There is nothing here. There was never anything here.   ║
  ║    This is a Raspberry Pi running static HTML.                   ║
  ║    You are wasting your time and mine.                           ║
  ║    Please reconsider your life choices."                         ║
  ║                                                                   ║
  ╚═══════════════════════════════════════════════════════════════════╝
```

---

## THE ARCHITECTURE

```
                    THE INTERNET
                         │
                    ┌────┴────┐
                    │CLOUDFLARE│
                    │ TUNNEL   │
                    └────┬────┘
                         │ (encrypted, IP hidden)
                         │
              ┌──────────┴──────────┐
              │   RASPBERRY PI 5    │
              │   4GB RAM / arm64   │
              │   Debian Bookworm   │
              ├─────────────────────┤
              │                     │
              │  ┌───────────────┐  │
              │  │  NGINX        │  │
              │  │  642 lines    │  │
              │  │  5 vhosts     │  │
              │  │  rate limited │  │
              │  │  bot blocked  │  │
              │  └───────┬───────┘  │
              │          │          │
              │  ┌───────┴───────┐  │
              │  │   DOCKER x11  │  │
              │  │               │  │
              │  │  jellyfin     │  │
              │  │  navidrome    │  │
              │  │  azuracast    │  │
              │  │  kavita       │  │
              │  │  calibre-web  │  │
              │  │  filebrowser  │  │
              │  │  tunarr       │  │
              │  │  memos        │  │
              │  │  shortener    │  │
              │  │  soulseek     │  │
              │  │  nginx        │  │
              │  └───────────────┘  │
              │                     │
              │  ┌───────────────┐  │
              │  │ CUSTOM PYTHON │  │
              │  │               │  │
              │  │  shoutbox     │  │
              │  │  msg drop     │  │
              │  │  pixel wall   │  │
              │  │  kpab hearts  │  │
              │  │  dropzone     │  │
              │  │  rom browser  │  │
              │  │  status API   │  │
              │  └───────────────┘  │
              │                     │
              └──────────┬──────────┘
                         │ USB 3.0
                    ┌────┴────┐
                    │ PASSPORT │
                    │ 5.5TB    │
                    │ HDD      │
                    └─────────┘
                   the whole library
```

---

## SOVEREIGNTY

This is a fully sovereign stack. No cloud provider has a kill switch.
No corporation can raise prices, change terms, or shut it down.

- **The hard drive** is the collection. Pick it up. Walk away. It's yours.
- **The Pi** is the infrastructure. $80. Replaceable in an afternoon.
- **The repo** is the blueprint. `git clone` and you're back online.
- **The tunnel** is the only external dependency, and it's swappable.

Everything that matters is physical, local, and owned. The entire server
can be rebuilt from a fresh Pi, this repo, and the hard drive. That's it.
No API keys required. No vendor lock-in. No "we're sunsetting this feature."

If Cloudflare disappears tomorrow, swap in a different tunnel or just
use it on LAN. If the Pi dies, buy another one. If the SD card corrupts,
flash a new one and run the deploy script. The collection survives
because it lives on a drive you can hold in your hand.

**This is what digital sovereignty actually looks like.** Not a manifesto.
Not a tweet. A working server under a desk proving the point every second
it stays online.

---

## QUICK START

```bash
# clone it
git clone https://github.com/pibulus/quickcat-os.git
cd quickcat-os

# plug in your hard drive, mount it at /media/pibulus/passport

# install docker
curl -fsSL https://get.docker.com | sh

# fire it up
docker compose -f config/stacks/pirate.yml up -d

# set up the tunnel
# (you'll need a Cloudflare account and a domain)
cp config/cloudflared/config.yml /etc/cloudflared/config.yml
systemctl enable --now cloudflared

# that's it. you have your own internet now.
```

---

## THE REPO

```
  quickcat-os/
  ├── config/
  │   ├── nginx/hardening.conf ........ 642 lines of routing & security
  │   ├── stacks/pirate.yml ........... main docker compose
  │   ├── cloudflared/ ................ tunnel config
  │   └── systemd/ .................... service files
  ├── scripts/ ........................ 39 shell & python scripts
  │   ├── status.sh ................... live system stats API
  │   ├── deploy.sh ................... stack deployment wizard
  │   ├── nightly-backup.sh ........... automated config backup
  │   ├── dropzone.py ................. file upload server
  │   ├── wall_server.py .............. pixel graffiti backend
  │   ├── kpab_shoutbox.py ............ transmission wall
  │   ├── kpab_hearts.py .............. heart voting system
  │   ├── msgdrop.py .................. message inbox
  │   └── ... 30 more
  ├── www/html/ ....................... 20 HTML pages
  │   ├── index.html .................. quickcat.club portal
  │   ├── deck/index.html ............. cyberdeck control panel
  │   ├── kpab/index.html ............. pirate radio frontend
  │   ├── arcade/ ..................... retro game emulators
  │   ├── wall/ ....................... pixel graffiti
  │   ├── fiction/ .................... interactive fiction
  │   ├── palestine/ .................. solidarity resources
  │   ├── conspiracy/ ................. occult vault
  │   └── drop/ ...................... file upload UI
  ├── LETTER.md ....................... a letter to ourselves
  ├── FIELD_MANUAL.md ................. operational reference
  ├── GLOSSARY.md ..................... system map
  └── README.md ....................... you are here
```

---

## THE PHILOSOPHY

```
  ┌────────────────────────────────────────────────────────────────┐
  │                                                                │
  │   SOFTWARE IS POLITICS.                                        │
  │                                                                │
  │   Every platform you use is a statement about who owns         │
  │   your attention. This server says: nobody does.               │
  │                                                                │
  │   The data lives on a drive you can hold.                      │
  │   The services run on a computer you own.                      │
  │   The radio plays what you choose.                             │
  │   The books are yours to keep.                                 │
  │                                                                │
  │   Spotify's algorithms are a con. Radio compartmentalises      │
  │   people into taste categories. Every dollar or minute taken   │
  │   away from platforms that exploit musicians is worth it.      │
  │   We're bigger than genre. It's time to build our own          │
  │   platforms and think local digitally.                         │
  │                                                                │
  │   No scale. No subscriptions. No data harvesting.              │
  │   "Can't scale" IS the feature.                                │
  │                                                                │
  │   4GB of RAM means every container earns its place.            │
  │   A single hard drive means the collection is curated.         │
  │   Limitations force taste.                                     │
  │                                                                │
  │   The server doesn't know who you are. It doesn't want to.    │
  │   There's no analytics, no cookies, no tracking pixels,        │
  │   no third-party scripts. The constraint isn't a compromise.   │
  │   It's the whole point.                                        │
  │                                                                │
  │   Build yours. A Pi, a drive, and a weekend.                   │
  │                                                                │
  └────────────────────────────────────────────────────────────────┘
```

---

```
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

                         MELBOURNE  //  2026
                    ~(=^..^) QUICK CAT CLUB

        175 commits  //  0 dependencies on big tech  //  $0/month
             4GB of RAM  //  5.5TB of everything good

  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

  ── GR33TZ ──────────────────────────────────────────────────────────────

  shouts to the demoscene kids who made art on machines that couldn't
  handle it. to the BBS sysops who ran servers in their bedrooms. to the
  zine makers and pirate radio operators and everyone who ever built
  something weird and beautiful on hardware they actually owned.

  to everyone who ever said "you can't run that on a Pi" — watch us.

  RESPECT: Raspberry Pi Foundation // Docker // Cloudflare // Deno
  RESPECT: AzuraCast // Jellyfin // Navidrome // Kavita // Calibre
  RESPECT: the entire FOSS ecosystem that makes this possible
  RESPECT: Claude Code for being the best late-night co-pilot

  ANTI-RESPECT: surveillance capitalism, algorithmic feeds, subscription
  fatigue, planned obsolescence, and the five websites full of screenshots
  of the other four.

  this readme was written at 11pm on a Monday night in Melbourne
  while pirate radio played in the background.

  if you made it this far, you're one of us.

  ── EOF ─────────────────────────────────────────────────────────────────

  License: Do whatever you want with this. It's a zine, not a product.
```
