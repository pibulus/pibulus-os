#!/bin/bash
# 📖 BISHOP'S MANIFEST GENERATOR
# Creates a lightweight index of the deck's soul.

echo "Indexing Passport drive..."
find /media/pibulus/passport -maxdepth 3 -not -path '*/.*' > ~/pibulus-os/mission-control/manifest.txt
echo "✅ Manifest updated: $(wc -l < ~/pibulus-os/mission-control/manifest.txt) items indexed."
