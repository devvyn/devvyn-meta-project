#!/bin/bash
# Provision OpenRouter API key using provisioning key
# Uses OpenRouter Admin API to create keys programmatically

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROV_KEY_FILE="$PROJECT_ROOT/secrets/openrouter-provisioning.key"
API_KEY_FILE="$PROJECT_ROOT/secrets/openrouter.key"

usage() {
    cat << 'EOF'
Usage: ./scripts/provision-openrouter-key.sh [OPTIONS]

Programmatically create OpenRouter API key using provisioning key

Options:
  --name NAME         Name for the API key (default: "devvyn-meta-project")
  --limit AMOUNT      Spending limit in dollars (optional)
  --rotate            Rotate existing key (create new, revoke old)
  --list              List existing keys
  --revoke KEY_ID     Revoke a specific key

Examples:
  ./scripts/provision-openrouter-key.sh --name "code-agent"
  ./scripts/provision-openrouter-key.sh --name "code-agent" --limit 15.00
  ./scripts/provision-openrouter-key.sh --rotate
  ./scripts/provision-openrouter-key.sh --list

EOF
    exit 1
}

# Check provisioning key exists
if [[ ! -f "$PROV_KEY_FILE" ]]; then
    echo "Error: Provisioning key not found at $PROV_KEY_FILE" >&2
    echo "" >&2
    echo "Create one at: https://openrouter.ai/settings/provisioning-keys" >&2
    echo "Then store at: $PROV_KEY_FILE" >&2
    exit 1
fi

PROV_KEY=$(cat "$PROV_KEY_FILE")

# Parse arguments
ACTION="create"
KEY_NAME="devvyn-meta-project"
LIMIT=""
REVOKE_KEY=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --name) KEY_NAME="$2"; shift 2 ;;
        --limit) LIMIT="$2"; shift 2 ;;
        --rotate) ACTION="rotate"; shift ;;
        --list) ACTION="list"; shift ;;
        --revoke) ACTION="revoke"; REVOKE_KEY="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1" >&2; usage ;;
    esac
done

# List existing keys
list_keys() {
    echo "📋 Listing API keys..."
    echo ""

    response=$(curl -s https://openrouter.ai/api/v1/keys \
        -H "Authorization: Bearer $PROV_KEY")

    # Check for error
    if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
        echo "Error:" >&2
        echo "$response" | jq -r '.error.message' >&2
        exit 1
    fi

    # Pretty print keys
    echo "$response" | jq -r '.data[] |
        "ID: \(.id)\n" +
        "Name: \(.name)\n" +
        "Created: \(.created_at)\n" +
        "Limit: $\(.limit // "none")\n" +
        "---"'
}

# Create new API key
create_key() {
    local name="$1"
    local limit="${2:-}"

    echo "🔑 Creating new API key: $name"
    if [[ -n "$limit" ]]; then
        echo "   Spending limit: \$$limit"
    fi
    echo ""

    # Build request
    local request=$(jq -n --arg name "$name" '{name: $name}')
    if [[ -n "$limit" ]]; then
        request=$(echo "$request" | jq --arg limit "$limit" '. + {limit: ($limit | tonumber)}')
    fi

    # Make request
    response=$(curl -s https://openrouter.ai/api/v1/keys \
        -X POST \
        -H "Authorization: Bearer $PROV_KEY" \
        -H "Content-Type: application/json" \
        -d "$request")

    # Check for error
    if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
        echo "Error creating key:" >&2
        echo "$response" | jq -r '.error.message' >&2
        exit 1
    fi

    # Extract key
    api_key=$(echo "$response" | jq -r '.key')
    key_id=$(echo "$response" | jq -r '.id')

    echo "✅ API key created successfully!"
    echo ""
    echo "   ID: $key_id"
    echo "   Key: ${api_key:0:20}..."
    echo ""

    # Store key
    echo "$api_key" > "$API_KEY_FILE"
    chmod 600 "$API_KEY_FILE"

    echo "💾 Saved to: $API_KEY_FILE"
    echo ""
    echo "🎯 Verify with:"
    echo "   ./scripts/llm-call.sh --prompt 'test' --max-tokens 5 --caller test"
}

# Revoke key
revoke_key() {
    local key_id="$1"

    echo "🗑️  Revoking key: $key_id"
    echo ""

    response=$(curl -s "https://openrouter.ai/api/v1/keys/$key_id" \
        -X DELETE \
        -H "Authorization: Bearer $PROV_KEY")

    # Check for error
    if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
        echo "Error revoking key:" >&2
        echo "$response" | jq -r '.error.message' >&2
        exit 1
    fi

    echo "✅ Key revoked successfully"
}

# Rotate key (create new, revoke old)
rotate_key() {
    echo "🔄 Rotating API key..."
    echo ""

    # Get current key ID
    if [[ ! -f "$API_KEY_FILE" ]]; then
        echo "No existing key to rotate. Creating new key."
        create_key "$KEY_NAME" "$LIMIT"
        return
    fi

    current_key=$(cat "$API_KEY_FILE")

    # List keys to find current key's ID
    echo "Finding current key ID..."
    response=$(curl -s https://openrouter.ai/api/v1/keys \
        -H "Authorization: Bearer $PROV_KEY")

    # This is approximate - OpenRouter doesn't let us match keys directly
    # In practice, we'd need to store the key ID when creating
    echo "⚠️  Manual verification recommended"
    echo ""

    # Create new key
    create_key "${KEY_NAME}-rotated-$(date +%Y%m%d)" "$LIMIT"

    echo ""
    echo "⚠️  Old key still active. Revoke manually:"
    echo "   ./scripts/provision-openrouter-key.sh --list"
    echo "   ./scripts/provision-openrouter-key.sh --revoke <key-id>"
}

# Execute action
case "$ACTION" in
    list) list_keys ;;
    create) create_key "$KEY_NAME" "$LIMIT" ;;
    revoke) revoke_key "$REVOKE_KEY" ;;
    rotate) rotate_key ;;
esac
