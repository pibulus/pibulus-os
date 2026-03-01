#!/bin/bash
# 📥 DIGITAL SCAVENGER MODULE v2.1
# Integrated with Soulseek (slskd) and yt-dlp.

pull_media() {
    while true; do
        render_hud
        echo -e "$(gum style --foreground 51 '--- 📥 DIGITAL SCAVENGER ---')"
        local action=$(tactile_choose \
            "🎵 Soulseek (slskd)" \
            "📹 Grab Video (yt-dlp)" \
            "📻 Grab Audio (yt-dlp)" \
            "Back")

        case $action in
            "🎵 Soulseek (slskd)")
                local slsk_status=$(get_status slskd)
                echo -e "  Status: $slsk_status"
                gum style --foreground 226 "Soulseek UI: http://pibulus.local:5030"
                gum style --foreground 245 "Downloads: /media/pibulus/passport/Soulseek"
                gum input --placeholder "Press Enter to return..."
                ;;

            "📹 Grab Video (yt-dlp)")
                if ! command -v yt-dlp &>/dev/null; then
                    gum style --foreground 196 "yt-dlp not installed"
                    sleep 2
                    continue
                fi
                local url=$(gum input --placeholder "🔗 Paste Video URL...")
                if [ -n "$url" ]; then
                    local target=$(gum choose "Movies" "Shows" "Palestine" "The_Bucket")
                    [ -z "$target" ] && continue
                    DEST="$PASSPORT_ROOT/$target"
                    play_tone "confirm"
                    gum spin --spinner moon --title "Sucking bits from the ether..." -- \
                        yt-dlp -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best' \
                        -o "$DEST/%(title)s.%(ext)s" "$url"
                    if [ $? -eq 0 ]; then
                        play_tone "confirm"
                        gum style --foreground 46 "✅ Captured to $target"
                    else
                        play_tone "error"
                        gum style --foreground 196 "❌ Download failed"
                    fi
                    sleep 2
                fi
                ;;

            "📻 Grab Audio (yt-dlp)")
                if ! command -v yt-dlp &>/dev/null; then
                    gum style --foreground 196 "yt-dlp not installed"
                    sleep 2
                    continue
                fi
                local url=$(gum input --placeholder "🔗 Paste Audio URL...")
                if [ -n "$url" ]; then
                    local target=$(gum choose "Radio/Tunes" "Radio/Rants" "Radio/Jingles" "Music/Inbox")
                    [ -z "$target" ] && continue
                    DEST="$PASSPORT_ROOT/$target"
                    play_tone "confirm"
                    gum spin --spinner moon --title "Extracting frequencies..." -- \
                        yt-dlp -x --audio-format mp3 --audio-quality 0 \
                        -o "$DEST/%(title)s.%(ext)s" "$url"
                    if [ $? -eq 0 ]; then
                        play_tone "confirm"
                        gum style --foreground 46 "✅ Captured to $target"
                    else
                        play_tone "error"
                        gum style --foreground 196 "❌ Download failed"
                    fi
                    sleep 2
                fi
                ;;

            "Back") return ;;
        esac
    done
}
