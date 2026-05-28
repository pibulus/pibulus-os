# Quick Audit Commands

Use these when you need to remember what the Pi is doing.

## Running Containers

```bash
docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"
docker stats --no-stream
```

## Running Custom Services

```bash
systemctl list-units --type=service --state=running --all
```

Useful filters:

```bash
systemctl list-units --type=service --state=running --all | rg "talktype|ziplist|riffrap|qrbuddy|project|button|hexbloop|spellbreak|stargram|rain|cloudflared"
```

## Public Hostnames

```bash
sudo sed -n '/ingress:/,$p' /etc/cloudflared/config.yml
```

Do not paste secrets into notes.

## Listening Ports

```bash
ss -tulpn
```

## Recent Tunnel Errors

```bash
journalctl -u cloudflared --since "24 hours ago" --no-pager | rg -i "error|warn|failed|timeout"
```

## Before Bunny-ing Something

Ask:

- is it public?
- is it file-like/static?
- would stale content be okay?
- would it be okay if a stranger got the same response?
- can we undo it in five minutes?

If yes, try it.

If no, bypass it.
