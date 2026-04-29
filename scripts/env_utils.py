from __future__ import annotations

import os
from pathlib import Path


def load_env_file(path: Path) -> None:
    if not path.exists():
        return
    for raw_line in path.read_text().splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("export "):
            line = line[len("export "):].strip()
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in {'"', "'"}:
            value = value[1:-1]
        os.environ.setdefault(key, value)


def load_local_env(root: str | Path | None = None) -> Path:
    if root is None:
        root = Path(os.environ.get("PIBULUS_OS_ROOT", Path(__file__).resolve().parents[1]))
    else:
        root = Path(root)
    load_env_file(Path(os.environ.get("PIBULUS_OS_ENV", root / "pibulus-os.env")))
    load_env_file(root / "config/stacks/.env")
    return root


def require_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if value:
        return value
    raise RuntimeError(f"{name} not set. Add it to pibulus-os.env or config/stacks/.env")
