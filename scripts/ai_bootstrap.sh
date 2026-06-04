#!/usr/bin/env bash
set -euo pipefail

ROOT="${PIBULUS_ROOT:-/home/pibulus/pibulus-os}"
DOCTOR_JSON="${DECK_DOCTOR_JSON:-/media/pibulus/passport/www/html/deck-doctor.json}"
DIARY="${PIBULUS_AI_DIARY:-/home/pibulus/.claude/claude_diary.md}"
MODE="text"

usage() {
  cat <<'EOF'
Usage: ai_bootstrap.sh [--json]

Read-only start-of-session context for Pi agents. No model calls. No writes.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) MODE="json" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

python3 - "$MODE" "$ROOT" "$DOCTOR_JSON" "$DIARY" <<'PY'
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

mode, root, doctor_json, diary = sys.argv[1:5]
root_path = Path(root)


def run(cmd, cwd=None):
    try:
        out = subprocess.run(
            cmd,
            cwd=cwd,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        return out.stdout.strip()
    except OSError:
        return ""


def df_line(path):
    out = run(["df", "-h", path])
    lines = out.splitlines()
    if len(lines) < 2:
        return {"path": path, "summary": "unknown"}
    cols = lines[1].split()
    if len(cols) < 6:
        return {"path": path, "summary": lines[1]}
    return {
        "path": path,
        "filesystem": cols[0],
        "size": cols[1],
        "used": cols[2],
        "avail": cols[3],
        "use_percent": cols[4],
        "mount": cols[5],
        "summary": f"{cols[4]} used, {cols[3]} free",
    }


def memory_line():
    out = run(["free", "-h"])
    mem = swap = "unknown"
    for line in out.splitlines():
        if line.startswith("Mem:"):
            cols = line.split()
            if len(cols) >= 7:
                mem = f"{cols[2]}/{cols[1]} used, {cols[6]} available"
        elif line.startswith("Swap:"):
            cols = line.split()
            if len(cols) >= 4:
                swap = f"{cols[2]}/{cols[1]} used, {cols[3]} free"
    return {"memory": mem, "swap": swap}


def git_state():
    if not (root_path / ".git").exists():
        return {"branch": "unknown", "changed": None, "recent": []}
    branch = run(["git", "branch", "--show-current"], cwd=root) or "unknown"
    status = run(["git", "status", "--porcelain"], cwd=root)
    recent = run(["git", "log", "--oneline", "-3"], cwd=root).splitlines()
    return {
        "branch": branch,
        "changed": len([line for line in status.splitlines() if line.strip()]),
        "recent": recent,
    }


def doctor_state():
    path = Path(doctor_json)
    if not path.exists():
        return {
            "status": "missing",
            "summary": "deck doctor JSON not found",
            "gateway_bootstrap": "unknown",
            "root_disk": "unknown",
            "passport_disk": "unknown",
            "repo_state": "unknown",
        }
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return {
            "status": "bad-json",
            "summary": str(exc),
            "gateway_bootstrap": "unknown",
            "root_disk": "unknown",
            "passport_disk": "unknown",
            "repo_state": "unknown",
        }
    checks = {item.get("key"): item for item in data.get("checks", [])}
    return {
        "status": data.get("status", "unknown"),
        "checked_at": data.get("checked_at"),
        "gateway_bootstrap": checks.get("gateway_bootstrap", {}).get("summary", "unknown"),
        "root_disk": checks.get("root_disk", {}).get("summary", "unknown"),
        "passport_disk": checks.get("passport_disk", {}).get("summary", "unknown"),
        "repo_state": checks.get("repo_state", {}).get("summary", "unknown"),
    }


def tool_count():
    tool = root_path / "scripts" / "agent_tools.sh"
    if not tool.exists():
        return {"available": False, "count": None}
    out = run([str(tool), "--json"])
    try:
        data = json.loads(out)
        return {"available": True, "count": data.get("count")}
    except json.JSONDecodeError:
        return {"available": True, "count": None}


def diary_headings():
    path = Path(diary)
    if not path.exists():
        return []
    headings = []
    try:
        for line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
            if line.startswith("## "):
                headings.append(line[3:].strip())
    except OSError:
        return []
    return headings[-4:]


read_order = [
    "docs/AI_COLLECTIVE_CONTEXT.md",
    "docs/AI_CONTINUITY.md",
    "docs/PIBULUS_SPIRIT.md",
    "DOCS_INDEX.md",
    "scripts/agent_tools.sh --list",
    "/media/pibulus/passport/www/html/deck-doctor.json",
]

data = {
    "ok": True,
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "host": run(["hostname"]) or "unknown",
    "root": root,
    "git": git_state(),
    "disk": {
        "root": df_line("/"),
        "passport": df_line("/media/pibulus/passport"),
    },
    "memory": memory_line(),
    "doctor": doctor_state(),
    "tools": tool_count(),
    "recent_diary_headings": diary_headings(),
    "read_order": read_order,
}

if mode == "json":
    print(json.dumps(data, indent=2))
    raise SystemExit(0)

print("PIBULUS AI BOOTSTRAP")
print(f"- host: {data['host']}")
print(f"- repo: {data['git']['branch']}, {data['git']['changed']} changed file(s)")
print(
    "- health: "
    f"doctor {data['doctor']['status']}; "
    f"root {data['disk']['root']['summary']}; "
    f"passport {data['disk']['passport']['summary']}"
)
print(f"- memory: {data['memory']['memory']}; swap {data['memory']['swap']}")
print(f"- models: {data['doctor'].get('gateway_bootstrap', 'unknown')}")
print(f"- tools: {data['tools']['count']} mapped entries")
if data["recent_diary_headings"]:
    print("- recent diary:")
    for heading in data["recent_diary_headings"]:
        print(f"  - {heading}")
print("- read order:")
for index, item in enumerate(read_order, start=1):
    print(f"  {index}. {item}")
print("- rule: live config/logs beat docs; dry-run before writes; no secrets")
PY
