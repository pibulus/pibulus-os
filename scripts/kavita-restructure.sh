#!/bin/bash
# kavita-restructure.sh — Restructure comics folder for Kavita series grouping
#
# Kavita expects: Library Root / Series Name / files
# This script fixes:
#   1. Flattens range subfolders (e.g., Sandman 01-56, 57-69 → all in The Sandman/)
#   2. Promotes series out of author meta-folders (Alan Moore - DC/Batman → Batman/)
#   3. Cleans scan group tags from folder names
#   4. Removes torrent junk folders
#
# Usage: kavita-restructure.sh [--execute]
#   Default: dry-run (shows what would happen)
#   --execute: actually perform the moves
#
# Run ON the Pi or via SSH

set -uo pipefail

COMICS_ROOT="/media/pibulus/passport/Comics"
DRY_RUN=true
LOG_FILE="/tmp/kavita-restructure.log"

if [[ "${1:-}" == "--execute" ]]; then
    DRY_RUN=false
    echo "⚡ EXECUTE MODE — changes will be made!"
    echo ""
else
    echo "🔍 DRY RUN — no changes will be made"
    echo "   Run with --execute to apply changes"
    echo ""
fi

# Counters
FLATTEN_COUNT=0
PROMOTE_COUNT=0
CLEAN_COUNT=0
JUNK_COUNT=0
SKIP_COUNT=0

> "$LOG_FILE"

log() {
    echo "$1"
    echo "$1" >> "$LOG_FILE"
}

safe_move() {
    local src="$1"
    local dst="$2"

    if [[ "$DRY_RUN" == true ]]; then
        log "  MOVE: $(basename "$src") → $dst"
    else
        if [[ -e "$dst" ]]; then
            log "  ⚠️  SKIP (exists): $dst"
            SKIP_COUNT=$((SKIP_COUNT + 1))
            return
        fi
        mkdir -p "$(dirname "$dst")"
        mv "$src" "$dst"
        log "  ✅ MOVED: $(basename "$src") → $dst"
    fi
}

# ═══════════════════════════════════════════════════════════
# 1. FLATTEN RANGE SUBFOLDERS
#    Moves files from range-split subdirs up to series root
# ═══════════════════════════════════════════════════════════
log "═══ PHASE 1: Flatten range subfolders ═══"
log ""

# Pattern: dirs containing parenthesized ranges like (01 - 56) or (01-56)
while IFS= read -r -d '' subdir; do
    parent="$(dirname "$subdir")"
    dirname_base="$(basename "$subdir")"

    # Skip if this is a top-level series folder (no range pattern)
    if [[ ! "$dirname_base" =~ \([0-9]+-.*[0-9]+\) && ! "$dirname_base" =~ \([0-9]+\ -\ [0-9]+\) && ! "$dirname_base" =~ \([0-9]+\ -\ [0-9]+\) ]]; then
        continue
    fi

    log "📂 Flattening: $dirname_base → $(basename "$parent")/"

    # Move all comic files up to parent
    find "$subdir" -maxdepth 1 -type f \( -name "*.cbr" -o -name "*.cbz" -o -name "*.pdf" -o -name "*.epub" \) -print0 | while IFS= read -r -d '' file; do
        safe_move "$file" "$parent/$(basename "$file")"
        FLATTEN_COUNT=$((FLATTEN_COUNT + 1))
    done

    # Remove empty subdir after flattening
    if [[ "$DRY_RUN" == false ]]; then
        rmdir "$subdir" 2>/dev/null && log "  🗑️  Removed empty dir: $dirname_base" || true
    fi

    log ""
done < <(find "$COMICS_ROOT" -mindepth 2 -maxdepth 2 -type d -print0 | sort -z)

# ═══════════════════════════════════════════════════════════
# 2. PROMOTE SERIES FROM AUTHOR META-FOLDERS
#    "Alan Moore - ABC Comics/Promethea" → "Promethea"
# ═══════════════════════════════════════════════════════════
log "═══ PHASE 2: Promote series from author meta-folders ═══"
log ""

# Known author meta-folders (detected from scan)
AUTHOR_FOLDERS=(
    "Alan Moore - ABC Comics"
    "Alan Moore - DC Comics"
    "Alan Moore - Future Shocks"
    "Alan Moore - More Moore"
    "Frank Miller - RoboCop"
)

for author_dir in "${AUTHOR_FOLDERS[@]}"; do
    full_path="$COMICS_ROOT/$author_dir"
    [[ -d "$full_path" ]] || continue

    log "👤 Promoting series from: $author_dir"

    # Move each subfolder to comics root
    find "$full_path" -mindepth 1 -maxdepth 1 -type d -print0 | while IFS= read -r -d '' series_dir; do
        series_name="$(basename "$series_dir")"
        target="$COMICS_ROOT/$series_name"

        if [[ -d "$target" ]]; then
            log "  ⚠️  CONFLICT: $series_name already exists at root — skipping"
            SKIP_COUNT=$((SKIP_COUNT + 1))
        else
            safe_move "$series_dir" "$target"
            PROMOTE_COUNT=$((PROMOTE_COUNT + 1))
        fi
    done

    # Move any stray files at author root into an "Author - Misc" folder
    stray_count=$(find "$full_path" -maxdepth 1 -type f | wc -l)
    if [[ "$stray_count" -gt 0 ]]; then
        stray_target="$COMICS_ROOT/$author_dir - Misc"
        log "  📄 Moving $stray_count stray files → $(basename "$stray_target")/"
        if [[ "$DRY_RUN" == false ]]; then
            mkdir -p "$stray_target"
            find "$full_path" -maxdepth 1 -type f -exec mv {} "$stray_target/" \;
        fi
    fi

    # Remove empty author dir
    if [[ "$DRY_RUN" == false ]]; then
        rmdir "$full_path" 2>/dev/null && log "  🗑️  Removed empty meta-folder: $author_dir" || true
    fi

    log ""
done

# ═══════════════════════════════════════════════════════════
# 3. CLEAN SCAN GROUP TAGS FROM FOLDER NAMES
#    "The Sandman (01 - 56) (Digital-Empire)" stays as-is
#    after flattening — but top-level folders with tags get cleaned
# ═══════════════════════════════════════════════════════════
log "═══ PHASE 3: Clean scan group tags from folder names ═══"
log ""

# Common scan group patterns in folder names
while IFS= read -r -d '' dir; do
    dirname_base="$(basename "$dir")"

    # Strip common scan group tags: (Digital-Empire), (Bean-Empire), (c2c), etc.
    cleaned="$dirname_base"
    cleaned=$(echo "$cleaned" | sed -E 's/ *\((Digital|Bean|Zone|Minutemen|DCP|c2c|webrip|Empire|Digital-Empire|Bean-Empire|Zone-Empire|Minutemen-InnerDemons)[^)]*\)//gi')
    # Strip trailing whitespace
    cleaned=$(echo "$cleaned" | sed 's/ *$//')

    if [[ "$cleaned" != "$dirname_base" ]]; then
        log "🏷️  Clean: '$dirname_base' → '$cleaned'"
        target="$COMICS_ROOT/$cleaned"

        if [[ -d "$target" && "$target" != "$dir" ]]; then
            log "  ⚠️  CONFLICT: '$cleaned' already exists — needs manual merge"
            SKIP_COUNT=$((SKIP_COUNT + 1))
        elif [[ "$cleaned" != "$dirname_base" ]]; then
            safe_move "$dir" "$target"
            CLEAN_COUNT=$((CLEAN_COUNT + 1))
        fi
    fi
done < <(find "$COMICS_ROOT" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

# ═══════════════════════════════════════════════════════════
# 4. REMOVE TORRENT JUNK
# ═══════════════════════════════════════════════════════════
log ""
log "═══ PHASE 4: Flag torrent junk ═══"
log ""

JUNK_PATTERNS=("_Info For Torrent Sites" "Extra bull" "Torrent downloaded from" "Thumbs.db" ".DS_Store")

for pattern in "${JUNK_PATTERNS[@]}"; do
    while IFS= read -r -d '' junk; do
        log "🗑️  Junk: $junk"
        if [[ "$DRY_RUN" == false ]]; then
            rm -rf "$junk"
        fi
        JUNK_COUNT=$((JUNK_COUNT + 1))
    done < <(find "$COMICS_ROOT" -name "$pattern" -print0 2>/dev/null)
done

# ═══════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════
log ""
log "═══════════════════════════════════════"
log "📊 SUMMARY"
log "═══════════════════════════════════════"
log "  Flattened files:    $FLATTEN_COUNT"
log "  Promoted series:    $PROMOTE_COUNT"
log "  Cleaned names:      $CLEAN_COUNT"
log "  Junk flagged:       $JUNK_COUNT"
log "  Skipped/conflicts:  $SKIP_COUNT"
log ""

if [[ "$DRY_RUN" == true ]]; then
    log "🔍 This was a DRY RUN. No changes were made."
    log "   Review above, then run with --execute to apply."
    log "   Full log saved to: $LOG_FILE"
else
    log "✅ Restructuring complete!"
    log "   Full log saved to: $LOG_FILE"
    log ""
    log "📋 NEXT STEPS:"
    log "   1. Run mary_poppins.py --pattern comics on the Comics folder to clean filenames"
    log "   2. Trigger a library scan in Kavita (Settings → Libraries → Scan)"
    log "   3. Check series grouping in the Kavita UI"
fi
