#!/usr/bin/env bash
# Safe Credential Checker
# NEVER outputs actual credential values - only confirms existence
#
# Usage:
#   credential-safe-check.sh keychain <service-name>
#   credential-safe-check.sh env <variable-name>
#   credential-safe-check.sh file <path>

set -euo pipefail

check_keychain_credential() {
    local service="$1"
    if security find-generic-password -s "$service" -w >/dev/null 2>&1; then
        echo "✅ Credential '$service' exists in keychain"
        return 0
    else
        echo "❌ Credential '$service' not found in keychain"
        return 1
    fi
}

check_env_variable() {
    local var_name="$1"
    if [[ -n "${!var_name:-}" ]]; then
        echo "✅ Environment variable '$var_name' is set"
        return 0
    else
        echo "❌ Environment variable '$var_name' not set"
        return 1
    fi
}

check_file_exists() {
    local filepath="$1"
    if [[ -f "$filepath" ]]; then
        echo "✅ File exists: $filepath"
        return 0
    else
        echo "❌ File not found: $filepath"
        return 1
    fi
}

usage() {
    cat <<EOF
Safe Credential Checker - NEVER outputs actual values

Usage:
    $(basename "$0") keychain <service-name>
    $(basename "$0") env <variable-name>
    $(basename "$0") file <path>

Examples:
    $(basename "$0") keychain ELEVEN_LABS_API_KEY
    $(basename "$0") env ANTHROPIC_API_KEY
    $(basename "$0") file ~/devvyn-meta-project/secrets/openrouter.key

Returns:
    0 - Credential exists/configured
    1 - Credential not found

Output: Human-readable status message ONLY (no credential values)
EOF
}

# Main
case "${1:-}" in
    keychain)
        [[ -z "${2:-}" ]] && usage && exit 1
        check_keychain_credential "$2"
        ;;
    env)
        [[ -z "${2:-}" ]] && usage && exit 1
        check_env_variable "$2"
        ;;
    file)
        [[ -z "${2:-}" ]] && usage && exit 1
        check_file_exists "$2"
        ;;
    -h|--help|help)
        usage
        exit 0
        ;;
    *)
        echo "Error: Unknown command '${1:-}'"
        echo
        usage
        exit 1
        ;;
esac
