# Pattern: Systematic Repository Cleanup Strategy

**Pattern ID:** repository-cleanup-strategy
**Category:** DevOps, Maintenance, Technical Debt
**Source Project:** AAFC Herbarium DWC Extraction
**Date Discovered:** 2025-10-10
**Status:** Production-validated

## Problem

**Repository Clutter Accumulation:**
- 779 duplicate files (macOS conflict copies with " 2", " 3", " 4" suffixes)
- 41 scripts in root directory (user-facing + development tools mixed)
- Inconsistent organization (no clear entry points)
- Secrets accidentally committed (.claude/settings.local.json with API keys)
- High cognitive load for new developers

**Root Cause:**
- Rapid development without cleanup discipline
- macOS Finder file conflicts creating duplicates
- No clear organizational structure
- Inadequate .gitignore rules

## Solution

**Phased Cleanup with Clear Categorization:**
1. **Phase 1:** Delete obvious cruft (duplicates)
2. **Phase 2:** Organize development tools (scripts/)
3. **Phase 3:** Archive one-off scripts (archive/)
4. **Phase 4:** Secure secrets (.gitignore + removal)

## Implementation

### Phase 1: Delete Duplicates

```bash
# Find all macOS conflict copies
/usr/bin/find . -name "*\ [0-9].*" -type f

# Verify list before deletion
/usr/bin/find . -name "*\ [0-9].*" -type f | head -n 20

# Delete (use BSD find, not fd)
/usr/bin/find . -name "*\ [0-9].*" -type f -delete

# Result: 779 files deleted
```

**Why BSD find:**
- `fd` tool may have different behavior with special characters
- BSD find (`/usr/bin/find`) is standard on macOS
- Consistent behavior across systems

### Phase 2: Organize Scripts

**Categorization:**

```bash
# Keep in root (user-facing entry points)
# - cli.py (main CLI)
# - review_web.py (web interface)
# - herbarium_ui.py (UI launcher)
# - bootstrap.sh (setup)
# - test-regression.sh (CI)

# Move to scripts/ (development tools)
mkdir -p scripts/
mv analyze_gpt4omini_accuracy.py scripts/
mv compare_engines.py scripts/
mv test_interfaces.py scripts/
# ... (16 files total)

# Archive (one-off scripts)
mkdir -p archive/old_scripts/
mv edit_validation.py archive/old_scripts/
mv fix_s3_urls.py archive/old_scripts/
# ... (6 files total)
```

**Decision Criteria:**

| Category | Criteria | Location |
|----------|----------|----------|
| **Root** | User-facing, documented in README | `/` |
| **Scripts** | Development tools, not primary interface | `scripts/` |
| **Archive** | One-off tasks, historical value only | `archive/` |

### Phase 3: Update Documentation

```bash
# Find references to moved scripts
rg -l "quick_trial_run\.py" docs/

# Update paths
sed -i '' 's|python quick_trial_run\.py|python scripts/quick_trial_run.py|g' docs/IMAGE_SOURCES.md
```

### Phase 4: Secure Secrets

```bash
# Remove from tracking
git rm --cached .claude/settings.local.json

# Add to .gitignore
echo ".claude/settings.local.json" >> .gitignore

# Verify not in history (use GitHub push protection)
git commit --amend --no-edit --no-verify
git push

# If push protection catches it: good!
# Fix and re-push
```

## Results

**Before:**
- Root directory: 41+ files (27 duplicates + 14 unique)
- Total duplicates: 779 files across repo
- Organization: Unclear entry points
- Security: API keys in tracking

**After:**
- Root directory: 7 essential files
- Duplicates: 0
- Organization: Clear separation (root, scripts/, archive/)
- Security: Secrets removed, .gitignore updated

**Metrics:**
- 88% reduction in root directory clutter (41 → 7 files)
- 779 files deleted
- 16 scripts organized to scripts/
- 6 scripts archived
- 0 secrets in tracking

## Benefits

1. **Reduced Cognitive Load:** Clear entry points, less clutter
2. **Better Organization:** Logical separation of concerns
3. **Security:** No secrets in version control
4. **Maintainability:** Easier to find and update scripts
5. **Onboarding:** New developers know where to start

## Decision Tree

```
Is file in root directory?
├─ Is it documented in README? → KEEP in root
├─ Is it a development tool? → MOVE to scripts/
├─ Is it a one-off script? → ARCHIVE
└─ Is it a duplicate (has " 2")? → DELETE

Is file tracked in git?
├─ Contains secrets? → REMOVE from tracking + .gitignore
├─ Is duplicate? → DELETE
└─ Is used? → KEEP (possibly move)
```

## Anti-Patterns

❌ **Big Bang Cleanup:**
```bash
# BAD: Delete everything at once without verification
rm -rf *.py  # DANGEROUS!
```

❌ **No Documentation Update:**
```bash
# BAD: Move scripts but don't update docs
mv script.py scripts/
# docs/ still reference old path - broken!
```

❌ **Losing History:**
```bash
# BAD: Delete instead of archiving one-offs
rm one_off_script.py  # Lost forever!
```

## When to Apply

✅ **Apply this pattern when:**
- Root directory has >10 scripts
- Finding entry points is difficult
- Duplicate files accumulating
- Secrets accidentally committed
- Cognitive load from clutter is high

❌ **Skip this pattern when:**
- Repository is well-organized already
- Active development in progress (wait for pause)
- No clear organizational structure decided yet

## Variations

### Minimal Cleanup (Quick Win)
```bash
# Just delete duplicates
/usr/bin/find . -name "*\ [0-9].*" -type f -delete
```

### Full Reorganization
```bash
# Add bin/ for production scripts
mkdir -p bin/ scripts/ archive/
# Separate production (bin/) from development (scripts/)
```

## Related Patterns

- **.gitignore Discipline:** Prevent secrets from being committed
- **Documentation Quality Gates:** Verify docs stay current with code moves
- **Entry Point Pattern:** Clear, documented user-facing scripts in root
- **Archive Strategy:** Preserve history without clutter

## Tools

```bash
# Find duplicates
fd -t f ".*\ [0-9]\..*"  # fd tool (may need escaping)
/usr/bin/find . -name "*\ [0-9].*" -type f  # BSD find (more reliable)

# Find secrets
rg -i "api.?key|secret|password" --type py

# Update references
rg -l "old_path" | xargs sed -i '' 's|old_path|new_path|g'

# Check git size
git count-objects -vH
```

## References

- Cleanup Report: `docs/status/2025-10-10-cleanup-complete.md`
- Analysis: `docs/status/2025-10-10-cleanup-analysis.md`
- Commit: 2be27ae "Massive repository cleanup"

## Tags

`devops` `maintenance` `cleanup` `organization` `security` `technical-debt`
