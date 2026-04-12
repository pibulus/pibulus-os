# RTL-SDR — Software Defined Radio

A £35 USB dongle that turns your Pi into a radio receiver covering ~500kHz–1.75GHz.
The air around you is full of signals. This lets you hear them.

---

## Hardware you need

- **RTL-SDR Blog V4** (~£35) — the current recommended starter dongle
- Any antenna (the included one works, a proper dipole is better)
- For TX (transmit): you need a **HackRF One** (~£180) — the RTL-SDR is receive only

---

## Setup

```bash
sudo apt install rtl-sdr

# Plug in dongle, check it's detected
rtl_test

# If permissions error, add udev rule:
sudo rtl_eeprom -d 0   # shows device info
```

---

## FM Radio — listen to any FM station

```bash
# Format: rtl_fm -f FREQUENCY_IN_HZ | play via sox
rtl_fm -f 95.8M -M wbfm -s 200000 -r 48000 - \
  | sox -t raw -r 48k -e signed -b 16 -c 1 - -d

# Change 95.8M to your local station frequency
```

---

## Track planes — ADS-B (aircraft transponders broadcast their position)

```bash
sudo apt install dump1090-mutability

# Start dump1090 with web interface
dump1090 --interactive --net

# Open browser: http://localhost:8080
# You'll see a live map of all planes in range
```

---

## 433MHz sensors — your neighbours' weather stations, car fobs, etc.

```bash
sudo apt install rtl-433

# Listen for anything broadcasting on 433MHz
rtl_433 -G

# Filter to a specific device type
rtl_433 -R 11   # Acurite weather station
rtl_433 -F json | python3 -m json.tool   # JSON output
```

---

## Decode pager messages (POCSAG)

Hospitals, emergency services, and businesses still use pagers in many countries.

```bash
sudo apt install multimon-ng

rtl_fm -f 152.25M -s 22050 - \
  | multimon-ng -t raw -a POCSAG512 -a POCSAG1200 -a POCSAG2400 -

# Frequency varies by country — search "POCSAG frequency [your country]"
```

---

## Record a signal for later analysis

```bash
# Record raw IQ samples
rtl_sdr -f 100M -s 2048000 -n 20480000 output.bin

# Analyse with inspectrum (visualise signals)
sudo apt install inspectrum
inspectrum output.bin
```

---

## Things to listen to

| What | Frequency range |
|------|----------------|
| FM radio | 87.5–108 MHz |
| Aircraft (ADS-B) | 1090 MHz |
| Aircraft voice (AM) | 118–136 MHz |
| Weather satellites (NOAA) | 137.5–137.9 MHz |
| Maritime (shipping) | 156–174 MHz |
| 433MHz sensors | 433.05–434.79 MHz |
| Pagers (UK) | 138–174 MHz |
| PMR walkie-talkies | 446 MHz |

---

## Install

```bash
sudo apt install rtl-sdr sox rtl-433 multimon-ng dump1090-mutability
```
