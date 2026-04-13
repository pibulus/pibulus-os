#!/bin/bash
# 📚 COUNTS — library sizes for the quickcat.club signal strip
# Runs daily via cron (slow API calls / file walks, no need to hammer every minute)

MOVIE_COUNT=$(curl -s --max-time 5 "http://localhost:8096/Items?IncludeItemTypes=Movie&Recursive=true&Limit=0&api_key=1980cdafcfec43b58b04b89c4d1f5b99" 2>/dev/null | \
  python3 -c "import sys,json; print(json.load(sys.stdin).get('TotalRecordCount',0))" 2>/dev/null || echo "0")

SHOW_COUNT=$(curl -s --max-time 5 "http://localhost:8096/Items?IncludeItemTypes=Series&Recursive=true&Limit=0&api_key=1980cdafcfec43b58b04b89c4d1f5b99" 2>/dev/null | \
  python3 -c "import sys,json; print(json.load(sys.stdin).get('TotalRecordCount',0))" 2>/dev/null || echo "0")

BOOK_COUNT=$(python3 -c "import sqlite3; c=sqlite3.connect('/media/pibulus/passport/Ebooks/Calibre-Library/metadata.db'); print(c.execute('SELECT COUNT(*) FROM books').fetchone()[0])" 2>/dev/null || echo "0")

COMIC_COUNT=$(find /media/pibulus/passport/Comics -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')

ROM_COUNT=$(find /media/pibulus/passport/Roms -maxdepth 2 -type f 2>/dev/null | wc -l | tr -d ' ')

AUDIOBOOK_COUNT=$(find /media/pibulus/passport/Audiobooks -type f 2>/dev/null | wc -l | tr -d ' ')
CRATES_COUNT=$(find /media/pibulus/passport/Resources/Guitar /media/pibulus/passport/Resources/Piano "/media/pibulus/passport/Ebooks/Music Theory - eBook Collection" -type f 2>/dev/null | wc -l | tr -d ' ')
LOOPS_COUNT=$(find /media/pibulus/passport/Resources/Loops -type f 2>/dev/null | wc -l | tr -d ' ')

cat > /media/pibulus/passport/www/html/counts.json <<JSON
{
  "movies": ${MOVIE_COUNT:-0},
  "shows": ${SHOW_COUNT:-0},
  "books": ${BOOK_COUNT:-0},
  "comics": ${COMIC_COUNT:-0},
  "roms": ${ROM_COUNT:-0},
  "audiobooks": ${AUDIOBOOK_COUNT:-0},
  "crates": ${CRATES_COUNT:-0},
  "loops": ${LOOPS_COUNT:-0},
  "ts": "$(date '+%Y-%m-%d %H:%M')"
}
JSON
