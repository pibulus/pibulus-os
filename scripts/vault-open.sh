#!/bin/bash
# 🔓 OPEN YOUR PERSONAL VAULT
# Usage: ./vault-open.sh

VAULT="/media/pibulus/passport/Perso/.vault"
MOUNT="/media/pibulus/passport/Perso/OPEN"

echo "🔐 Enter password to unlock personal vault:"
gocryptfs "$VAULT" "$MOUNT"

if [ $? -eq 0 ]; then
    echo "✅ Vault unlocked at: $MOUNT"
    echo "   (Files here are encrypted on disk but readable now)"
else
    echo "❌ Unlock failed."
fi
