#!/bin/bash
# 🤖 QUICK CAT CLUB - MISSION CONTROL OPS v1.1

manage_mission_control() {
    local TASKS_FILE="$HOME/pibulus-os/mission-control/tasks.json"

    # Ensure tasks file exists and is valid JSON
    if [ ! -f "$TASKS_FILE" ]; then
        echo '[]' > "$TASKS_FILE"
    fi

    while true; do
        render_hud
        echo -e "$(gum style --foreground 212 '--- 🤖 MISSION CONTROL ---')"
        local action=$(tactile_choose \
            "🚀 View Task Board" \
            "📝 Add New Task" \
            "✅ Complete a Task" \
            "🗑️  Clear Completed" \
            "Back")

        case $action in
            "🚀 View Task Board")
                echo ""
                gum style --foreground 226 "ACTIVE OBJECTIVES:"
                echo ""
                python3 -c "
import json, sys
try:
    tasks = json.load(open('$TASKS_FILE'))
    if not tasks:
        print('  (No tasks. The board is empty.)')
    for t in tasks:
        status = t.get('status', 'Todo')
        icon = '🔲' if status == 'Todo' else '🟡' if status == 'In Progress' else '✅'
        print(f'  {icon} {t[\"task\"]}  ({status})')
except Exception as e:
    print(f'  Error reading tasks: {e}')
" 2>/dev/null
                echo ""
                gum input --placeholder "Press Enter to return..."
                ;;

            "📝 Add New Task")
                local new_task=$(gum input --placeholder "What needs doing?")
                if [ -n "$new_task" ]; then
                    # Properly append to JSON array using python
                    python3 -c "
import json, time
tasks = json.load(open('$TASKS_FILE'))
tasks.append({'id': int(time.time()), 'task': '''$new_task'''.replace(\"'''\", ''), 'assigned': 'Bishop', 'status': 'Todo'})
json.dump(tasks, open('$TASKS_FILE', 'w'), indent=2)
" 2>/dev/null
                    play_tone "confirm"
                    gum style --foreground 46 "✅ Task added to the board."
                    sleep 1
                fi
                ;;

            "✅ Complete a Task")
                local tasks=$(python3 -c "
import json
tasks = json.load(open('$TASKS_FILE'))
for i, t in enumerate(tasks):
    if t.get('status') != 'Done':
        print(f'{i}|{t[\"task\"]}')
" 2>/dev/null)
                if [ -z "$tasks" ]; then
                    gum style --foreground 245 "No open tasks."
                    sleep 1
                    continue
                fi
                local pick=$(echo "$tasks" | cut -d'|' -f2 | gum choose)
                if [ -n "$pick" ]; then
                    python3 -c "
import json
tasks = json.load(open('$TASKS_FILE'))
for t in tasks:
    if t['task'] == '''$pick'''.replace(\"'''\", ''):
        t['status'] = 'Done'
json.dump(tasks, open('$TASKS_FILE', 'w'), indent=2)
" 2>/dev/null
                    play_tone "confirm"
                    gum style --foreground 46 "Task completed."
                    sleep 1
                fi
                ;;

            "🗑️  Clear Completed")
                python3 -c "
import json
tasks = json.load(open('$TASKS_FILE'))
remaining = [t for t in tasks if t.get('status') != 'Done']
removed = len(tasks) - len(remaining)
json.dump(remaining, open('$TASKS_FILE', 'w'), indent=2)
print(f'Cleared {removed} completed task(s).')
" 2>/dev/null
                sleep 1
                ;;

            "Back") return ;;
        esac
    done
}
