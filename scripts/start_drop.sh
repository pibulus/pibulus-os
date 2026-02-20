#!/bin/bash
# 📥 QUICK CAT CLUB - MODULAR DROPBOX

PORT=${1:-8888}
SUBDIR=${2:-"Incoming"}
DIR="/media/pibulus/passport/Radio/$SUBDIR"
mkdir -p "$DIR"

echo "🚀 Starting Drop on port $PORT for $SUBDIR..."
python3 -m droopy -p $PORT -d "$DIR" --dl
