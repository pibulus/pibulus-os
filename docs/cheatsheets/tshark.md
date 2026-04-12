# TSHARK — Terminal Wireshark

Wireshark's CLI soul. Captures and analyzes packets on the wire. Understanding traffic
changes how you think about every service you run.

---

## 80/20 quickstart

```bash
# List available interfaces
tshark -D

# Capture on eth0 (Ctrl-C to stop)
sudo tshark -i eth0

# Capture only 100 packets then stop
sudo tshark -i eth0 -c 100

# Capture to a file for later analysis
sudo tshark -i eth0 -w capture.pcap

# Read a saved capture
tshark -r capture.pcap
```

---

## Filters (the important bit)

```bash
# Show only HTTP traffic
sudo tshark -i eth0 -f "port 80"

# Show only DNS queries
sudo tshark -i eth0 -f "port 53"

# Show traffic to/from a specific IP
sudo tshark -i eth0 -f "host 192.168.1.1"

# Show only TCP SYN packets (connection attempts)
sudo tshark -i eth0 -f "tcp[tcpflags] & tcp-syn != 0"

# Filter after capture (display filter, more powerful)
tshark -r capture.pcap -Y "http.request"
tshark -r capture.pcap -Y "dns"
tshark -r capture.pcap -Y "ip.addr == 192.168.1.50"
```

---

## Useful one-liners

```bash
# Show all DNS queries being made on your network
sudo tshark -i eth0 -Y "dns.flags.response == 0" -T fields -e dns.qry.name

# Show HTTP GET requests
sudo tshark -i eth0 -Y "http.request.method == GET" -T fields -e http.host -e http.request.uri

# Show all unique IPs talking on the network
sudo tshark -i eth0 -T fields -e ip.src | sort -u
```

---

## Install

```bash
sudo apt install tshark
# During install: allow non-root capture → add yourself to wireshark group
sudo usermod -aG wireshark $USER
# Log out and back in for group to take effect
```
