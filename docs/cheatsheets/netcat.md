# NETCAT — The Swiss Army Knife

`nc` or `ncat`. Reads and writes raw data across network connections. Simple on the surface,
endlessly useful underneath. Every serious move eventually goes through netcat.

---

## 80/20 quickstart

```bash
# Connect to a host and port
nc 192.168.1.1 80

# Listen on a port (wait for connection)
nc -l 4444

# Send a file
nc 192.168.1.2 4444 < file.txt

# Receive a file (on the receiving end)
nc -l 4444 > received.txt

# Port scan (check if a port is open)
nc -zv 192.168.1.1 22
nc -zv 192.168.1.1 1-1024   # scan port range
```

---

## Banner grabbing (identify services)

```bash
# See what a service announces itself as
echo "" | nc -w 3 192.168.1.1 22    # SSH banner
echo "" | nc -w 3 192.168.1.1 25    # SMTP banner
printf "HEAD / HTTP/1.0\r\n\r\n" | nc 192.168.1.1 80   # HTTP headers
```

---

## Simple chat (two terminals)

```bash
# Terminal 1 — listen
nc -l 5000

# Terminal 2 — connect
nc 127.0.0.1 5000

# Now type in either window — it appears in the other
```

---

## Transfer stuff between machines without SCP

```bash
# Receiver
nc -l 9999 | tar xz

# Sender (from the machine with the files)
tar cz /path/to/dir | nc receiver-ip 9999
```

---

## Notes

- `ncat` (from nmap package) is the modern version — supports SSL, proxies, more
- `-v` verbose, `-w 3` timeout after 3 seconds, `-z` zero-I/O mode (for scanning)
- If something is listening, you can probably talk to it with netcat

---

## Install

```bash
sudo apt install ncat    # modern version (recommended)
# or: sudo apt install netcat-openbsd
```
