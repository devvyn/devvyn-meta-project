# API Key Management Best Practices for Multi-Agent Systems
## Research Summary (2024-2025)

**Research Date**: 2025-10-09
**Sources**: Agent frameworks (LangChain, CrewAI, AutoGPT), API gateways (AWS, Azure), LLM observability (LangFuse, Helicone)

## Key Finding: No Standard Pattern for Per-Agent Quotas

**Industry status**:
- ❌ Major agent frameworks (LangChain, CrewAI) don't implement per-agent budgets
- ❌ No open-source tools specifically for multi-agent cost allocation
- ✅ Enterprise API gateways use **tagging + chargeback** models
- ✅ LLM observability platforms track costs **per user/session**

**Conclusion**: Per-agent budget management is an **emerging need** with custom solutions required.

## Best Practices from Industry

### 1. Tagging Strategy (from AWS/Azure API Gateway)

**Pattern**: Tag every API call with metadata for cost attribution

**Implementation**:
```bash
# Tag API calls with caller agent
curl https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $API_KEY" \
  -H "X-Agent-ID: code" \
  -H "X-Session-ID: session-123" \
  -H "X-Cost-Center: engineering" \
  -d '{
    "model": "anthropic/claude-3.5-sonnet",
    "messages": [...],
    "metadata": {
      "agent": "code",
      "session": "session-123",
      "purpose": "pattern_analysis"
    }
  }'
```

**Benefits**:
- Enables retroactive cost analysis
- Supports chargeback without upfront quotas
- Flexible for changing team structures

### 2. Showback vs Chargeback Models (from Enterprise FinOps)

**Showback** (informational):
- Track and report costs per agent
- No enforcement of limits
- Build awareness and accountability
- **Recommended for initial implementation**

**Chargeback** (enforced):
- Pre-allocated budgets per agent
- Enforce quotas before API calls
- Requires approval for overages
- **Implement after showback establishes patterns**

**Decision tree**:
```
Start → Showback (3-6 months) → Review usage patterns → Decide:
  - High trust, low variation? → Keep showback
  - Cost concerns, unequal usage? → Implement chargeback
```

### 3. Cost Tracking Per User/Team (from LangFuse, Helicone)

**Pattern**: Real-time observability with cost breakdowns

**Key dimensions**:
- Agent/caller ID
- Session ID
- Model used
- Purpose/task type
- Geography/environment

**Implementation via LangFuse** (open-source):
```python
from langfuse import Langfuse

langfuse = Langfuse()

# Trace agent LLM call
trace = langfuse.trace(
    name="agent_llm_call",
    user_id="code_agent",
    metadata={
        "agent": "code",
        "session": "session-123",
        "purpose": "pattern_analysis"
    }
)

# LangFuse automatically calculates costs
# Query later: "Show me costs for code_agent this week"
```

**Alternative**: Helicone as LLM proxy (hosted solution)

### 4. Progressive Quota Implementation (from Cloud Cost Management)

**Phase 1: No Quotas (Trust Model)**
- Track all usage with tagging
- Report costs weekly
- Build baseline understanding
- **Duration**: 1-3 months

**Phase 2: Soft Quotas (Warning Model)**
```bash
if (( cost > soft_quota )); then
    echo "⚠️  Approaching quota: $cost / $soft_quota"
    # Continue anyway, but log warning
fi
```
- **Duration**: 1-2 months

**Phase 3: Hard Quotas (Enforcement Model)**
```bash
if (( cost > hard_quota )); then
    echo "❌ Quota exceeded: $cost / $hard_quota"
    echo "Request approval or defer task"
    exit 1
fi
```

### 5. Shared Resource Allocation Models

**Model A: Equal Base + Merit Pool**
```json
{
  "allocation_strategy": "equal_base_plus_merit",
  "total_budget": 15.00,
  "allocations": {
    "base_per_agent": 3.00,
    "merit_pool": 6.00
  }
}
```

**Model B: Role-Based**
```json
{
  "allocation_strategy": "role_based",
  "roles": {
    "primary_agents": {"allocation": 5.00, "agents": ["code", "chat"]},
    "background_agents": {"allocation": 2.00, "agents": ["investigator"]},
    "shared_pool": {"allocation": 3.00}
  }
}
```

**Model C: Dynamic (AWS-style)**
- No pre-allocation
- First-come-first-served from pool
- Monthly review and adjustment based on value delivered

## Recommended Implementation for Your System

### Current State (v1.0)
✅ Single shared key
✅ Usage logging with caller tags
✅ Manual review via `openrouter-budget.sh`

### Next Step: Enhanced Showback (v1.5)

**Effort**: 1-2 hours
**Impact**: High visibility, no enforcement friction

**Implementation**:
```bash
# 1. Add detailed tagging to llm-call.sh
CALLER_TAGS="{
  \"agent\": \"$CALLER\",
  \"session\": \"$SESSION_ID\",
  \"purpose\": \"$PURPOSE\",
  \"priority\": \"$PRIORITY\"
}"

# 2. Enhanced budget logging
log_usage_detailed() {
    jq --argjson tags "$CALLER_TAGS" \
       --argjson cost "$cost" \
       '.usage_log += [{
         timestamp: now,
         tags: $tags,
         cost: $cost,
         model: $model,
         tokens: {in: $tokens_in, out: $tokens_out}
       }]' "$BUDGET_FILE"
}

# 3. Rich reporting
./scripts/openrouter-budget.sh breakdown --by-agent
./scripts/openrouter-budget.sh breakdown --by-purpose
./scripts/openrouter-budget.sh forecast --next-week
```

### Future: Soft Quotas (v2.0)

**When**: After 2-3 months of showback data

**Trigger**: If any agent exceeds 50% of budget in <30% of time period

**Implementation**: Warnings at 50%, 75%, 90% of allocated quota

## Security Best Practices

### 1. Key Storage

**Priority order**:
1. ✅ Enterprise secret management (HashiCorp Vault, AWS Secrets Manager)
2. ✅ OS-level keychain with CLI access
3. ✅ File-based with restrictive permissions (600)
4. ❌ Environment variables (persists in shell history)
5. ❌ Committed to git (obviously never)

**Current implementation**: File-based (acceptable for prototype)

**Production recommendation**: Migrate to HashiCorp Vault or cloud secret manager

### 2. Key Rotation

**Industry standard**: 90-day rotation

**Implementation**:
```bash
# Script: rotate-openrouter-key.sh
# 1. Generate new key on OpenRouter dashboard
# 2. Test new key
# 3. Atomic swap (no downtime)
# 4. Revoke old key after 24h grace period
# 5. Log rotation in audit trail
```

### 3. Principle of Least Privilege

**Multiple keys for different risk levels**:
```json
{
  "production_key": {
    "budget": 15.00,
    "allowed_models": ["claude-3.5-sonnet", "claude-3-haiku"],
    "rate_limit": "100/day",
    "alerts": "enabled"
  },
  "development_key": {
    "budget": 5.00,
    "allowed_models": ["claude-3-haiku"],
    "rate_limit": "50/day"
  }
}
```

### 4. Audit Logging

**What to log**:
- Every API call (timestamp, agent, cost)
- Quota enforcement decisions
- Key rotation events
- Budget adjustments
- Anomalous usage patterns

**Retention**: 90 days minimum

## Anti-Patterns to Avoid

### ❌ Over-Engineering Early

**Problem**: Implementing chargeback before understanding usage patterns

**Solution**: Start with showback, add enforcement only when needed

### ❌ Shared Key Without Tracking

**Problem**: "Just use this API key" with no logging

**Solution**: Always tag calls with caller, even in trust model

### ❌ Hard Quotas Without Escape Valve

**Problem**: Agent blocked on critical task because quota exhausted

**Solution**: Approval workflow for quota increases or shared pool

### ❌ Storing Keys in Code

**Problem**: `API_KEY="sk-or-v1-..."` in scripts

**Solution**: Always external storage (file, keychain, secret manager)

### ❌ No Cost Awareness

**Problem**: Agents don't know/care about costs, make expensive calls

**Solution**: Show estimated cost before calls, log actual cost after

## Metrics to Track

### Operational Metrics

1. **Total spend per period** (daily/weekly/monthly)
2. **Cost per agent** (who's using what)
3. **Cost per model** (which models are expensive)
4. **Cost per task type** (what activities are costly)
5. **Cost per token** (efficiency over time)

### Leading Indicators

1. **Burn rate** ($ per day)
2. **Quota utilization** (% of allocated budget used)
3. **Days until budget exhaustion** (at current rate)
4. **Cost anomalies** (unusual spikes)

### Business Metrics

1. **Cost per valuable output** ($ per useful decision/analysis)
2. **ROI per agent** (value delivered vs cost)
3. **Cost optimization opportunities** (cheaper models for same quality)

## Tools Comparison

| Tool | Type | Cost | Per-Agent Tracking | Best For |
|------|------|------|-------------------|----------|
| **LangFuse** | Observability | Free (self-host) | ✅ Yes (userId) | Detailed tracing |
| **Helicone** | Proxy | Free (10k reqs) | ✅ Yes | Easy integration |
| **Custom (your system)** | Scripts | Free | ✅ Yes | Full control |
| **AWS API Gateway** | Gateway | Pay-per-use | ✅ Via tagging | Enterprise scale |
| **LangSmith** | Observability | $39/user/mo | ✅ Yes | LangChain users |

**Recommendation for your system**: Stay with custom scripts (you have full control), consider LangFuse if you want advanced analytics.

## Implementation Checklist

### Phase 1: Enhanced Showback (Now)
- [ ] Add detailed tagging to `llm-call.sh`
- [ ] Enhanced logging with purpose, priority
- [ ] Rich reporting scripts (breakdown by agent, purpose, forecast)
- [ ] Weekly cost review ritual

### Phase 2: Soft Quotas (Month 2)
- [ ] Analyze 1 month of showback data
- [ ] Define fair quota allocations
- [ ] Implement warning thresholds
- [ ] Approval workflow for overages

### Phase 3: Production Hardening (Month 3+)
- [ ] Migrate to secret manager (Vault/AWS)
- [ ] Implement key rotation
- [ ] Multiple keys (prod/dev/emergency)
- [ ] Anomaly detection alerts

## Summary: What Actually Works

### For Small Teams (2-5 agents):
✅ Showback with tagging
✅ Manual weekly review
✅ Trust-based shared budget
❌ Don't need: Hard quotas, complex approval workflows

### For Growing Systems (5-10 agents):
✅ Showback + soft quotas (warnings)
✅ Per-agent allocation (but flexible)
✅ Shared pool for overages
❌ Don't need: Multiple keys (yet)

### For Production Scale (10+ agents):
✅ Hard quotas with approval workflows
✅ Multiple keys by risk level
✅ Automated anomaly detection
✅ Integration with secret manager

## Your System: Recommended Next Steps

**Immediate** (this week):
1. Keep current single-key setup
2. Add `--purpose` flag to `llm-call.sh`
3. Enhance budget reporting (breakdown scripts)

**Month 1**:
1. Track usage patterns
2. Weekly review: Who used what, for what purpose, was it valuable?
3. Calculate baseline: Average cost per agent per week

**Month 2** (if needed):
1. Implement soft quotas based on baseline
2. Add warning messages at 50%, 75%, 90%
3. Create approval process for overages

**Month 3+** (optional):
1. Consider LangFuse for advanced analytics
2. Migrate to HashiCorp Vault if handling sensitive data
3. Implement key rotation schedule

---

**Document Version**: 1.0
**Based on**: Industry research (LangChain, AWS, LangFuse, Helicone)
**Recommendation**: Start simple (showback), add complexity only when needed
**Anti-Pattern**: Over-engineering before understanding usage
