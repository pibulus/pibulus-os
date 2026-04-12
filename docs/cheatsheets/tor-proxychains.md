# TOR + PROXYCHAINS — Anonymity Stack

Tor routes your traffic through 3 volunteer relays before it exits. Proxychains forces
any program to use Tor (or other proxies) even if it doesn't natively support it.
Understanding *why* it works matters more than just having it installed.

---

## How Tor works (the important bit)

```
You → Entry node → Middle node → Exit node → Destination
         ↑               ↑             ↑
    knows you      knows nothing    knows destination
                                   but not you
```

Your ISP sees you connecting to the entry node. That's it.
The destination sees the exit node's IP. Not yours.

---

## Setup

```bash
# Start Tor service
sudo systemctl start tor
sudo systemctl enable tor   # start on boot

# Check it's running
systemctl is-active tor

# Verify your Tor exit IP
torify curl https://check.torproject.org/api/ip

# Your real IP for comparison
curl https://1.1.1.1/cdn-cgi/trace
```

---

## Proxychains — route any program through Tor

```bash
# Edit config to use Tor's SOCKS5 proxy
sudo nano /etc/proxychains4.conf
# At the bottom, ensure this line exists:
# socks5  127.0.0.1 9050

# Now prefix any command with proxychains4
proxychains4 curl https://check.torproject.org/api/ip
proxychains4 nmap -sT -Pn 192.168.1.1      # TCP scan via Tor
proxychains4 ssh user@somehost.onion        # reach .onion sites
```

---

## .onion addresses (hidden services)

These only exist on Tor. You can't reach them without it.

```bash
# Connect to an .onion via SSH
torify ssh user@address.onion

# Browse .onion in w3m
torify w3m http://some-onion-address.onion
```

---

## Things Tor does NOT protect against

- Browser fingerprinting (use Tor Browser for web browsing)
- JavaScript that reveals your real IP
- Logging in to accounts tied to your identity
- Patterns in your behaviour over time
- Exit node traffic sniffing (use HTTPS end-to-end)

---

## Torsocks — cleaner than proxychains for most things

```bash
sudo apt install torsocks
torsocks curl https://check.torproject.org/api/ip
torsocks wget https://example.com/file
```

---

## Install

```bash
sudo apt install tor proxychains-ng torsocks
```
