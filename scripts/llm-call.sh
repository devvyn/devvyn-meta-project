#!/bin/bash
# Shared LLM API Call Wrapper with Budget Tracking
# Manages $15 prepaid OpenRouter budget for collective benefit

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KEY_FILE="$PROJECT_ROOT/secrets/openrouter.key"
BUDGET_FILE="$PROJECT_ROOT/secrets/openrouter-budget.json"

usage() {
    cat << 'EOF'
Usage: ./scripts/llm-call.sh [OPTIONS]

Budget-aware LLM API calls via OpenRouter

Options:
  --model MODEL       Model to use (default: anthropic/claude-3.5-sonnet)
  --prompt TEXT       Prompt text (required)
  --system TEXT       System prompt (optional)
  --max-tokens N      Max tokens (default: 1000)
  --temperature N     Temperature (default: 1.0)
  --json              Request JSON output
  --dry-run           Estimate cost without calling
  --caller NAME       Calling agent/script name (for logging)

Budget Management:
  --check-budget      Show remaining budget
  --usage-log         Show usage history

Examples:
  # Simple call
  ./scripts/llm-call.sh --prompt "Summarize this data" --caller investigator

  # With system prompt
  ./scripts/llm-call.sh \
    --system "You are a technical analyst" \
    --prompt "Analyze these logs" \
    --caller code-agent

  # Check budget first
  ./scripts/llm-call.sh --check-budget

Models:
  anthropic/claude-3.5-sonnet    $3/$15 per M tokens (in/out)
  anthropic/claude-3-haiku       $0.25/$1.25 per M tokens
  openai/gpt-4o-mini             $0.15/$0.60 per M tokens

EOF
    exit 1
}

# Cost estimation (per million tokens)
get_model_cost() {
    local model="$1"
    local direction="$2"  # input or output

    case "$model" in
        anthropic/claude-3.5-sonnet|anthropic/claude-sonnet-4)
            [[ "$direction" == "input" ]] && echo "3.00" || echo "15.00"
            ;;
        anthropic/claude-3-haiku)
            [[ "$direction" == "input" ]] && echo "0.25" || echo "1.25"
            ;;
        openai/gpt-4o-mini)
            [[ "$direction" == "input" ]] && echo "0.15" || echo "0.60"
            ;;
        *)
            # Conservative estimate
            [[ "$direction" == "input" ]] && echo "5.00" || echo "20.00"
            ;;
    esac
}

estimate_cost() {
    local model="$1"
    local input_tokens="$2"
    local output_tokens="$3"

    local input_cost_per_m=$(get_model_cost "$model" "input")
    local output_cost_per_m=$(get_model_cost "$model" "output")

    local input_cost=$(echo "scale=6; $input_tokens * $input_cost_per_m / 1000000" | bc)
    local output_cost=$(echo "scale=6; $output_tokens * $output_cost_per_m / 1000000" | bc)
    local total_cost=$(echo "scale=6; $input_cost + $output_cost" | bc)

    echo "$total_cost"
}

check_budget() {
    if [[ ! -f "$BUDGET_FILE" ]]; then
        echo "Error: Budget file not found at $BUDGET_FILE" >&2
        exit 1
    fi

    local remaining=$(jq -r '.remaining' "$BUDGET_FILE")
    local initial=$(jq -r '.initial_budget' "$BUDGET_FILE")
    local spent=$(echo "scale=2; $initial - $remaining" | bc)

    echo "💰 Budget Status:"
    echo "   Initial:   \$$initial"
    echo "   Spent:     \$$spent"
    echo "   Remaining: \$$remaining"
    echo ""

    if (( $(echo "$remaining < 1.00" | bc -l) )); then
        echo "⚠️  Warning: Budget running low!"
    fi

    if (( $(echo "$remaining < 0.10" | bc -l) )); then
        echo "🚨 Critical: Budget nearly exhausted!"
        return 1
    fi
}

show_usage_log() {
    if [[ ! -f "$BUDGET_FILE" ]]; then
        echo "No usage log found"
        exit 1
    fi

    echo "📊 Usage Log:"
    jq -r '.usage_log[] | "[\(.timestamp)] \(.caller) - \(.model) - $\(.cost) (\(.tokens_in)in/\(.tokens_out)out)"' "$BUDGET_FILE"
}

log_usage() {
    local model="$1"
    local tokens_in="$2"
    local tokens_out="$3"
    local cost="$4"
    local caller="${5:-unknown}"

    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local temp=$(mktemp)

    jq --arg ts "$timestamp" \
       --arg model "$model" \
       --arg caller "$caller" \
       --argjson tokens_in "$tokens_in" \
       --argjson tokens_out "$tokens_out" \
       --argjson cost "$cost" \
       '.usage_log += [{
           timestamp: $ts,
           model: $model,
           caller: $caller,
           tokens_in: $tokens_in,
           tokens_out: $tokens_out,
           cost: $cost
       }] | .remaining = (.remaining - $cost)' "$BUDGET_FILE" > "$temp"

    mv "$temp" "$BUDGET_FILE"
}

make_api_call() {
    local model="$1"
    local prompt="$2"
    local system="${3:-}"
    local max_tokens="${4:-1000}"
    local temperature="${5:-1.0}"
    local json_mode="${6:-false}"
    local caller="${7:-script}"

    # Get API key (from Keychain or file)
    local api_key=$("$SCRIPT_DIR/get-openrouter-key.sh")
    if [[ -z "$api_key" ]]; then
        echo "Error: Failed to retrieve OpenRouter API key" >&2
        exit 1
    fi

    # Build messages
    local messages='[]'
    if [[ -n "$system" ]]; then
        messages=$(jq -n --arg sys "$system" '[{role: "system", content: $sys}]')
    fi
    messages=$(echo "$messages" | jq --arg prompt "$prompt" '. += [{role: "user", content: $prompt}]')

    # Build request
    local request=$(jq -n \
        --arg model "$model" \
        --argjson messages "$messages" \
        --argjson max_tokens "$max_tokens" \
        --argjson temperature "$temperature" \
        '{model: $model, messages: $messages, max_tokens: $max_tokens, temperature: $temperature}')

    if [[ "$json_mode" == "true" ]]; then
        request=$(echo "$request" | jq '.response_format = {type: "json_object"}')
    fi

    # Make call
    local response=$(curl -s https://openrouter.ai/api/v1/chat/completions \
        -H "Authorization: Bearer $api_key" \
        -H "Content-Type: application/json" \
        -H "HTTP-Referer: https://github.com/devvyn" \
        -H "X-Title: DevvynMetaProject" \
        -d "$request")

    # Check for errors
    if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
        echo "API Error:" >&2
        echo "$response" | jq -r '.error.message' >&2
        exit 1
    fi

    # Extract usage
    local tokens_in=$(echo "$response" | jq -r '.usage.prompt_tokens // 0')
    local tokens_out=$(echo "$response" | jq -r '.usage.completion_tokens // 0')
    local cost=$(estimate_cost "$model" "$tokens_in" "$tokens_out")

    # Log usage
    log_usage "$model" "$tokens_in" "$tokens_out" "$cost" "$caller"

    # Return response
    echo "$response" | jq -r '.choices[0].message.content'

    # Show usage to stderr
    echo "" >&2
    echo "📊 Usage: $tokens_in in / $tokens_out out = \$$cost" >&2
    echo "💰 Remaining: \$$(jq -r '.remaining' "$BUDGET_FILE")" >&2
}

# Parse arguments
MODEL="anthropic/claude-3.5-sonnet"
PROMPT=""
SYSTEM=""
MAX_TOKENS=1000
TEMPERATURE=1.0
JSON_MODE=false
DRY_RUN=false
CALLER="manual"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --model) MODEL="$2"; shift 2 ;;
        --prompt) PROMPT="$2"; shift 2 ;;
        --system) SYSTEM="$2"; shift 2 ;;
        --max-tokens) MAX_TOKENS="$2"; shift 2 ;;
        --temperature) TEMPERATURE="$2"; shift 2 ;;
        --json) JSON_MODE=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        --caller) CALLER="$2"; shift 2 ;;
        --check-budget) check_budget; exit 0 ;;
        --usage-log) show_usage_log; exit 0 ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1" >&2; usage ;;
    esac
done

# Validate
if [[ -z "$PROMPT" ]]; then
    echo "Error: --prompt required" >&2
    usage
fi

# Check budget
if (( $(jq -r '.remaining' "$BUDGET_FILE" | xargs printf "%.2f\n") < 0.10 )); then
    echo "Error: Insufficient budget remaining" >&2
    check_budget
    exit 1
fi

# Estimate cost for dry run
if [[ "$DRY_RUN" == "true" ]]; then
    # Rough estimate: 4 chars per token
    local est_input=$(( (${#PROMPT} + ${#SYSTEM}) / 4 ))
    local est_output=$MAX_TOKENS
    local est_cost=$(estimate_cost "$MODEL" "$est_input" "$est_output")

    echo "💵 Dry Run Cost Estimate:"
    echo "   Model: $MODEL"
    echo "   Est. input tokens: $est_input"
    echo "   Max output tokens: $est_output"
    echo "   Est. cost: \$$est_cost"
    exit 0
fi

# Make the call
make_api_call "$MODEL" "$PROMPT" "$SYSTEM" "$MAX_TOKENS" "$TEMPERATURE" "$JSON_MODE" "$CALLER"
