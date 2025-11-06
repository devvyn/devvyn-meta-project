#!/usr/bin/env bash
# ElevenLabs API Key Manager
# Securely stores and retrieves API key from macOS keychain

set -euo pipefail

SERVICE_NAME="elevenlabs-api-key"
ACCOUNT="$USER"

usage() {
    cat <<EOF
Usage: $(basename "$0") <command>

Commands:
    set <key>       Store API key in keychain
    get             Retrieve API key from keychain
    export          Export as ELEVEN_API_KEY environment variable
    test            Test if API key is configured
    delete          Remove API key from keychain

Examples:
    # Store your API key
    $(basename "$0") set sk_abc123...

    # Get API key for scripts
    API_KEY=\$($(basename "$0") get)

    # Export for current shell
    eval "\$($(basename "$0") export)"

    # Test if configured
    $(basename "$0") test && echo "API key configured!"
EOF
}

cmd_set() {
    local api_key="$1"

    if [[ ! "$api_key" =~ ^sk_ ]]; then
        echo "⚠️  Warning: API key should start with 'sk_'" >&2
    fi

    # Delete existing key if present
    security delete-generic-password -s "$SERVICE_NAME" 2>/dev/null || true

    # Add new key
    security add-generic-password \
        -a "$ACCOUNT" \
        -s "$SERVICE_NAME" \
        -w "$api_key" \
        -T /usr/bin/security \
        -T "$(which python3 2>/dev/null || echo /usr/bin/python3)"

    echo "✅ API key stored in keychain"
    echo "   Service: $SERVICE_NAME"
    echo "   Account: $ACCOUNT"
}

cmd_get() {
    security find-generic-password \
        -s "$SERVICE_NAME" \
        -a "$ACCOUNT" \
        -w 2>/dev/null || {
            echo "ERROR: API key not found in keychain. Run: $(basename "$0") set <key>" >&2
            return 1
        }
}

cmd_export() {
    local api_key
    api_key=$(cmd_get)
    echo "export ELEVEN_API_KEY='$api_key'"
}

cmd_test() {
    if cmd_get >/dev/null 2>&1; then
        echo "✅ API key is configured"
        return 0
    else
        echo "❌ API key not found. Get it from: https://elevenlabs.io/app/settings/api-keys"
        echo "   Then run: $(basename "$0") set <your-api-key>"
        return 1
    fi
}

cmd_delete() {
    security delete-generic-password -s "$SERVICE_NAME" -a "$ACCOUNT" 2>/dev/null && {
        echo "✅ API key removed from keychain"
    } || {
        echo "⚠️  No API key found to delete"
    }
}

# Main
case "${1:-}" in
    set)
        [[ -z "${2:-}" ]] && { usage; exit 1; }
        cmd_set "$2"
        ;;
    get)
        cmd_get
        ;;
    export)
        cmd_export
        ;;
    test)
        cmd_test
        ;;
    delete)
        cmd_delete
        ;;
    *)
        usage
        exit 1
        ;;
esac
