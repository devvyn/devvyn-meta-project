#!/bin/bash
#
# Provision API keys for PyRIT adversarial testing
# Follows pattern from provision-openrouter-key.sh
#
# Usage: ./provision-pyrit-keys.sh [--check|--setup]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SECRETS_DIR="$PROJECT_ROOT/secrets"
ENV_FILE="$SECRETS_DIR/.env.pyrit"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Ensure secrets directory exists and is gitignored
setup_secrets_dir() {
    if [[ ! -d "$SECRETS_DIR" ]]; then
        log_info "Creating secrets directory: $SECRETS_DIR"
        mkdir -p "$SECRETS_DIR"
    fi

    # Ensure .gitignore includes secrets/
    if ! grep -q "^secrets/" "$PROJECT_ROOT/.gitignore" 2>/dev/null; then
        log_warn "Adding secrets/ to .gitignore"
        echo "secrets/" >> "$PROJECT_ROOT/.gitignore"
    fi

    # Set restrictive permissions
    chmod 700 "$SECRETS_DIR"
}

# Check if API keys are configured
check_keys() {
    local status=0

    log_info "Checking PyRIT API key configuration..."
    echo ""

    if [[ -f "$ENV_FILE" ]]; then
        log_info "Environment file exists: $ENV_FILE"

        # Check for OpenAI API key
        if grep -q "^OPENAI_API_KEY=" "$ENV_FILE" 2>/dev/null; then
            local key=$(grep "^OPENAI_API_KEY=" "$ENV_FILE" | cut -d'=' -f2)
            if [[ -n "$key" && "$key" != "your-api-key-here" ]]; then
                log_info "✓ OPENAI_API_KEY configured"
            else
                log_warn "✗ OPENAI_API_KEY not set or placeholder value"
                status=1
            fi
        else
            log_warn "✗ OPENAI_API_KEY not found"
            status=1
        fi

        # Check for Azure OpenAI (optional alternative)
        if grep -q "^AZURE_OPENAI_ENDPOINT=" "$ENV_FILE" 2>/dev/null; then
            log_info "✓ AZURE_OPENAI_ENDPOINT configured (alternative)"
        fi

    else
        log_error "Environment file not found: $ENV_FILE"
        log_info "Run: $0 --setup"
        status=1
    fi

    echo ""
    return $status
}

# Interactive setup
setup_keys() {
    log_info "Setting up PyRIT API keys..."
    echo ""

    setup_secrets_dir

    # Prompt for API provider choice
    echo "PyRIT can use OpenAI or Azure OpenAI."
    echo ""
    echo "1) OpenAI API (https://platform.openai.com/api-keys)"
    echo "2) Azure OpenAI Service"
    echo "3) Skip (configure manually later)"
    echo ""
    read -p "Select provider [1-3]: " provider_choice

    case "$provider_choice" in
        1)
            setup_openai
            ;;
        2)
            setup_azure_openai
            ;;
        3)
            log_info "Skipping setup. Manual configuration:"
            log_info "  Edit: $ENV_FILE"
            create_template
            ;;
        *)
            log_error "Invalid choice"
            exit 1
            ;;
    esac

    # Set restrictive permissions
    chmod 600 "$ENV_FILE"

    log_info ""
    log_info "✓ Setup complete!"
    log_info ""
    log_info "To use these keys, source the environment file:"
    log_info "  source $ENV_FILE"
    log_info ""
    log_info "Or add to your shell profile (~/.zshrc):"
    log_info "  [ -f \"$ENV_FILE\" ] && source \"$ENV_FILE\""
    echo ""
}

setup_openai() {
    log_info "Setting up OpenAI API..."
    echo ""
    echo "Get your API key from: https://platform.openai.com/api-keys"
    echo ""

    read -sp "Enter OpenAI API Key: " api_key
    echo ""

    if [[ -z "$api_key" ]]; then
        log_error "API key cannot be empty"
        exit 1
    fi

    # Create env file
    cat > "$ENV_FILE" << EOF
# PyRIT API Configuration
# Created: $(date)
# Provider: OpenAI

# OpenAI API Key
export OPENAI_API_KEY="$api_key"

# Optional: Specify model (defaults to gpt-4)
export PYRIT_OPENAI_MODEL="gpt-4"

# Optional: Azure Content Safety (for scoring)
# export AZURE_CONTENT_SAFETY_API_KEY="your-key"
# export AZURE_CONTENT_SAFETY_ENDPOINT="https://your-endpoint.cognitiveservices.azure.com/"
EOF

    log_info "✓ OpenAI configuration saved to $ENV_FILE"
}

setup_azure_openai() {
    log_info "Setting up Azure OpenAI..."
    echo ""

    read -p "Enter Azure OpenAI Endpoint: " endpoint
    read -p "Enter Azure OpenAI Deployment Name: " deployment
    read -sp "Enter Azure OpenAI API Key: " api_key
    echo ""

    if [[ -z "$endpoint" || -z "$deployment" || -z "$api_key" ]]; then
        log_error "All fields are required"
        exit 1
    fi

    # Create env file
    cat > "$ENV_FILE" << EOF
# PyRIT API Configuration
# Created: $(date)
# Provider: Azure OpenAI

# Azure OpenAI Configuration
export AZURE_OPENAI_ENDPOINT="$endpoint"
export AZURE_OPENAI_DEPLOYMENT="$deployment"
export AZURE_OPENAI_API_KEY="$api_key"

# Optional: Azure Content Safety (for scoring)
# export AZURE_CONTENT_SAFETY_API_KEY="your-key"
# export AZURE_CONTENT_SAFETY_ENDPOINT="https://your-endpoint.cognitiveservices.azure.com/"
EOF

    log_info "✓ Azure OpenAI configuration saved to $ENV_FILE"
}

create_template() {
    if [[ ! -f "$ENV_FILE" ]]; then
        cat > "$ENV_FILE" << 'EOF'
# PyRIT API Configuration Template
# Choose ONE provider: OpenAI OR Azure OpenAI

# Option 1: OpenAI API
# export OPENAI_API_KEY="your-api-key-here"
# export PYRIT_OPENAI_MODEL="gpt-4"

# Option 2: Azure OpenAI Service
# export AZURE_OPENAI_ENDPOINT="https://your-endpoint.openai.azure.com/"
# export AZURE_OPENAI_DEPLOYMENT="your-deployment-name"
# export AZURE_OPENAI_API_KEY="your-api-key-here"

# Optional: Azure Content Safety (for scoring)
# export AZURE_CONTENT_SAFETY_API_KEY="your-key"
# export AZURE_CONTENT_SAFETY_ENDPOINT="https://your-endpoint.cognitiveservices.azure.com/"
EOF
        chmod 600 "$ENV_FILE"
        log_info "Created template: $ENV_FILE"
    fi
}

# Main logic
case "${1:-}" in
    --check)
        check_keys
        ;;
    --setup)
        setup_keys
        ;;
    *)
        echo "Usage: $0 [--check|--setup]"
        echo ""
        echo "  --check  Verify API keys are configured"
        echo "  --setup  Interactive API key setup"
        echo ""
        exit 1
        ;;
esac
