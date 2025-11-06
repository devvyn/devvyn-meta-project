# Credential Leak Scanner

**Location**: `~/devvyn-meta-project/scripts/credential-leak-scanner.sh`
**Purpose**: Detect exposed credentials in files, directories, and system locations
**Created**: 2025-11-03 (in response to credential leak incident)

## Overview

Scans text files for credential-like patterns that may have been accidentally exposed. Useful for:
- Pre-commit checks before sharing code
- Regular security audits
- Incident investigation
- Cleanup after suspected leaks

## Usage

### Scan Single File

```bash
~/devvyn-meta-project/scripts/credential-leak-scanner.sh ~/Desktop/conversation.txt
```

Returns exit code 0 if clean, 1 if credentials found.

### Scan Directory

```bash
~/devvyn-meta-project/scripts/credential-leak-scanner.sh --dir ~/devvyn-meta-project/
```

Recursively scans all text files, excluding:
- `.git/` directories
- `node_modules/`, `__pycache__/`
- Virtual environments
- Build artifacts
- Binary files

### Quick System Scan

```bash
~/devvyn-meta-project/scripts/credential-leak-scanner.sh --quick
```

Scans high-risk locations:
- Shell history (`~/.zsh_history`, `~/.bash_history`)
- Desktop files (`.txt`, `.md`)
- Downloads folder
- `/tmp` logs

**Recommended frequency**: Weekly

## Detected Patterns

### API Keys

- **sk- prefix**: `sk-[a-zA-Z0-9]{20,}`
  - Common in OpenAI, Anthropic, Stripe keys
  - Example: `sk-proj-abc123...`

### Bearer Tokens

- **Pattern**: `Bearer [a-zA-Z0-9_\.\-]{20,}`
- Often used in HTTP Authorization headers

### AWS Keys

- **Pattern**: `AKIA[A-Z0-9]{16}`
- AWS access key format

### GitHub Tokens

- **Pattern**: `ghp_[a-zA-Z0-9]{36}`
- GitHub personal access tokens

### JWT Tokens

- **Pattern**: `eyJ[a-zA-Z0-9_\-]+\.eyJ[a-zA-Z0-9_\-]+`
- JSON Web Tokens (potential false positives in examples)

### Private Keys

- **Pattern**: `-----BEGIN [A-Z]+ PRIVATE KEY-----`
- PEM-encoded private keys (SSH, TLS, etc.)

### Long Hex Strings

- **Pattern**: `[a-f0-9]{64,}`
- Potential secrets (excludes git commit hashes when detected)

## Output Format

### When Clean

```
=== SCAN COMPLETE ===
Files scanned: 42
Findings: 0

✅ No credential leaks detected
```

Exit code: `0`

### When Leaks Found

```
⚠️  API Key (sk-): /Users/user/.zsh_history
47:  -H "Authorization: Bearer sk-proj-abc123..."

⚠️  Bearer Token: /Users/user/Desktop/notes.txt
12:  curl -H "Bearer eyJhbGciOi..."

=== SCAN COMPLETE ===
Files scanned: 42
Findings: 2

⚠️  CREDENTIALS DETECTED - ACTION REQUIRED

Next steps:
1. Review findings above
2. Rotate any exposed credentials immediately
3. Remove or redact sensitive files
4. Use credential-safe-check.sh for future verification
```

Exit code: `1`

## Integration Examples

### Pre-Commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

if ~/devvyn-meta-project/scripts/credential-leak-scanner.sh --dir .; then
    echo "✅ No credentials detected"
else
    echo "❌ ABORT: Credentials detected in commit"
    exit 1
fi
```

### Weekly Cron Job

```bash
# Run every Monday at 9am
0 9 * * 1 ~/devvyn-meta-project/scripts/credential-leak-scanner.sh --quick && notify "Clean" || notify "LEAKS FOUND"
```

### CI/CD Pipeline

```yaml
# GitHub Actions example
- name: Scan for credentials
  run: |
    ./scripts/credential-leak-scanner.sh --dir .
    if [ $? -ne 0 ]; then
      echo "::error::Credentials detected in repository"
      exit 1
    fi
```

## Limitations

### False Positives

- Example credentials in documentation (mitigated by excluding "example", "placeholder")
- Long commit hashes (mitigated by excluding "commit", "hash", "sha256")
- JWT tokens in test fixtures

**Recommendation**: Review findings manually before taking action.

### False Negatives

- Credentials not matching standard patterns
- Obfuscated or encoded credentials
- Credentials split across multiple lines
- Binary-encoded secrets

**Recommendation**: Combine with other security tools and manual review.

## Response Playbook

### If Scan Finds Credentials

**1. Immediate containment**
```bash
# Stop any sharing/committing
# Review the finding
cat <file> | grep -A2 -B2 <line-number>
```

**2. Assess scope**
```bash
# When was it created?
ls -l <file>

# Is it committed to git?
git log --all --full-history -- <file>

# Is it synced/backed up?
# Check Time Machine, cloud sync, etc.
```

**3. Rotate credentials**
- Invalidate exposed credential immediately at provider
- Generate new credential
- Update keychain/env with new value

**4. Clean up**
```bash
# Remove from file
vi <file>

# Remove from git history (if committed)
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch <file>" \
  --prune-empty --tag-name-filter cat -- --all

# Clean shell history
vi ~/.zsh_history
```

**5. Document**
- Log incident in `docs/security/credential-leak-incident-YYYY-MM-DD.md`
- Note what was exposed, how, and remediation

## Complementary Tools

Use together with:

**credential-safe-check.sh**
- Checks credential existence without exposing values
- Use when you need to verify setup, not scan for leaks

**secure-api-access.md pattern**
- Guidance on proper credential handling in code
- Preventive (stops leaks before they happen)

**CLAUDE.md security directives**
- Rules for AI agents working with credentials
- Behavioral controls

## Known Detections (Confirmed)

From incident 2025-11-03:
- ✅ Detected Bearer tokens in `~/.zsh_history`
- ✅ Detected API keys with sk- prefix
- ✅ Exit code correctly indicated findings

## Future Enhancements

Potential improvements:
- HTML report generation with severity scoring
- Integration with macOS notifications
- Pattern library expansion (database connection strings, etc.)
- Whitelist/ignore file support
- Parallel processing for large directories

## Related Documentation

- **Quick reference**: `docs/security/credential-safety-quick-reference.md`
- **Incident report**: `docs/security/credential-leak-incident-2025-11-03.md`
- **Safe patterns**: `knowledge-base/patterns/secure-api-access.md`
- **Security rules**: `CLAUDE.md` (SECURITY section)

---

**Remember**: Detection is reactive. Prevention is better. Use safe credential handling patterns to avoid leaks in the first place.
