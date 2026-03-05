#!/bin/bash
# 🤖 QUICK CAT CLUB - MISSION CONTROL OPS

manage_mission_control() {
    while true; do
        render_hud
        echo -e "$(gum style --foreground 212 '--- 🤖 BISHOP MISSION CONTROL ---')"
        local action=$(tactile_choose "🚀 View Task Board" "📝 Add New Task" "📖 Open Web Dashboard" "Back")
        
        case $action in
            "🚀 View Task Board")
                echo "CURRENT OBJECTIVES:"
                cat ~/pibulus-os/mission-control/tasks.json | grep -oP '"task": "\K[^"]+'
                gum input --placeholder "Press Enter to return..."
                ;;
            "📝 Add New Task")
                local new_task=$(gum input --placeholder "What should Bishop do next? (e.g., Scan for new FM frequencies)")
                if [ \! -z "$new_task" ]; then
                    echo "{\"id\": $(date +%s), \"task\": \"$new_task\", \"assigned\": \"Bishop\", \"status\": \"Todo\"}" >> ~/pibulus-os/mission-control/tasks.json
                    gum style --foreground 46 "✅ Task Added to Bishop's Queue."
                    sleep 2
                fi
                ;;
            "📖 Open Web Dashboard")
                echo "URL: http://pibulus.local/mission-control/"
                gum input --placeholder "Press Enter to return..."
                ;;
            "Back") return ;;
        esac
    done
}
