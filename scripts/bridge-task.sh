#!/bin/bash
# Bridge Task Script - GPT Integration
# Processes tasks from bridge inbox

BRIDGE_ROOT="/Users/devvynmurphy/infrastructure/agent-bridge/bridge"
AGENT_TYPE="${1:-gpt}"
TASK_FILE="$2"

if [ -z "$TASK_FILE" ]; then
    echo "Usage: $0 <agent_type> <task_file>"
    echo "Example: $0 gpt message-2025-09-27.md"
    exit 1
fi

INBOX="${BRIDGE_ROOT}/inbox/${AGENT_TYPE}"
OUTBOX="${BRIDGE_ROOT}/outbox/${AGENT_TYPE}"
ARCHIVE="${BRIDGE_ROOT}/archive"

echo "Processing task: ${TASK_FILE} for ${AGENT_TYPE} agent"

if [ -f "${INBOX}/${TASK_FILE}" ]; then
    echo "Task found in inbox, processing..."

    # Extract priority from task file
    PRIORITY=$(grep "^# \[PRIORITY:" "${INBOX}/${TASK_FILE}" | sed 's/.*PRIORITY: *\([^\]]*\).*/\1/')
    echo "Priority: ${PRIORITY:-NORMAL}"

    # Simulate task processing (replace with actual agent logic)
    TIMESTAMP=$(date -Iseconds)
    RESPONSE_FILE="response-${AGENT_TYPE}-${TIMESTAMP}.md"

    echo "# [PRIORITY: NORMAL] Task Completed" > "${OUTBOX}/${RESPONSE_FILE}"
    echo "**From**: ${AGENT_TYPE}" >> "${OUTBOX}/${RESPONSE_FILE}"
    echo "**To**: Requesting Agent" >> "${OUTBOX}/${RESPONSE_FILE}"
    echo "**Timestamp**: ${TIMESTAMP}" >> "${OUTBOX}/${RESPONSE_FILE}"
    echo "" >> "${OUTBOX}/${RESPONSE_FILE}"
    echo "## Task Processing Complete" >> "${OUTBOX}/${RESPONSE_FILE}"
    echo "Original task from ${TASK_FILE} has been processed." >> "${OUTBOX}/${RESPONSE_FILE}"

    # Archive the processed task
    mv "${INBOX}/${TASK_FILE}" "${ARCHIVE}/processed-${TASK_FILE}"

    echo "Task completed. Response: ${RESPONSE_FILE}"
else
    echo "Error: Task file not found in ${INBOX}/${TASK_FILE}"
    exit 1
fi
