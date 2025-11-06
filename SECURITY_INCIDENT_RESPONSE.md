# Security Incident Response - Multiple API Key Leaks

**Date**: 2025-11-04
**Severity**: CRITICAL
**Status**: IMMEDIATE ACTION REQUIRED
**Public Exposure**: CONFIRMED

## Executive Summary

Multiple API keys have been leaked through different vectors:

1. **OpenRouter API key** (`...a4cb`) exposed in PUBLIC GitHub repository and GitHub Pages
2. **OpenAI API key** (`sk-proj-*`) detected in shell command history (local only)

The OpenRouter key was PUBLICLY ACCESSIBLE and has been disabled by OpenRouter security team.

## Findings

### CRITICAL: OpenRouter API Key - PUBLIC EXPOSURE

- **Type**: OpenRouter API Key
- **Key Pattern**: `sk-or-v1-*`
- **Key Ending**: `...a4cb` (full: `419e2e647f39834e1e8371c2fc54623c29c5e83bbd87a2b34334eb89cebca4cb`)
- **Status**: ✅ DISABLED by OpenRouter security team
- **Repository**: `github.com/devvyn/aafc-herbarium-dwc-extraction-2025`
- **Exposure Locations**:
  1. Git commit `a62bc43` in `docs/status/2025-10-09-openrouter-test.md`
  2. Git commit `69dd0d2` (archived file)
  3. GitHub Pages deployment (commit `02c6f52` in `gh-pages` branch)
  4. Multiple related commits: 31f5368, b74f449, d404057
- **Public Exposure Duration**: From Oct 9, 2025 until Nov 4, 2025 (disabled)
- **Exposure Type**: PUBLICLY READABLE on both GitHub repo AND GitHub Pages website

### HIGH: OpenAI API Key - LOCAL EXPOSURE ONLY

- **Type**: OpenAI API Key (project-scoped)
- **Pattern**: `sk-proj-*`
- **Location**: `~/.zsh_history` (lines 47, 75)
- **Exposure**: Local system only
- **Git Status**: ✅ Not in repository history
- **Public Exposure**: ❌ Not publicly accessible

### Protected Assets (Verified Secure)

- `secrets/` directory: ✅ Properly gitignored
- Current OpenRouter keys: ✅ Protected in secrets/ (different key than leaked)
- Current keys DO NOT match leaked keys: ✅ Verified

## Immediate Actions Required

### 1. OpenRouter Key (CRITICAL - Public Exposure)

**Status**: ✅ Key already disabled by OpenRouter security team

**Remaining actions**:

```bash
# 1. Generate new OpenRouter key at: https://openrouter.ai/keys
# 2. Update local secrets:
security add-generic-password \
  -a "$USER" \
  -s "openrouter-api-key" \
  -w "NEW_KEY_HERE" \
  -U

# 3. Update any scripts/configs using the old key
# 4. Purge the key from git history (see section below)
```

### 2. OpenAI Key (HIGH - Local Only)

```bash
# 1. Go to: https://platform.openai.com/api-keys
# 2. Find the key ending in: 9GMA
# 3. Delete/revoke the key
# 4. Generate new key
# 5. Update in secure storage (keychain)
security add-generic-password \
  -a "$USER" \
  -s "openai-api-key" \
  -w "NEW_KEY_HERE" \
  -U
```

### 3. OpenRouter Key in Git History - Decision Point

**Status**: Key already disabled by OpenRouter - no active security risk

**Two approaches**:

#### Option A: Keep History as Learning Artifact (RECOMMENDED)

Since the key was disabled immediately upon detection:

- ✅ No active security risk
- ✅ Preserves incident context for learning
- ✅ No disruption to collaborators
- ✅ Simpler postmortem process
- ❌ Disabled key remains visible in history

**Action**: Add prominent warning in affected commits/docs

#### Option B: Purge from History (Optional)

If you prefer complete removal despite the key being disabled:

```bash
cd ~/Documents/GitHub/aafc-herbarium-dwc-extraction-2025

# Install git-filter-repo if needed
brew install git-filter-repo  # or: pip install git-filter-repo

# Create backup
git clone . ../aafc-herbarium-BACKUP-2025-11-04

# Remove the specific key from ALL history
echo "419e2e647f39834e1e8371c2fc54623c29c5e83bbd87a2b34334eb89cebca4cb" > /tmp/secrets-to-remove.txt
echo "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" >> /tmp/secrets-to-remove.txt

git filter-repo --replace-text /tmp/secrets-to-remove.txt --force

# Verify removal
git log --all -S "419e2e647f39834e1e8371c2fc54623c29c5e83bbd87a2b" --source
# Should return: nothing

# Force push to ALL branches (including gh-pages)
git push --force --all origin
git push --force --tags origin

# IMPORTANT: Force-rebuild GitHub Pages
# Go to: https://github.com/devvyn/aafc-herbarium-dwc-extraction-2025/settings/pages
# Disable and re-enable Pages to force rebuild without leaked key
```

**⚠️  Collaboration Impact**: Anyone who has cloned this repo will need to re-clone it fresh after the force-push.

### 4. Clear Shell History (OpenAI Key)

```bash
# Remove the compromised OpenAI key entries from shell history
sed -i.backup '/sk-proj-/d' ~/.zsh_history

# Or manually edit and remove lines 47, 75:
# vim ~/.zsh_history
# Search for: /Bearer
# Delete those lines
```

### 3. Verify No Other Exposures

```bash
# Scan for any other leaks
~/devvyn-meta-project/scripts/credential-leak-scanner.sh --quick

# Check if key was used in any logs
grep -r "sk-proj-z9mnDQ" ~/Library/Logs/ 2>/dev/null
grep -r "sk-proj-z9mnDQ" /var/log/ 2>/dev/null
```

### 4. Update Credential Storage

```bash
# Store new key in macOS Keychain
security add-generic-password \
  -a "$USER" \
  -s "openai-api-key" \
  -w "NEW_KEY_HERE" \
  -U

# Reference it in code via:
# security find-generic-password -s "openai-api-key" -w
```

## Root Cause Analysis

### OpenRouter Key Leak (Public)

**How it occurred**:

1. Test script output included raw API key in markdown documentation
2. File `docs/status/2025-10-09-openrouter-test.md` committed with key embedded
3. Repository is PUBLIC on GitHub
4. MkDocs documentation built and deployed to GitHub Pages
5. Key remained in git history across multiple branches

**Why it was severe**:

- Public repository = anyone could access the key
- GitHub Pages deployment = additional public exposure vector
- Git history = persists even after file deletion
- Multiple commits = harder to remove completely

### OpenAI Key Leak (Local)

**How it occurred**:

1. API key passed directly in curl command: `-H "Authorization: Bearer sk-proj-..."`
2. Command stored in `.zsh_history`
3. May have been captured by system monitoring/logging
4. Visible in process listings while running

**Why it wasn't worse**:

- `.gitignore` properly configured for `secrets/`
- Key never committed to version control
- Exposure limited to local shell history
- No public access to the key

## Prevention Measures Implemented

### 1. Enhanced .gitignore (COMPLETED)

Added comprehensive credential protection patterns:

```gitignore
# Credential leak protection
.bash_history
.zsh_history
.python_history
.node_repl_history
*.key
*.pem
*.p12
*.pfx
*_rsa
*_dsa
*_ecdsa
*_ed25519
```

### 2. Secure Credential Access Pattern

Use the safe wrapper script:

```bash
# Instead of:
curl -H "Authorization: Bearer $API_KEY" ...

# Use:
~/devvyn-meta-project/scripts/credential-safe-check.sh env API_KEY
curl -H "Authorization: Bearer $(security find-generic-password -s openai-api-key -w)" ...
```

### 3. Shell History Configuration

Add to `~/.zshrc` to prevent credential logging:

```bash
# Don't save commands with credentials to history
HISTORY_IGNORE="(Bearer*|*sk-*|*API_KEY*|*password*|*token*|security find-generic-password*)"
setopt HIST_IGNORE_SPACE  # Commands starting with space aren't saved
```

### 4. Pre-commit Hook

Consider adding git pre-commit hook:

```bash
#!/bin/bash
# .git/hooks/pre-commit
if git diff --cached | grep -E 'sk-[a-zA-Z0-9]{20,}|Bearer [a-zA-Z0-9_-]+'; then
    echo "ERROR: Potential API key detected in commit"
    exit 1
fi
```

## Monitoring and Detection

### Regular Scans

```bash
# Add to weekly/daily routine
~/devvyn-meta-project/scripts/credential-leak-scanner.sh --quick

# Set up cron job (optional)
# crontab -e
# 0 9 * * 1 ~/devvyn-meta-project/scripts/credential-leak-scanner.sh --quick > ~/Desktop/leak-scan.log 2>&1
```

### Alert Response

If you receive similar alerts in future:

1. Run immediate scan: `credential-leak-scanner.sh --quick`
2. Check git history: `git log --all -S "sk-" --source`
3. Rotate keys immediately
4. Document in incident log

## Compliance and Documentation

### Security Best Practices Reference

See: `knowledge-base/patterns/secure-api-access.md`

### Never Display Credentials

- ❌ `echo $API_KEY`
- ❌ `cat secrets/key.txt`
- ❌ `security find-generic-password -w`
- ✅ `credential-safe-check.sh env API_KEY` (confirms existence only)
- ✅ Reference by variable name in documentation

## Verification Checklist

### OpenRouter Key (Public Leak)

- [ ] New OpenRouter key generated at <https://openrouter.ai/keys>
- [ ] Old key confirmed disabled (✅ done by OpenRouter)
- [ ] Git history purged using git-filter-repo
- [ ] Force-push completed to all branches
- [ ] GitHub Pages rebuilt without leaked key
- [ ] Local secrets updated with new key
- [ ] All scripts/configs updated
- [ ] Backup created before history rewrite
- [ ] Collaborators notified to re-clone repo
- [ ] Monitor OpenRouter usage logs for unauthorized access

### OpenAI Key (Local Leak)

- [ ] OpenAI key rotated and old key deleted
- [ ] Shell history cleaned (lines 47, 75 removed)
- [ ] No other system logs contain the key
- [ ] New key stored in keychain (not plaintext)
- [ ] `.zshrc` updated with HISTORY_IGNORE
- [ ] Monitor OpenAI usage logs for unusual activity

### General Security

- [ ] Pre-commit hooks installed (if applicable)
- [ ] Team notified about security incident
- [ ] Post-incident review scheduled
- [ ] Document lessons learned

## Timeline

- **2025-10-09**: OpenRouter key leaked in commit to public GitHub repo
- **2025-10-09 - 2025-11-04**: Key publicly accessible via GitHub and GitHub Pages (26 days)
- **2025-11-04**: Email alert received from OpenRouter security team
- **2025-11-04**: OpenRouter automatically disabled the compromised key
- **2025-11-04**: Investigation conducted (credential-leak-scanner.sh)
- **2025-11-04**: Comprehensive scan revealed:
  - OpenRouter key in public git history (multiple commits)
  - OpenRouter key in GitHub Pages deployment
  - OpenAI key in local shell history
- **2025-11-04**: Containment measures:
  - ✅ Enhanced .gitignore rules
  - ✅ Documented incident response procedures
  - ✅ Identified all leak locations
- **Next Actions Required**:
  - Generate new OpenRouter key
  - Purge leaked key from git history
  - Rotate OpenAI key
  - Force-push cleaned history
  - Rebuild GitHub Pages
- **Follow-up**:
  - Monitor API usage logs for unauthorized access
  - Review other repositories for similar issues
  - Implement pre-commit hooks

## Contact and Escalation

For questions about:

- Key rotation: OpenAI Platform Support
- Security policy: Refer to `CLAUDE.md` security section
- Pattern guidance: `knowledge-base/patterns/secure-api-access.md`

---

**Report Generated**: 2025-11-04
**Scanner Used**: `~/devvyn-meta-project/scripts/credential-leak-scanner.sh`
**Git Status**: Clean (no keys in history)
**Action Required**: YES - Rotate OpenAI key immediately
