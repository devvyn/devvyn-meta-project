#!/bin/bash
# OpenRouter Budget Management

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUDGET_FILE="$PROJECT_ROOT/secrets/openrouter-budget.json"

usage() {
    cat << 'EOF'
Usage: ./scripts/openrouter-budget.sh [COMMAND]

Budget management for shared $15 OpenRouter resource

Commands:
  status      Show current budget status (default)
  log         Show usage history
  top         Show top consumers
  reset       Reset budget (requires confirmation)

Examples:
  ./scripts/openrouter-budget.sh status
  ./scripts/openrouter-budget.sh log
  ./scripts/openrouter-budget.sh top

EOF
    exit 1
}

show_status() {
    if [[ ! -f "$BUDGET_FILE" ]]; then
        echo "Error: Budget file not found" >&2
        exit 1
    fi

    local remaining=$(jq -r '.remaining' "$BUDGET_FILE")
    local initial=$(jq -r '.initial_budget' "$BUDGET_FILE")
    local spent=$(echo "scale=2; $initial - $remaining" | bc)
    local percent_used=$(echo "scale=1; ($spent / $initial) * 100" | bc)

    echo "💰 OpenRouter Budget Status"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    printf "Initial:    \$%.2f\n" "$initial"
    printf "Spent:      \$%.2f (%.1f%%)\n" "$spent" "$percent_used"
    printf "Remaining:  \$%.2f\n" "$remaining"
    echo ""

    # Visual budget bar
    local bar_width=30
    local used_width=$(echo "scale=0; ($spent / $initial) * $bar_width" | bc)
    local remaining_width=$((bar_width - used_width))

    printf "["
    printf "%${used_width}s" | tr ' ' '█'
    printf "%${remaining_width}s" | tr ' ' '░'
    printf "]\n"
    echo ""

    # Warnings
    if (( $(echo "$remaining < 1.00" | bc -l) )); then
        echo "⚠️  Warning: Budget running low!"
    fi

    if (( $(echo "$remaining < 0.10" | bc -l) )); then
        echo "🚨 Critical: Budget nearly exhausted!"
    fi

    # Usage count
    local call_count=$(jq '.usage_log | length' "$BUDGET_FILE")
    if (( call_count > 0 )); then
        local avg_cost=$(echo "scale=4; $spent / $call_count" | bc)
        echo "📊 Stats:"
        printf "   Calls: %d\n" "$call_count"
        printf "   Avg cost: \$%.4f\n" "$avg_cost"
    fi
}

show_log() {
    if [[ ! -f "$BUDGET_FILE" ]]; then
        echo "No usage log found"
        exit 1
    fi

    local count=$(jq '.usage_log | length' "$BUDGET_FILE")

    if (( count == 0 )); then
        echo "No usage recorded yet"
        exit 0
    fi

    echo "📊 Usage Log ($count calls)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    jq -r '.usage_log[] |
        "\(.timestamp | split("T")[0]) \(.timestamp | split("T")[1] | split("Z")[0])\n" +
        "  \(.caller) → \(.model)\n" +
        "  \(.tokens_in) in / \(.tokens_out) out = $\(.cost | tonumber | . * 100 | round / 100)\n"' \
        "$BUDGET_FILE"
}

show_top() {
    if [[ ! -f "$BUDGET_FILE" ]]; then
        echo "No usage log found"
        exit 1
    fi

    echo "🏆 Top Consumers"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    jq -r '.usage_log |
        group_by(.caller) |
        map({
            caller: .[0].caller,
            calls: length,
            total_cost: (map(.cost) | add),
            total_tokens: (map(.tokens_in + .tokens_out) | add)
        }) |
        sort_by(.total_cost) |
        reverse |
        .[] |
        "  \(.caller):\n" +
        "    Calls: \(.calls)\n" +
        "    Cost: $\(.total_cost | . * 100 | round / 100)\n" +
        "    Tokens: \(.total_tokens)\n"' \
        "$BUDGET_FILE"
}

reset_budget() {
    echo "⚠️  Reset Budget?"
    echo ""
    echo "This will:"
    echo "  - Set remaining budget back to $15.00"
    echo "  - Preserve usage log for historical reference"
    echo ""
    read -p "Confirm reset? (yes/no): " confirm

    if [[ "$confirm" != "yes" ]]; then
        echo "Cancelled"
        exit 0
    fi

    local temp=$(mktemp)
    jq '.remaining = 15.00 | .initial_budget = 15.00 | .last_checked = (now | strftime("%Y-%m-%d"))' \
        "$BUDGET_FILE" > "$temp"
    mv "$temp" "$BUDGET_FILE"

    echo "✅ Budget reset to $15.00"
}

# Main
COMMAND="${1:-status}"

case "$COMMAND" in
    status) show_status ;;
    log) show_log ;;
    top) show_top ;;
    reset) reset_budget ;;
    -h|--help) usage ;;
    *) echo "Unknown command: $COMMAND" >&2; usage ;;
esac
