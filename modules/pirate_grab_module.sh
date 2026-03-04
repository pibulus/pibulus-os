#!/bin/bash
# pirate-grab deck module - Interactive torrent grabber TUI

manage_pirate_grab() {
    while true; do
        render_hud
        echo -e "$(gum style --foreground 196 '━━━ 🏴‍☠️ PIRATE GRAB ━━━')"
        gum style --foreground 245 "Search torrents for TV shows & movies. For legally owned media."

        local choice=$(tactile_choose \
            "📺 Grab a TV Show" \
            "🎬 Grab a Movie" \
            "🍩 Simpsons Goldmine" \
            "Back")

        case $choice in
            "📺 Grab a TV Show")
                local show=$(gum input --placeholder "Show name (e.g. Nirvana The Band The Show)")
                [ -z "$show" ] && continue

                local season=$(gum input --placeholder "Season number (blank for all/any)")

                local flags="--dry-run"
                [ -n "$season" ] && flags="$flags --season $season"

                echo ""
                gum style --foreground 212 "Searching..."
                python3 ~/pibulus-os/scripts/pirate_grab.py "$show" $flags --top 5 2>&1

                echo ""
                if gum confirm "Download the top result?"; then
                    local live_flags=""
                    [ -n "$season" ] && live_flags="--season $season"
                    python3 ~/pibulus-os/scripts/pirate_grab.py "$show" $live_flags 2>&1
                    play_tone "confirm"
                    echo ""
                    gum style --foreground 46 "Done! Run 'jellyfin-merge --scan' to organize."
                fi
                gum input --placeholder "Press Enter..."
                ;;

            "🎬 Grab a Movie")
                local movie=$(gum input --placeholder "Movie name (e.g. Mad Max Fury Road)")
                [ -z "$movie" ] && continue

                echo ""
                gum style --foreground 212 "Searching..."
                python3 ~/pibulus-os/scripts/pirate_grab.py "$movie" --movie --dry-run --top 5 2>&1

                echo ""
                if gum confirm "Download the top result?"; then
                    python3 ~/pibulus-os/scripts/pirate_grab.py "$movie" --movie 2>&1
                    play_tone "confirm"
                fi
                gum input --placeholder "Press Enter..."
                ;;

            "🍩 Simpsons Goldmine")
                local min_rating=$(gum input --placeholder "Min IMDb rating (default: 7.0)" --value "7.0")
                [ -z "$min_rating" ] && min_rating="7.0"

                local cache="$HOME/.cache/simpsons-goldmine/gems.json"
                if [ -f "$cache" ]; then
                    # Use cached data
                    python3 -c "
import json
gems = json.load(open('$cache'))
gems = [g for g in gems if g.get('rating', 0) >= $min_rating]
print(f'\n  SIMPSONS GOLDMINE')
print(f'  {\"=\"*45}')
print(f'  {len(gems)} episodes with rating >= $min_rating\n')
print(f'{\"S\":>5}{\"E\":>4}  {\"Rating\":>6}  Title')
print(f'{\"─\"*5}{\"─\"*4}  {\"─\"*6}  {\"─\"*35}')
for ep in gems:
    star = ' ★' if ep.get('rating',0) >= 8.0 else ''
    print(f'{ep[\"season\"]:>5}{ep[\"episode\"]:>4}  {ep.get(\"rating\",0):>6.1f}  {ep[\"title\"]}{star}')
print()
"
                else
                    gum style --foreground 226 "No cached data. Run simpsons-goldmine from Mac first."
                fi

                echo ""
                if gum confirm "Download these episodes via pirate-grab?"; then
                    gum style --foreground 212 "Downloading season by season..."
                    python3 -c "
import json, subprocess
gems = json.load(open('$cache'))
gems = [g for g in gems if g.get('rating', 0) >= $min_rating]
seasons = sorted(set(g['season'] for g in gems))
for s in seasons:
    eps = [g for g in gems if g['season'] == s]
    print(f'\n  Season {s}: {len(eps)} gems')
    # If 5+ episodes, grab whole season
    if len(eps) >= 5:
        subprocess.run(['python3', '$HOME/pibulus-os/scripts/pirate_grab.py',
                       'The Simpsons', '--season', str(s)])
    else:
        for ep in eps:
            subprocess.run(['python3', '$HOME/pibulus-os/scripts/pirate_grab.py',
                           'The Simpsons', '--season', str(s), '--episode', str(ep['episode']),
                           ])
print('\n  (Downloads queued!)')
"
                fi
                gum input --placeholder "Press Enter..."
                ;;

            "Back") return ;;
        esac
    done
}
