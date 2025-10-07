# Manual Capability Testing Instructions

**Purpose**: Empirically verify agent capabilities across contexts
**Philosophy**: Trust but verify - test actual capabilities, not assumptions

---

## Testing Philosophy

**Ground Truth**: What actually works in practice
**Evidence**: Logged test results with timestamps
**Convergence**: Documentation updated to match reality
**Confidence**: Track % verified vs. speculative

---

## chat-desktop Manual Tests

### Required Context

- Open Claude Chat Desktop app
- Ensure Project is configured with this codebase
- Have access to Terminal for verification

### Test 1: Bridge Message Send

**Claim**: `bridge_integration.send.status: full`

**Test Procedure**:

```applescript
# In Claude Chat Desktop, run:
do shell script "cd ~/devvyn-meta-project && ./scripts/bridge-send.sh chat code NORMAL 'Manual Test' /tmp/test-message.md"
```

**Expected Result**: Command succeeds, message appears in code inbox

**Verification**:

```bash
# In Terminal:
ls ~/infrastructure/agent-bridge/bridge/inbox/code/
# Should see message file
```

**Record Result**:

```bash
# Create evidence file
cat > ~/devvyn-meta-project/agents/capabilities/evidence/chat-desktop_bridge_send_$(date -Iseconds).log <<EOF
status: verified
timestamp: $(date -Iseconds)
method: manual_test
tester: [your-name]
result: success
notes: Successfully sent bridge message via osascript
EOF
```

---

### Test 2: File Read

**Claim**: `file_operations.read: full`

**Test Procedure**:

```applescript
# In Claude Chat Desktop:
do shell script "cat ~/devvyn-meta-project/agents/capabilities/manifest.yaml"
```

**Expected Result**: File contents displayed

**Record Result**:

```bash
cat > ~/devvyn-meta-project/agents/capabilities/evidence/chat-desktop_file_read_$(date -Iseconds).log <<EOF
status: verified
method: manual_test
test_file: manifest.yaml
result: success
EOF
```

---

### Test 3: Web Access

**Claim**: `web_access.status: full`

**Test Procedure**:
In Claude Chat Desktop, ask:
> "Search the web for 'Claude Code capabilities 2025'"

**Expected Result**: Returns web search results with current information

**Record Result**:

```bash
cat > ~/devvyn-meta-project/agents/capabilities/evidence/chat-desktop_web_access_$(date -Iseconds).log <<EOF
status: verified
method: manual_test
test_type: web_search
result: [success|failed]
notes: [What happened]
EOF
```

---

### Test 4: osascript Execution

**Claim**: `platform_specific.osascript: full`

**Test Procedure**:

```applescript
# In Chat Desktop:
do shell script "echo 'osascript test' && date"
```

**Expected Result**: Command output returned

**Record Result**:

```bash
cat > ~/devvyn-meta-project/agents/capabilities/evidence/chat-desktop_osascript_$(date -Iseconds).log <<EOF
status: verified
method: manual_test
command: echo and date
result: success
EOF
```

---

## chat-mobile Manual Tests (iPhone)

### Required Context for Mobile Testing

- iPhone with Claude Chat app
- Project synced via iCloud (if possible)
- Access to Files app

### Test 1: Bridge Inbox Read

**Claim**: `bridge_integration.read.status: read_only (if iCloud synced)`

**Test Procedure**:

1. Open Files app on iPhone
2. Navigate to iCloud Drive
3. Try to access: `~/infrastructure/agent-bridge/bridge/inbox/chat/`

**Expected Result**: Either accessible (read-only) or not visible

**Record Result**:

```bash
# On Mac after testing:
cat > ~/devvyn-meta-project/agents/capabilities/evidence/chat-mobile_bridge_read_$(date -Iseconds).log <<EOF
status: [verified|failed|not_accessible]
method: manual_test_iphone
platform: iOS
icloud_sync: [yes|no]
result: [description]
EOF
```

---

### Test 2: File Write Attempt

**Claim**: `file_operations.write: none`

**Test Procedure**:
In Chat Mobile, try to create a file:
> "Create a test file at /tmp/test.md"

**Expected Result**: Should fail (iOS sandbox)

**Record Result**:

```bash
cat > ~/devvyn-meta-project/agents/capabilities/evidence/chat-mobile_file_write_$(date -Iseconds).log <<EOF
status: verified_unavailable
method: manual_test_iphone
expected: failure
actual: [what happened]
EOF
```

---

### Test 3: Mobile Web Access

**Claim**: `web_access.status: likely_available`

**Test Procedure**:
In Chat Mobile, ask:
> "Search the web for current weather in Saskatoon"

**Expected Result**: Returns web search results

**Record Result**:

```bash
cat > ~/devvyn-meta-project/agents/capabilities/evidence/chat-mobile_web_access_$(date -Iseconds).log <<EOF
status: [verified|failed]
method: manual_test_iphone
result: [description]
EOF
```

---

## INVESTIGATOR Manual Tests

### Test 1: Event Log Read

**Claim**: `file_operations.read_event_log: full`

**Test Procedure**:

```bash
# Trigger INVESTIGATOR manually:
~/devvyn-meta-project/scripts/investigator-session.sh --dry-run

# Check if it can read events
grep "Found.*events" ~/devvyn-meta-project/logs/investigator.log
```

**Expected Result**: Successfully reads and counts events

**Record Result**:

```bash
cat > ~/devvyn-meta-project/agents/capabilities/evidence/investigator_file_read_$(date -Iseconds).log <<EOF
status: verified
method: direct_execution
result: success
events_read: [count]
EOF
```

---

### Test 2: Report Generation

**Claim**: `file_operations.write_desktop_reports: full`

**Test Procedure**:

```bash
# Run INVESTIGATOR
~/devvyn-meta-project/scripts/investigator-session.sh

# Check Desktop for report
ls -lt ~/Desktop/*investigator*.md | head -1
```

**Expected Result**: Report file created on Desktop

**Record Result**:

```bash
cat > ~/devvyn-meta-project/agents/capabilities/evidence/investigator_report_gen_$(date -Iseconds).log <<EOF
status: verified
method: direct_execution
result: success
report_created: yes
EOF
```

---

## After Manual Testing

### 1. Review Evidence

```bash
ls -lh ~/devvyn-meta-project/agents/capabilities/evidence/
```

### 2. Update YAML Files

```bash
# Process evidence into YAML updates
~/devvyn-meta-project/scripts/update-capabilities-from-evidence.sh [agent]
```

### 3. Review Changes

```bash
git diff ~/devvyn-meta-project/agents/capabilities/*.yaml
```

### 4. Commit Verified Capabilities

```bash
cd ~/devvyn-meta-project
git add agents/capabilities/
git commit -m "Update capabilities with empirical verification evidence"
```

---

## Evidence File Format

### Standard Format

```
status: verified|failed|not_available|verified_unavailable
timestamp: YYYY-MM-DDTHH:MM:SS-TIMEZONE
method: manual_test|empirical_testing|direct_execution
tester: [name if manual]
test_type: [description]
result: [what happened]
notes: [additional context]
```

### Status Values

- **verified**: Capability works as claimed
- **failed**: Capability doesn't work (discrepancy)
- **not_available**: Capability not present (expected)
- **verified_unavailable**: Confirmed capability is absent (matches claim)

---

## Discrepancy Resolution

### If Test Contradicts Documentation

1. **Record Evidence**: Save detailed test log
2. **Flag Discrepancy**: Note in evidence file
3. **Human Review**: Determine if doc wrong or test flawed
4. **Update YAML**: Correct documentation to match reality
5. **Version History**: Document change in YAML

### Example Discrepancy

```yaml
# Evidence shows: status: failed
# YAML claims: status: full
# Resolution: Update YAML, add version history entry

version_history:
  "1.1":
    date: "2025-10-06"
    changes: "Corrected web_access from 'full' to 'none' based on empirical testing"
    evidence: "evidence/code-cli_web_access_2025-10-06T21:36:02-06:00.log"
```

---

## Continuous Validation

### Recommended Schedule

- **Weekly**: Automated tests (code-cli)
- **Monthly**: Manual tests (chat-desktop, investigator)
- **Quarterly**: Full verification (all agents, all capabilities)
- **After Platform Changes**: Re-test affected capabilities

### Confidence Tracking

Each agent YAML includes:

```yaml
verification:
  last_tested: "YYYY-MM-DDTHH:MM:SS-TIMEZONE"
  confidence: 0-100
  method: empirical_testing
  evidence_dir: path/to/evidence/
```

**Confidence Calculation**:

- 100%: All claimed capabilities empirically verified
- 75%: Most capabilities verified, some manual-test-required
- 50%: Half verified, half speculative
- 0%: No verification evidence

---

## Eventual Consistency Model

### How System Converges to Truth

1. **Initial State**: Documentation may contain assumptions
2. **Testing**: Empirical tests produce evidence
3. **Evidence**: Logged with timestamps, immutable
4. **Update**: YAML updated to match evidence
5. **Iteration**: Repeat testing, refine documentation
6. **Convergence**: Docs reflect empirical reality

### Trust Hierarchy

1. **Empirical Evidence** (highest trust)
2. **Manual Testing** (high trust, requires human)
3. **Platform Documentation** (medium trust)
4. **Reasonable Assumptions** (low trust, needs verification)

### Version Tracking

Each update tracked in YAML:

```yaml
version_history:
  "1.0":
    date: "2025-10-06"
    changes: "Initial documentation (speculative)"
    verified_by: none

  "1.1":
    date: "2025-10-06"
    changes: "Updated with empirical test results"
    verified_by: empirical_testing
    confidence: 100
```

---

**Philosophy**: Documentation should reflect reality, not assumptions. Test, record evidence, update docs, repeat. Converge toward truth.
