#!/bin/bash
# Bridge Signal Script - GPT Integration
# Signals agent availability and status

BRIDGE_ROOT="/Users/devvynmurphy/infrastructure/agent-bridge/bridge"
TIMESTAMP=$(date -Iseconds)
AGENT_TYPE="${1:-gpt}"

echo "[${TIMESTAMP}] Bridge signal from ${AGENT_TYPE} agent"
echo "Status: ACTIVE"
echo "Inbox: ${BRIDGE_ROOT}/inbox/${AGENT_TYPE}/"
echo "Outbox: ${BRIDGE_ROOT}/outbox/${AGENT_TYPE}/"

# Check for pending messages
PENDING=$(ls "${BRIDGE_ROOT}/inbox/${AGENT_TYPE}/" 2>/dev/null | wc -l)
echo "Pending messages: ${PENDING}"

# Update agent status in context
echo "{\"agent\": \"${AGENT_TYPE}\", \"status\": \"active\", \"timestamp\": \"${TIMESTAMP}\", \"pending\": ${PENDING}}" > "${BRIDGE_ROOT}/context/${AGENT_TYPE}_status.json"
