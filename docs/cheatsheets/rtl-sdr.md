# RTL-SDR — Quick Cat Edition

The Pi now has a real SDR lab, not just a dongle dangling off USB.

Current hardware:
- `Nooelec NESDR SMArt v5`
- receive-only, no transmit

What actually works on this box:
- FM radio
- airband AM voice
- analog narrowband utility / public-safety-style listening
- 433 MHz sensors
- pager decode
- ADS-B plane radar
- remote web streaming for audio modes

What does **not** magically work:
- modern digital / trunked / encrypted police and emergency systems

---

## Fastest ways in

### 1. Deck menu

```bash
deck
```

Then open:
- `🎛️ sdr`
- `🧭 SDR Snapshot` to sanity-check the dongle
- `🌐 Remote Stream` to see the web URLs

Menu meanings:
- `🧭 SDR Snapshot` = quick health/status view
- `🧪 Self Test` = prove the tuner opens and samples
- `🌐 Remote Stream` = browser audio status and URLs
- `📻 FM Presets` / `🎛️ Tune FM` = music radio
- `🛫 Airband Listen` = aircraft voice
- `🚓 Utility / Public Safety Listen (Analog)` = generic analog narrowband listening
- `🌡️ 433MHz Hunt` = sensors/remotes/weather junk
- `📟 Pager Hunt` = pager decode
- `✈️ Plane Radar (ADS-B)` = aircraft positions, not audio
- `📖 Cheatsheets` = this file in launcher form

### 2. Remote web tuner

Use this when you want audio on your own device instead of the Pi:

- `https://deck.quickcat.club/sdr/`
- `http://pibulus.local/sdr/`

Notes:
- audio plays in your browser/device
- the stream auto-sleeps after ~3 minutes with no listeners
- favorites are saved in your browser only

### 3. Shell helpers

```bash
~/pibulus-os/scripts/sdr_lab.sh status
~/pibulus-os/scripts/sdr_lab.sh selftest
~/pibulus-os/scripts/sdr_lab.sh remote-status
~/pibulus-os/scripts/sdr_lab.sh remote-start fm 106.7
~/pibulus-os/scripts/sdr_lab.sh remote-stop
```

---

## Audio reality check

There are two different audio paths:

### Local tuning from SSH / launcher

Examples:

```bash
~/pibulus-os/scripts/sdr_lab.sh fm 106.7
~/pibulus-os/scripts/sdr_lab.sh airband 121.5
~/pibulus-os/scripts/sdr_lab.sh nfm 156.8
```

This audio comes out of the **Pi's local ALSA output**.
Plain SSH does **not** pipe that sound back to your laptop terminal.

### Remote tuning from the web page

Start a station from `/sdr/` and the audio plays in your browser/device.

---

## Good starter moves

### FM music

- `PBS 106.7`
- `Triple R 102.7`
- `JOY 94.9`
- `SYN 90.7`
- `ABC Classic 105.9`

### Airband

- `118.0`
- `121.5` guard
- `123.45` air-to-air

### Analog utility / marine / ham

- `146.5`
- `156.8` marine channel 16
- `460.550` generic narrowband starter

These are starter bookmarks, not promises of active traffic.

---

## Plane radar

The Pi has a working RTL-capable `readsb` build installed at:

```bash
/usr/local/bin/readsb-rtl
```

Quick way to run it:

```bash
~/pibulus-os/scripts/sdr_lab.sh planes
```

That is terminal-first, not part of the remote audio page.

---

## Sensors and pagers

### 433 MHz junk drawer

```bash
~/pibulus-os/scripts/sdr_lab.sh 433
```

### Pager decode

```bash
~/pibulus-os/scripts/sdr_lab.sh pagers
~/pibulus-os/scripts/sdr_lab.sh pagers 152.25
```

---

## If something feels broken

Run these in order:

```bash
~/pibulus-os/scripts/sdr_lab.sh status
~/pibulus-os/scripts/sdr_lab.sh selftest
~/pibulus-os/scripts/sdr_lab.sh remote-status
systemctl status sdr-remote.service --no-pager
```

What you want to see:
- dongle detected in `status`
- `selftest` finds `R820T tuner`
- remote service says `active`

Common gotchas:
- if you are tuning from SSH, audio is still on the Pi, not your laptop
- if `/sdr/` is dead but `sdr-remote.service` is active, nginx routing is the likely culprit
- if a tune fails instantly, the dongle may be busy or the frequency/mode combo may be wrong

---

## Files that matter

Repo-side:

- `launcher.sh`
- `scripts/sdr_lab.sh`
- `scripts/sdr_remote.py`
- `config/system/sdr-remote.service`
- `config/nginx/hardening.conf`

System-side:

- `/etc/systemd/system/sdr-remote.service`
- `/etc/udev/rules.d/99-rtlsdr.rules`
- `/usr/local/bin/readsb-rtl`
