#!/bin/bash
# Quick Cat Club Microservices Launcher
# Starts: mutiny (8090), shoutbox (8087), dropzone (8085), wall (8086), public deck (7683)
# Run after Docker services are up

SCRIPTS=/home/pibulus/pibulus-os

sleep 10  # wait for AzuraCast to be ready

echo "[$(date)] Starting Quick Cat Club microservices..."

python3 $SCRIPTS/scripts/mutiny.py &
echo "Mutiny (8090) PID: $!"

python3 $SCRIPTS/scripts/kpab_shoutbox.py &
echo "Shoutbox (8087) PID: $!"

python3 $SCRIPTS/scripts/dropzone.py &
echo "Dropzone (8085) PID: $!"

python3 $SCRIPTS/scripts/wall_server.py &
echo "Wall Server (8086) PID: $!"

# Public Cyberdeck — no auth, sandboxed to game launcher only
/usr/local/bin/ttyd -p 7683 -t fontSize=16 -t fontFamily=monospace   -t 'theme={"background":"#050505","foreground":"#e0e0e0","cursor":"#ff00ff"}'   --max-clients 5 $SCRIPTS/public-deck.sh &
echo "Public Deck (7683) PID: $!"

echo "[$(date)] All microservices started"
wait
