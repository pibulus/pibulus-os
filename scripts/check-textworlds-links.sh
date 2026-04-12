#!/usr/bin/env bash
set -u

check_tcp() {
  local name="$1" host="$2" port="$3"
  if timeout 8 bash -c "</dev/tcp/$host/$port" >/dev/null 2>&1; then
    printf "OK   %-24s %s:%s\n" "$name" "$host" "$port"
  else
    printf "FAIL %-24s %s:%s\n" "$name" "$host" "$port"
  fi
}

echo "Textworlds network destination check"
echo

check_tcp "LORD / Red Dragon" lord.stabs.org 23
check_tcp "Fozz BBS" bbs.fozztexx.com 23
check_tcp "TW Lounge" bbs.twlounge.net 23
check_tcp "Realm of Serion" connect.serionbbs.com 23
check_tcp "ConstructiveChaos" conchaos.synchro.net 23
check_tcp "Gateway BBS" gatewaybbs.net 2023
check_tcp "NerdRage BBS" nerdragebbs.ddns.net 23

check_tcp "Aardwolf" aardmud.org 4000
check_tcp "Discworld MUD" discworld.starturtle.net 4242
check_tcp "MUME" mume.org 4242
check_tcp "Realms of Despair" realmsofdespair.com 4000
check_tcp "BatMUD" bat.org 23
check_tcp "Medievia" medievia.com 4000
check_tcp "Threshold RPG" thresholdrpg.com 3333
check_tcp "Lost Souls" lostsouls.org 23
check_tcp "Achaea" achaea.com 23

check_tcp "Telehack" telehack.com 23
check_tcp "MapSCII" mapscii.me 23
check_tcp "SSHTron" sshtron.zachlatta.com 22
check_tcp "ASCII Star Wars" towel.blinkenlights.nl 23
check_tcp "NetHack Alt.org" alt.org 23
