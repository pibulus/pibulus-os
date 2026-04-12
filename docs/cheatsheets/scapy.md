# SCAPY — Packet Crafting in Python

The moment you stop using other people's tools and start building your own.
Scapy lets you construct, send, receive, and analyse any network packet at the byte level.
Understanding TCP/IP at this level changes everything.

---

## Start it

```bash
sudo scapy   # needs root for raw socket access
```

---

## 80/20 quickstart (inside the scapy REPL)

```python
# See all available packet types
ls()

# Inspect a specific layer
ls(IP)
ls(TCP)
ls(ICMP)

# Build a packet
pkt = IP(dst="192.168.1.1") / TCP(dport=80, flags="S")

# Show what you built
pkt.show()

# Send it and get a response
response = sr1(pkt, timeout=2)
response.show()

# Send a ping
ping = IP(dst="192.168.1.1") / ICMP()
reply = sr1(ping, timeout=2)
reply.show()
```

---

## Sniff packets

```python
# Sniff 10 packets on eth0
pkts = sniff(iface="eth0", count=10)

# Sniff with a filter
pkts = sniff(iface="eth0", filter="tcp port 80", count=20)

# Process packets in real time
sniff(iface="eth0", prn=lambda x: x.summary())

# Save to pcap
wrpcap("/tmp/capture.pcap", pkts)

# Load pcap
pkts = rdpcap("/tmp/capture.pcap")
```

---

## Build and send custom packets

```python
# UDP packet
pkt = IP(dst="8.8.8.8") / UDP(dport=53)
send(pkt)

# TCP handshake (SYN scan style)
pkt = IP(dst="192.168.1.1") / TCP(dport=80, flags="S")
ans, unans = sr(pkt, timeout=2)

# For each response, show the flags returned
for sent, received in ans:
    print(received.sprintf("%TCP.flags%"))
```

---

## In a Python script

```python
from scapy.all import *

# Simple port scanner
def scan_port(host, port):
    pkt = IP(dst=host) / TCP(dport=port, flags="S")
    reply = sr1(pkt, timeout=1, verbose=0)
    if reply and reply.haslayer(TCP):
        if reply[TCP].flags == "SA":   # SYN-ACK = open
            return True
    return False

for port in [22, 80, 443, 8080]:
    state = "OPEN" if scan_port("192.168.1.1", port) else "closed"
    print(f"  {port}: {state}")
```

---

## The mental model

Every network protocol is just bytes in a specific order.
Scapy lets you see and control every byte. That's it.
Once you can build any packet, you understand any protocol.

---

## Install

```bash
pip3 install scapy
# or: sudo apt install python3-scapy
```
