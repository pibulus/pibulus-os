#!/bin/bash
# 📥 MEDIA PULLER MODULE v1.1
# Uses yt-dlp to grab media from the ether.

pull_media() {
    clear
    figlet -f slant "PULLER" | lolcat
    echo "Where should we stash this, Captain?" | lolcat
    
    local target=$(gum choose "Radio/Tunes" "Radio/Rants" "Radio/Jingles" "Movies" "The_Bucket")
    local url=$(gum input --placeholder "🔗 Paste the URL (YouTube, SoundCloud, etc.)...")
    
    if [ ! -z "$url" ]; then
        case $target in
            "Radio/Tunes") DEST="$PASSPORT_ROOT/Radio/Tunes" ;;
            "Radio/Rants") DEST="$PASSPORT_ROOT/Radio/Rants" ;;
            "Radio/Jingles") DEST="$PASSPORT_ROOT/Radio/Jingles" ;;
            "Movies") DEST="$PASSPORT_ROOT/Movies" ;;
            "The_Bucket") DEST="$PASSPORT_ROOT/Radio/The_Bucket" ;;
        esac
        
        play_tone "confirm"
        gum spin --spinner moon --title "Extracting from the ether..." -- yt-dlp -x --audio-format mp3 -o "$DEST/%(title)s.%(ext)s" "$url"
        gum style --foreground 46 "✅ Pulled into $target"
        sleep 2
    fi
}
