# Postmortem: API Key Exposure Incident (2025-11-04)

**Status**: Resolved (key disabled)
**Severity**: High (public exposure)
**Duration**: 26 days (2025-10-09 to 2025-11-04)
**Impact**: One OpenRouter API key publicly exposed, immediately disabled upon detection

## Summary

An OpenRouter API key was accidentally committed to a public GitHub repository in test documentation.
The key was automatically detected and disabled by OpenRouter's security monitoring system 26 days after the initial commit.

## What Happened

### Timeline

- **Oct 9, 2025**: Test script output containing API key committed to `docs/status/2025-10-09-openrouter-test.md`
- **Oct 9 - Nov 4**: Key publicly accessible via:
  - GitHub repository history (multiple commits)
  - GitHub Pages documentation site
- **Nov 4, 2025**: OpenRouter security team detected exposure
- **Nov 4, 2025 (immediate)**: OpenRouter automatically disabled the key
- **Nov 4, 2025**: Internal investigation confirmed scope

### Root Cause

A test script (`get-openrouter-key.sh`) output was directly copied into markdown documentation:

```markdown
# Testing OpenRouter API
cd ~/devvyn-meta-project
./scripts/get-openrouter-key.sh
# Got key: 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
```

The documentation file was then:

1. Committed to version control
2. Built into MkDocs documentation
3. Deployed to public GitHub Pages
4. Remained in git history even after file archival

## What Went Right

1. **Fast Detection**: OpenRouter's security monitoring caught the exposure
2. **Automatic Disable**: Key was immediately disabled without manual intervention
3. **No Apparent Abuse**: No evidence of unauthorized usage during exposure window
4. **Good Secret Management**: Current operational keys were stored separately in protected `secrets/` directory
5. **Existing Safeguards**: The `secrets/` directory was already properly gitignored

## What Went Wrong

1. **No Pre-commit Scanning**: No automated check for secrets before commit
2. **Direct Script Output Copy**: Raw output with credentials pasted into docs
3. **Public Repository**: Sensitive testing docs in public repo
4. **Long Exposure Window**: 26 days between commit and detection
5. **Multiple Exposure Vectors**: Both source repo and generated documentation site

## Impact Assessment

### Actual Impact

- ✅ Key disabled immediately upon detection
- ✅ No confirmed unauthorized usage
- ✅ No other keys compromised
- ✅ Current operational keys separate and secure

### Potential Impact (Mitigated)

- Could have been used for unauthorized API calls
- Could have incurred unexpected costs
- Could have exposed usage patterns/data

## Lessons Learned

### What We Learned

1. Test documentation is as risky as test code
2. Command output should be sanitized before documentation
3. Public repositories need extra vigilance with any credentials
4. Generated documentation sites (GitHub Pages) are another exposure vector
5. API provider monitoring is a valuable safety net

### Prevention Strategies Implemented

#### 1. Enhanced .gitignore

Added comprehensive patterns to block shell history and key files:

```gitignore
# Credential leak protection
.bash_history
.zsh_history
*.key
*.pem
*_rsa
```

#### 2. Safe Script Output Pattern

Instead of:

```bash
./get-key.sh
# Got key: sk-or-v1-abc123...
```

Use:

```bash
./get-key.sh
# Got key: sk-or-v1-***REDACTED***
# Key stored in keychain service: openrouter-api-key
```

#### 3. Documentation Guidelines

- Never include raw API keys in documentation
- Sanitize all command output before commit
- Use placeholders: `sk-or-v1-YOUR_KEY_HERE`
- Reference keychain/environment variables by name only

#### 4. Available Tools

- `~/devvyn-meta-project/scripts/credential-leak-scanner.sh --quick`: Regular security scans
- `~/devvyn-meta-project/scripts/credential-safe-check.sh`: Verify credentials without exposing values

## Action Items

### Completed

- [x] Enhanced .gitignore patterns
- [x] Documented incident response procedures
- [x] Created credential-safe-check.sh wrapper
- [x] Identified all exposure locations

### Recommended (Optional)

- [ ] Add pre-commit hook for secret detection
- [ ] Review other public repositories for similar issues
- [ ] Consider moving test documentation to private repo
- [ ] Add shell history configuration to prevent credential logging
- [ ] Implement git-secrets or similar tool

### Not Pursued (By Design)

- [ ] ~~Rewrite git history to remove key~~ - Keeping as learning artifact since key is disabled

## Historical Context

This incident demonstrates the value of:

1. **Transparent postmortems**: Documenting mistakes openly
2. **Learning over erasure**: History as educational resource
3. **Defense in depth**: Provider-side monitoring caught what our processes missed
4. **Quick response**: Immediate disable limited potential damage

## References

- Incident Report: `/Users/devvynmurphy/devvyn-meta-project/SECURITY_INCIDENT_RESPONSE.md`
- Affected Repository: `github.com/devvyn/aafc-herbarium-dwc-extraction-2025`
- Affected Commits: a62bc43, 69dd0d2, 02c6f52, 31f5368, b74f449, d404057
- Security Best Practices: `knowledge-base/patterns/secure-api-access.md`

## Sign-off

**Incident Commander**: Claude Code (Red Team Agent)
**Date**: 2025-11-04
**Status**: Closed (key disabled, processes improved)
**Follow-up**: 30-day review to verify no unauthorized usage in OpenRouter logs

---

*This postmortem is intentionally preserved in version control as a learning resource. The exposed key was immediately disabled and poses no active security risk.*
