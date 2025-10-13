# Collective API Key Management (Proposed)

## Current Implementation (v1.0 - Basic)

**Model**: Shared key with usage tracking

**Features**:
- Single OpenRouter key stored at `secrets/openrouter.key`
- Budget tracking logs which agent/caller used what
- Manual review via `openrouter-budget.sh log` and `openrouter-budget.sh top`

**Limitations**:
- No quotas per agent
- No access control
- No approval workflow
- Trust-based system

## Proposed Collective Management (v2.0)

### 1. Per-Agent Quotas

**Budget structure**:
```json
{
  "total_budget": 15.00,
  "remaining": 12.50,
  "quotas": {
    "code": {
      "allocated": 5.00,
      "used": 1.50,
      "remaining": 3.50
    },
    "chat": {
      "allocated": 5.00,
      "used": 0.50,
      "remaining": 4.50
    },
    "investigator": {
      "allocated": 3.00,
      "used": 0.50,
      "remaining": 2.50
    },
    "shared_pool": {
      "allocated": 2.00,
      "remaining": 2.00,
      "notes": "Overflow for agents exceeding quota with approval"
    }
  },
  "usage_log": [...]
}
```

**Enforcement**:
```bash
# In llm-call.sh, check quota before call
check_quota() {
    local caller="$1"
    local estimated_cost="$2"

    local remaining=$(jq -r ".quotas.$caller.remaining // 0" "$BUDGET_FILE")

    if (( $(echo "$estimated_cost > $remaining" | bc -l) )); then
        echo "Error: Quota exceeded for $caller" >&2
        echo "Remaining: \$$remaining, Request: \$$estimated_cost" >&2
        echo "Request approval via: ./scripts/request-quota-increase.sh $caller $estimated_cost" >&2
        return 1
    fi
}
```

### 2. Approval Workflow for High-Cost Operations

**Threshold-based approval**:
```bash
# Calls > $0.10 require approval
if (( $(echo "$estimated_cost > 0.10" | bc -l) )); then
    echo "⚠️  High-cost operation ($estimated_cost)"
    read -p "Requires approval. Continue? (yes/no): " approval
    if [[ "$approval" != "yes" ]]; then
        echo "Cancelled by user"
        exit 0
    fi
fi
```

**Or async approval via bridge**:
```bash
# Request approval from human
./scripts/bridge-send.sh code human HIGH \
  "LLM Call Approval Request" \
  /tmp/approval-request.md

# Wait for response or timeout
```

### 3. Multiple Keys with Access Levels

**Key types**:
```json
{
  "keys": {
    "production": {
      "file": "secrets/openrouter-prod.key",
      "budget": 15.00,
      "allowed_agents": ["code", "chat", "investigator"],
      "requires_approval": true
    },
    "development": {
      "file": "secrets/openrouter-dev.key",
      "budget": 5.00,
      "allowed_agents": ["*"],
      "requires_approval": false,
      "rate_limit": "10/hour"
    },
    "emergency": {
      "file": "secrets/openrouter-emergency.key",
      "budget": 50.00,
      "allowed_agents": ["code", "chat"],
      "requires_approval": true,
      "only_when": "production_key_failed"
    }
  }
}
```

**Key selection logic**:
```bash
select_key() {
    local caller="$1"
    local priority="$2"

    # Try production first
    if is_allowed "$caller" "production" && has_budget "production"; then
        echo "production"
        return 0
    fi

    # Fall back to dev
    if is_allowed "$caller" "development"; then
        echo "development"
        return 0
    fi

    # Emergency requires explicit approval
    if [[ "$priority" == "CRITICAL" ]]; then
        request_emergency_key "$caller"
    fi

    return 1
}
```

### 4. Fair Sharing Policies

**Policy**: Equal opportunity, with overflow

```json
{
  "policy": {
    "allocation_strategy": "equal_base_plus_merit",
    "base_allocation": 3.00,
    "merit_pool": 6.00,
    "merit_criteria": {
      "high_value_tasks": "2x multiplier",
      "efficient_usage": "1.5x multiplier",
      "collaborative_benefit": "1.5x multiplier"
    }
  }
}
```

**Dynamic reallocation**:
```bash
# Weekly: Reallocate unused quota to active agents
reallocate_budget() {
    # Identify inactive agents (no usage in 7 days)
    inactive=$(jq -r '.quotas | to_entries[] |
        select(.value.last_used < (now - 604800)) |
        .key' "$BUDGET_FILE")

    # Return unused quota to shared pool
    for agent in $inactive; do
        unused=$(jq -r ".quotas.$agent.remaining" "$BUDGET_FILE")
        # Move to shared pool
    done
}
```

### 5. Accountability and Audit

**Enhanced logging**:
```json
{
  "usage_log": [
    {
      "timestamp": "2025-10-09T08:30:00Z",
      "caller": "code",
      "session_id": "dev-123",
      "model": "anthropic/claude-3.5-sonnet",
      "prompt_preview": "Analyze pattern in...",
      "tokens_in": 2000,
      "tokens_out": 500,
      "cost": 0.015,
      "purpose": "pattern_analysis",
      "approved_by": "auto",
      "value_rating": null
    }
  ]
}
```

**Audit reports**:
```bash
# Generate weekly report
./scripts/openrouter-audit.sh weekly

# Output:
# - Cost per agent
# - Top expensive calls
# - Value assessment
# - Quota utilization
# - Recommendations for reallocation
```

### 6. Revocation and Rate Limiting

**Agent-specific limits**:
```json
{
  "rate_limits": {
    "code": {
      "calls_per_hour": 20,
      "max_cost_per_call": 0.50,
      "max_cost_per_day": 2.00
    },
    "investigator": {
      "calls_per_hour": 5,
      "max_cost_per_call": 0.10,
      "max_cost_per_day": 1.00
    }
  }
}
```

**Revocation**:
```bash
# Suspend agent access
./scripts/openrouter-access.sh revoke investigator "Excessive usage"

# Budget file updated:
{
  "quotas": {
    "investigator": {
      "status": "suspended",
      "reason": "Excessive usage",
      "suspended_at": "2025-10-09T10:00:00Z",
      "suspended_by": "human"
    }
  }
}
```

## Implementation Priority

**Phase 1** (Current - v1.0):
- ✅ Basic shared key
- ✅ Usage logging
- ✅ Manual review

**Phase 2** (Next - v1.5):
- [ ] Per-agent quotas
- [ ] High-cost approval workflow
- [ ] Rate limiting

**Phase 3** (Future - v2.0):
- [ ] Multiple keys with access levels
- [ ] Dynamic reallocation
- [ ] Comprehensive audit reporting
- [ ] Revocation mechanisms

## Decision: Implement Now or Defer?

**Arguments for "defer until needed"**:
- Current usage is low, trust-based works
- Over-engineering for hypothetical problems
- Can implement incrementally when pain points emerge

**Arguments for "implement per-agent quotas now"**:
- Prevents single agent exhausting budget
- Establishes fairness norms early
- Low implementation cost (30 min work)

**Recommendation**: **Implement Phase 2 (per-agent quotas) now**, defer Phase 3 (multi-key, revocation) until needed.

## Simple Quota Implementation (Minimal Viable)

```bash
# Add to llm-call.sh, before API call:

CALLER="${CALLER:-manual}"
QUOTA=$(jq -r ".quotas.$CALLER.remaining // 999" "$BUDGET_FILE")

if (( $(echo "$estimated_cost > $QUOTA" | bc -l) )); then
    echo "⚠️  Quota exceeded for $CALLER" >&2
    echo "   Remaining: \$$QUOTA" >&2
    echo "   Request: \$$estimated_cost" >&2
    echo "" >&2
    read -p "Use shared pool? (yes/no): " use_shared
    if [[ "$use_shared" != "yes" ]]; then
        exit 1
    fi
fi

# After call, deduct from caller's quota
jq --arg caller "$CALLER" \
   --argjson cost "$actual_cost" \
   '.quotas[$caller].used += $cost |
    .quotas[$caller].remaining -= $cost' \
   "$BUDGET_FILE" > "$temp"
mv "$temp" "$BUDGET_FILE"
```

## Questions for Human Operator

1. **Should we implement per-agent quotas now?** (Phase 2)
   - If yes: How to allocate $15 across code, chat, investigator, shared?

2. **What threshold requires approval?**
   - Current default: >$0.10 per call
   - Or: Trust-based, no approval workflow?

3. **Multiple keys or single shared key?**
   - Single: Simpler, current approach
   - Multiple: Better isolation, requires more setup

4. **Fair sharing philosophy?**
   - Equal allocation?
   - Merit-based?
   - First-come-first-served?

---

**Current Status**: v1.0 (basic shared, no quotas)
**Proposed**: v1.5 (add per-agent quotas)
**Timeline**: 30 min implementation, human approval on allocation amounts
