# NMAP — Network Mapper

The essential. Port scanning, service detection, OS fingerprinting, and a scripting engine
that can do almost anything. Learn this one properly.

---

## 80/20 quickstart

```bash
# Find all live hosts on your LAN (no port scan, just who's there)
nmap -sn 192.168.1.0/24

# Scan a single target — top 1000 ports, service versions
nmap -sV 192.168.1.1

# Full scan: OS detection, version, scripts, traceroute (needs root)
sudo nmap -A 192.168.1.1

# Quick scan — top 100 ports only
nmap -F 192.168.1.1

# Specific ports
nmap -p 22,80,443,8080 192.168.1.1

# Scan a range of ports
nmap -p 1-65535 192.168.1.1

# Save output to file
nmap -oN scan.txt 192.168.1.1

# Scan multiple hosts
nmap 192.168.1.1 192.168.1.2 192.168.1.50-60
```

---

## NSE scripts (the real power)

```bash
# Run common vulnerability scripts
sudo nmap --script vuln 192.168.1.1

# Grab HTTP page titles across a subnet
nmap --script http-title 192.168.1.0/24

# Check for default credentials on services
sudo nmap --script auth 192.168.1.1

# List all available scripts
ls /usr/share/nmap/scripts/
```

---

## Output formats

```
-oN  human readable
-oX  XML (for importing into other tools)
-oG  greppable
-oA  all three at once
```

---

## Golden rules

1. Scan your own network first — understand what's normal
2. `-sn` (ping scan) before `-sV` (full scan) — don't hammer things unnecessarily
3. `sudo` unlocks SYN scanning (`-sS`) which is faster and stealthier than default TCP

---

## Install

```bash
sudo apt install nmap
```
