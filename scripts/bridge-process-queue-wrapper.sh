#!/bin/bash
#
# Bridge Queue Processor - Fault-Tolerant Wrapper
# Adds retry logic, error handling, and health monitoring
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROCESSOR="$SCRIPT_DIR/bridge-process-queue.sh"
LOG_DIR="$HOME/devvyn-meta-project/logs"
ERROR_LOG="$LOG_DIR/bridge-queue-wrapper-errors.log"
MAX_RETRIES=3
RETRY_DELAY=5

log() {
    echo "[$(date -Iseconds)] $1" | tee -a "$ERROR_LOG"
}

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Check if processor script exists
if [ ! -x "$PROCESSOR" ]; then
    log "ERROR: Processor script not found or not executable: $PROCESSOR"
    exit 1
fi

# Run with retry logic
attempt=1
while [ $attempt -le $MAX_RETRIES ]; do
    log "Attempt $attempt/$MAX_RETRIES"

    if "$PROCESSOR" 2>&1; then
        log "Queue processing completed successfully"
        exit 0
    else
        exit_code=$?
        log "ERROR: Processor failed with exit code $exit_code"

        if [ $attempt -lt $MAX_RETRIES ]; then
            log "Retrying in ${RETRY_DELAY}s..."
            sleep $RETRY_DELAY
            attempt=$((attempt + 1))
        else
            log "CRITICAL: All $MAX_RETRIES attempts failed"

            # Send alert to human if bridge is operational
            if [ -x "$SCRIPT_DIR/bridge-send.sh" ]; then
                ALERT_FILE="/tmp/bridge-queue-failure-$$.md"
                cat > "$ALERT_FILE" <<EOF
# Bridge Queue Processor Failure

The bridge queue processor failed after $MAX_RETRIES attempts.

## Error Details

- **Last Exit Code**: $exit_code
- **Time**: $(date -Iseconds)
- **Script**: $PROCESSOR

## Impact

Messages may not be delivered until issue is resolved.

## Recommended Actions

1. Check queue processor logs: \`tail -50 $LOG_DIR/bridge-queue-error.log\`
2. Verify bridge directory permissions: \`ls -la ~/infrastructure/agent-bridge/bridge/queue/\`
3. Check for stuck lock files: \`ls ~/infrastructure/agent-bridge/bridge/queue/processing/*.lock\`
4. Run health check: \`~/devvyn-meta-project/scripts/system-health-check.sh\`

## Recovery

\`\`\`bash
# Manual queue processing
cd ~/devvyn-meta-project/scripts
./bridge-process-queue.sh --verbose
\`\`\`
EOF

                "$SCRIPT_DIR/bridge-send.sh" monitor human CRITICAL \
                    "Bridge Queue Processor Failure" \
                    "$ALERT_FILE" 2>&1 || log "Failed to send alert message"

                rm -f "$ALERT_FILE"
            fi

            exit 1
        fi
    fi
done
