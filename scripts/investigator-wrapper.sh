#!/bin/bash
#
# INVESTIGATOR Agent - Fault-Tolerant Wrapper
# Isolates failures, prevents hanging
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INVESTIGATOR="$SCRIPT_DIR/investigator-session.sh"
LOG_DIR="$HOME/devvyn-meta-project/logs"
ERROR_LOG="$LOG_DIR/investigator-wrapper-errors.log"
TIMEOUT=300  # 5 minutes max

log() {
    echo "[$(date -Iseconds)] $1" | tee -a "$ERROR_LOG"
}

mkdir -p "$LOG_DIR"

if [ ! -x "$INVESTIGATOR" ]; then
    log "ERROR: INVESTIGATOR script not found: $INVESTIGATOR"
    exit 1
fi

log "Starting INVESTIGATOR session with ${TIMEOUT}s timeout"

# Run with timeout to prevent hanging
if timeout $TIMEOUT "$INVESTIGATOR" 2>&1; then
    log "INVESTIGATOR session completed"
    exit 0
else
    exit_code=$?

    if [ $exit_code -eq 124 ]; then
        log "WARNING: INVESTIGATOR timed out after ${TIMEOUT}s"
    else
        log "WARNING: INVESTIGATOR exited with code $exit_code"
    fi

    # Non-critical - don't block system
    exit 0
fi
