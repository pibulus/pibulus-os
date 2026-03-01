#!/bin/bash
# 📚 QUICK CAT CLUB - VAULT NAVIGATOR v3.1

explore_folder() {
    local folder="$1"
    local label="$2"
    render_hud
    echo -e "$(gum style --foreground 46 "--- Exploring $label ---")"
    echo -e "$(gum style --foreground 245 '[arrows to browse, type to search, Enter to view]')"

    local selected=$(find "$folder" -type f 2>/dev/null | fzf --height 40% --reverse --border --prompt="$label > ")

    if [ -n "$selected" ]; then
        local ext="${selected##*.}"
        case "$ext" in
            md|txt) glow "$selected" 2>/dev/null || less "$selected" ;;
            pdf) gum style --foreground 226 "📄 PDF: $(basename "$selected") — best viewed on web portal." ; sleep 2 ;;
            epub) gum style --foreground 226 "📖 EPUB: $(basename "$selected") — open via Calibre-Web." ; sleep 2 ;;
            jpg|jpeg|png|gif) gum style --foreground 226 "🖼️  Image: $(basename "$selected")" ; sleep 2 ;;
            *) echo "📁 $(basename "$selected") ($(du -h "$selected" 2>/dev/null | cut -f1))" ; gum input --placeholder "Press Enter..." ;;
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
                gum style --foreground 46 "Wikipedia (Kiwix): http://pibulus.local:8084"
                gum input --placeholder "Press Enter to return..." ;;
            "🌐 Terminal Browser")
                if command -v lynx &>/dev/null; then lynx http://localhost
                else gum style --foreground 196 "lynx not installed"; sleep 2; fi
                ;;
            "🔍 Global Search") explore_folder "/media/pibulus/passport/" "Global Vault" ;;
            "Back") return ;;
        esac
    done
}
