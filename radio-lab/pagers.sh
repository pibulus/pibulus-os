#!/bin/bash
# 📟 QUICK CAT CLUB - PAGER DECODER (POCSAG)

# Brunswick / Melbourne Pager Frequencies:
# 148.3375 MHz, 148.6375 MHz, 148.9875 MHz, 149.1875 MHz

echo "Tuning to Pager Frequencies..."
echo "[Plug in your Nooelec SDR now]"

rtl_fm -f 148.3375M -s 22050 -g 30 | multimon-ng -t raw -a POCSAG512 -a POCSAG1200 -a POCSAG2400 -f alpha -
