# 📻 THE RADIO LAB
### Quick Cat Club - Signals Intelligence & Broadcasting

This is your workspace for RF (Radio Frequency) experimentation. 

## 🛠️ GEAR LIST
- **Receiver:** Nooelec NESDR SMArt v5
- **Transmitter:** [Awaiting 0.5W LPFM Transmitter]
- **Antenna:** Tuned Dipole (Target: Brunswick coverage)

## 📜 SOP (Standard Operating Procedure)
1. **Listen First:** Always scan the band before broadcasting.
2. **Find the Silence:** Use `scan_fm.sh` to find the frequency with the lowest Noise Floor.
3. **Check Harmonics:** Use the SDR to monitor your own FM transmitter to ensure you aren't leaking signal onto other bands.
4. **Stay Low:** Use the minimum power needed to reach your target.

## 🛰️ PROJECTS
- [ ] **FM Pirate Station:** Neighborhood broadcast.
- [ ] **ADS-B Tracker:** Track aircraft over Melbourne.
- [ ] **NOAA Weather:** Pull images from satellites.
- [ ] **Pagers:** Decode local POCSAG pager traffic (for the aesthetic).

