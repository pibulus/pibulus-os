# 🧠 Knowledge Vault Download Manager

VAULT_ROOT="/media/pibulus/passport/Knowledge-Vault"

manage_knowledge_vault() {
    while true; do
        render_hud
        
        # Check download session status
        local session_status="🔴 Stopped"
        if tmux has-session -t knowledge-vault 2>/dev/null; then
            session_status="🟢 Running"
        fi
        
        # Check vault size
        local vault_size="0B"
        if [ -d "$VAULT_ROOT" ]; then
            vault_size=$(du -sh "$VAULT_ROOT" 2>/dev/null | cut -f1)
        fi
        
        echo -e "$(gum style --foreground 46 "--- 🧠 KNOWLEDGE VAULT MANAGER ---")"
        echo -e "$(gum style --foreground 226 "Status: $session_status  |  Size: $vault_size")"
        echo ""
        
        local action=$(tactile_choose \
            "🚀 Start Full Vault Download" \
            "📊 Monitor Downloads" \
            "📁 Browse Categories" \
            "⚡ Quick Downloads" \
            "🛑 Stop Downloads" \
            "📝 View Log" \
            "🗑️  Clear Vault" \
            "Back")
        
        case $action in
            "🚀 Start Full Vault Download")
                play_tone "confirm"
                if tmux has-session -t knowledge-vault 2>/dev/null; then
                    gum style --foreground 226 "⚠️  Download session already running!"
                    gum style --foreground 46 "Use 'Monitor Downloads' to watch progress"
                else
                    gum style --foreground 46 "🚀 Starting autonomous knowledge vault downloads..."
                    gum style --foreground 226 "Categories: Practical, Esoteric, Music, Culture, Security"
                    gum style --foreground 226 "Total: ~850GB (will take several days)"
                    echo ""
                    if gum confirm "Start downloads in background?"; then
                        bash "$SCRIPT_DIR/scripts/knowledge-vault-downloader.sh"
                        sleep 2
                        gum style --foreground 46 "✅ Downloads started in tmux session 'knowledge-vault'"
                        gum style --foreground 226 "Use 'Monitor Downloads' to watch progress"
                    fi
                fi
                gum input --placeholder "Press Enter to continue..."
                ;;
                
            "📊 Monitor Downloads")
                play_tone "confirm"
                if tmux has-session -t knowledge-vault 2>/dev/null; then
                    gum style --foreground 46 "📊 Attaching to download session..."
                    gum style --foreground 226 "Press Ctrl+B then D to detach"
                    sleep 2
                    tmux attach -t knowledge-vault
                else
                    gum style --foreground 226 "⚠️  No download session running"
                    gum input --placeholder "Press Enter to continue..."
                fi
                ;;
                
            "📁 Browse Categories")
                play_tone "confirm"
                render_hud
                echo -e "$(gum style --foreground 46 '--- 📁 VAULT CATEGORIES ---')"
                
                if [ -d "$VAULT_ROOT" ]; then
                    for dir in "$VAULT_ROOT"/*; do
                        if [ -d "$dir" ]; then
                            local size=$(du -sh "$dir" 2>/dev/null | cut -f1)
                            local count=$(find "$dir" -type f 2>/dev/null | wc -l)
                            echo "$(basename "$dir"): $size ($count files)"
                        fi
                    done
                else
                    echo "Vault not initialized yet"
                fi
                
                echo ""
                gum input --placeholder "Press Enter to continue..."
                ;;
                
            "⚡ Quick Downloads")
                play_tone "confirm"
                render_hud
                echo -e "$(gum style --foreground 46 '--- ⚡ QUICK DOWNLOADS ---')"
                
                local quick=$(tactile_choose \
                    "📚 Simple Wikipedia (5GB)" \
                    "🎸 Guitar Tabs (577MB)" \
                    "📖 Music Theory (2GB)" \
                    "🔮 Occult Starter Pack (5GB)" \
                    "🤖 Hacking Basics (1GB)" \
                    "Back")
                
                case $quick in
                    "📚 Simple Wikipedia (5GB)")
                        mkdir -p "$VAULT_ROOT/Practical"
                        cd "$VAULT_ROOT/Practical"
                        gum spin --spinner moon --title "Downloading Simple Wikipedia..." -- \
                            aria2c -x 16 -s 16 https://download.kiwix.org/zim/wikipedia/wikipedia_en_simple_all_maxi_2025-01.zim
                        gum style --foreground 46 "✅ Downloaded!"
                        ;;
                    "🎸 Guitar Tabs (577MB)")
                        mkdir -p "$VAULT_ROOT/Music"
                        cd "$VAULT_ROOT/Music"
                        gum spin --spinner moon --title "Downloading Guitar Tabs..." -- \
                            ~/.local/bin/ia download guitar-chords-and-tabs --no-directories
                        gum style --foreground 46 "✅ Downloaded!"
                        ;;
                    "📖 Music Theory (2GB)")
                        mkdir -p "$VAULT_ROOT/Music"
                        cd "$VAULT_ROOT/Music"
                        gum spin --spinner moon --title "Downloading Music Theory..." -- \
                            ~/.local/bin/ia download MusicTheoryGeorgeThaddeusJones1974 --no-directories
                        gum style --foreground 46 "✅ Downloaded!"
                        ;;
                    "🔮 Occult Starter Pack (5GB)")
                        mkdir -p "$VAULT_ROOT/Esoteric"
                        cd "$VAULT_ROOT/Esoteric"
                        gum spin --spinner moon --title "Downloading 340 Occult Books..." -- \
                            ~/.local/bin/ia download 340freeoccultbooks --no-directories
                        gum style --foreground 46 "✅ Downloaded!"
                        ;;
                    "🤖 Hacking Basics (1GB)")
                        mkdir -p "$VAULT_ROOT/Security"
                        cd "$VAULT_ROOT/Security"
                        gum spin --spinner moon --title "Downloading Pentesting Collection..." -- \
                            ~/.local/bin/ia download gray-hat-hacking-the-ethical-hackers-handbook-pdfdrive --no-directories
                        gum style --foreground 46 "✅ Downloaded!"
                        ;;
                esac
                [ "$quick" != "Back" ] && gum input --placeholder "Press Enter to continue..."
                ;;
                
            "🛑 Stop Downloads")
                play_tone "confirm"
                if tmux has-session -t knowledge-vault 2>/dev/null; then
                    if gum confirm "Stop all downloads?"; then
                        tmux kill-session -t knowledge-vault
                        pkill -f aria2c
                        pkill -f transmission-cli
                        gum style --foreground 46 "✅ Downloads stopped"
                    fi
                else
                    gum style --foreground 226 "⚠️  No download session running"
                fi
                gum input --placeholder "Press Enter to continue..."
                ;;
                
            "📝 View Log")
                play_tone "confirm"
                if [ -f "$VAULT_ROOT/download-log.txt" ]; then
                    less "$VAULT_ROOT/download-log.txt"
                else
                    gum style --foreground 226 "⚠️  No log file found"
                    gum input --placeholder "Press Enter to continue..."
                fi
                ;;
                
            "🗑️  Clear Vault")
                play_tone "confirm"
                if [ -d "$VAULT_ROOT" ]; then
                    local size=$(du -sh "$VAULT_ROOT" 2>/dev/null | cut -f1)
                    gum style --foreground 226 "⚠️  WARNING: This will delete $size of data!"
                    if gum confirm "Are you absolutely sure?"; then
                        rm -rf "$VAULT_ROOT"
                        gum style --foreground 46 "✅ Vault cleared"
                    fi
                else
                    gum style --foreground 226 "⚠️  Vault doesn't exist"
                fi
                gum input --placeholder "Press Enter to continue..."
                ;;
                
            "Back")
                return
                ;;
        esac
    done
}
