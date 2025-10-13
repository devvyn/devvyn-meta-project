#!/bin/bash
# Check status of collective resource provisioning system
# Usage: ./resource-status.sh [--json]

set -euo pipefail

JSON_OUTPUT=false
if [[ "${1:-}" == "--json" ]]; then
    JSON_OUTPUT=true
fi

# Check if transmission-daemon is running
if pgrep -q transmission-daemon; then
    DAEMON_STATUS="running"
else
    DAEMON_STATUS="stopped"
fi

# Get transmission stats if running
if [[ "$DAEMON_STATUS" == "running" ]]; then
    ACTIVE_COUNT=$(transmission-remote -l 2>/dev/null | grep -v "^Sum:" | grep -v "^ID" | wc -l | tr -d ' ')
    DOWNLOADING=$(transmission-remote -l 2>/dev/null | grep -c "Downloading" || echo "0")
    SEEDING=$(transmission-remote -l 2>/dev/null | grep -c "Seeding" || echo "0")
    IDLE=$(transmission-remote -l 2>/dev/null | grep -c "Idle" || echo "0")
else
    ACTIVE_COUNT=0
    DOWNLOADING=0
    SEEDING=0
    IDLE=0
fi

# Check disk usage of shared resources
if [[ -d ~/infrastructure/shared-resources ]]; then
    DISK_USAGE=$(du -sh ~/infrastructure/shared-resources 2>/dev/null | cut -f1)
    RESOURCE_COUNT=$(find ~/infrastructure/shared-resources -maxdepth 1 -type d ! -name "shared-resources" ! -name ".incomplete" | wc -l | tr -d ' ')
else
    DISK_USAGE="N/A"
    RESOURCE_COUNT=0
fi

# Check watch folder
WATCH_FOLDER="$HOME/Music/Music/Media.localized/Automatically Add to Music.localized"
if [[ -d "$WATCH_FOLDER" ]]; then
    WATCH_COUNT=$(find "$WATCH_FOLDER" -name "*.torrent" 2>/dev/null | wc -l | tr -d ' ')
else
    WATCH_COUNT=0
fi

# Recent completions
LOG_FILE="$HOME/devvyn-meta-project/logs/torrent-completions.log"
if [[ -f "$LOG_FILE" ]]; then
    RECENT_COMPLETIONS=$(grep -c "^---" "$LOG_FILE" 2>/dev/null || echo "0")
else
    RECENT_COMPLETIONS=0
fi

if [[ "$JSON_OUTPUT" == "true" ]]; then
    cat <<EOF
{
  "daemon_status": "$DAEMON_STATUS",
  "active_torrents": $ACTIVE_COUNT,
  "downloading": $DOWNLOADING,
  "seeding": $SEEDING,
  "idle": $IDLE,
  "shared_resources": {
    "disk_usage": "$DISK_USAGE",
    "resource_count": $RESOURCE_COUNT
  },
  "watch_folder_pending": $WATCH_COUNT,
  "total_completions": $RECENT_COMPLETIONS,
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
else
    cat <<EOF
==================================================
Collective Resource Provisioning Status
==================================================

Transmission Daemon: $DAEMON_STATUS

Active Torrents: $ACTIVE_COUNT
  - Downloading: $DOWNLOADING
  - Seeding: $SEEDING
  - Idle: $IDLE

Shared Resources:
  - Location: ~/infrastructure/shared-resources/
  - Disk Usage: $DISK_USAGE
  - Resource Count: $RESOURCE_COUNT

Watch Folder:
  - Pending Torrents: $WATCH_COUNT

Total Completions: $RECENT_COMPLETIONS

Web UI: http://localhost:9091

==================================================
EOF

    if [[ "$DAEMON_STATUS" == "running" && $ACTIVE_COUNT -gt 0 ]]; then
        echo ""
        echo "Current torrents:"
        transmission-remote -l 2>/dev/null || echo "Error fetching torrent list"
    fi
fi
