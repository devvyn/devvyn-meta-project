#!/bin/bash
# email-send.sh - Send bridge messages via email (SMTP)
# Usage: email-send.sh <to> <subject> <content-file>

set -euo pipefail

CONFIG_FILE="${HOME}/infrastructure/agent-bridge/bridge/config/email-config.json"

# Color codes
BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

show_help() {
    echo "Usage: email-send.sh <to> <subject> <content-file>"
    echo ""
    echo "Examples:"
    echo "  email-send.sh user@example.com 'Project Update' message.md"
    echo ""
    echo "Configuration: $CONFIG_FILE"
}

if [[ $# -lt 3 ]]; then
    show_help
    exit 1
fi

TO="$1"
SUBJECT="$2"
CONTENT_FILE="$3"

if [[ ! -f "$CONTENT_FILE" ]]; then
    echo -e "${RED}Error: Content file not found: $CONTENT_FILE${RESET}"
    exit 1
fi

# Create config directory if it doesn't exist
mkdir -p "$(dirname "$CONFIG_FILE")"

# Create default config if it doesn't exist
if [[ ! -f "$CONFIG_FILE" ]]; then
    cat > "$CONFIG_FILE" << 'EOF'
{
  "smtp": {
    "host": "smtp.gmail.com",
    "port": 587,
    "username": "",
    "password": "",
    "from": "",
    "use_tls": true,
    "enabled": false
  },
  "allowed_recipients": []
}
EOF
    echo -e "${YELLOW}Created default config at: $CONFIG_FILE${RESET}"
    echo -e "${YELLOW}Please configure SMTP settings before using this tool${RESET}"
    exit 1
fi

# Check if email is enabled
ENABLED=$(jq -r '.smtp.enabled // false' "$CONFIG_FILE")

if [[ "$ENABLED" != "true" ]]; then
    echo -e "${RED}Error: Email sending is not enabled${RESET}"
    echo "Please edit $CONFIG_FILE and set smtp.enabled to true"
    exit 1
fi

# Read SMTP configuration
SMTP_HOST=$(jq -r '.smtp.host' "$CONFIG_FILE")
SMTP_PORT=$(jq -r '.smtp.port' "$CONFIG_FILE")
SMTP_USER=$(jq -r '.smtp.username' "$CONFIG_FILE")
SMTP_PASS=$(jq -r '.smtp.password' "$CONFIG_FILE")
SMTP_FROM=$(jq -r '.smtp.from' "$CONFIG_FILE")
USE_TLS=$(jq -r '.smtp.use_tls // true' "$CONFIG_FILE")

# Validate configuration
if [[ -z "$SMTP_HOST" ]] || [[ -z "$SMTP_USER" ]] || [[ -z "$SMTP_FROM" ]]; then
    echo -e "${RED}Error: Incomplete SMTP configuration${RESET}"
    exit 1
fi

# Check if recipient is allowed (if whitelist is configured)
ALLOWED_RECIPIENTS=$(jq -r '.allowed_recipients[]' "$CONFIG_FILE" 2>/dev/null || echo "")

if [[ -n "$ALLOWED_RECIPIENTS" ]]; then
    RECIPIENT_ALLOWED=false
    while read -r allowed; do
        if [[ "$TO" == "$allowed" ]]; then
            RECIPIENT_ALLOWED=true
            break
        fi
    done <<< "$ALLOWED_RECIPIENTS"

    if [[ "$RECIPIENT_ALLOWED" != "true" ]]; then
        echo -e "${RED}Error: Recipient not in allowed list${RESET}"
        exit 1
    fi
fi

# Read content
CONTENT=$(cat "$CONTENT_FILE")

# Prepare email
echo -e "${GREEN}Sending email to $TO...${RESET}"

# Use Python for SMTP (more reliable than bash mail utilities on macOS)
python3 << PYEOF
import smtplib
import sys
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# Configuration
smtp_host = "$SMTP_HOST"
smtp_port = int("$SMTP_PORT")
smtp_user = "$SMTP_USER"
smtp_pass = "$SMTP_PASS"
from_addr = "$SMTP_FROM"
to_addr = "$TO"
subject = "$SUBJECT"

# Read content
with open("$CONTENT_FILE", "r") as f:
    content = f.read()

# Create message
msg = MIMEMultipart("alternative")
msg["Subject"] = subject
msg["From"] = from_addr
msg["To"] = to_addr
msg["X-Agent-Bridge"] = "true"

# Add plain text and HTML versions
text_part = MIMEText(content, "plain")
msg.attach(text_part)

try:
    # Connect to SMTP server
    if "$USE_TLS" == "true":
        server = smtplib.SMTP(smtp_host, smtp_port)
        server.starttls()
    else:
        server = smtplib.SMTP(smtp_host, smtp_port)

    # Login if credentials provided
    if smtp_pass:
        server.login(smtp_user, smtp_pass)

    # Send email
    server.send_message(msg)
    server.quit()

    print("✓ Email sent successfully")
    sys.exit(0)

except Exception as e:
    print(f"✗ Failed to send email: {e}", file=sys.stderr)
    sys.exit(1)
PYEOF

EXIT_CODE=$?

if [[ $EXIT_CODE -eq 0 ]]; then
    echo -e "${GREEN}✓ Email sent to $TO${RESET}"
else
    echo -e "${RED}✗ Failed to send email${RESET}"
    exit 1
fi
