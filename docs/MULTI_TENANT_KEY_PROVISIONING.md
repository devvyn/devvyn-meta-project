# Multi-Tenant API Key Provisioning
## Architectural Patterns Enabled by Provisioning Keys

**Status**: Infrastructure operational (2025-10-09)
**Capability**: Programmatic API key creation with per-key limits

## Why Provisioning Keys Matter

**Traditional approach**:
- Manual key creation on OpenRouter dashboard
- Shared key across all users/services
- No isolation, no per-tenant limits
- Manual rotation

**Provisioning key approach**:
- ✅ Automated key creation
- ✅ Per-tenant/service isolation
- ✅ Per-key spending limits
- ✅ Programmatic rotation
- ✅ Revocation without affecting others

## Use Case 1: Multi-Tenant SaaS Application

**Scenario**: You build an AI-powered app, users sign up and use LLM features

### Architecture

```
User Signs Up
    ↓
./scripts/provision-openrouter-key.sh \
  --name "user-${USER_ID}" \
  --limit ${USER_PLAN_LIMIT}
    ↓
Store key in database: users.openrouter_key
    ↓
User makes LLM request
    ↓
Backend uses user's dedicated key
    ↓
Track usage per user (automatic via separate keys)
```

### Implementation

```bash
# On user signup (in your app backend)
provision_user_key() {
    local user_id="$1"
    local plan="$2"

    # Determine limit by plan
    local limit
    case "$plan" in
        free) limit=1.00 ;;
        basic) limit=5.00 ;;
        pro) limit=20.00 ;;
        enterprise) limit=100.00 ;;
    esac

    # Create key
    ./scripts/provision-openrouter-key.sh \
        --name "user-${user_id}" \
        --limit "$limit"

    # Store in database
    # psql -c "UPDATE users SET openrouter_key = '$key' WHERE id = '$user_id'"
}

# On user upgrade
upgrade_user() {
    local user_id="$1"

    # Revoke old key
    ./scripts/provision-openrouter-key.sh --revoke "$old_key_id"

    # Provision new key with higher limit
    provision_user_key "$user_id" "pro"
}
```

### Benefits

- **Isolation**: One user can't exhaust another's budget
- **Security**: Compromised key affects only one user
- **Billing**: Track exact usage per customer
- **Compliance**: Revoke user access without affecting platform
- **Fair usage**: Platform-level rate limits apply per key

## Use Case 2: Microservices Architecture

**Scenario**: Multiple services in your infrastructure need LLM access

### Architecture

```
Service Deployment
    ↓
Provision key per service:
  - api-service: $50/month
  - background-jobs: $20/month
  - analytics: $10/month
  - dev-environment: $5/month
    ↓
Each service uses dedicated key
    ↓
Track usage per service
Monitor for anomalies
Rotate keys monthly
```

### Implementation

```bash
# Deploy service
deploy_service() {
    local service_name="$1"
    local environment="$2"  # prod, staging, dev
    local monthly_limit="$3"

    # Create key
    key=$(./scripts/provision-openrouter-key.sh \
        --name "${environment}-${service_name}" \
        --limit "$monthly_limit")

    # Inject into service environment
    kubectl create secret generic openrouter-key \
        --from-literal=key="$key" \
        --namespace="$service_name"
}

# Monthly rotation
rotate_service_keys() {
    for service in api-service background-jobs analytics; do
        echo "Rotating key for $service..."
        ./scripts/provision-openrouter-key.sh --rotate \
            --name "$service"
    done
}
```

### Benefits

- **Blast radius**: Compromised service key doesn't expose others
- **Cost attribution**: Track which service costs what
- **Independent limits**: Critical services get higher limits
- **Rollback safety**: New deployment gets new key, old keeps working
- **Audit trail**: Know which service made which request

## Use Case 3: Per-Agent Key Allocation

**Scenario**: Multiple AI agents in meta-project need fair resource allocation

### Architecture

```
Agent Ecosystem:
  - code: $5/month (primary interactive)
  - chat: $5/month (strategic)
  - investigator: $2/month (background)
  - hopper: $1/month (low-priority)
  - emergency-pool: $2/month (shared overflow)
```

### Implementation

```bash
# Provision agent keys
provision_agent_keys() {
    ./scripts/provision-openrouter-key.sh --name "code-agent" --limit 5.00
    ./scripts/provision-openrouter-key.sh --name "chat-agent" --limit 5.00
    ./scripts/provision-openrouter-key.sh --name "investigator" --limit 2.00
    ./scripts/provision-openrouter-key.sh --name "hopper-agent" --limit 1.00
    ./scripts/provision-openrouter-key.sh --name "emergency-pool" --limit 2.00
}

# Enhanced llm-call.sh
llm_call_with_agent_key() {
    local caller="$1"
    local agent_key_file="$PROJECT_ROOT/secrets/keys/${caller}.key"

    # Use dedicated agent key if exists
    if [[ -f "$agent_key_file" ]]; then
        API_KEY=$(cat "$agent_key_file")
    else
        # Fall back to emergency pool
        API_KEY=$(cat "$PROJECT_ROOT/secrets/keys/emergency-pool.key")
        echo "⚠️  Using emergency pool for $caller" >&2
    fi

    # Make call with appropriate key
}
```

### Benefits

- **Fair allocation**: Each agent has guaranteed budget
- **No monopolization**: One agent can't exhaust collective budget
- **Transparency**: OpenRouter dashboard shows per-agent usage
- **Graceful degradation**: Emergency pool prevents total failure
- **Easy rebalancing**: Adjust limits based on observed value

## Use Case 4: Customer API Reselling

**Scenario**: You resell OpenRouter access to customers with markup

### Architecture

```
Your Platform
    ↓
Customer signs up for API access
    ↓
Provision key: --limit ${customer_prepaid_amount}
    ↓
Customer uses key directly (or via your wrapper)
    ↓
Monitor usage, alert at 80%
    ↓
Customer recharges → increase key limit
```

### Implementation

```bash
# Customer purchases $50 of credits
customer_purchase() {
    local customer_id="$1"
    local amount="$2"

    # Get existing key or create new
    local key_id=$(get_customer_key_id "$customer_id")

    if [[ -z "$key_id" ]]; then
        # New customer - provision key
        ./scripts/provision-openrouter-key.sh \
            --name "customer-${customer_id}" \
            --limit "$amount"
    else
        # Existing customer - increase limit
        ./scripts/provision-openrouter-key.sh \
            --increase-limit "$key_id" "$amount"
    fi

    # Your markup: customer paid $50, you set $40 limit (20% margin)
    actual_limit=$(echo "$amount * 0.8" | bc)
}
```

### Benefits

- **Automated billing**: OpenRouter tracks usage per customer
- **Prepaid model**: Customer can't exceed purchased limit
- **No overage surprises**: Hard limits prevent unexpected bills
- **Self-service**: Customers can check usage, recharge
- **Margin protection**: You control markup via limit setting

## Use Case 5: Automated Key Rotation (Security)

**Scenario**: Rotate keys monthly for security best practice

### Implementation

```bash
#!/bin/bash
# Monthly cron job: 0 0 1 * * /path/to/rotate-keys.sh

rotate_all_keys() {
    # List all active keys
    ./scripts/provision-openrouter-key.sh --list | grep "ID:" | while read -r line; do
        key_id=$(echo "$line" | sed 's/ID: //')
        key_name=$(echo "$line" | sed 's/Name: //')

        # Skip recently created keys
        created=$(get_key_creation_date "$key_id")
        age_days=$(days_since "$created")

        if (( age_days > 30 )); then
            echo "Rotating key: $key_name (age: $age_days days)"

            # Create new key
            new_key=$(./scripts/provision-openrouter-key.sh \
                --name "${key_name}-$(date +%Y%m)" \
                --limit $(get_key_limit "$key_id"))

            # Update services to use new key
            update_service_key "$key_name" "$new_key"

            # Grace period: Keep old key active for 24h
            sleep 86400

            # Revoke old key
            ./scripts/provision-openrouter-key.sh --revoke "$key_id"
        fi
    done
}
```

### Benefits

- **Compliance**: Meet security policies requiring key rotation
- **Breach mitigation**: Leaked key auto-expires
- **Zero downtime**: New key active before old revoked
- **Audit trail**: Historical record of all keys
- **Automated**: No manual intervention needed

## Use Case 6: Development vs Production Environments

**Scenario**: Separate keys for dev/staging/prod with different limits

### Architecture

```
Environment Isolation:
  - dev:     $5/month  (low limit, experimenting OK)
  - staging: $10/month (realistic testing)
  - prod:    $100/month (production workload)
```

### Implementation

```bash
# Deploy to environment
deploy() {
    local env="$1"

    case "$env" in
        dev)
            limit=5.00
            models="claude-3-haiku"  # Cheaper models only
            ;;
        staging)
            limit=10.00
            models="all"
            ;;
        prod)
            limit=100.00
            models="all"
            ;;
    esac

    # Provision environment-specific key
    key=$(./scripts/provision-openrouter-key.sh \
        --name "${env}-$(git rev-parse --short HEAD)" \
        --limit "$limit")

    # Deploy with key
    deploy_service "$env" "$key"
}
```

### Benefits

- **Cost control**: Dev can't accidentally run up prod-level bills
- **Isolation**: Dev key leak doesn't affect production
- **Testing realism**: Staging has budget for realistic tests
- **Deploy confidence**: Each deployment gets fresh key

## Enhanced Provisioning Script Features

**Current capabilities** (implemented):
- ✅ Create key with spending limit
- ✅ List existing keys
- ✅ Revoke key
- ✅ Basic rotation

**Future enhancements**:
```bash
# Increase existing key limit
./scripts/provision-openrouter-key.sh --increase-limit <key-id> 10.00

# Set key metadata (for tracking)
./scripts/provision-openrouter-key.sh --metadata '{"env": "prod", "service": "api"}'

# Bulk operations
./scripts/provision-openrouter-key.sh --revoke-all --older-than 90days

# Key health check
./scripts/provision-openrouter-key.sh --health-check  # Check all keys, report status
```

## Best Practices

### 1. Naming Convention

```
Format: {environment}-{service}-{purpose}-{date}

Examples:
  prod-api-service-202510
  dev-code-agent-202510
  customer-12345-main
  staging-background-jobs-202510
```

### 2. Limit Strategy

**Conservative**:
- Start with low limits
- Monitor usage patterns
- Increase based on actual need

**Tiered**:
```
Tier 1 (Critical): $100/month
Tier 2 (Important): $20/month
Tier 3 (Background): $5/month
Tier 4 (Experimental): $1/month
```

### 3. Monitoring

```bash
# Daily usage report
./scripts/provision-openrouter-key.sh --usage-report --period yesterday

# Alert on high usage
./scripts/provision-openrouter-key.sh --alert-if-over 80%

# Forecast exhaustion
./scripts/provision-openrouter-key.sh --forecast  # "Key X will hit limit in 3 days"
```

### 4. Secrets Management

**Don't**:
- ❌ Store keys in code
- ❌ Share keys between unrelated services
- ❌ Use production keys in development

**Do**:
- ✅ Store in secret manager (Vault, AWS Secrets Manager)
- ✅ Inject at runtime
- ✅ Rotate regularly
- ✅ Audit access

## Migration Path: Shared Key → Provisioned Keys

**Phase 1: Current state** (✅ Complete)
- Single shared key
- Basic usage tracking
- Manual creation

**Phase 2: Hybrid** (Optional)
- Keep shared key as fallback
- Provision per-agent keys
- Test in parallel
- Monitor for differences

**Phase 3: Full migration**
- All agents use dedicated keys
- Revoke shared key
- Pure provisioned model

**Phase 4: Advanced**
- Automated rotation
- Usage-based reallocation
- Predictive budget management

## Cost Comparison

### Shared Key Model
```
Total budget: $15/month
All agents share
No isolation
Manual tracking
```

### Provisioned Key Model
```
Platform cost: $0 (provisioning key is free)
Per-key limits: Flexible
Isolation: Complete
Tracking: Automatic (OpenRouter dashboard)
Overhead: Initial setup only
```

**Verdict**: Provisioning has no extra cost, only benefits.

## Security Considerations

### Provisioning Key Protection

**Risk**: Provisioning key can create unlimited API keys

**Mitigation**:
```bash
# Store provisioning key with maximum security
chmod 400 ~/devvyn-meta-project/secrets/openrouter-provisioning.key

# Restrict to root/admin only
sudo chown root:root openrouter-provisioning.key

# Or use secret manager
vault kv put secret/openrouter provisioning_key="sk-or-v1-..."

# Audit provisioning key usage
./scripts/provision-openrouter-key.sh --audit  # Log all key creations
```

### API Key Exposure

**If API key leaks**:
1. Revoke immediately: `./scripts/provision-openrouter-key.sh --revoke <key-id>`
2. Provision new key
3. Update affected service
4. Review audit logs for unauthorized usage

**If provisioning key leaks**:
1. Revoke on OpenRouter dashboard
2. Generate new provisioning key
3. Revoke ALL API keys created by old provisioning key
4. Re-provision from clean slate

## Conclusion

**Provisioning keys transform API key management from manual to programmatic.**

**Enables**:
- Multi-tenant applications
- Microservices isolation
- Fair resource allocation
- Automated security practices
- Customer API reselling

**Current status**: Infrastructure operational, ready for production use

**Next steps**: Choose use case, implement pattern, monitor results

---

**Implementation Date**: 2025-10-09
**Provisioning Key**: Operational
**First Provisioned Key**: ✅ Created with $15 limit
**Status**: Production-ready
