#!/bin/bash
# OpenClaw Cleanup - prune old sessions and logs
# Keeps last 7 days of sessions, rotates logs

SESSIONS_DIR="$HOME/.openclaw/agents/main/sessions"
CRON_RUNS="$HOME/.openclaw/cron/runs"

# Prune session files older than 14 days
if [ -d "$SESSIONS_DIR" ]; then
  COUNT=$(find "$SESSIONS_DIR" -name "*.jsonl" -mtime +14 | wc -l)
  if [ "$COUNT" -gt 0 ]; then
    find "$SESSIONS_DIR" -name "*.jsonl" -mtime +14 -delete
    echo "$(date): Pruned $COUNT old session files"
  fi
fi

# Prune cron run logs older than 7 days
if [ -d "$CRON_RUNS" ]; then
  find "$CRON_RUNS" -name "*.jsonl" -mtime +7 -delete 2>/dev/null
fi

# Prune failed deliveries older than 7 days
if [ -d "$HOME/.openclaw/delivery-queue/failed" ]; then
  find "$HOME/.openclaw/delivery-queue/failed" -mtime +7 -delete 2>/dev/null
fi
