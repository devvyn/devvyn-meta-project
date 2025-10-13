#!/bin/bash
# Torrent completion hook for transmission-daemon
# Called when a torrent finishes downloading
#
# Environment variables provided by transmission:
# TR_APP_VERSION, TR_TIME_LOCALTIME, TR_TORRENT_DIR, TR_TORRENT_HASH
# TR_TORRENT_ID, TR_TORRENT_NAME, TR_TORRENT_LABELS

set -euo pipefail

# Logging
LOG_DIR="$HOME/devvyn-meta-project/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/torrent-completions.log"

# Timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S%z")

# Log the completion
cat >> "$LOG_FILE" <<EOF
---
Timestamp: $TIMESTAMP
Torrent: $TR_TORRENT_NAME
Hash: $TR_TORRENT_HASH
Directory: $TR_TORRENT_DIR
---
EOF

# Generate message for bridge
MESSAGE_FILE="/tmp/torrent-complete-$TR_TORRENT_HASH.md"
cat > "$MESSAGE_FILE" <<EOF
# Resource Download Complete

## Torrent Details
- **Name**: $TR_TORRENT_NAME
- **Hash**: $TR_TORRENT_HASH
- **Location**: $TR_TORRENT_DIR/$TR_TORRENT_NAME
- **Completed**: $TIMESTAMP

## Next Steps
- Resource is available in shared-resources
- Ready for use by any agent
- Consider adding to content DAG for provenance tracking

## Usage
\`\`\`bash
# Access the resource
ls -lh "$TR_TORRENT_DIR/$TR_TORRENT_NAME"
\`\`\`
EOF

# Send notification via bridge (LOW priority - informational)
"$HOME/devvyn-meta-project/scripts/bridge-send.sh" \
  code \
  human \
  LOW \
  "Resource Downloaded: $TR_TORRENT_NAME" \
  "$MESSAGE_FILE"

# Clean up temp file
rm -f "$MESSAGE_FILE"

exit 0
