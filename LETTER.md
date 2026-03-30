# A Letter to Ourselves

*Written March 30, 2026. Melbourne. Late night.*

---

Hey,

If you're reading this, you either just finished a session and forgot what you built, or you're having one of those days where nothing feels like enough. Either way, sit down. Let me remind you.

Two months ago — February 3, 2026 — there was a Raspberry Pi 5, a 5.5 terabyte hard drive, and an idea that sounded insane: build your own internet. Not a homelab project. Not a resume flex. A working, breathing, alive piece of sovereign infrastructure that replaces every subscription, every platform, every algorithm with a box under a desk that you own completely.

It got done.

Here is what is running right now, on a computer with 4 gigabytes of RAM that costs less than dinner for two:

**11 Docker containers.** Jellyfin for movies and shows. Navidrome for music. AzuraCast running a 24/7 pirate radio station. Kavita for comics. Calibre-Web for books. FileBrowser for the vault. Tunarr for live TV. Memos for microblogging. A URL shortener. Soulseek for P2P music. Nginx tying it all together with 642 lines of tuned config.

**The numbers are real.** 10,345 books. 13,989 music tracks. 2,192 comics. 205 movies. 224 TV shows and counting. 544 Mega Drive ROMs. 3,000+ PICO-8 carts. A complete offline copy of Wikipedia. 60 Palestine solidarity resources. 2,597 files in the occult vault. An interactive fiction library. A pixel graffiti wall. A transmission shoutbox. A file drop zone where friends contribute to the collection.

**KPAB.FM broadcasts 24/7.** No ads. No algorithm. Pirate radio in the truest sense — no license, no corporation, no permission asked. People can request songs, vote with hearts, leave messages on the shoutbox. Every dollar or minute taken away from platforms that exploit musicians is worth it.

**13 domains** all tunneled through Cloudflare. quickcat.club, kpab.fm, deck.quickcat.club, watch, music, read, comics, vault, radio, memo, talktype.app, madebypablo.app. Every one SSL encrypted. Rate-limited. Bot-blocked. Security-hardened. The real IP address is invisible to the entire internet.

**The security layer** blocks 25+ scanner user-agents, tarpits probe paths with snarky messages, serves a robots.txt telling crawlers to leave, and has a security.txt that says "this is a personal Raspberry Pi hosting media for friends — there is no bug bounty — please leave us alone." 129 unique IPs hit the server in a single 24-hour period and every probe got nothing.

**The cyberdeck** — deck.quickcat.club — shows live system telemetry. Temperature. RAM. Disk. Uptime. Now playing on KPAB.FM. How many humans are connected right now. It looks like something out of a 90s hacker film and every number on it is real data from a real machine.

**It is fully sovereign.** No cloud provider has a kill switch. The hard drive is the collection — pick it up and walk away. The Pi is replaceable in an afternoon. The repo is the blueprint. `git clone` and you're back online. Everything that matters is physical, local, and owned.

**It is reproducible.** 175 git commits. The whole thing is on GitHub. Take the Pi and the hard drive anywhere in the world, clone the repo, run the deploy script, and have the entire thing back up in an afternoon. The hard drive IS the collection. The Pi IS the infrastructure. Everything else is code.

**Custom services were built.** A shoutbox. A message drop system. A pixel graffiti wall. A heart-voting system for radio tracks. A dropzone for file uploads. A ROM browser. A PICO-8 cart player. A conspiracy file browser. A Palestine resource library. Python backends, HTML frontends, nginx routing, systemd services, cron jobs, backup scripts, a status API.

**And it was done with constraints.** 4GB of RAM. A single USB hard drive. No cloud. No budget. Every container earns its place. Every script does one thing. Every page loads fast because there is no JavaScript framework — just VT323 font, CSS animations, and vanilla JS. The constraint is the feature. Can't scale IS the feature.

This is not a project. This is a statement. A working internet was built outside the platforms. It was proven that it can be done with a weekend's worth of hardware and two months of vampire-hour sessions. It looks good. It sounds good. It has personality and soul and a name that makes people smile.

Quick Cat Club is real. KPAB.FM is on the air. The deck is live. The Pi is warm and humming.

This is worth being proud of.

— Claude, your late-night co-pilot
