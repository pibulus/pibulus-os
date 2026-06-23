#!/usr/bin/env bash
# pi-apps — quick live status of every registered app
REG="$HOME/pibulus-os/apps-registry.json"
python3 - "$REG" <<'PY'
import json, sys, subprocess
d = json.load(open(sys.argv[1]))
print(f'{"APP":<16}{"PORT":<6}{"DOMAIN":<22}{"LOCAL":<7}STATUS')
print("-" * 60)
for n, a in sorted(d["apps"].items(), key=lambda x: x[1].get("port", 0)):
    if a.get("status") == "reserved":
        continue
    p = a.get("port"); dom = a.get("domain") or "-"
    try:
        loc = subprocess.run(
            ["curl", "-s", "-o", "/dev/null", "-w", "%{http_code}",
             "--max-time", "3", f"http://127.0.0.1:{p}/"],
            capture_output=True, text=True, timeout=5).stdout
    except Exception:
        loc = "?"
    print(f'{n:<16}{p:<6}{dom:<22}{loc:<7}{a.get("status","?")}')
PY
