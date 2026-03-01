#!/bin/bash
# 📀 QUICK CAT CLUB - VAULT & RECOVERY OPS v1.1

manage_vault() {
    while true; do
        render_hud
        echo -e "$(gum style --foreground 226 '--- 📀 VAULT & RECOVERY OPS ---')"
        local action=$(tactile_choose \
            "💾 Create Golden Image" \
            "🛡️  Run Security Audit" \
            "📖 Ship Log (Session Diary)" \
            "📖 Ledger (Changelog)" \
            "🤖 AI Handbook" \
            "📑 Glossary" \
            "📄 Manifesto" \
            "Back")

        case $action in
            "💾 Create Golden Image")
                if [ -f ~/pibulus-os/scripts/golden_image.sh ]; then
                    ~/pibulus-os/scripts/golden_image.sh
                else
                    gum style --foreground 196 "golden_image.sh not found"
                    sleep 2
                fi
                gum input --placeholder "Press Enter to return..."
                ;;
            "🛡️  Run Security Audit") run_audit ;;
            "📖 Ship Log (Session Diary)") glow ~/pibulus-os/SHIP_LOG.md 2>/dev/null || less ~/pibulus-os/SHIP_LOG.md ;;
            "📖 Ledger (Changelog)") glow ~/pibulus-os/LEDGER.md 2>/dev/null || less ~/pibulus-os/LEDGER.md ;;
            "🤖 AI Handbook") glow ~/pibulus-os/AI_HANDBOOK.md 2>/dev/null || less ~/pibulus-os/AI_HANDBOOK.md ;;
            "📑 Glossary") glow ~/pibulus-os/GLOSSARY.md 2>/dev/null || less ~/pibulus-os/GLOSSARY.md ;;
            "📄 Manifesto") glow ~/pibulus-os/MANIFESTO.md 2>/dev/null || less ~/pibulus-os/MANIFESTO.md ;;
            "Back") return ;;
        esac
    done
}
