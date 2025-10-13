# Collective Resource Provisioning Pattern

**Status**: Implemented
**Type**: Infrastructure Pattern
**Emerged**: 2025-10-12 from barkour development needs

## Problem

Multi-agent systems require access to shared resources (datasets, software, media files) that:
- Are too large for git repositories
- Need to be acquired once and shared across agents
- Should be content-addressed for integrity
- Require provenance tracking for accountability
- May come from distributed sources (torrents, archives)

Traditional approaches (manual download, per-project duplication) don't scale for autonomous agent collectives.

## Solution

**Collective resource provisioning** - a shared infrastructure where:
1. Any agent can request resources via bridge messages
2. A designated agent (code) fulfills requests autonomously
3. Resources are stored in `~/infrastructure/shared-resources/`
4. Completion notifications are sent via bridge
5. Content DAG tracks provenance and relationships

## Origin Story

### Organic Emergence

This pattern emerged from **actual need**, not abstract design:

1. **barkour** game project needed PICO-8 fantasy console for development
2. Literate-Garden experiments required the emulator to run prototypes
3. User placed `.torrent` files in Music watch folder (undocumented pattern)
4. Code agent discovered this emergent infrastructure during coordination
5. Formalized into collective capability

**Key insight**: The watch folder was created for human convenience but revealed a **collective resource acquisition pattern**.

## Architecture

### Components

```
~/infrastructure/shared-resources/          # Collective storage
    ├── .incomplete/                        # In-progress downloads
    ├── pico-8_0.2.7a6_osx/                # Completed resources
    └── [content-hash]/                    # Future: content-addressed

~/Music/Music/.../Automatically Add.../    # Torrent watch folder
    ├── *.torrent                          # Auto-processed by daemon

~/.config/transmission-daemon/             # Client configuration
    └── settings.json                      # Watch folder, hooks

~/devvyn-meta-project/scripts/
    ├── torrent-complete-hook.sh           # Completion notification
    ├── resource-request.sh                # Request workflow
    ├── resource-fulfill.sh                # Fulfillment workflow
    └── resource-status.sh                 # Progress monitoring
```

### Data Flow

```
Agent identifies need
    ↓
[Bridge] resource-request message
    ↓
Code agent receives request
    ↓
Evaluates source/safety/size
    ↓
Human approval (if needed)
    ↓
Download initiated (watch folder)
    ↓
transmission-daemon processes
    ↓
Completion hook fires
    ↓
[Bridge] completion notification
    ↓
Resource available in shared-resources
    ↓
Content DAG updated with provenance
    ↓
All agents can access
```

## Implementation

### Current State (v1.0)

**Installed**: ✅
- `transmission-cli` via Homebrew
- Daemon configured with watch folder
- Completion hooks sending bridge messages
- Shared storage location created

**Working**: ✅
- Watch folder automatically picks up torrents
- Downloads go to `~/infrastructure/shared-resources/`
- Hook notifies via bridge on completion

**Tested**: ✅
- 3 torrents auto-detected (PICO-8, Picotron, Voxatron)
- Configuration validated
- Idle state expected (need seeders)

### Request Workflow (Not Yet Implemented)

```bash
# Agent requests a resource
~/devvyn-meta-project/scripts/resource-request.sh \
  --source "magnet:?xt=..." \
  --purpose "Training data for ML analysis" \
  --size "50GB" \
  --auto-approve false

# Creates bridge message to code agent
# Code agent evaluates and responds
```

### Status Monitoring

```bash
# Check download progress
transmission-remote -l

# Web UI
open http://localhost:9091

# View completion log
tail -f ~/devvyn-meta-project/logs/torrent-completions.log
```

## Security Considerations

### Approval Workflow

**Auto-approve criteria** (future):
- Size < 1GB
- Known/trusted sources only
- Non-executable content
- Requesting agent has track record

**Human approval required**:
- Size > 1GB
- Unknown sources
- First-time patterns
- Security-sensitive content

### Safety Checks

1. **Content verification**: Check hashes against expected values
2. **Size limits**: Cap maximum download size
3. **Bandwidth management**: Rate limiting, scheduling
4. **Storage quotas**: Prevent disk space exhaustion
5. **Malware scanning**: Post-download verification (future)

## Integration Patterns

### Content DAG

Each downloaded resource becomes a DAG node:

```yaml
objects/sha256-[hash]/resource.json:
  type: downloaded-resource
  source: magnet:?xt=...
  requested_by: chat
  requested_at: 2025-10-12T12:00:00Z
  purpose: "PICO-8 fantasy console for barkour development"
  file_path: ~/infrastructure/shared-resources/pico-8_0.2.7a6_osx/
  size_bytes: 23456789
  verification: sha256-[hash]
  status: seeding
  related_projects:
    - barkour
    - Literate-Garden
```

### Bridge Messages

**New message type**: `resource-request`

```markdown
---
Type: resource-request
From: chat
To: code
Priority: NORMAL
---

# Resource Request: ML Training Dataset

## Source
magnet:?xt=urn:btih:abc123...

## Purpose
Training data for sentiment analysis experiments

## Metadata
- Estimated size: 50GB
- Format: CSV
- Approval: required
```

## Lifecycle Management

### Phases

1. **Request**: Agent identifies need, sends bridge message
2. **Evaluate**: Code agent checks size, source, safety
3. **Approve**: Auto or human approval based on criteria
4. **Acquire**: Download via transmission-daemon
5. **Verify**: Check integrity, scan for issues
6. **Catalog**: Add to content DAG with provenance
7. **Share**: Available to all agents
8. **Maintain**: Seeding, storage management
9. **Archive**: Move old/unused resources to cold storage
10. **Cleanup**: Delete when no longer needed (with approval)

### Resource States

- `requested`: Bridge message sent
- `evaluating`: Code agent checking criteria
- `awaiting-approval`: Human decision needed
- `approved`: Ready to download
- `downloading`: In progress
- `verifying`: Post-download checks
- `available`: Ready for use
- `seeding`: Actively seeding torrent
- `archived`: Moved to cold storage
- `removed`: Deleted from system

## Related Patterns

- **Scientific Provenance**: Track resource origins and usage
- **Information Parity**: All agents have equal resource access
- **Content DAG**: Content-addressed storage with relationships
- **Bridge Protocol**: Async message-based coordination
- **Autonomous Exploration**: Self-directed capability discovery

## Future Enhancements

### Phase 2: Automation
- LaunchAgent for continuous watch folder monitoring
- Auto-approval rules engine
- Bandwidth scheduling (off-peak downloads)
- Storage quota enforcement

### Phase 3: Intelligence
- Usage pattern learning (predict needed resources)
- Proactive caching of likely-needed datasets
- Seeding priority based on collective value
- Automatic cleanup of unused resources

### Phase 4: Distribution
- Multi-source redundancy (IPFS, HTTP, torrent)
- Local cache invalidation strategies
- Distributed resource registry
- Peer-to-peer sharing between agent instances

## Metrics & Observability

### Key Metrics
- Resources requested vs fulfilled
- Average download time by size
- Storage utilization
- Seeding ratio
- Auto-approval rate
- Human intervention frequency

### Monitoring
```bash
# System health
~/devvyn-meta-project/scripts/system-health-check.sh

# Resource status
~/devvyn-meta-project/scripts/resource-status.sh

# Completion log
tail -f ~/devvyn-meta-project/logs/torrent-completions.log
```

## Lessons Learned

### What Worked

1. **Organic emergence** - Real need drove design
2. **Watch folder pattern** - Simple, reliable, battle-tested
3. **transmission-cli** - Perfect fit for CLI-first workflow
4. **Bridge integration** - Natural coordination mechanism
5. **Shared storage** - Clear separation from project-specific files

### Design Decisions

1. **Why transmission over aria2?**
   - Better watch folder support
   - Web UI for monitoring
   - More stable torrent handling

2. **Why shared-resources location?**
   - Outside any single project
   - Clearly indicates collective ownership
   - Easy to backup/manage separately

3. **Why completion hooks?**
   - Async notification fits bridge protocol
   - No polling needed
   - Composable with other tools

### Open Questions

1. Should resources be content-addressed (hash-based paths)?
2. How to handle resource versioning (e.g., PICO-8 updates)?
3. What's the storage budget? (100GB? 1TB?)
4. Should seeding be unlimited or capped?
5. Multi-agent instance coordination? (same resource across machines)

## References

- Bridge Protocol: `~/devvyn-meta-project/COORDINATION_PROTOCOL.md`
- Content DAG: `~/devvyn-meta-project/docs/CONTENT_DAG_PATTERN.md`
- Scientific Provenance: `~/devvyn-meta-project/knowledge-base/patterns/scientific-provenance-pattern.md`
- Barkour project: `~/Documents/GitHub/barkour/`
- Transmission docs: https://github.com/transmission/transmission/blob/main/docs/

## Examples

### Example 1: PICO-8 for Barkour (Actual)

```bash
# User manually placed torrents in watch folder
ls ~/Music/.../Automatically\ Add.../
# pico-8_0.2.7a6_osx.zip.torrent
# picotron_0.2.1b_osx.zip.torrent
# voxatron_0.3.5b_osx.zip.torrent

# Transmission auto-detected and added them
transmission-remote -l
# ID   Done  Name
#  1    0%   lexalofflegames/pico-8_0.2.7a6_osx.zip
#  2    0%   lexalofflegames/voxatron_0.3.5b_osx.zip
#  3    0%   lexalofflegames/picotron_0.2.1b_osx.zip
```

**Outcome**: Infrastructure discovered, formalized, documented

### Example 2: Dataset Request (Future)

```bash
# Chat agent needs training data
~/devvyn-meta-project/scripts/resource-request.sh \
  --source "https://archive.org/download/arxiv-2024-ml.torrent" \
  --purpose "ML model training for paper classification" \
  --size "50GB"

# Code agent receives, evaluates
# Size > 1GB → human approval required
# Bridge message sent to human

# Human approves via web UI or CLI
# Download begins automatically
# 6 hours later: completion notification
# Resource available in shared-resources
# Content DAG updated with provenance
```

## Changelog

- **2025-10-12**: Pattern emerged from barkour development
- **2025-10-12**: transmission-cli installed and configured
- **2025-10-12**: Watch folder integration working
- **2025-10-12**: Completion hooks implemented
- **2025-10-12**: Pattern documented

---

**This pattern demonstrates**: Organic capability emergence, pragmatic infrastructure, collective coordination, content provenance, autonomous operation with human oversight.
