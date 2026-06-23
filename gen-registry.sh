#!/usr/bin/env bash
# Regenerate REGISTRY.md (human view) from apps-registry.json (source of truth).
# Also doubles as `pi-apps` quick status when run with --status (live-checks ports).
set -euo pipefail
REG="$HOME/pibulus-os/apps-registry.json"
OUT="$HOME/pibulus-os/REGISTRY.md"

python3 - "$REG" "$OUT" <<'PY'
import json, sys, subprocess
reg = json.load(open(sys.argv[1]))
apps = reg["apps"]
rows = sorted(apps.items(), key=lambda kv: kv[1].get("port", 0))
lines = ["# Pibulus OS — Deployed Apps Registry",
         "",
         f"> Source of truth: `apps-registry.json`. Tunnel `{reg['tunnel']}`. Ports `{reg['port_range']}`.",
         "> Regenerate this file: `bash ~/pibulus-os/gen-registry.sh`",
         "",
         "| Port | App | Domain | Status | Repo |",
         "|------|-----|--------|--------|------|"]
for name, a in rows:
    lines.append(f"| {a.get('port','?')} | {name} | {a.get('domain') or '—'} | {a.get('status','?')} | {a.get('repo','—')} |")
lines += ["", f"_{len(apps)} entries. Next free port: " +
          str(next(p for p in range(9001,9099) if p not in {x.get('port') for x in apps.values()})) + "_"]
open(sys.argv[2],"w").write("\n".join(lines)+"\n")
print(f"wrote {sys.argv[2]} ({len(apps)} apps)")
PY
