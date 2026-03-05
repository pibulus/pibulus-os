#!/bin/bash
# 📥 DIGITAL SCAVENGER MODULE v2.0
# Integrated with Soulseek (slskd) and yt-dlp.

pull_media() {
    while true; do
        render_hud
        echo -e "$(gum style --foreground 51 '--- 📥 DIGITAL SCAVENGER ---')"
        local action=$(tactile_choose "🎵 Soulseek (slskd)" "📹 Grab Video (yt-dlp)" "📻 Grab Audio (yt-dlp)" "Back")
        
        case $action in
            "🎵 Soulseek (slskd)")
                echo -e "$(gum style --foreground 226 'Soulseek Web Interface: http://pibulus.local:5030')"
                echo -e "$(gum style --foreground 46 'Stashing in: /media/pibulus/passport/Soulseek')"
                gum input --placeholder "Press Enter to return..."
                ;;
                
            "📹 Grab Video (yt-dlp)")
                local url=$(gum input --placeholder "🔗 Paste Video URL (YouTube, etc.)...")
                if [ ! -z "$url" ]; then
                    local target=$(gum choose "Movies" "Shows" "Palestine" "The_Bucket")
                    DEST="$PASSPORT_ROOT/$target"
                    play_tone "confirm"
                    gum spin --spinner moon --title "Sucking bits from the ether..." -- \
                        yt-dlp -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best' \
                        -o "$DEST/%(title)s.%(ext)s" "$url"
                    gum style --foreground 46 "✅ Captured to $target"
                    sleep 2
                fi
                ;;
                
            "📻 Grab Audio (yt-dlp)")
                local url=$(gum input --placeholder "🔗 Paste Audio URL (SoundCloud, YouTube, etc.)...")
                if [ ! -z "$url" ]; then
                    local target=$(gum choose "Radio/Tunes" "Radio/Rants" "Radio/Jingles" "Music/Inbox")
                    DEST="$PASSPORT_ROOT/$target"
                    play_tone "confirm"
                    gum spin --spinner moon --title "Extracting frequencies..." -- \
                        yt-dlp -x --audio-format mp3 --audio-quality 0 \
                        -o "$DEST/%(title)s.%(ext)s" "$url"
                    gum style --foreground 46 "✅ Captured to $target"
                    sleep 2
                fi
                ;;
                
            "Back")
                return
                ;;
        esac
    done
}
