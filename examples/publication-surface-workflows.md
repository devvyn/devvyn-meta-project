# Publication Surface Integration Workflows

Practical examples showing how to use publication surfaces in real-world scenarios.

---

## Example 1: Research → Analysis → Human Decision

**Scenario**: Code agent researches a topic, Chat agent analyzes, Human makes final decision.

### Workflow

```bash
# 1. Code agent completes research
cat > research-results.md << 'EOF'
# API Framework Research

## Findings
- Framework A: Fast, limited features
- Framework B: Feature-rich, slower
- Framework C: Balanced, newer

## Recommendation
Framework C appears optimal for our use case.
EOF

# 2. Send to Chat agent for strategic analysis
surface-publish.sh agent-inbox \
  --from code \
  --to chat \
  --priority HIGH \
  --subject "Framework Research Complete" \
  research-results.md

# 3. Chat agent receives, analyzes, escalates to human
# (Chat agent processes...)

# 4. Chat sends to human inbox with recommendation
cat > decision-request.md << 'EOF'
# Framework Selection Decision

## Context
Code agent researched 3 frameworks.

## Analysis
Framework C offers best balance of speed and features.
Low risk, proven in similar projects.

## Request
Approve Framework C selection for project.
EOF

surface-publish.sh human-inbox \
  --category decisions \
  decision-request.md

# 5. Also create event log entry
surface-publish.sh event-log \
  --type decision \
  decision-request.md

# 6. Human reviews and approves
# Decision is now part of permanent event history
```

---

## Example 2: Knowledge Base → Audio → Public Docs

**Scenario**: Convert documentation to multiple consumption formats.

### Workflow

```bash
# 1. Write documentation
cat > new-pattern.md << 'EOF'
# Pattern: Defer Queue Usage

## Problem
Good ideas arrive at wrong time and get lost.

## Solution
Use defer queue with condition-based activation.

## Implementation
```bash
surface-publish.sh defer-queue \
  --condition "project-phase-2" \
  enhancement.md
```
EOF

# 2. Add to knowledge base
cp new-pattern.md ~/devvyn-meta-project/knowledge-base/patterns/

# 3. Create audio version for ambient learning
surface-publish.sh audio-documentation \
  --provider macos \
  new-pattern.md

# 4. Publish to public documentation site
surface-publish.sh public-docs \
  github-pages \
  ~/devvyn-meta-project/knowledge-base

# 5. Notify team via Slack (if configured)
cat > slack-announcement.md << 'EOF'
New pattern documented: Defer Queue Usage

Read: https://your-domain.github.io/patterns/defer-queue
Listen: ~/Desktop/Knowledge-Base-Audio/defer-queue.mp3
EOF

surface-publish.sh web-webhooks \
  --service slack \
  --channel documentation \
  slack-announcement.md

# Result: Same content available in 4 formats:
# - Markdown (knowledge base)
# - Audio (passive learning)
# - Web (public access)
# - Slack (team notification)
```

---

## Example 3: Pattern Discovery → Story → Propagation

**Scenario**: INVESTIGATOR discovers pattern, wraps in narrative, propagates to team.

### Workflow

```bash
# 1. INVESTIGATOR finds pattern in code
cat > pattern-discovery.md << 'EOF'
# Pattern: Atomic Script Operations

## Discovery
Analyzed 50+ bridge operations. All use atomic scripts.
Zero race conditions observed.

## Pattern
Always use atomic operations for bridge writes.
Never write files directly - use provided scripts.

## Evidence
- bridge-send.sh uses UUID + atomic write
- bridge-defer.sh uses lockfile mechanism
- All operations have TLA+ verification
EOF

# 2. Create event log entry
surface-publish.sh event-log \
  --type pattern \
  pattern-discovery.md

# 3. Wrap in story format
cat > pattern-story.md << 'EOF'
# Story: The Race Condition That Never Happened

## Origin
INVESTIGATOR analyzed 50+ bridge operations looking for bugs.
Expected to find concurrency issues. Found none.

## Discovery
Every operation uses atomic scripts with UUID-based naming
and lockfile mechanisms. TLA+ specs verify correctness.

## Lesson
Atomic operations aren't just best practice - they're
enforced by architecture. Race conditions impossible.

## Propagation
This pattern should spread to:
- All new file-based operations
- Documentation for contributors
- Code review checklist
EOF

# 4. Send story to Chat for strategic context
surface-publish.sh agent-inbox \
  --from investigator \
  --to chat \
  --priority NORMAL \
  --subject "Pattern Discovery: Atomic Operations" \
  pattern-story.md

# 5. Add to collective memory
cat pattern-story.md >> ~/devvyn-meta-project/knowledge-base/collective-memory.md

# 6. Create audio version for team learning
surface-publish.sh audio-documentation \
  --provider macos \
  pattern-story.md
```

---

## Example 4: External Collaboration via Email

**Scenario**: External consultant sends feedback, agents process, human approves response.

### Setup

```bash
# Configure email bridge (one-time)
cat > ~/infrastructure/agent-bridge/bridge/config/email-config.json << 'EOF'
{
  "smtp": {
    "host": "smtp.gmail.com",
    "port": 587,
    "username": "your-email@gmail.com",
    "password": "your-app-password",
    "from": "your-email@gmail.com",
    "use_tls": true,
    "enabled": true
  },
  "imap": {
    "host": "imap.gmail.com",
    "port": 993,
    "username": "your-email@gmail.com",
    "password": "your-app-password",
    "folder": "INBOX",
    "enabled": true
  },
  "allowed_senders": [
    "consultant@external.com"
  ],
  "allowed_recipients": [
    "consultant@external.com"
  ]
}
EOF
```

### Workflow

```bash
# 1. Consultant sends email with X-Agent-Bridge: true header

# 2. LaunchAgent runs email-receive.sh every 30 minutes
~/devvyn-meta-project/scripts/adapters/email-receive.sh --mark-read

# Email converted to bridge message in inbox/code/

# 3. Code agent processes feedback
cat > response-draft.md << 'EOF'
# Response to Consultant Feedback

Thank you for the detailed analysis. We've reviewed your
suggestions and agree with points 1-3. Point 4 requires
further discussion.

## Action Items
1. Implement suggested optimization (Points 1-3)
2. Schedule call to discuss Point 4
3. Send updated timeline

Best regards
EOF

# 4. Send to human for approval
surface-publish.sh human-inbox \
  --category external-comms \
  response-draft.md

# 5. Human approves, agent sends via email
surface-publish.sh email-bridge \
  --to consultant@external.com \
  --subject "Re: Project Feedback" \
  response-draft.md

# 6. Log interaction in event log
cat > interaction-log.md << 'EOF'
# External Interaction

Date: 2025-11-01
Participant: consultant@external.com
Topic: Project feedback review
Outcome: Points 1-3 approved, Point 4 needs discussion
EOF

surface-publish.sh event-log \
  --type state-change \
  interaction-log.md
```

---

## Example 5: Urgent Security Issue Escalation

**Scenario**: Security vulnerability discovered, immediate human attention needed.

### Workflow

```bash
# 1. Code agent discovers security issue
cat > security-alert.md << 'EOF'
# CRITICAL SECURITY ISSUE

## Severity: HIGH
## Component: API authentication

## Issue
JWT tokens not properly validated in /api/admin endpoint.
Allows unauthorized access to admin functions.

## Impact
- Admin functions accessible without proper auth
- Data breach risk: HIGH
- Exploit difficulty: LOW

## Recommended Actions
1. Disable /api/admin endpoint immediately
2. Add proper JWT validation
3. Audit access logs for suspicious activity
4. Notify security team

## Timeline
- Immediate: Disable endpoint
- Within 1 hour: Implement fix
- Within 2 hours: Deploy to production
EOF

# 2. Create event log (permanent record)
surface-publish.sh event-log \
  --type state-change \
  security-alert.md

# 3. Desktop for immediate visibility
surface-publish.sh human-desktop CRITICAL-SECURITY-ISSUE.md

# 4. Send to Chat for strategic coordination
surface-publish.sh agent-inbox \
  --from code \
  --to chat \
  --priority CRITICAL \
  --subject "SECURITY: Auth bypass in admin endpoint" \
  security-alert.md

# 5. Email security team (if configured)
surface-publish.sh email-bridge \
  --to security-team@company.com \
  --subject "URGENT: Security vulnerability detected" \
  security-alert.md

# 6. Slack notification (if configured)
surface-publish.sh web-webhooks \
  --service slack \
  --channel security \
  security-alert.md

# Result: Human alerted 4 ways:
# - Desktop (immediate visibility)
# - Agent inbox (coordinated response)
# - Email (external notification)
# - Slack (team broadcast)
```

---

## Example 6: Good Idea, Wrong Time → Defer Queue

**Scenario**: Enhancement proposal arrives during freeze period.

### Workflow

```bash
# 1. Developer submits enhancement idea during feature freeze
cat > enhancement-proposal.md << 'EOF'
# Enhancement: Real-time Collaboration

## Proposal
Add real-time collaborative editing to documentation.

## Benefits
- Multiple editors simultaneously
- Reduced conflicts
- Better team coordination

## Effort
- 3 weeks development
- 1 week testing
EOF

# 2. Code agent recognizes timing issue (feature freeze)
# Instead of rejecting, defer until next planning phase

surface-publish.sh defer-queue \
  --condition "planning-phase-starts" \
  --category strategic \
  enhancement-proposal.md

# 3. Also notify human of deferral
cat > deferral-notice.md << 'EOF'
# Enhancement Proposal Deferred

The real-time collaboration proposal is excellent but
arrived during feature freeze.

Deferred to next planning phase (estimated 2 weeks).
Will be automatically re-surfaced when planning starts.
EOF

surface-publish.sh human-inbox \
  --category notifications \
  deferral-notice.md

# 4. Two weeks later, planning phase starts
# LaunchAgent activates deferred item

review-deferred.sh --trigger "planning-phase-starts"

# Proposal automatically re-surfaces for consideration
# Good idea not lost due to timing
```

---

## Example 7: Multi-Agent Collaboration Workflow

**Scenario**: Complex task requires coordination across agents.

### Workflow

```bash
# 1. Human initiates project
cat > project-brief.md << 'EOF'
# New Project: User Analytics Dashboard

## Goal
Build analytics dashboard showing user behavior patterns.

## Requirements
- Real-time data updates
- Custom report generation
- Export to PDF/CSV
- Mobile responsive

## Timeline
4 weeks
EOF

surface-publish.sh agent-inbox \
  --from human \
  --to chat \
  --priority HIGH \
  --subject "New Project: Analytics Dashboard" \
  project-brief.md

# 2. Chat analyzes and breaks down tasks
cat > task-breakdown.md << 'EOF'
# Analytics Dashboard - Task Breakdown

## Phase 1: Research & Planning (Code)
- Research visualization libraries
- Design database schema
- API endpoint design

## Phase 2: Pattern Analysis (Investigator)
- Analyze similar dashboards in codebase
- Extract reusable patterns
- Document anti-patterns to avoid

## Phase 3: Implementation (Code)
- Build backend APIs
- Implement frontend
- Testing

## Phase 4: Review (Human)
- Final approval
- Deployment decision
EOF

# 3. Chat delegates to Code agent
surface-publish.sh agent-inbox \
  --from chat \
  --to code \
  --priority HIGH \
  --subject "Phase 1: Analytics Dashboard Research" \
  task-breakdown.md

# 4. Chat also requests pattern analysis
surface-publish.sh agent-inbox \
  --from chat \
  --to investigator \
  --priority NORMAL \
  --subject "Pattern Analysis: Dashboard Implementations" \
  task-breakdown.md

# 5. Code agent completes research
cat > research-complete.md << 'EOF'
# Research Complete

## Recommendations
- Visualization: D3.js + React
- Database: TimescaleDB for time-series
- API: GraphQL for flexible queries

## Next Steps
Begin implementation
EOF

surface-publish.sh agent-inbox \
  --from code \
  --to chat \
  --priority NORMAL \
  --subject "Research Complete" \
  research-complete.md

# 6. Investigator finds patterns
cat > patterns-found.md << 'EOF'
# Dashboard Patterns

## Reusable Patterns
- Dashboard container component (3 instances)
- Data fetching hooks (5 instances)
- Export utilities (2 instances)

## Recommended Reuse
Use existing DashboardContainer and useDashboardData hook.
Extend ExportService for PDF/CSV.
EOF

surface-publish.sh agent-inbox \
  --from investigator \
  --to code \
  --priority NORMAL \
  --subject "Reusable Patterns Identified" \
  patterns-found.md

# 7. Code implements, then sends for human review
surface-publish.sh human-inbox \
  --category reviews \
  implementation-review.md

# 8. All interactions logged in event log
# Complete audit trail of collaboration
```

---

## Example 8: Knowledge Accumulation Pipeline

**Scenario**: Continuous learning and documentation improvement.

### Workflow

```bash
# 1. Daily pattern detection (LaunchAgent)
# INVESTIGATOR runs every day at 9am

# 2. Patterns found are logged as events
surface-publish.sh event-log \
  --type pattern \
  daily-patterns.md

# 3. Patterns synthesized into collective memory
cat daily-patterns.md >> ~/devvyn-meta-project/knowledge-base/collective-memory.md

# 4. Weekly: Convert new patterns to audio
find ~/devvyn-meta-project/knowledge-base/patterns/ \
  -name "*.md" \
  -mtime -7 \
  -exec surface-publish.sh audio-documentation --provider macos {} \;

# 5. Monthly: Publish updated docs to web
surface-publish.sh public-docs \
  github-pages \
  ~/devvyn-meta-project/knowledge-base

# 6. Notify team of updates
cat > update-notification.md << 'EOF'
# Monthly Knowledge Base Update

- 12 new patterns documented
- 8 patterns converted to audio
- Documentation site updated

Visit: https://your-domain.github.io
Audio: ~/Desktop/Knowledge-Base-Audio/
EOF

surface-publish.sh web-webhooks \
  --service slack \
  --channel knowledge-sharing \
  update-notification.md

# Result: Continuous knowledge accumulation
# - Automatic pattern detection
# - Multi-format distribution
# - Team awareness
```

---

## Integration Scripts

### Quick Publish to Multiple Surfaces

```bash
#!/bin/bash
# multi-publish.sh - Publish content to multiple surfaces

CONTENT="$1"

# Agent communication
surface-publish.sh agent-inbox \
  --from code --to chat \
  --priority NORMAL \
  --subject "Update" \
  "$CONTENT"

# Human notification
surface-publish.sh human-inbox \
  --category notifications \
  "$CONTENT"

# Event log
surface-publish.sh event-log \
  --type state-change \
  "$CONTENT"

# Audio version
surface-publish.sh audio-documentation \
  --provider macos \
  "$CONTENT"
```

### Smart Escalation

```bash
#!/bin/bash
# smart-escalate.sh - Escalate based on priority

PRIORITY="$1"
CONTENT="$2"

case "$PRIORITY" in
  CRITICAL)
    # Desktop + Email + Slack
    surface-publish.sh human-desktop "$CONTENT"
    surface-publish.sh email-bridge \
      --to admin@company.com \
      --subject "CRITICAL: Immediate Action Required" \
      "$CONTENT"
    surface-publish.sh web-webhooks \
      --service slack \
      --channel urgent \
      "$CONTENT"
    ;;
  HIGH)
    # Human inbox + Agent notification
    surface-publish.sh human-inbox \
      --category urgent \
      "$CONTENT"
    surface-publish.sh agent-inbox \
      --from code --to chat \
      --priority HIGH \
      --subject "High Priority Item" \
      "$CONTENT"
    ;;
  NORMAL)
    # Just agent inbox
    surface-publish.sh agent-inbox \
      --from code --to chat \
      --priority NORMAL \
      --subject "Update" \
      "$CONTENT"
    ;;
esac
```

---

## Best Practices from Examples

### 1. Always Create Event Log Entries for Important Decisions

Events are permanent record. Even if you send to inbox/desktop, log it.

### 2. Use Multi-Channel for Critical Information

Security issues, critical decisions → Desktop + Email + Slack + Event Log

### 3. Defer Don't Discard

Good ideas at wrong time → Defer queue, not rejection

### 4. Multi-Format for Accessibility

Documentation → Markdown + Audio + Web for different consumption preferences

### 5. Complete Audit Trails

Log all agent interactions in event log for full traceability

---

## Testing Your Workflows

```bash
# 1. Test discovery
surface-discover.sh

# 2. Test specific surface
surface-info.sh agent-inbox

# 3. Test publishing (dry run concept)
# Create test message
echo "Test message" > /tmp/test.md

# Publish to agent inbox
surface-publish.sh agent-inbox \
  --from code --to code \
  --priority INFO \
  --subject "Test" \
  /tmp/test.md

# Check delivery
ls ~/infrastructure/agent-bridge/bridge/inbox/code/

# 4. Test multi-surface workflow
cat > /tmp/workflow-test.md << 'EOF'
# Workflow Test

This is a test of multi-surface publishing.
EOF

# Publish to multiple surfaces
surface-publish.sh event-log --type state-change /tmp/workflow-test.md
surface-publish.sh human-inbox --category tests /tmp/workflow-test.md
surface-publish.sh audio-documentation --provider macos /tmp/workflow-test.md

# Verify each surface received the content
```

---

## Troubleshooting

### Surface Not Found

```bash
# List all surfaces
surface-discover.sh

# Check spelling
surface-info.sh <surface-name>
```

### Publishing Failed

```bash
# Check configuration
cat ~/infrastructure/agent-bridge/bridge/config/*.json

# Check permissions
ls -la ~/infrastructure/agent-bridge/bridge/inbox/

# Check logs
tail -f ~/devvyn-meta-project/logs/bridge-*.log
```

### External Surface Not Working

```bash
# Web webhooks
cat ~/infrastructure/agent-bridge/bridge/config/web-adapters.json
# Ensure enabled: true and webhook_url configured

# Email
cat ~/infrastructure/agent-bridge/bridge/config/email-config.json
# Ensure smtp.enabled: true and credentials set
```

---

## Next Steps

1. **Try Example 1** - Basic agent-to-human workflow
2. **Configure External Surfaces** - Set up Slack/email if needed
3. **Create Custom Workflows** - Adapt examples to your use cases
4. **Automate with LaunchAgents** - Schedule periodic publishing
5. **Monitor Usage** - Track which surfaces work best for which scenarios

For more information, see:
- `knowledge-base/patterns/publication-surfaces.md` - Comprehensive guide
- `~/infrastructure/agent-bridge/bridge/registry/publication-surfaces.json` - Surface registry
- `scripts/surface-*.sh` - Discovery and publishing tools
