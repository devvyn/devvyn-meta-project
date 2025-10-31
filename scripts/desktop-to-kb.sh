#!/bin/bash
# Desktop to Knowledge Base Triage Script
# Helps organize Desktop markdown files into proper KB structure

set -euo pipefail

DESKTOP="$HOME/Desktop"
KB_ROOT="$HOME/devvyn-meta-project/knowledge-base"
INBOX="$HOME/inbox"

usage() {
    echo "Usage: $0 [--interactive|--auto|--dry-run]"
    echo ""
    echo "Modes:"
    echo "  --interactive  Ask for each file (default)"
    echo "  --auto         Auto-categorize based on filename patterns"
    echo "  --dry-run      Show what would happen without moving files"
    exit 1
}

MODE="${1:---interactive}"

# Categorization patterns
categorize_file() {
    local filename="$1"

    # Pattern matching for auto-categorization
    case "$filename" in
        *phase*|*completion*|*summary*)
            echo "project-management"
            ;;
        *pattern*|*architecture*|*design*)
            echo "architecture"
            ;;
        *guide*|*howto*|*tutorial*)
            echo "guides"
            ;;
        *config*|*setup*|*install*)
            echo "configuration"
            ;;
        *platform*|*dependency*|*porting*)
            echo "platform"
            ;;
        *session*|*daily*|*check-in*)
            echo "sessions"
            ;;
        *)
            echo "uncategorized"
            ;;
    esac
}

process_interactive() {
    local file="$1"
    local basename=$(basename "$file")
    local suggested=$(categorize_file "$basename")

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "File: $basename"
    echo "Suggested category: $suggested"
    echo ""
    echo "Options:"
    echo "  1) Move to KB: coordination-system/$suggested"
    echo "  2) Move to inbox (for later processing)"
    echo "  3) Archive (move to archive, rarely accessed)"
    echo "  4) Delete (remove permanently)"
    echo "  5) Skip (leave on Desktop)"
    echo "  6) Custom location"
    echo ""
    read -p "Choice [1-6]: " choice

    case "$choice" in
        1)
            mkdir -p "$KB_ROOT/coordination-system/$suggested"
            mv "$file" "$KB_ROOT/coordination-system/$suggested/"
            echo "✅ Moved to KB: coordination-system/$suggested/"
            ;;
        2)
            mkdir -p "$INBOX"
            mv "$file" "$INBOX/"
            echo "✅ Moved to inbox for processing"
            ;;
        3)
            mkdir -p "$HOME/Archive/desktop-docs"
            mv "$file" "$HOME/Archive/desktop-docs/"
            echo "✅ Archived"
            ;;
        4)
            read -p "Confirm delete '$basename'? [y/N]: " confirm
            if [[ "$confirm" == "y" ]]; then
                rm "$file"
                echo "✅ Deleted"
            else
                echo "⏭️  Skipped deletion"
            fi
            ;;
        5)
            echo "⏭️  Skipped"
            ;;
        6)
            read -p "Enter destination path: " dest
            mkdir -p "$dest"
            mv "$file" "$dest/"
            echo "✅ Moved to $dest"
            ;;
        *)
            echo "⚠️  Invalid choice, skipping"
            ;;
    esac
}

process_auto() {
    local file="$1"
    local basename=$(basename "$file")
    local category=$(categorize_file "$basename")

    mkdir -p "$KB_ROOT/coordination-system/$category"

    if [[ "$MODE" == "--dry-run" ]]; then
        echo "[DRY RUN] Would move: $basename → KB/coordination-system/$category/"
    else
        mv "$file" "$KB_ROOT/coordination-system/$category/"
        echo "✅ Moved: $basename → KB/coordination-system/$category/"
    fi
}

# Main processing
echo "🗂️  Desktop to Knowledge Base Triage"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Find markdown files on Desktop
mapfile -t md_files < <(find "$DESKTOP" -maxdepth 1 -name "*.md" -type f)

if [ ${#md_files[@]} -eq 0 ]; then
    echo "✨ No markdown files found on Desktop!"
    exit 0
fi

echo "Found ${#md_files[@]} markdown files on Desktop"
echo ""

case "$MODE" in
    --interactive)
        for file in "${md_files[@]}"; do
            process_interactive "$file"
        done
        ;;
    --auto|--dry-run)
        for file in "${md_files[@]}"; do
            process_auto "$file"
        done
        ;;
    *)
        usage
        ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Triage complete!"
echo ""
echo "Knowledge Base: $KB_ROOT"
echo "View KB index: cat $KB_ROOT/coordination-system/KB-INDEX.md"
