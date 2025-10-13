#!/bin/bash
#
# Unanswered Queries Monitor - Fault-Tolerant Wrapper
# Prevents failures from halting monitoring
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONITOR="$SCRIPT_DIR/unanswered-queries-monitor.sh"
LOG_DIR="$HOME/devvyn-meta-project/logs"
ERROR_LOG="$LOG_DIR/unanswered-queries-wrapper-errors.log"

log() {
    echo "[$(date -Iseconds)] $1" | tee -a "$ERROR_LOG"
}

mkdir -p "$LOG_DIR"

if [ ! -x "$MONITOR" ]; then
    log "ERROR: Monitor script not found: $MONITOR"
    exit 1
fi

# Run monitor with error isolation
if "$MONITOR" 2>&1; then
    log "Unanswered queries monitoring completed"
    exit 0
else
    exit_code=$?
    log "WARNING: Monitor exited with code $exit_code (non-critical)"

    # Don't block system operation - log and continue
    # This prevents one failing monitor from halting entire system
    exit 0
fi
