#!/usr/bin/env bash
set -euo pipefail

# Legacy compatibility wrapper for /home/pibulus/bin/bishop.
# The canonical Pi control surface is the deck launcher.
exec /home/pibulus/pibulus-os/launcher.sh "$@"
