#!/bin/bash
# email-receive.sh - Check IMAP inbox and convert emails to bridge messages
# Usage: email-receive.sh [--mark-read]
# Designed to run periodically via LaunchAgent

set -euo pipefail

CONFIG_FILE="${HOME}/infrastructure/agent-bridge/bridge/config/email-config.json"
BRIDGE_DIR="${HOME}/infrastructure/agent-bridge/bridge"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
DIM="\033[2m"
RESET="\033[0m"

MARK_READ=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --mark-read)
            MARK_READ=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if config exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${RED}Error: Email config not found${RESET}"
    exit 1
fi

# Check if IMAP is enabled
IMAP_ENABLED=$(jq -r '.imap.enabled // false' "$CONFIG_FILE")

if [[ "$IMAP_ENABLED" != "true" ]]; then
    echo -e "${DIM}Email receiving is not enabled${RESET}"
    exit 0
fi

# Read IMAP configuration
IMAP_HOST=$(jq -r '.imap.host' "$CONFIG_FILE")
IMAP_PORT=$(jq -r '.imap.port // 993' "$CONFIG_FILE")
IMAP_USER=$(jq -r '.imap.username' "$CONFIG_FILE")
IMAP_PASS=$(jq -r '.imap.password' "$CONFIG_FILE")
IMAP_FOLDER=$(jq -r '.imap.folder // "INBOX"' "$CONFIG_FILE")
ALLOWED_SENDERS=$(jq -r '.allowed_senders[]?' "$CONFIG_FILE")

# Validate configuration
if [[ -z "$IMAP_HOST" ]] || [[ -z "$IMAP_USER" ]]; then
    echo -e "${RED}Error: Incomplete IMAP configuration${RESET}"
    exit 1
fi

echo -e "${GREEN}Checking inbox...${RESET}"

# Use Python for IMAP (more reliable than bash mail utilities)
python3 << 'PYEOF'
import imaplib
import email
from email.header import decode_header
import sys
import os
import json
import re
from datetime import datetime

# Read config
config_file = os.environ.get("CONFIG_FILE")
with open(config_file) as f:
    config = json.load(f)

imap_config = config["imap"]
allowed_senders = config.get("allowed_senders", [])
mark_read = os.environ.get("MARK_READ") == "true"

# Connect to IMAP
try:
    mail = imaplib.IMAP4_SSL(imap_config["host"], int(imap_config.get("port", 993)))
    mail.login(imap_config["username"], imap_config["password"])
    mail.select(imap_config.get("folder", "INBOX"))

    # Search for unread emails with agent-bridge header
    status, messages = mail.search(None, 'UNSEEN', 'HEADER', 'X-Agent-Bridge', 'true')

    if status != "OK":
        print("No messages found")
        sys.exit(0)

    email_ids = messages[0].split()

    if not email_ids:
        print("No unread agent-bridge emails")
        sys.exit(0)

    print(f"Found {len(email_ids)} unread message(s)")

    bridge_dir = os.environ.get("BRIDGE_DIR")

    for email_id in email_ids:
        # Fetch email
        status, msg_data = mail.fetch(email_id, "(RFC822)")

        if status != "OK":
            continue

        # Parse email
        raw_email = msg_data[0][1]
        msg = email.message_from_bytes(raw_email)

        # Get sender
        from_header = msg.get("From", "")
        sender_match = re.search(r'<(.+?)>', from_header)
        sender = sender_match.group(1) if sender_match else from_header

        # Check if sender is allowed
        if allowed_senders and sender not in allowed_senders:
            print(f"Skipping email from unauthorized sender: {sender}")
            continue

        # Get subject
        subject = ""
        subject_header = msg.get("Subject", "")
        if subject_header:
            decoded = decode_header(subject_header)[0]
            if isinstance(decoded[0], bytes):
                subject = decoded[0].decode(decoded[1] or "utf-8")
            else:
                subject = decoded[0]

        # Get body
        body = ""
        if msg.is_multipart():
            for part in msg.walk():
                if part.get_content_type() == "text/plain":
                    body = part.get_payload(decode=True).decode("utf-8")
                    break
        else:
            body = msg.get_payload(decode=True).decode("utf-8")

        # Create bridge message
        timestamp = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")

        # Sanitize sender for filename
        sender_safe = re.sub(r'[^a-z0-9]', '-', sender.lower())

        message_file = os.path.join(
            bridge_dir,
            "inbox",
            "code",  # Default to code agent
            f"email-{timestamp}-{sender_safe}.md"
        )

        os.makedirs(os.path.dirname(message_file), exist_ok=True)

        with open(message_file, "w") as f:
            f.write(f"# {subject}\n\n")
            f.write(f"From: {sender}\n")
            f.write(f"Received: {timestamp}\n\n")
            f.write("---\n\n")
            f.write(body)

        print(f"✓ Converted email to bridge message: {os.path.basename(message_file)}")

        # Mark as read if requested
        if mark_read:
            mail.store(email_id, '+FLAGS', '\\Seen')

    mail.close()
    mail.logout()

except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
PYEOF

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✓ Email check complete${RESET}"
else
    echo -e "${RED}✗ Email check failed${RESET}"
    exit 1
fi
