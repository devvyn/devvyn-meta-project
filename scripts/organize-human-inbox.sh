#!/bin/bash
#
# Human Inbox Organizer
# Moves Desktop reports to structured inbox with status tracking
#
# This solves the Desktop overflow problem by creating accountability loops
#

set -euo pipefail

DESKTOP="$HOME/Desktop"
INBOX="$HOME/inbox"
STATUS_FILE="$INBOX/status.json"

log() {
    echo "[INBOX-ORGANIZER] $1"
}

# Initialize status tracking if doesn't exist
if [[ ! -f "$STATUS_FILE" ]]; then
    cat > "$STATUS_FILE" <<'EOF'
{
  "last_updated": "",
  "documents": {}
}
EOF
fi

# Categorize report types
categorize_report() {
    local filename="$1"

    case "$filename" in
        *investigator-session-report*)
            echo "investigator"
            ;;
        *unanswered-queries-report*)
            echo "queries"
            ;;
        *orchestration*|*technical-feasibility*)
            echo "architecture"
            ;;
        *bridge-registry*|*bridge-*implementation*)
            echo "infrastructure"
            ;;
        *hopper*|*pattern*)
            echo "patterns"
            ;;
        *story*|*inter-subjective*)
            echo "knowledge"
            ;;
        *)
            echo "general"
            ;;
    esac
}

# Determine priority/urgency
get_priority() {
    local filename="$1"
    local file_path="$2"

    # Check file modification time - if less than 7 days old, mark as pending
    if [[ -f "$file_path" ]]; then
        local file_age=$(($(date +%s) - $(stat -f %m "$file_path")))
        local days_old=$((file_age / 86400))

        if [[ $days_old -le 7 ]]; then
            echo "pending"
        else
            echo "archived"
        fi
    else
        # Fallback: try to parse date from filename
        if [[ "$filename" =~ 20251[01][0-9][0-9] ]]; then
            echo "pending"
        else
            echo "archived"
        fi
    fi
}

MOVED=0
ARCHIVED=0

log "Organizing Desktop reports..."

# Process all markdown files
shopt -s nullglob
for file in "$DESKTOP"/*.md; do
    [[ -f "$file" ]] || continue

    filename=$(basename "$file")
    category=$(categorize_report "$filename")
    priority=$(get_priority "$filename" "$file")

    # Determine destination
    if [[ "$priority" == "pending" ]]; then
        DEST="$INBOX/pending/$category"
        mkdir -p "$DEST"
        mv "$file" "$DEST/"
        MOVED=$((MOVED + 1))

        # Add to status tracking
        TEMP_STATUS=$(mktemp)
        jq --arg file "$filename" \
           --arg cat "$category" \
           --arg status "pending" \
           --arg moved "$(date -Iseconds)" \
           '.documents[$file] = {
               category: $cat,
               status: $status,
               moved_to_inbox: $moved,
               read: false,
               responded: false
           } | .last_updated = $moved' \
           "$STATUS_FILE" > "$TEMP_STATUS"
        mv "$TEMP_STATUS" "$STATUS_FILE"

        log "→ pending/$category/$filename"
    else
        DEST="$INBOX/archived/$category"
        mkdir -p "$DEST"
        mv "$file" "$DEST/"
        ARCHIVED=$((ARCHIVED + 1))
        log "→ archived/$category/$filename"
    fi
done

log "✅ Organization complete: $MOVED to pending, $ARCHIVED archived"

# Generate inbox summary
cat > "$INBOX/README.md" <<'EOF'
# Human Inbox

Your personal accountability system for agent-generated reports.

## Directory Structure

```
~/inbox/
├── pending/          # Reports requiring your review
│   ├── investigator/ # INVESTIGATOR session reports
│   ├── queries/      # Unanswered queries monitoring
│   ├── architecture/ # Technical feasibility & design
│   ├── infrastructure/ # System implementation reports
│   ├── patterns/     # Pattern adoption & HOPPER reports
│   └── knowledge/    # Knowledge base & story system
├── in-progress/      # Currently reviewing
├── completed/        # Read & responded
└── archived/         # Older reports for reference
```

## Workflow

### 1. Review Pending
```bash
ls -lh ~/inbox/pending/*/
```

### 2. Mark as Read
```bash
~/devvyn-meta-project/scripts/inbox-status.sh mark-read <filename>
```

### 3. Move to In-Progress
```bash
mv ~/inbox/pending/*/<file> ~/inbox/in-progress/
```

### 4. After Action, Mark Complete
```bash
~/devvyn-meta-project/scripts/inbox-status.sh mark-complete <filename>
mv ~/inbox/in-progress/<file> ~/inbox/completed/
```

## Check Status
```bash
~/devvyn-meta-project/scripts/inbox-status.sh summary
```

## Integration

- HOPPER agent manages Desktop → Inbox automatically
- Unanswered queries monitor checks inbox age
- Reports older than 7 days get escalated

EOF

log "📄 Inbox README created"
log "📊 Status tracking: $STATUS_FILE"

exit 0
