#\!/bin/bash
# 📚 QUICK CAT CLUB - VAULT NAVIGATOR v3.0
# The Ergonomic Spotlight.

explore_folder() {
    local folder="$1"
    local label="$2"
    render_hud
    echo -e "$(gum style --foreground 46 "--- Exploring $label ---")"
    echo "[Use arrows to browse, type to fuzzy search, Enter to view/open]"
    
    local selected=$(find "$folder" -type f 2>/dev/null | fzf --height 40% --reverse --border)
    
    if [ \! -z "$selected" ]; then
        local ext="${selected##*.}"
        case "$ext" in
            md|txt) glow "$selected" || less "$selected" ;;
            pdf) echo "📄 PDF detected. Best viewed on Web Portal." ; sleep 2 ;;
            *) echo "📁 File: $(basename "$selected")" ; gum input --placeholder "Press Enter..." ;;
        esac
    fi
}

manage_knowledge_vault() {
    while true; do
        render_hud
        echo -e "$(gum style --foreground 226 '--- 📚 VAULT NAVIGATOR ---')"
        
        local category=$(tactile_choose \
            "📖 Ebooks & Comics" \
            "🇵🇸 Palestine Archive" \
            "🛸 Conspiracy Vault" \
            "🎸 Guitar & Piano" \
            "🌐 Offline Wikipedia" \
            "🌐 Terminal Browser" \
            "🔍 Global Search" \
            "Back")
            
        case $category in
            "📖 Ebooks & Comics") explore_folder "/media/pibulus/passport/Ebooks" "Ebooks" ;;
            "🇵🇸 Palestine Archive") explore_folder "/media/pibulus/passport/Palestine" "Palestine" ;;
            "🛸 Conspiracy Vault") explore_folder "/media/pibulus/passport/Conspiracy" "Conspiracy" ;;
            "🎸 Guitar & Piano") explore_folder "/media/pibulus/passport/Guitar" "Guitar" ;;
            "🌐 Offline Wikipedia") 
                echo -e "$(gum style --foreground 46 'Wikipedia: http://pibulus.local:8083')"
                gum input --placeholder "Press Enter to return..." ;;
            "🌐 Terminal Browser") lynx http://localhost ;;
            "🔍 Global Search") explore_folder "/media/pibulus/passport/" "Global Vault" ;;
            "Back") return ;;
        esac
    done
}
