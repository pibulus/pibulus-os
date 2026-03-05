#\!/bin/bash
# 📀 QUICK CAT CLUB - VAULT OPS

manage_vault() {
    while true; do
        render_hud
        echo -e "$(gum style --foreground 226 '--- 📀 VAULT & RECOVERY OPS ---')"
        local action=$(tactile_choose \
            "💾 Create Golden Image" \
            "📖 Read Ship Log (Ledger)" \
            "🤖 AI Handbook" \
            "📑 Glossary" \
            "📄 Read Manifesto" \
            "Back")
        
        case $action in
            "💾 Create Golden Image")
                ~/pibulus-os/scripts/golden_image.sh
                gum input --placeholder "Press Enter to return..."
                ;;
            "📖 Read Ship Log (Ledger)") glow ~/pibulus-os/LEDGER.md || less ~/pibulus-os/LEDGER.md ;;
            "🤖 AI Handbook") glow ~/pibulus-os/AI_HANDBOOK.md || less ~/pibulus-os/AI_HANDBOOK.md ;;
            "📑 Glossary") glow ~/pibulus-os/GLOSSARY.md || less ~/pibulus-os/GLOSSARY.md ;;
            "📄 Read Manifesto")
                glow ~/pibulus-os/MANIFESTO.md || less ~/pibulus-os/MANIFESTO.md
                ;;
            "Back") return ;;
        esac
    done
}
