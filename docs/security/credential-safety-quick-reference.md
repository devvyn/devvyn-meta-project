# Credential Safety - Quick Reference

**For**: Humans and AI agents working with credentials
**Updated**: 2025-11-03

## Safe Credential Checking

```bash
# Check if credential exists (safe - no value exposed)
~/devvyn-meta-project/scripts/credential-safe-check.sh keychain SERVICE_NAME
~/devvyn-meta-project/scripts/credential-safe-check.sh env VARIABLE_NAME
~/devvyn-meta-project/scripts/credential-safe-check.sh file /path/to/key/file

# Examples
~/devvyn-meta-project/scripts/credential-safe-check.sh keychain ELEVEN_LABS_API_KEY
~/devvyn-meta-project/scripts/credential-safe-check.sh env ANTHROPIC_API_KEY
```

## Leak Detection

```bash
# Scan single file
~/devvyn-meta-project/scripts/credential-leak-scanner.sh ~/Desktop/file.txt

# Scan directory
~/devvyn-meta-project/scripts/credential-leak-scanner.sh --dir ~/devvyn-meta-project/

# Quick system scan (history, Desktop, Downloads, tmp)
~/devvyn-meta-project/scripts/credential-leak-scanner.sh --quick
```

## What NOT to Do

### ❌ Forbidden Commands

```bash
# NEVER - outputs raw credential
security find-generic-password -s SERVICE_NAME -w

# NEVER - exposes credential files
cat ~/devvyn-meta-project/secrets/key.txt
cat .env

# NEVER - prints credential values
printenv ANTHROPIC_API_KEY
echo $OPENAI_API_KEY
```

### ✅ Safe Alternatives

```bash
# Check existence only
credential-safe-check.sh keychain SERVICE_NAME
credential-safe-check.sh env VARIABLE_NAME

# Use in code (env var reference, not retrieval)
# Python
api_key = os.environ.get("ANTHROPIC_API_KEY")

# Shell (SDK reads automatically)
# Just set env var, don't echo/print it
export ANTHROPIC_API_KEY="value"  # In ~/.zshrc, not command line
```

## Safe Usage in Code

### ✅ Correct Pattern

```python
import os
from anthropic import Anthropic

# Reference env var - never print/log the value
api_key = os.environ.get("ANTHROPIC_API_KEY")

if not api_key:
    raise ValueError("ANTHROPIC_API_KEY not set. See README for setup.")

# SDK uses key internally, never logs it
client = Anthropic(api_key=api_key)
response = client.messages.create(...)
```

### ❌ Anti-Patterns

```python
# DON'T - reads secret file directly
with open(".env") as f:
    api_key = f.read()

# DON'T - prints secret value
print(f"Using key: {api_key}")

# DON'T - logs secret
logging.info(f"API key: {api_key}")
```

## When User Asks About Credentials

### If user says: "Do you have access to X credential?"

**Response pattern**:
```
Let me check if the credential is configured...
[Uses credential-safe-check.sh]

✅ Credential 'X' exists in keychain
or
❌ Credential 'X' not found - here's how to set it up: [instructions]
```

**NEVER**:
- Retrieve the actual credential value
- Display the credential in output
- Execute commands that print credentials

## Regular Maintenance

### Weekly
```bash
# Scan for credential leaks
~/devvyn-meta-project/scripts/credential-leak-scanner.sh --quick
```

### Before Sharing
- Screenshots: Review for visible env vars, terminal output
- Logs: Scan with `credential-leak-scanner.sh`
- Shell history: Check for credentials in command history

### After Leak Detection
1. Review findings
2. **Rotate credentials immediately**
3. Remove/redact from leaked locations
4. Update keychain/env with new credentials

## Emergency: Credential Exposed

1. **Stop** - Don't share/commit further
2. **Rotate** - Invalidate exposed credential immediately
3. **Scan** - Use `credential-leak-scanner.sh` to find all occurrences
4. **Clean** - Remove from logs, history, files
5. **Update** - Set new credential in keychain/env
6. **Document** - Note in `docs/security/` what happened

## Tool Locations

- **Safe checker**: `~/devvyn-meta-project/scripts/credential-safe-check.sh`
- **Leak scanner**: `~/devvyn-meta-project/scripts/credential-leak-scanner.sh`
- **Pattern guide**: `~/devvyn-meta-project/knowledge-base/patterns/secure-api-access.md`
- **Security rules**: `~/devvyn-meta-project/CLAUDE.md` (SECURITY section)

## Detectable Patterns

The leak scanner detects:
- API keys (sk- prefix and generic patterns)
- Bearer tokens
- AWS access keys (AKIA...)
- GitHub tokens (ghp_...)
- JWT tokens
- Private keys (PEM format)
- Long hex strings (64+ chars, potential secrets)

## Quick Decision Tree

**Need to check if credential exists?**
→ Use `credential-safe-check.sh`

**Need to use credential in code?**
→ Reference env var, let SDK load it

**Sharing files/logs?**
→ Scan with `credential-leak-scanner.sh` first

**Found credential in output?**
→ Rotate immediately, then clean up

**Writing new code?**
→ Consult `knowledge-base/patterns/secure-api-access.md`

---

**Remember**: If in doubt, check existence only - never retrieve values.
