#!/usr/bin/env bash
# One-time cleanup of message backlog
set -euo pipefail

echo "=== Bridge System Optimization ==="
echo

BRIDGE_ROOT="${HOME}/infrastructure/agent-bridge/bridge"
BACKUP_DIR="${HOME}/backups/bridge-optimization-$(date +%Y%m%d-%H%M%S)"

echo "1. Creating backup at: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
cp -r "${BRIDGE_ROOT}/inbox" "$BACKUP_DIR/"
echo "   ✓ Backup complete"
echo

echo "2. Running auto-triage on current backlog..."
"${HOME}/devvyn-meta-project/scripts/bridge-auto-triage.sh"
echo "   ✓ Triage complete"
echo

echo "3. Analyzing remaining messages..."
HUMAN_INBOX="${BRIDGE_ROOT}/inbox/human"
REMAINING=$(find "$HUMAN_INBOX" -name "*.md" 2>/dev/null | wc -l)
echo "   Messages remaining for human review: $REMAINING"
echo

echo "4. Token efficiency analysis..."
TEMPLATE_OLD="${BRIDGE_ROOT}/_message_template.md"
TEMPLATE_NEW="${BRIDGE_ROOT}/_message_template_compact.md"

OLD_SIZE=$(wc -c < "$TEMPLATE_OLD")
NEW_SIZE=$(wc -c < "$TEMPLATE_NEW")
REDUCTION=$((100 - (NEW_SIZE * 100 / OLD_SIZE)))

echo "   Old template: $OLD_SIZE chars"
echo "   New template: $NEW_SIZE chars"
echo "   Reduction: ${REDUCTION}% per message"
echo

echo "5. Setting up recurring triage..."
cat > ~/Library/LaunchAgents/com.devvyn.bridge-triage.plist << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.devvyn.bridge-triage</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>~/devvyn-meta-project/scripts/bridge-auto-triage.sh >> ~/devvyn-meta-project/logs/triage.log 2>&1</string>
    </array>
    <key>StartInterval</key>
    <integer>900</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>/Users/devvynmurphy/devvyn-meta-project/logs/triage-errors.log</string>
    <key>StandardOutPath</key>
    <string>/Users/devvynmurphy/devvyn-meta-project/logs/triage.log</string>
</dict>
</plist>
PLIST

launchctl unload ~/Library/LaunchAgents/com.devvyn.bridge-triage.plist 2>/dev/null || true
launchctl load ~/Library/LaunchAgents/com.devvyn.bridge-triage.plist

echo "   ✓ Triage agent loaded (runs every 15 minutes)"
echo

echo "=== Optimization Complete ==="
echo
echo "Summary:"
echo "  - Backup saved to: $BACKUP_DIR"
echo "  - Token overhead reduced: ${REDUCTION}% per message"
echo "  - Auto-triage enabled: every 15 minutes"
echo "  - Human inbox reduced to: $REMAINING actionable messages"
echo
echo "Next: Review remaining messages with:"
echo "  ls -lt $HUMAN_INBOX"
