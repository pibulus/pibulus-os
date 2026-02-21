#!/bin/bash
# 🔒 CLOSE YOUR PERSONAL VAULT
# Usage: ./vault-close.sh

MOUNT="/media/pibulus/passport/Perso/OPEN"

echo "🔒 Locking vault..."
fusermount -u "$MOUNT"

if [ $? -eq 0 ]; then
    echo "✅ Vault locked. Access denied."
else
    echo "⚠️ Lock failed. Is it busy?"
fi
