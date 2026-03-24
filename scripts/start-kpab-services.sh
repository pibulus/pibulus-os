#!/bin/bash
# KPAB Microservices Launcher
# Starts: mutiny (8090), shoutbox (8087)
# Run after Docker services are up

sleep 10  # wait for AzuraCast to be ready

echo "[$(date)] Starting KPAB microservices..."

python3 /media/pibulus/passport/pibulus-os/scripts/mutiny.py &
echo "Mutiny PID: $!"

python3 /media/pibulus/passport/pibulus-os/scripts/kpab_shoutbox.py &
echo "Shoutbox PID: $!"

echo "[$(date)] All KPAB microservices started"
wait
