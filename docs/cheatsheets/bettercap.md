# BETTERCAP — Network Attack & Monitoring Framework

The modern swiss army knife for network recon and MITM. Actively maintained, has a web UI,
works on WiFi AND ethernet. This is what serious people actually use daily.

---

## 80/20 quickstart

```bash
# Start interactive session
sudo bettercap

# Start targeting a specific interface
sudo bettercap -iface eth0
```

---

## Inside the bettercap REPL

```
# Show help
help

# Discover live hosts on LAN
net.probe on
net.show

# Show network map
net.show

# Start sniffing
net.sniff on

# Watch HTTP traffic (shows visited URLs)
set net.sniff.verbose true
net.sniff on

# Stop probing
net.probe off
```

---

## One-liner mode (non-interactive)

```bash
# Quick LAN discovery and show results
sudo bettercap -eval "net.probe on; sleep 5; net.show; quit"

# Capture and log to file
sudo bettercap -eval "net.sniff on" -caplet /usr/share/bettercap/caplets/http-req-dump.cap
```

---

## WiFi recon (needs monitor-mode adapter)

```bash
sudo bettercap -iface wlan1
# Inside REPL:
wifi.recon on
wifi.show
```

---

## Caplets (saved scripts)

```bash
# List built-in caplets
ls /usr/share/bettercap/caplets/

# Run a caplet
sudo bettercap -caplet /path/to/caplet.cap
```

---

## Web UI

```bash
# Start with web UI on port 8083
sudo bettercap -caplet /usr/share/bettercap/caplets/http-ui.cap
# Open: http://localhost:8083  (user: user, pass: pass)
```

---

## Golden rules

1. Only run on networks you own or have explicit permission to test
2. `net.probe on` sends ARP probes — it is visible on the network
3. Start with `net.show` before doing anything active — know what's there

---

## Install

```bash
sudo apt install bettercap
sudo bettercap -eval "caplets.update; quit"   # update built-in caplets
```
