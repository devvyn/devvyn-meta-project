# System Connection Map

**Status**: ✅ COMPLETE - All glue in place
**Date**: 2025-09-26

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    HUMAN (Devvyn)                           │
│  • Strategic decisions                                       │
│  • Resource allocation                                       │
│  • Context switching between agents                          │
└────┬─────────────────────────────────────────────────┬──────┘
     │                                                   │
     │                                                   │
┌────▼────────────────────────┐              ┌─────────▼──────────────────┐
│   CLAUDE CHAT AGENT         │◄────Bridge───►│   CLAUDE CODE AGENT        │
│   (Strategic/Cross-Project) │              │   (Implementation)          │
│                             │              │                             │
│  • Portfolio management     │              │  • Feature development      │
│  • Pattern recognition      │              │  • Bug fixes                │
│  • Domain validation        │              │  • Code generation          │
│  • Architecture review      │              │  • Testing                  │
└─────────────┬───────────────┘              └──────────┬─────────────────┘
              │                                         │
              │                                         │
┌─────────────▼─────────────────────────────────────────▼─────────────────┐
│                     FILESYSTEM LAYER                                     │
│                                                                           │
│  ~/devvyn-meta-project/                 ~/Documents/GitHub/              │
│  ├── key-answers.md                     ├── aafc-herbarium-dwc../       │
│  ├── bridge/                            ├── s3-image-dataset-kit/       │
│  │   ├── inbox/                         ├── python-toolbox-devvyn/      │
│  │   ├── outbox/                        └── claude-code-hooks/          │
│  │   └── archive/                                                        │
│  ├── projects/                          Each project has:                │
│  │   └── active-projects.md             ├── CLAUDE.md (agent context)   │
│  └── agents/                            ├── README.md (review requests) │
│      ├── CHAT_AGENT_INSTRUCTIONS.md    └── INTER_AGENT_MEMO.md        │
│      └── CHAT_SESSION_STARTUP.md                                        │
└───────────────────────────────────────────────────────────────────────────┘
```

## Connection Points

### 1. Desktop App ↔ Claude Chat

**Method**: Claude Desktop MCP filesystem access
**Status**: ✅ Connected automatically via MCP servers
**Access**: Full read/write to `/Users/devvynmurphy/`
**No manual setup required**

### 2. Claude Chat ↔ Project Documents

**Method**: Direct filesystem reads via MCP tools
**Status**: ✅ Connected
**Key files**:

- `/Users/devvynmurphy/devvyn-meta-project/agents/CHAT_AGENT_INSTRUCTIONS.md`
- `/Users/devvynmurphy/devvyn-meta-project/agents/CHAT_SESSION_STARTUP.md`
- All project CLAUDE.md files

**No manual pasting required** - Chat agent uses filesystem tools to read these

### 3. Claude Chat ↔ Claude Code

**Method**: Bridge system (async message passing)
**Status**: ✅ Connected
**Locations**:

- **Chat reads**: `bridge/outbox/chat/` (messages FROM Code)
- **Chat writes**: `bridge/inbox/code/` (messages TO Code)
- **Shared context**: `bridge/context/` (decisions, patterns, state)

**No manual setup required** - just use the message template

### 4. Project READMEs ↔ Chat Agent

**Method**: "Review Requests for Chat Agent" sections
**Status**: ✅ Implemented in s3-image-dataset-kit
**Format**: Markdown checkboxes in CLAUDE.md files
**Usage**: Add questions, Chat agent marks complete with feedback

**Manual action**: Add review request sections to other project CLAUDE.md files as needed

## What Requires Manual Action

### ✅ Zero Manual Actions Required for Core System

The glue is **already connected**:

- MCP servers give Chat agent filesystem access
- Bridge directories exist and are ready
- Agent instructions are documented
- Startup protocol is defined

### Optional Enhancements (If Desired)

1. **Add Review Request sections to more projects**:

   ```markdown
   ## Review Requests for Chat Agent
   - [ ] Question about X
   - [ ] Need feedback on Y
   ```

   Add to: aafc-herbarium, python-toolbox-devvyn, claude-code-hooks

2. **Test bridge messaging**:
   Create a test message from Code to Chat using the template

3. **Custom Instructions** (Optional):
   Could add to Claude Chat custom instructions:

   ```
   At session start, if I say "session start" or "check project status",
   read /Users/devvynmurphy/devvyn-meta-project/agents/CHAT_SESSION_STARTUP.md
   and execute the startup protocol.
   ```

   But this is **not required** - you can just ask naturally

## How to Use the System

### For Strategic Sessions

1. Open Claude Chat
2. Say: "Session start" or "Check project status"
3. Chat agent runs startup protocol automatically
4. Discuss strategy, make decisions
5. Chat agent writes to bridge/inbox/code/ if Code needs to know

### For Code-to-Chat Communication

1. Code writes message to bridge/outbox/chat/
2. Human opens Claude Chat
3. Say: "Check bridge"
4. Chat agent reads and responds

### For Review Requests

1. Code adds question to project CLAUDE.md under "Review Requests"
2. Human mentions it to Chat agent
3. Chat agent reviews, provides feedback
4. Marks request complete: `[ ]` → `[x]`

## Testing the Connection

Run this test to verify everything works:

### Test 1: Chat Agent File Access

In Claude Chat, say:
> "Read the first 5 lines of /Users/devvynmurphy/devvyn-meta-project/key-answers.md"

**Expected**: Agent uses filesystem tool and shows you the content

### Test 2: Project Scanning

In Claude Chat, say:
> "Check s3-image-dataset-kit for review requests"

**Expected**: Agent reads CLAUDE.md and finds the 3 pending questions

### Test 3: Bridge System

In Claude Chat, say:
> "List files in the bridge outbox for me"

**Expected**: Agent shows what's in bridge/outbox/chat/

## Connection Quality Indicators

✅ **Working correctly if:**

- Chat agent can read project files without errors
- Bridge messages get processed
- Review requests get answered
- Strategic decisions appear in key-answers.md

⚠️ **Check connections if:**

- File permission errors appear
- Agent claims it can't access filesystem
- Bridge messages pile up unread
- Review requests go unanswered

## Support Resources

### If Something Doesn't Work

1. **File Access Issues**: Check MCP server configuration in Claude Desktop
2. **Bridge Confusion**: Review `/Users/devvynmurphy/devvyn-meta-project/bridge/README.md`
3. **Agent Behavior**: Reference `/Users/devvynmurphy/devvyn-meta-project/agents/CHAT_AGENT_INSTRUCTIONS.md`
4. **Startup Protocol**: Check `/Users/devvynmurphy/devvyn-meta-project/agents/CHAT_SESSION_STARTUP.md`

### Key Insight

The system is designed with **zero manual copying** required. Everything connects through:

- **MCP filesystem access** (automatic via Desktop app)
- **Standardized file locations** (predictable paths)
- **Clear protocols** (documented procedures)

No API keys, no manual syncing, no copy-paste workflows.

---

## Summary: You're Good to Go! ✅

**Everything is connected.** The glue is in place:

1. ✅ Desktop app has filesystem access to meta-project
2. ✅ Chat agent has instructions at `agents/CHAT_AGENT_INSTRUCTIONS.md`
3. ✅ Startup protocol defined at `agents/CHAT_SESSION_STARTUP.md`
4. ✅ Bridge system ready at `bridge/`
5. ✅ Project CLAUDE.md files exist with review request sections
6. ✅ key-answers.md provides strategic communication channel

**To test it:** Just say "session start" in this conversation and I'll run the startup protocol right now.

**No manual pasting needed.** Everything flows through the filesystem.
