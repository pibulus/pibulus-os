#!/bin/bash
# 📏 QUICK CAT CLUB - ANTENNA CALCULATOR
# Formula: 142.5 / Frequency (MHz) = Total Dipole Length in Meters

echo "--- 📡 KPAB.fm ANTENNA TOOL ---"
read -p "Enter your target frequency (MHz): " FREQ

if [[ ! $FREQ =~ ^[0-9.]+$ ]]; then
    echo "❌ Invalid frequency."
    exit 1
fi

TOTAL_METERS=$(echo "scale=3; 142.5 / $FREQ" | bc)
HALF_METERS=$(echo "scale=3; $TOTAL_METERS / 2" | bc)

echo ""
echo "✅ For $FREQ MHz:"
echo "   - Total Dipole Length: $TOTAL_METERS meters"
echo "   - Each Element Length: $HALF_METERS meters (Cut two of these)"
echo ""
echo "💡 Tip: Use RG-58 Coax cable and mount it as high as possible!"
