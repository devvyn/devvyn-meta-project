#!/bin/bash
#
# System Health Check
# Verifies all autonomous monitoring components are operational
#
# Runs diagnostics and generates actionable recovery steps if issues detected
#

set -euo pipefail

BRIDGE_ROOT="$HOME/infrastructure/agent-bridge/bridge"
META_ROOT="$HOME/devvyn-meta-project"
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
REPORT_FILE="$HOME/Desktop/${TIMESTAMP}-0600-system-health-check.md"

# Health check results
CHECKS_PASSED=0
CHECKS_FAILED=0
CRITICAL_FAILURES=0
declare -a FAILURES
declare -a WARNINGS

log() {
    echo "[HEALTH-CHECK] $1"
}

check() {
    local name="$1"
    local command="$2"
    local critical="${3:-false}"

    if eval "$command" >/dev/null 2>&1; then
        ((CHECKS_PASSED++))
        log "✅ $name"
        return 0
    else
        ((CHECKS_FAILED++))
        FAILURES+=("$name")
        if [ "$critical" = "true" ]; then
            ((CRITICAL_FAILURES++))
            log "❌ CRITICAL: $name"
        else
            WARNINGS+=("$name")
            log "⚠️  WARNING: $name"
        fi
        return 1
    fi
}

log "Running system health diagnostics..."

# Critical infrastructure checks
check "Bridge directory exists" \
    "[ -d '$BRIDGE_ROOT' ]" \
    true

check "Bridge registry accessible" \
    "[ -f '$BRIDGE_ROOT/registry/agents.json' ]" \
    true

check "Bridge scripts accessible" \
    "[ -x '$META_ROOT/scripts/bridge-send.sh' ]" \
    true

check "Event log exists" \
    "[ -d '$BRIDGE_ROOT/events' ]" \
    true

# LaunchAgent checks
check "Unanswered queries agent loaded" \
    "launchctl list | grep -q com.devvyn.unanswered-queries"

check "INVESTIGATOR agent loaded" \
    "launchctl list | grep -q com.devvyn.investigator"

check "HOPPER monitor loaded" \
    "launchctl list | grep -q com.devvyn.hopper-monitor"

check "Bridge queue processor loaded" \
    "launchctl list | grep -q com.devvyn.bridge-queue" \
    true

# Queue health checks
PENDING_COUNT=$(ls "$BRIDGE_ROOT/queue/pending/"*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$PENDING_COUNT" -gt 10 ]; then
    ((CHECKS_FAILED++))
    WARNINGS+=("Queue depth high: $PENDING_COUNT pending messages")
    log "⚠️  Queue depth: $PENDING_COUNT messages"
else
    ((CHECKS_PASSED++))
    log "✅ Queue depth healthy: $PENDING_COUNT messages"
fi

# Inbox health checks
check "Human inbox initialized" \
    "[ -f '$HOME/inbox/status.json' ]"

check "Human inbox organizer script exists" \
    "[ -x '$META_ROOT/scripts/organize-human-inbox.sh' ]"

# Log file checks
check "Bridge queue logs exist" \
    "[ -f '$META_ROOT/logs/bridge-queue.log' ]"

# Dependency checks
check "jq available" \
    "command -v jq"

check "fd available" \
    "command -v fd"

# Recent activity checks
LAST_EVENT=$(ls -t "$BRIDGE_ROOT/events/"*.json 2>/dev/null | head -1)
if [ -n "$LAST_EVENT" ]; then
    EVENT_AGE=$(( ($(date +%s) - $(stat -f %m "$LAST_EVENT")) / 3600 ))

    if [ "$EVENT_AGE" -gt 24 ]; then
        ((CHECKS_FAILED++))
        WARNINGS+=("No events in last 24h (last event ${EVENT_AGE}h ago)")
        log "⚠️  Event log stale: ${EVENT_AGE}h since last event"
    else
        ((CHECKS_PASSED++))
        log "✅ Event log active: ${EVENT_AGE}h since last event"
    fi
else
    ((CHECKS_FAILED++))
    WARNINGS+=("No events found in event log")
    log "⚠️  Event log empty"
fi

# Generate report
{
    echo "# System Health Check Report"
    echo ""
    echo "**Generated**: $(date -Iseconds)"
    echo "**System**: Multi-Agent Autonomous Monitoring"
    echo ""
    echo "## Summary"
    echo ""
    echo "**Total Checks**: $((CHECKS_PASSED + CHECKS_FAILED))"
    echo "**Passed**: $CHECKS_PASSED ✅"
    echo "**Failed**: $CHECKS_FAILED ❌"
    echo "**Critical Failures**: $CRITICAL_FAILURES 🚨"
    echo ""

    if [ $CRITICAL_FAILURES -gt 0 ]; then
        echo "## ⚠️ CRITICAL FAILURES DETECTED"
        echo ""
        echo "System requires immediate attention. Core infrastructure compromised."
        echo ""
    fi

    if [ ${#FAILURES[@]} -gt 0 ]; then
        echo "## Failed Checks"
        echo ""
        for failure in "${FAILURES[@]}"; do
            echo "- $failure"
        done
        echo ""
    fi

    if [ ${#WARNINGS[@]} -gt 0 ]; then
        echo "## Warnings"
        echo ""
        for warning in "${WARNINGS[@]}"; do
            echo "- $warning"
        done
        echo ""
    fi

    echo "## Recovery Actions"
    echo ""

    if [ $CRITICAL_FAILURES -gt 0 ]; then
        echo "### Critical Recovery Steps"
        echo ""
        echo "1. **Verify bridge directory**:"
        echo "   \`\`\`bash"
        echo "   ls -la ~/infrastructure/agent-bridge/bridge/"
        echo "   \`\`\`"
        echo ""
        echo "2. **Check agent registry**:"
        echo "   \`\`\`bash"
        echo "   cat ~/infrastructure/agent-bridge/bridge/registry/agents.json"
        echo "   \`\`\`"
        echo ""
        echo "3. **Reload LaunchAgents**:"
        echo "   \`\`\`bash"
        echo "   launchctl unload ~/Library/LaunchAgents/com.devvyn.*.plist"
        echo "   launchctl load ~/Library/LaunchAgents/com.devvyn.*.plist"
        echo "   \`\`\`"
        echo ""
    fi

    if [ ${#WARNINGS[@]} -gt 0 ]; then
        echo "### Recommended Actions"
        echo ""

        if echo "${WARNINGS[@]}" | grep -q "Queue depth"; then
            echo "**Queue Depth High**:"
            echo "\`\`\`bash"
            echo "~/devvyn-meta-project/scripts/bridge-process-queue.sh"
            echo "\`\`\`"
            echo ""
        fi

        if echo "${WARNINGS[@]}" | grep -q "Event log"; then
            echo "**Event Log Stale**:"
            echo "\`\`\`bash"
            echo "# Trigger manual event"
            echo "~/devvyn-meta-project/scripts/append-event.sh state-change \"Health check performed\" code"
            echo "\`\`\`"
            echo ""
        fi

        if echo "${WARNINGS[@]}" | grep -q "agent loaded"; then
            echo "**LaunchAgent Not Loaded**:"
            echo "\`\`\`bash"
            echo "launchctl load ~/Library/LaunchAgents/com.devvyn.*.plist"
            echo "launchctl list | grep devvyn"
            echo "\`\`\`"
            echo ""
        fi
    fi

    echo "## System Status"
    echo ""
    echo "### LaunchAgents"
    echo "\`\`\`"
    launchctl list | grep -i devvyn || echo "No devvyn agents loaded"
    echo "\`\`\`"
    echo ""
    echo "### Queue Status"
    echo "\`\`\`"
    echo "Pending: $PENDING_COUNT messages"
    ls -lh "$BRIDGE_ROOT/queue/pending/" 2>/dev/null | tail -5 || echo "Queue empty"
    echo "\`\`\`"
    echo ""
    echo "### Recent Events"
    echo "\`\`\`"
    ls -lt "$BRIDGE_ROOT/events/"*.json 2>/dev/null | head -5 || echo "No events"
    echo "\`\`\`"
    echo ""

    if [ $CRITICAL_FAILURES -eq 0 ] && [ $CHECKS_FAILED -eq 0 ]; then
        echo "---"
        echo ""
        echo "✅ **All systems operational**"
        echo ""
        echo "Multi-agent autonomous monitoring is healthy and active."
    elif [ $CRITICAL_FAILURES -eq 0 ]; then
        echo "---"
        echo ""
        echo "⚠️ **System operational with warnings**"
        echo ""
        echo "Address warnings above to ensure optimal performance."
    else
        echo "---"
        echo ""
        echo "🚨 **SYSTEM DEGRADED - Immediate attention required**"
    fi

    echo ""
    echo "**Next Health Check**: Run manually or schedule via cron"
    echo "**Report Location**: $REPORT_FILE"

} > "$REPORT_FILE"

# Print summary
echo ""
echo "╔════════════════════════════════════════╗"
echo "║     SYSTEM HEALTH CHECK COMPLETE       ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "  Passed:   $CHECKS_PASSED ✅"
echo "  Failed:   $CHECKS_FAILED ❌"
echo "  Critical: $CRITICAL_FAILURES 🚨"
echo ""

if [ $CRITICAL_FAILURES -gt 0 ]; then
    echo "🚨 CRITICAL FAILURES - System degraded"
    echo "📄 Full report: $(basename "$REPORT_FILE")"
    open "$REPORT_FILE" 2>/dev/null || true
    exit 2
elif [ $CHECKS_FAILED -gt 0 ]; then
    echo "⚠️  Warnings detected - review recommended"
    echo "📄 Full report: $(basename "$REPORT_FILE")"
    open "$REPORT_FILE" 2>/dev/null || true
    exit 1
else
    echo "✅ All systems operational"
    # Don't create Desktop file if everything is healthy
    rm -f "$REPORT_FILE"
    exit 0
fi
