#!/bin/bash
# Retrieve OpenRouter API key from macOS Keychain or file

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KEY_FILE="$PROJECT_ROOT/secrets/openrouter.key"

# Try file first (for backwards compatibility)
if [[ -f "$KEY_FILE" ]]; then
    cat "$KEY_FILE"
    exit 0
fi

# Try macOS Keychain
if command -v security >/dev/null 2>&1; then
    # Primary lookup: service="OpenRouter" (case sensitive)
    key=$(security find-generic-password -s "OpenRouter" -w 2>/dev/null || true)
    if [[ -n "$key" ]]; then
        echo "$key"
        exit 0
    fi

    # Try with account specified
    key=$(security find-generic-password -s "OpenRouter" -a "bridge-control" -w 2>/dev/null || true)
    if [[ -n "$key" ]]; then
        echo "$key"
        exit 0
    fi

    # Fallback: try other variations
    for name in "openrouter" "openrouter.ai" "OpenRouter.ai"; do
        key=$(security find-generic-password -s "$name" -w 2>/dev/null || true)
        if [[ -n "$key" ]]; then
            echo "$key"
            exit 0
        fi
    done

    # If not found, provide helpful error
    echo "Error: OpenRouter API key not found in Keychain or file" >&2
    echo "" >&2
    echo "📚 Setup Guide: docs/OPENROUTER_SETUP.md" >&2
    echo "" >&2
    echo "Quick setup (if you already have a key):" >&2
    echo "  echo 'sk-or-v1-...' > $KEY_FILE && chmod 600 $KEY_FILE" >&2
    echo "" >&2
    echo "To acquire key (requires human):" >&2
    echo "  1. Visit https://openrouter.ai and create account" >&2
    echo "  2. Add credits (e.g. \$15)" >&2
    echo "  3. Generate API key in Settings" >&2
    echo "  4. Store at: $KEY_FILE" >&2
    exit 1
fi

echo "Error: API key not found and Keychain access not available" >&2
exit 1
