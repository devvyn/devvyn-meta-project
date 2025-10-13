# OpenRouter API Setup Guide

## For Code Agents: Acquiring API Access

### Current Status
✅ OpenRouter budget system is implemented and operational
❌ API key acquisition requires human action

### How to Get OpenRouter API Key (Human Required)

**If you're a Code instance reading this**: You cannot complete this process autonomously. Escalate to human operator.

**For human operators**:

1. **Sign Up**
   - Visit: https://openrouter.ai
   - Create account (email/password or OAuth)
   - Verify email

2. **Add Credits**
   - Navigate to: Settings → Billing
   - Add payment method
   - Purchase credits (current system: $15 prepaid)
   - Minimum typically $5-10

3. **Generate API Key**
   - Navigate to: Settings → API Keys
   - Click "Create New Key"
   - Copy key (format: `sk-or-v1-...`)
   - **Important**: Save immediately - cannot retrieve later

4. **Store Key Securely**
   ```bash
   # Option 1: File-based (recommended for CLI)
   echo 'sk-or-v1-YOUR-KEY-HERE' > ~/devvyn-meta-project/secrets/openrouter.key
   chmod 600 ~/devvyn-meta-project/secrets/openrouter.key

   # Option 2: macOS Keychain
   security add-generic-password \
     -s "OpenRouter" \
     -a "bridge-control" \
     -w "sk-or-v1-YOUR-KEY-HERE"
   ```

5. **Verify Access**
   ```bash
   # Test key retrieval
   ~/devvyn-meta-project/scripts/get-openrouter-key.sh

   # Check budget system
   ~/devvyn-meta-project/scripts/openrouter-budget.sh status

   # Test API call (small request)
   ~/devvyn-meta-project/scripts/llm-call.sh \
     --prompt "Reply with just 'OK'" \
     --max-tokens 5 \
     --caller test
   ```

### Key Security Best Practices

**Do**:
- ✅ Store in gitignored location (`secrets/`)
- ✅ Use restrictive permissions (600)
- ✅ Rotate periodically
- ✅ Monitor usage (`openrouter-budget.sh log`)

**Don't**:
- ❌ Commit to git
- ❌ Share in messages/logs
- ❌ Store in environment variables (persists in shell history)
- ❌ Include in screenshots/documentation

### Budget Management

**Initial Setup**:
```json
{
  "initial_budget": 15.00,
  "remaining": 15.00,
  "last_checked": "2025-10-09",
  "usage_log": []
}
```

**Monitoring**:
```bash
# Current status
./scripts/openrouter-budget.sh status

# Usage history
./scripts/openrouter-budget.sh log

# Top consumers
./scripts/openrouter-budget.sh top
```

**When budget runs low**:
1. Review usage logs
2. Decide: Add more credits or optimize usage
3. If adding credits: Purchase on OpenRouter dashboard
4. Update `secrets/openrouter-budget.json`:
   ```bash
   # Manual update or reset
   ./scripts/openrouter-budget.sh reset
   ```

## For Code Agents: Detecting Unblocked State

### Error States and Resolution

**Error**: "OpenRouter API key not found"
```bash
# Check 1: Does key file exist?
ls -la ~/devvyn-meta-project/secrets/openrouter.key

# Check 2: Can key be retrieved?
~/devvyn-meta-project/scripts/get-openrouter-key.sh

# Check 3: Is budget system initialized?
cat ~/devvyn-meta-project/secrets/openrouter-budget.json
```

**Resolution Path**:
1. If file missing → Escalate to human (acquisition required)
2. If file exists but retrieval fails → Check permissions (chmod 600)
3. If budget exhausted → Report to human, defer non-critical LLM usage

**Escalation Template**:
```markdown
# OpenRouter Access Blocked

**Issue**: API key not available
**Required Action**: Human must acquire OpenRouter API key
**Instructions**: See docs/OPENROUTER_SETUP.md

**Steps**:
1. Visit https://openrouter.ai and create account
2. Add $15 credits (or desired amount)
3. Generate API key
4. Store at: ~/devvyn-meta-project/secrets/openrouter.key

**Self-Service Check**:
- [ ] Key file exists: `secrets/openrouter.key`
- [ ] Key retrieval works: `scripts/get-openrouter-key.sh`
- [ ] Budget initialized: `secrets/openrouter-budget.json`
- [ ] Test call succeeds: `scripts/llm-call.sh --prompt "test" --max-tokens 5`

**ETA for unblock**: Depends on human operator availability (~10 minutes hands-on time)
```

## Troubleshooting

### Key Not Found

```bash
# Check file permissions
ls -la ~/devvyn-meta-project/secrets/openrouter.key

# Should show: -rw------- (600)
# If not: chmod 600 ~/devvyn-meta-project/secrets/openrouter.key
```

### Invalid Key Format

OpenRouter keys have format: `sk-or-v1-[64 hex characters]`

```bash
# Validate format
key=$(cat ~/devvyn-meta-project/secrets/openrouter.key)
echo "$key" | grep -E '^sk-or-v1-[0-9a-f]{64}$' && echo "Valid format" || echo "Invalid format"
```

### API Call Failures

```bash
# Test with minimal request
./scripts/llm-call.sh \
  --prompt "test" \
  --max-tokens 5 \
  --dry-run

# Check actual call
./scripts/llm-call.sh \
  --prompt "Reply OK" \
  --max-tokens 5 \
  --caller troubleshooting
```

Common errors:
- `401 Unauthorized` → Invalid key, regenerate on OpenRouter
- `402 Payment Required` → Credits exhausted, add funds
- `429 Too Many Requests` → Rate limit, wait or upgrade plan

### Budget Tracking Errors

```bash
# Verify budget file format
jq . ~/devvyn-meta-project/secrets/openrouter-budget.json

# Reset if corrupted
cp ~/devvyn-meta-project/secrets/openrouter-budget.json ~/devvyn-meta-project/secrets/openrouter-budget.json.backup
./scripts/openrouter-budget.sh reset
```

## Alternative: Self-Service for Advanced Users

**If you have existing OpenRouter key**:

```bash
# Quick setup (paste key when prompted)
cat > ~/devvyn-meta-project/secrets/openrouter.key
# Paste key, then Ctrl+D
chmod 600 ~/devvyn-meta-project/secrets/openrouter.key

# Verify
~/devvyn-meta-project/scripts/openrouter-budget.sh status
```

**If you're migrating from another project**:

```bash
# Copy existing key
cp /path/to/other/project/openrouter.key ~/devvyn-meta-project/secrets/
chmod 600 ~/devvyn-meta-project/secrets/openrouter.key

# Initialize budget (adjust amount as needed)
cat > ~/devvyn-meta-project/secrets/openrouter-budget.json << 'EOF'
{
  "initial_budget": 15.00,
  "remaining": 15.00,
  "last_checked": "2025-10-09",
  "usage_log": [],
  "notes": "Migrated from other project"
}
EOF
```

## Cost Reference

**Current Pricing** (as of 2025-10-09):

| Model | Input (per 1M tokens) | Output (per 1M tokens) |
|-------|----------------------|----------------------|
| Claude Sonnet 3.5 | $3.00 | $15.00 |
| Claude Haiku | $0.25 | $1.25 |
| GPT-4o-mini | $0.15 | $0.60 |

**Typical Usage**:
- Small query (100 in / 50 out): ~$0.001
- Medium query (2k in / 500 out): ~$0.015
- Large analysis (10k in / 2k out): ~$0.06

**$15 budget estimate**:
- ~15,000 small queries
- ~1,000 medium queries
- ~250 large analyses

## Summary for Code Agents

**Can I acquire a key autonomously?** ❌ No - requires human with payment method

**Can I detect if system is ready?** ✅ Yes:
```bash
[[ -f ~/devvyn-meta-project/secrets/openrouter.key ]] && \
~/devvyn-meta-project/scripts/get-openrouter-key.sh >/dev/null 2>&1 && \
echo "OpenRouter ready" || echo "OpenRouter blocked - escalate to human"
```

**What should I do if blocked?**
1. Check documentation (this file)
2. Create escalation message
3. Send via bridge to human
4. Defer non-critical LLM tasks

**Can I help human with setup?** ✅ Yes:
- Guide them through this doc
- Verify file permissions after they add key
- Test API calls to confirm setup
- Monitor budget usage

---

**Document Version**: 1.0
**Last Updated**: 2025-10-09
**Status**: Production-ready, human setup required
