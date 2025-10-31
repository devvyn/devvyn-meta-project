# Platform Porting Guide: Multi-Agent Coordination System

**Version**: 1.0
**Date**: 2025-10-30
**Status**: Complete Porting Roadmap
**Scope**: macOS → Linux, Windows, Web

---

## Executive Summary

The devvyn-meta-project coordination system is currently **macOS-native**. This guide provides complete, step-by-step instructions for porting to Linux, Windows, and Web platforms.

**Quick Reference**:

- **Linux Port**: 90% compatible, 1-2 weeks, $9k - RECOMMENDED
- **Windows (WSL2)**: 85% compatible, 2-4 weeks, $20k
- **Windows (Native)**: 60% compatible, 3-6 months, $56k - Only if WSL2 blocked
- **Web Platform**: 40% compatible, 6-12 months, $136k - SaaS transformation

---

## Table of Contents

1. Platform Comparison Matrix
2. Porting Strategy Overview
3. macOS → Linux Port (Detailed)
4. macOS → Windows Port (WSL2 & Native)
5. macOS → Web Platform
6. Script Conversion Examples
7. Testing Strategy
8. Migration Checklists
9. Cost & Effort Estimates
10. Decision Framework

---

## Platform Comparison Matrix

### Feature Compatibility

| Component | macOS | Linux | Windows (WSL2) | Windows (Native) | Web |
|-----------|-------|-------|----------------|------------------|-----|
| Bash Scripts | ✅ Native | ✅ Native | ✅ Via WSL | ❌ Rewrite | ❌ Backend API |
| Message Queue | ✅ File | ✅ File | ✅ File | ⚠️ Paths | 🔄 PostgreSQL |
| Event Sourcing | ✅ | ✅ | ✅ | ✅ | ✅ Database |
| Background Tasks | ✅ LaunchAgents | 🔄 systemd | 🔄 systemd | ⚠️ Task Sched | ✅ Cron |
| Claude Integration | ✅ osascript | ❌ API only | ❌ API only | ❌ API only | ✅ API |

---

## Complete Dependency Matrix

# Platform Dependency Matrix

**Status**: Platform Portability Reference
**Version**: 1.0
**Purpose**: Complete mapping of platform dependencies and alternatives
**Audience**: Porters, system administrators, cross-platform developers

---

## Overview

This document provides a comprehensive matrix of all platform dependencies in the devvyn-meta-project coordination system. For each component, we document:

- **What platforms it works on** (macOS, Linux, Windows, Web)
- **What alternatives exist** for unsupported platforms
- **Migration effort** required for porting
- **Compatibility notes** and gotchas

**Color Code**:

- ✅ **Fully Supported** - Works out of the box
- ⚠️ **Partial Support** - Works with modifications
- ❌ **Not Supported** - Requires alternative implementation
- 🔄 **Migration Available** - Clear migration path exists

---

## Dependency Categories

### Category 1: Operating System & Shell

### Category 2: Background Automation

### Category 3: File System Operations

### Category 4: Command-Line Tools

### Category 5: Python & Package Management

### Category 6: Integration APIs

### Category 7: Storage Backends

---

## Category 1: Operating System & Shell

### Bash Shell

| Platform | Status | Version | Notes | Alternative |
|----------|--------|---------|-------|-------------|
| macOS | ✅ | 3.2 (builtin) or 5.x (Homebrew) | Default bash is old (3.2), recommend Homebrew bash 5.x | zsh (default shell on macOS 10.15+) |
| Linux | ✅ | 4.x-5.x | Standard on most distros | sh, zsh, dash |
| Windows | ⚠️ | WSL or Git Bash | Requires WSL, Git Bash, or Cygwin | PowerShell rewrite required |
| Web | ❌ | N/A | Shell scripts don't run in browser | Backend API required |

**Migration Effort**:

- macOS → Linux: 95% compatible (minor syntax differences)
- macOS/Linux → Windows: 40% compatible (requires significant rewrite)
- Any → Web: 0% compatible (complete architecture change)

**Key Script Dependencies**: 7,864 lines of bash scripts

**Porting Strategy**:

```bash
# Check bash version
bash --version

# Install modern bash on macOS
brew install bash
echo /opt/homebrew/bin/bash | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/bash

# Windows: Use WSL2
wsl --install -d Ubuntu

# Alternative: Rewrite in Python
python3 script.py  # Portable to all platforms
```

---

## Category 2: Background Automation

### LaunchAgents (macOS)

| Platform | Status | Alternative | Migration Effort | Notes |
|----------|--------|-------------|------------------|-------|
| macOS | ✅ | N/A | Native | XML plist format, launchd system |
| Linux | ❌ | systemd timers | 2-4 hours | Timer + service unit files |
| Windows | ❌ | Task Scheduler | 3-6 hours | Different scheduling paradigm |
| Web | ❌ | Cron jobs (server-side) | 1-2 hours | Standard cron on backend |

**Current Implementation**: 8 LaunchAgents for automation

**LaunchAgent Example** (macOS):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.devvyn.bridge-queue</string>
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/script.sh</string>
    </array>
    <key>StartInterval</key>
    <integer>300</integer>  <!-- Every 5 minutes -->
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
```

**systemd Timer Equivalent** (Linux):

```ini
# bridge-queue.timer
[Unit]
Description=Bridge Queue Processing Timer

[Timer]
OnCalendar=*:0/5  # Every 5 minutes
Persistent=true

[Install]
WantedBy=timers.target

# bridge-queue.service
[Unit]
Description=Bridge Queue Processor

[Service]
Type=oneshot
ExecStart=/path/to/script.sh
```

**Task Scheduler Equivalent** (Windows PowerShell):

```powershell
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File C:\path\to\script.ps1"
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5)
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "BridgeQueue"
```

**Migration Script**:

```bash
# scripts/migrate-automation.sh
#!/bin/bash

PLATFORM=$(uname -s)

case "$PLATFORM" in
    Darwin)
        # macOS - LaunchAgents
        cp launchagents/*.plist ~/Library/LaunchAgents/
        launchctl load ~/Library/LaunchAgents/com.devvyn.*.plist
        ;;
    Linux)
        # Linux - systemd
        cp systemd/* ~/.config/systemd/user/
        systemctl --user daemon-reload
        systemctl --user enable --now bridge-queue.timer
        ;;
    MINGW*|MSYS*|CYGWIN*)
        # Windows
        echo "Use Task Scheduler GUI or PowerShell script"
        ;;
esac
```

---

## Category 3: File System Operations

### POSIX File System

| Component | macOS | Linux | Windows | Web | Notes |
|-----------|-------|-------|---------|-----|-------|
| Atomic `mv` | ✅ | ✅ | ⚠️ | N/A | Windows NTFS: mostly atomic, test thoroughly |
| File locking (`flock`) | ✅ | ✅ | ❌ | N/A | Windows: use `LockFileEx` API |
| Symbolic links | ✅ | ✅ | ⚠️ | N/A | Windows: requires admin privileges or Developer Mode |
| Path separators | `/` | `/` | `\` or `/` | `/` (URL) | Windows accepts both in most cases |
| Max path length | 1024 chars | 4096 chars | 260 chars (legacy) | N/A | Windows: enable long paths in registry |
| Case sensitivity | ❌ (APFS optional) | ✅ (ext4) | ❌ (NTFS) | Depends | Affects file lookup |

**Critical Dependency**: Atomic file operations for collision-free message creation

**Platform-Specific Code**:

```bash
# macOS / Linux
mv "$temp_file" "$final_file"  # Atomic rename

# Windows (PowerShell)
Move-Item -Path $temp_file -Destination $final_file -Force

# Python (cross-platform)
import shutil
shutil.move(temp_file, final_file)  # Atomic on POSIX, mostly on Windows
```

**File Locking Cross-Platform**:

```python
import fcntl  # Unix
import msvcrt  # Windows
import platform

def lock_file(file_handle):
    if platform.system() == 'Windows':
        msvcrt.locking(file_handle.fileno(), msvcrt.LK_LOCK, 1)
    else:
        fcntl.flock(file_handle, fcntl.LOCK_EX)

def unlock_file(file_handle):
    if platform.system() == 'Windows':
        msvcrt.locking(file_handle.fileno(), msvcrt.LK_UNLCK, 1)
    else:
        fcntl.flock(file_handle, fcntl.LOCK_UN)
```

---

## Category 4: Command-Line Tools

### Core Utilities

| Tool | macOS | Linux | Windows | Alternative | Purpose |
|------|-------|-------|---------|-------------|---------|
| `date` | ✅ BSD | ✅ GNU | ❌ | PowerShell `Get-Date` | Timestamp generation |
| `find` | ✅ BSD | ✅ GNU | ⚠️ Git Bash | `fd`, PowerShell `Get-ChildItem` | File search |
| `grep` | ✅ BSD | ✅ GNU | ⚠️ Git Bash | `rg`, PowerShell `Select-String` | Text search |
| `sed` | ✅ BSD | ✅ GNU | ⚠️ Git Bash | `perl`, Python | Text transformation |
| `awk` | ✅ BSD | ✅ GNU | ⚠️ Git Bash | Python, `jq` | Text processing |
| `shasum` | ✅ | ❌ | ❌ | `sha256sum` (Linux), `Get-FileHash` (Win) | Hash computation |
| `uuidgen` | ✅ | ✅ | ❌ | PowerShell `[guid]::NewGuid()` | UUID generation |

**Key Differences: BSD vs. GNU**

```bash
# Date formatting
# macOS (BSD)
date -Iseconds               # 2025-10-30T12:34:56-06:00

# Linux (GNU)
date --iso-8601=seconds      # 2025-10-30T12:34:56-06:00

# Cross-platform solution
if date --version >/dev/null 2>&1; then
    # GNU date
    date --iso-8601=seconds
else
    # BSD date
    date -Iseconds
fi
```

```bash
# Find command
# macOS (BSD)
find /path -type f -name "*.md"

# Linux (GNU) - same syntax, more options
find /path -type f -name "*.md" -printf "%T@ %p\n"

# fd (cross-platform alternative)
fd --type f "\.md$" /path
```

### Modern Tool Alternatives (Recommended)

| Modern Tool | Purpose | macOS | Linux | Windows | Notes |
|-------------|---------|-------|-------|---------|-------|
| `fd` | File search | ✅ Homebrew | ✅ Cargo | ✅ Scoop | Faster than find |
| `rg` (ripgrep) | Text search | ✅ Homebrew | ✅ Cargo | ✅ Scoop | Faster than grep |
| `jq` | JSON processing | ✅ Homebrew | ✅ apt | ✅ Scoop | Cross-platform |
| `bat` | File viewer | ✅ Homebrew | ✅ apt | ✅ Scoop | Syntax highlighting |
| `uv` | Python package mgr | ✅ | ✅ | ✅ | Rust-based, fast |

**Installation Commands**:

```bash
# macOS
brew install fd ripgrep jq bat uv

# Linux (Ubuntu/Debian)
sudo apt install fd-find ripgrep jq bat
curl -LsSf https://astral.sh/uv/install.sh | sh

# Windows (Scoop)
scoop install fd ripgrep jq bat uv

# Cargo (all platforms)
cargo install fd-find ripgrep bat-extras
```

---

## Category 5: Python & Package Management

### Python Environment

| Component | macOS | Linux | Windows | Notes |
|-----------|-------|-------|---------|-------|
| Python 3.8+ | ✅ | ✅ | ✅ | Universal |
| `pip` | ✅ | ✅ | ✅ | Standard |
| `uv` | ✅ | ✅ | ✅ | Rust-based, 10-100x faster |
| Virtual environments | ✅ | ✅ | ✅ | `venv` or `uv venv` |

**Package Management Comparison**:

| Tool | Speed | Compatibility | Platform Support |
|------|-------|---------------|------------------|
| `pip` | 1x (baseline) | 100% | All |
| `poetry` | 0.8x (slower) | 95% | All |
| `conda` | 0.5x (slowest) | 90% | All |
| `uv` | 10-100x (fastest) | 99% | All |

**Recommended Setup**:

```bash
# Install uv (cross-platform)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Create virtual environment
uv venv

# Activate (platform-specific)
source .venv/bin/activate  # macOS / Linux
.venv\Scripts\activate      # Windows

# Install dependencies
uv pip install -r requirements.txt
```

**PyRIT Integration** (RED TEAM Agent):

```yaml
Platform Support:
  - macOS: ✅ (pip install pyrit-toolkit)
  - Linux: ✅ (pip install pyrit-toolkit)
  - Windows: ✅ (pip install pyrit-toolkit)

Dependencies:
  - OpenAI API: Optional (fallback to simulation)
  - Azure OpenAI: Optional
  - Local LLM: Future support
```

---

## Category 6: Integration APIs

### Notes.app (macOS Only)

| Platform | Status | Alternative | Migration Effort | Notes |
|----------|--------|-------------|------------------|-------|
| macOS | ✅ | N/A | Native | AppleScript via `osascript` |
| Linux | ❌ | Joplin, SQLite | 4-8 hours | Custom storage layer |
| Windows | ❌ | OneNote API, SQLite | 4-8 hours | Different API |
| Web | ❌ | PostgreSQL, MongoDB | 2-4 hours | Database backend |

**Current Usage**: Persistent memory, cross-session context

**AppleScript Example** (macOS):

```applescript
tell application "Notes"
    tell account "iCloud"
        tell folder "Claude Code"
            make new note with properties {name:"Session Memory", body:"[content]"}
        end tell
    end tell
end tell
```

**Cross-Platform Alternative** (SQLite):

```python
import sqlite3
import json
from datetime import datetime

class PersistentMemory:
    def __init__(self, db_path="memory.db"):
        self.conn = sqlite3.connect(db_path)
        self.setup_schema()

    def setup_schema(self):
        self.conn.execute("""
            CREATE TABLE IF NOT EXISTS notes (
                id INTEGER PRIMARY KEY,
                title TEXT NOT NULL,
                content TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            )
        """)

    def create_note(self, title, content):
        now = datetime.utcnow().isoformat()
        self.conn.execute("""
            INSERT INTO notes (title, content, created_at, updated_at)
            VALUES (?, ?, ?, ?)
        """, (title, content, now, now))
        self.conn.commit()

    def get_note(self, title):
        cursor = self.conn.execute("""
            SELECT content FROM notes WHERE title = ? ORDER BY created_at DESC LIMIT 1
        """, (title,))
        row = cursor.fetchone()
        return row[0] if row else None
```

**Joplin CLI Alternative** (Linux):

```bash
# Install Joplin CLI
npm install -g joplin

# Configure
joplin config editor "vim"

# Create note
echo "Session memory content" | joplin mkbook "Claude Code"
echo "Session memory content" | joplin mknote "Session Memory"

# Read note
joplin cat "Session Memory"
```

### Claude.app Automation (osascript)

| Platform | Status | Alternative | Notes |
|----------|--------|-------------|-------|
| macOS | ✅ | N/A | `osascript` automation enables autonomous Chat agent |
| Linux | ❌ | Manual or API | No desktop app automation |
| Windows | ❌ | Manual or API | No desktop app automation |
| Web | ✅ | API integration | Claude API available |

**Key Feature Lost**: Without `osascript` automation, Chat agent cannot operate autonomously.

**Alternative**: Claude API integration

```python
import anthropic

client = anthropic.Anthropic(api_key="your-api-key")

message = client.messages.create(
    model="claude-sonnet-4.5",
    max_tokens=4096,
    messages=[
        {"role": "user", "content": "Message from bridge system"}
    ]
)

print(message.content)
```

---

## Category 7: Storage Backends

### File-Based Storage

| Platform | Scalability | Performance | Notes |
|----------|-------------|-------------|-------|
| macOS | 10k messages/day | Good | APFS optimized |
| Linux | 10k messages/day | Good | ext4/btrfs/xfs |
| Windows | 5k messages/day | Fair | NTFS slower for many small files |
| Web | N/A | N/A | Use database |

**Migration to Database**:

```yaml
File-Based (Current):
  Pros:
    - Simple (no daemon, no config)
    - Debuggable (cat files)
    - Git-friendly (text files)
  Cons:
    - Scales to ~10k messages/day
    - Query performance O(n) scan
    - No complex queries

Database (Future):
  Options:
    - SQLite: Embedded, no daemon, 100k msgs/day
    - PostgreSQL: Full-featured, 1M msgs/day
    - Redis: In-memory, 10M msgs/day (with persistence)

  Migration Effort:
    - SQLite: 1-2 weeks
    - PostgreSQL: 2-4 weeks
    - Redis: 1-2 weeks
```

**SQLite Migration Example**:

```sql
-- Schema
CREATE TABLE messages (
    id INTEGER PRIMARY KEY,
    message_id TEXT UNIQUE NOT NULL,
    queue_number INTEGER NOT NULL,
    sender TEXT NOT NULL,
    recipient TEXT NOT NULL,
    priority TEXT NOT NULL,
    timestamp TEXT NOT NULL,
    content TEXT NOT NULL,
    status TEXT DEFAULT 'pending',
    created_at TEXT NOT NULL
);

CREATE INDEX idx_recipient_priority ON messages(recipient, priority, queue_number);
CREATE INDEX idx_status ON messages(status);

-- Insert message (replaces file write)
INSERT INTO messages (message_id, queue_number, sender, recipient, priority, timestamp, content, created_at)
VALUES (?, ?, ?, ?, ?, ?, ?, ?);

-- Retrieve messages (replaces file scan)
SELECT * FROM messages
WHERE recipient = ? AND status = 'pending'
ORDER BY
    CASE priority
        WHEN 'CRITICAL' THEN 0
        WHEN 'HIGH' THEN 1
        WHEN 'NORMAL' THEN 2
        WHEN 'INFO' THEN 3
    END,
    queue_number ASC
LIMIT 10;
```

---

## Platform-Specific Gotchas

### macOS

```bash
# 1. Date command (BSD)
date -Iseconds  # Works
date --iso-8601=seconds  # Fails

# 2. Default bash is old (3.2)
bash --version  # 3.2.57 (2007!)
brew install bash  # Get 5.x

# 3. GNU tools available with 'g' prefix
brew install coreutils
gdate --iso-8601=seconds  # GNU date as gdate

# 4. Case-insensitive filesystem (default)
touch FILE.txt
touch file.txt  # Same file!
# Solution: Use APFS case-sensitive volume

# 5. Homebrew paths
/opt/homebrew/bin/  # Apple Silicon
/usr/local/bin/     # Intel Macs
```

### Linux

```bash
# 1. Distribution differences
apt install  # Debian/Ubuntu
yum install  # RHEL/CentOS
pacman -S    # Arch

# 2. systemd user services
systemctl --user enable service.timer  # Requires loginctl enable-linger

# 3. File paths
~/.config/systemd/user/  # User units
/etc/systemd/system/     # System units

# 4. Python executable name
python3  # Most distros
python   # Some distros alias to python3, others don't exist
```

### Windows

```bash
# 1. Path separators
C:\path\to\file    # Native
C:/path/to/file    # Also works in most cases

# 2. Line endings
CRLF (\r\n)  # Windows
LF (\n)      # Unix
# Solution: git config core.autocrlf true

# 3. PowerShell vs CMD
PowerShell: Modern, recommended
CMD: Legacy, limited

# 4. WSL2 vs Native
WSL2: Linux environment on Windows (recommended for bash scripts)
Native Windows: Requires PowerShell rewrites

# 5. Long path support
# Registry: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem
# Set LongPathsEnabled = 1
```

---

## Migration Paths

### Path 1: macOS → Linux

**Compatibility**: 90%

**Changes Required**:

1. LaunchAgents → systemd timers (2-4 hours)
2. BSD tools → GNU tools (minor syntax changes, 1-2 hours)
3. Notes.app → Joplin CLI or SQLite (4-8 hours)
4. Test all scripts (2-4 hours)

**Total Effort**: 1-2 weeks

**Migration Checklist**:

- [ ] Replace `date -Iseconds` with `date --iso-8601=seconds`
- [ ] Test `find` commands (usually compatible)
- [ ] Convert LaunchAgents to systemd timers
- [ ] Implement persistent memory alternative
- [ ] Update paths (`~/Library` → `~/.config`)
- [ ] Test file locking with `flock`
- [ ] Verify all tests pass

### Path 2: macOS → Windows

**Compatibility**: 60%

**Changes Required**:

1. Bash scripts → PowerShell (3-6 months for 7,864 lines)
2. LaunchAgents → Task Scheduler (3-6 hours)
3. File operations → Windows APIs (1-2 weeks)
4. Notes.app → OneNote API or SQLite (4-8 hours)
5. Path handling → Windows paths (1 week)

**Total Effort**: 3-6 months (significant rewrite)

**Recommendation**: Use WSL2 for bash scripts, native Windows for UI/automation

**WSL2 Hybrid Approach**:

```powershell
# PowerShell wrapper that calls WSL2 bash scripts
$WSL_SCRIPT = "~/devvyn-meta-project/scripts/bridge-send.sh"
wsl bash -c "$WSL_SCRIPT code chat HIGH 'Test Message' /tmp/test.md"
```

### Path 3: Any → Web Application

**Compatibility**: 40% (architecture change)

**Changes Required**:

1. Bash scripts → Backend API (Python/Node.js) (2-4 months)
2. File queue → Database (PostgreSQL/MongoDB) (2-4 weeks)
3. LaunchAgents → Cron jobs (backend) (1 week)
4. Add frontend UI (React/Vue) (2-3 months)
5. Authentication & authorization (1-2 months)

**Total Effort**: 6-12 months (complete rewrite)

**Architecture**:

```
Frontend (React)
  ↓ HTTP/WebSocket
Backend API (Python FastAPI / Node Express)
  ↓
Database (PostgreSQL)
  ↓
Background Workers (Celery / Bull)
  ↓
Message Queue (Redis / RabbitMQ)
```

---

## Testing Matrix

### Test Coverage by Platform

| Component | macOS Test | Linux Test | Windows Test | Web Test |
|-----------|------------|------------|--------------|----------|
| Message Creation | ✅ Passing | 🔄 Needed | ❌ Not Impl | N/A |
| Queue Processing | ✅ Passing | 🔄 Needed | ❌ Not Impl | N/A |
| Event Sourcing | ✅ Passing | 🔄 Needed | ❌ Not Impl | N/A |
| Content DAG | ✅ Passing | 🔄 Needed | ❌ Not Impl | N/A |
| Agent Registration | ✅ Passing | 🔄 Needed | ❌ Not Impl | N/A |
| LaunchAgents | ✅ Working | ❌ Not Impl (systemd) | ❌ Not Impl | N/A |
| Notes Integration | ✅ Working | ❌ Not Impl | ❌ Not Impl | N/A |

**Testing Commands**:

```bash
# macOS
./scripts/test-all.sh

# Linux (after port)
./scripts/test-all-linux.sh

# Windows (after port)
powershell ./scripts/Test-All.ps1

# Cross-platform (Python)
python3 -m pytest tests/
```

---

## Dependency Decision Tree

```
Start: Choosing Implementation Strategy
    |
    ├─ Need: macOS only?
    │   └─ Use: Current implementation (LaunchAgents, Notes.app, osascript)
    |
    ├─ Need: Linux support?
    │   ├─ Option 1: Port to Linux (1-2 weeks)
    │   │   - systemd timers
    │   │   - Joplin or SQLite
    │   │   - GNU tools
    │   └─ Option 2: Docker (run macOS scripts in container)
    |       - Heavier but faster to deploy
    |
    ├─ Need: Windows support?
    │   ├─ Option 1: WSL2 (recommended, 1-2 weeks)
    │   │   - Run Linux version in WSL2
    │   │   - PowerShell wrappers for integration
    │   ├─ Option 2: Native port (3-6 months)
    │   │   - Rewrite scripts in PowerShell
    │   │   - Use Task Scheduler
    │   │   - Windows APIs for file operations
    │   └─ Option 3: Web app (6-12 months)
    │       - Browser-based, works everywhere
    |
    └─ Need: Web/mobile access?
        └─ Option: Full rewrite as web application
            - Backend API (Python/Node)
            - Database (PostgreSQL)
            - Frontend (React)
            - Mobile apps (React Native)
```

---

## Recommendations by Use Case

### Individual User (Single Platform)

**Recommendation**: Use current macOS implementation OR Linux port

- **Effort**: 0-2 weeks
- **Maintenance**: Low (single platform)
- **Features**: Full feature set

### Small Team (Mixed Platforms)

**Recommendation**: Docker containers + shared bridge

- **Effort**: 2-4 weeks
- **Maintenance**: Medium (container updates)
- **Features**: 90% feature parity

### Enterprise (100+ Users)

**Recommendation**: Web application

- **Effort**: 6-12 months
- **Maintenance**: High (full application)
- **Features**: Custom features, authentication, RBAC

### Research Lab (Linux Servers)

**Recommendation**: Linux port

- **Effort**: 1-2 weeks
- **Maintenance**: Low
- **Features**: Full feature set, server-friendly

---

## Platform Support Roadmap

### Phase 1: Current State (✅ Complete)

- macOS: Full support
- Production-ready: AAFC herbarium (2,885 specimens)

### Phase 2: Linux Port (📋 Planned - Q1 2026)

- systemd timers
- Joplin integration
- GNU tool adaptations
- Full test coverage

### Phase 3: WSL2 Support (📋 Planned - Q2 2026)

- Windows compatibility via WSL2
- PowerShell wrappers
- Installation guide

### Phase 4: Database Backend (📋 Planned - Q3 2026)

- SQLite for embedded
- PostgreSQL for multi-user
- Migration tools
- Performance benchmarks

### Phase 5: Web Application (📋 Conceptual - Q4 2026)

- REST API
- React frontend
- Authentication
- Mobile-responsive

---

## Platform-Specific Installation Guides

### macOS Installation

```bash
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install dependencies
brew install bash jq fd ripgrep uv

# 3. Clone repository
git clone https://github.com/user/devvyn-meta-project.git
cd devvyn-meta-project

# 4. Run setup
./scripts/setup-macos.sh

# 5. Register agent
./scripts/bridge-register.sh register code

# 6. Test
./scripts/bridge-send.sh code chat NORMAL "Test" /tmp/test.md
```

### Linux Installation (Future)

```bash
# 1. Install dependencies
sudo apt update
sudo apt install jq fd-find ripgrep
curl -LsSf https://astral.sh/uv/install.sh | sh

# 2. Clone repository
git clone https://github.com/user/devvyn-meta-project.git
cd devvyn-meta-project

# 3. Run setup
./scripts/setup-linux.sh

# 4. Enable systemd timers
systemctl --user enable --now bridge-queue.timer

# 5. Register agent
./scripts/bridge-register.sh register code

# 6. Test
./scripts/bridge-send.sh code chat NORMAL "Test" /tmp/test.md
```

### Windows + WSL2 Installation (Future)

```powershell
# 1. Install WSL2
wsl --install -d Ubuntu

# 2. Inside WSL2, follow Linux installation

# 3. Create PowerShell wrapper (optional)
# See docs/platform/windows-wsl2-guide.md
```

---

## Summary: Platform Portability at a Glance

| Feature | macOS | Linux | Windows (WSL2) | Windows (Native) | Web |
|---------|-------|-------|----------------|------------------|-----|
| Bash Scripts | ✅ | ✅ | ✅ | ❌ | N/A |
| Message Queue | ✅ | ✅ | ✅ | ⚠️ | 🔄 DB |
| Event Sourcing | ✅ | ✅ | ✅ | ✅ | 🔄 DB |
| Content DAG | ✅ | ✅ | ✅ | ✅ | 🔄 DB |
| Background Tasks | ✅ LaunchAgents | 🔄 systemd | 🔄 systemd | ⚠️ Task Scheduler | ✅ Cron |
| Persistent Memory | ✅ Notes.app | 🔄 Joplin/SQLite | 🔄 SQLite | 🔄 SQLite | ✅ PostgreSQL |
| Claude Automation | ✅ osascript | ❌ | ❌ | ❌ | 🔄 API |
| File Operations | ✅ | ✅ | ✅ | ⚠️ | N/A |
| **Overall** | ✅ 100% | 🔄 90% | 🔄 85% | ⚠️ 60% | 🔄 75% |

**Legend**:

- ✅ Fully Working
- 🔄 Implementation Needed
- ⚠️ Partial/Limited
- ❌ Not Available

---

**Document Version**: 1.0
**Last Updated**: 2025-10-30
**Maintained By**: CODE agent
**Next Review**: After first Linux port (Q1 2026)

**Related Documents**:

- `universal-patterns.md` - Platform-agnostic patterns
- `customization-guide.md` - Configuration options
- `docs/branching/platform-porting-guide.md` - Detailed porting steps

---

## macOS → Linux Port: Complete Guide

### Step 1: Prerequisites

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y bash jq curl git fd-find ripgrep \
  systemd coreutils python3 python3-pip sqlite3

# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Note: Create fd symlink
sudo ln -s $(which fdfind) /usr/local/bin/fd
```

### Step 2: Directory Structure

```bash
mkdir -p ~/.local/share/agent-bridge/bridge/{queue/{pending,processing,archive},inbox,outbox,registry/{sessions,archive},events,defer-queue}
mkdir -p ~/.local/share/devvyn-meta-project/logs
mkdir -p ~/.config/devvyn-meta-project
mkdir -p ~/.config/systemd/user
```

### Step 3: Platform Detection

Create `scripts/platform-detect.sh`:

```bash
#!/bin/bash
detect_platform() {
    case "$(uname -s)" in
        Darwin)  echo "macos" ;;
        Linux)   echo "linux" ;;
        *)       echo "unknown" ;;
    esac
}

iso_date() {
    if date --version >/dev/null 2>&1; then
        date --iso-8601=seconds  # GNU
    else
        date -Iseconds  # BSD
    fi
}

export -f detect_platform iso_date
```

### Step 4: Path Abstraction

Create `scripts/platform-paths.sh`:

```bash
#!/bin/bash
get_bridge_root() {
    case "$(detect_platform)" in
        macos)  echo "/Users/$USER/infrastructure/agent-bridge/bridge" ;;
        linux)  echo "$HOME/.local/share/agent-bridge/bridge" ;;
    esac
}

export -f get_bridge_root
```

### Step 5: LaunchAgents → systemd

**For each LaunchAgent plist**, create timer + service:

`~/.config/systemd/user/bridge-queue.timer`:

```ini
[Unit]
Description=Bridge Queue Processing Timer

[Timer]
OnCalendar=*:0/5  # Every 5 minutes
Persistent=true

[Install]
WantedBy=timers.target
```

`~/.config/systemd/user/bridge-queue.service`:

```ini
[Unit]
Description=Bridge Queue Processor

[Service]
Type=oneshot
ExecStart=%h/devvyn-meta-project/scripts/bridge-process-queue-wrapper.sh
StandardOutput=append:%h/.local/share/devvyn-meta-project/logs/bridge-queue.log
StandardError=append:%h/.local/share/devvyn-meta-project/logs/bridge-queue-error.log

[Install]
WantedBy=default.target
```

Enable:

```bash
systemctl --user daemon-reload
systemctl --user enable --now bridge-queue.timer
sudo loginctl enable-linger $USER
```

### Step 6: Notes.app → SQLite

Create `scripts/persistent-memory-sqlite.py` for cross-platform persistent storage.

### Step 7: Claude API Integration

Since osascript doesn't work on Linux, use Claude API for automation.

---

## macOS → Windows Port

### Option 1: WSL2 (RECOMMENDED - 85% compatible)

```powershell
# Install WSL2
wsl --install -d Ubuntu

# Inside WSL, follow Linux port instructions
wsl
cd ~
git clone https://github.com/user/devvyn-meta-project.git
cd devvyn-meta-project
./scripts/setup-linux.sh
```

**PowerShell Wrapper Example**:

```powershell
# scripts/windows/Bridge-Send.ps1
param(
    [Parameter(Mandatory=$true)][string]$Sender,
    [Parameter(Mandatory=$true)][string]$Recipient,
    [Parameter(Mandatory=$true)][string]$Priority,
    [Parameter(Mandatory=$true)][string]$Title
)

$scriptPath = "~/devvyn-meta-project/scripts/bridge-send.sh"
$cmd = "bash $scriptPath $Sender $Recipient $Priority '$Title'"
wsl bash -c $cmd
```

### Option 2: Native Windows (60% compatible)

Requires complete PowerShell rewrite. Only pursue if WSL2 blocked by corporate policy.

**Effort**: 3-6 months, $56k

---

## macOS → Web Platform

### Architecture

```
Frontend (React) → Backend API (FastAPI) → PostgreSQL → Background Workers (Celery) → Redis
```

### Key Changes

1. **File-based → Database**: All messages, events, content in PostgreSQL
2. **Bash scripts → API endpoints**: RESTful API replaces shell scripts
3. **LaunchAgents → Cron jobs**: Server-side background tasks
4. **Notes.app → PostgreSQL**: Persistent memory in database

### Backend API Example (FastAPI)

```python
from fastapi import FastAPI
import asyncpg, uuid
from datetime import datetime

app = FastAPI()

@app.post("/api/v1/messages")
async def create_message(sender: str, recipient: str, priority: str, content: str):
    message_id = f"{datetime.utcnow().isoformat()}-{sender}-{uuid.uuid4()}"

    async with app.state.db.acquire() as conn:
        await conn.execute(
            "INSERT INTO messages (message_id, sender, recipient, priority, content) "
            "VALUES ($1, $2, $3, $4, $5)",
            message_id, sender, recipient, priority, content
        )

    return {"message_id": message_id}
```

---

## Testing Strategy

### Linux Test Suite

```bash
#!/bin/bash
# tests/test-linux-compatibility.sh

PASSED=0
FAILED=0

test_case() {
    local name="$1"
    local command="$2"
    echo -n "Testing: $name... "
    if eval "$command" >/dev/null 2>&1; then
        echo "✅ PASS"
        PASSED=$((PASSED + 1))
    else
        echo "❌ FAIL"
        FAILED=$((FAILED + 1))
    fi
}

test_case "Platform detection" "[ $(uname -s) = 'Linux' ]"
test_case "bash available" "command -v bash"
test_case "jq available" "command -v jq"
test_case "systemd works" "systemctl --user status >/dev/null"
test_case "Message creation" "./scripts/bridge-send.sh code chat INFO 'Test'"

echo "Results: Passed=$PASSED Failed=$FAILED"
[ $FAILED -eq 0 ]
```

---

## Migration Checklists

### macOS → Linux (1-2 weeks)

**Phase 1: Preparation (Day 1)**

- [ ] Provision Linux machine (Ubuntu 22.04 LTS recommended)
- [ ] Install base dependencies
- [ ] Configure SSH access

**Phase 2: Directory Structure (Day 1)**

- [ ] Create ~/.local/share/agent-bridge/bridge/
- [ ] Create ~/.config/devvyn-meta-project/
- [ ] Initialize agent registry

**Phase 3: Script Migration (Days 2-3)**

- [ ] Create platform-detect.sh
- [ ] Create platform-paths.sh
- [ ] Update all bridge scripts with platform detection
- [ ] Test each script individually

**Phase 4: Automation (Days 3-4)**

- [ ] Convert each LaunchAgent to systemd timer+service
- [ ] Enable all timers
- [ ] Enable user lingering
- [ ] Verify timers run on schedule

**Phase 5: Storage (Days 4-5)**

- [ ] Implement SQLite persistent memory
- [ ] Migrate Notes.app data
- [ ] Test persistence

**Phase 6: Integration (Days 5-6)**

- [ ] Configure Claude API key
- [ ] Test API wrapper
- [ ] Test end-to-end message flow

**Phase 7: Testing (Days 6-7)**

- [ ] Run test-linux-compatibility.sh
- [ ] Run TLA+ verification
- [ ] Collision test (10 simultaneous messages)
- [ ] Load test (100 messages)

**Phase 8: Production (Days 7-8)**

- [ ] Run side-by-side with macOS for 24 hours
- [ ] Compare outputs
- [ ] Monitor queue depth
- [ ] Performance benchmark

**Phase 9: Post-Migration (Days 8-14)**

- [ ] Document changes
- [ ] Update README
- [ ] Monitor for 1 week
- [ ] Optimize performance

### macOS → Windows (WSL2) (2-4 weeks)

Follow Linux checklist inside WSL2, then add:

**Windows Integration**

- [ ] Create PowerShell wrapper scripts
- [ ] Test path conversion (Windows ↔ WSL)
- [ ] Configure Task Scheduler (optional)
- [ ] Test Windows → WSL communication

### macOS → Web (6-12 months)

**Phase 1: Architecture (Weeks 1-2)**

- [ ] Design API schema
- [ ] Design database schema
- [ ] Choose tech stack

**Phase 2: Database (Weeks 3-4)**

- [ ] Install PostgreSQL
- [ ] Run schema migrations
- [ ] Test connectivity

**Phase 3: Backend API (Weeks 5-8)**

- [ ] Implement message endpoints
- [ ] Implement event sourcing
- [ ] Implement authentication

**Phase 4: Background Workers (Weeks 9-10)**

- [ ] Set up Celery/Bull
- [ ] Implement queue processing
- [ ] Configure scaling

**Phase 5: Frontend (Weeks 11-16)**

- [ ] Set up React/Vue
- [ ] Implement message queue viewer
- [ ] Implement agent dashboard
- [ ] Add real-time updates (WebSocket)

**Phase 6: Deployment (Weeks 17-18)**

- [ ] Containerize with Docker
- [ ] Deploy to cloud
- [ ] Configure SSL

**Phase 7: Migration (Weeks 19-20)**

- [ ] Export existing data to database
- [ ] Run side-by-side
- [ ] Cutover

**Phase 8: Launch (Weeks 21-24)**

- [ ] Load testing
- [ ] Security audit
- [ ] User acceptance testing
- [ ] Public launch

---

## Cost & Effort Estimates

### Summary Table

| Platform | Effort | Cost @ $100/hr | Difficulty | ROI | Recommendation |
|----------|--------|----------------|------------|-----|----------------|
| **Linux** | 1-2 weeks (90h) | **$9,000** | Medium | ⭐⭐⭐⭐⭐ | **Highest priority** |
| **Windows (WSL2)** | 2-4 weeks (194h) | **$19,400** | Medium | ⭐⭐⭐⭐ | Good value |
| **Windows (Native)** | 3-6 months (561h) | **$56,100** | Hard | ⭐⭐ | Only if WSL2 blocked |
| **Web Platform** | 6-12 months (1,300h) | **$130,000** | Hard | ⭐⭐⭐⭐⭐ | If SaaS opportunity |

### Linux Port Breakdown

| Task | Hours | Cost |
|------|-------|------|
| Dependency installation | 2 | $200 |
| Directory setup | 1 | $100 |
| Script platform detection | 8 | $800 |
| Path updates | 4 | $400 |
| LaunchAgents → systemd | 16 | $1,600 |
| SQLite persistent memory | 12 | $1,200 |
| Claude API integration | 8 | $800 |
| Testing & validation | 16 | $1,600 |
| Documentation | 8 | $800 |
| Buffer (20%) | 15 | $1,500 |
| **Total** | **90** | **$9,000** |

**ROI**: Production deployment capability ($50k+ value), server cost savings ($2k/year), supports 10x more agents.

---

## Decision Framework

### Decision Tree

```
Q1: Primary deployment target?
  ├─ Server/Cloud → Linux ⭐⭐⭐⭐⭐
  ├─ Windows Desktops → WSL2 ⭐⭐⭐⭐
  ├─ Web/Mobile → Web Platform ⭐⭐⭐⭐⭐ (if SaaS)
  └─ Stay on macOS → No port needed

Q2: Budget?
  ├─ $5-10k → Linux
  ├─ $15-25k → Linux + WSL2
  ├─ $50-60k → Native Windows (only if WSL2 blocked)
  └─ $100-150k → Web Platform

Q3: Timeline?
  ├─ 1-2 weeks → Linux
  ├─ 2-4 weeks → WSL2
  ├─ 3-6 months → Native Windows
  └─ 6-12 months → Web Platform

Q4: Team composition?
  ├─ Bash experts → Linux/WSL2
  ├─ PowerShell experts → Native Windows
  ├─ Web developers → Web Platform
  └─ Mixed → Linux (most universal)
```

### When to Port to Linux

**✅ Port to Linux if**:

- Need server deployment (cloud, on-premise)
- Want cost-effective scaling
- Team uses Linux development environment
- macOS hardware is limiting factor
- Open-source ecosystem is priority

**❌ Don't port if**:

- Team is macOS-only and happy
- No server deployment needs
- Budget/time extremely limited

### When to Port to Windows

**✅ WSL2 if**:

- Team uses Windows machines
- Enterprise Windows compliance required
- Want Linux compatibility with Windows integration

**✅ Native PowerShell if**:

- WSL2 blocked by corporate policy
- Need absolute maximum performance
- Budget allows 3-6 months

### When to Port to Web

**✅ Port to Web if**:

- Want SaaS product (revenue opportunity)
- Need multi-user collaboration
- Mobile access required
- Scaling to 100+ users
- Budget allows 6-12 months

**❌ Don't port if**:

- Single-user or small team
- Budget constrained
- Desktop experience sufficient

### Recommended Path for Most Users

```
Phase 1: Linux Port (Month 1-2)
  → Production-ready, cost-effective, reusable investment

Phase 2: Assess Growth (Month 3-6)
  ├─ If Windows needed → WSL2 port (leverages Linux)
  └─ If web needed → Start design

Phase 3: Scale (Month 6-12)
  └─ If SaaS opportunity → Web platform
```

---

## Key Insights

### Universal Patterns (95%+ Portable)

These design patterns port cleanly to any platform:

1. **Collision-Free Message Protocol** - ISO8601 + namespace + UUID
2. **Event Sourcing** - Immutable append-only log
3. **Content-Addressed Storage (DAG)** - SHA256 hashing
4. **Authority Domain Separation** - Configuration-based
5. **Priority-Based FIFO Queue** - Pure algorithm
6. **TLA+ Formal Verification** - Mathematical spec

### Platform-Specific Components

These require reimplementation per platform:

1. **Automation Layer** - LaunchAgents vs systemd vs Task Scheduler
2. **Persistent Storage** - Notes.app vs Joplin vs SQLite vs PostgreSQL
3. **Claude Integration** - osascript vs API
4. **File Utilities** - BSD vs GNU vs PowerShell
5. **Path Conventions** - macOS vs Linux vs Windows

### Common Pitfalls

**Linux**:

- Distribution differences (apt vs dnf vs pacman)
- systemd requires user lingering for timers
- fd-find vs fd naming differences

**Windows**:

- Line endings (CRLF vs LF) break bash scripts
- Path separators (backslash vs forward slash)
- WSL2 cross-filesystem performance

**Web**:

- No file system - everything in database
- WebSocket connection management
- Horizontal scaling complexities

---

## Automation Opportunities

### CI/CD Multi-Platform Testing

`.github/workflows/cross-platform.yml`:

```yaml
name: Cross-Platform Tests

on: [push, pull_request]

jobs:
  test-linux:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: ./scripts/setup-linux.sh
      - run: ./tests/test-linux-compatibility.sh

  test-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - run: ./tests/test-macos-compatibility.sh

  test-wsl:
    runs-on: windows-latest
    steps:
      - run: wsl --install -d Ubuntu
      - run: wsl bash -c "cd devvyn-meta-project && ./scripts/setup-linux.sh"
      - run: powershell -File tests/test-wsl2-compatibility.ps1
```

### Container-Based Portability

```dockerfile
# Dockerfile for cross-platform development
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    bash jq curl git fd-find ripgrep python3 sqlite3

COPY scripts/ /app/scripts/
COPY bridge/ /app/bridge/

WORKDIR /app
CMD ["/bin/bash"]
```

---

## Conclusion

This comprehensive guide provides everything needed to port the devvyn-meta-project coordination system across platforms.

**Key Takeaways**:

1. **Linux first** - Highest ROI, easiest port, foundation for others
2. **Universal patterns are truly universal** - 95% of design is platform-agnostic
3. **Automation layer is the main challenge** - LaunchAgents → systemd takes most effort
4. **Web is not a port** - It's an architectural transformation with different value proposition

**Success Metrics**:

- **Linux**: 90% script reuse, 1-2 weeks, $9k investment
- **Windows (WSL2)**: Leverage Linux port, add 2 weeks
- **Web**: 6-12 months, $130k, but opens SaaS opportunity

**Next Steps**:

1. Review this guide completely
2. Choose target platform based on decision tree
3. Follow phase-by-phase migration checklist
4. Test thoroughly at each phase
5. Monitor in production
6. Document platform-specific learnings

---

**Document Version**: 1.0
**Date**: 2025-10-30
**Maintained By**: CODE agent
**Next Review**: After first production port (Q1 2026)

**Related Documents**:

- `docs/platform/dependency-matrix.md` - Detailed dependency reference
- `docs/abstractions/universal-patterns.md` - Portable design patterns
- `COORDINATION_PROTOCOL.md` - Protocol specification
- `ClaudeCodeSystem.tla` - Formal verification spec

**Contact**: For questions or assistance with porting, create an issue on GitHub.

---

**END OF PLATFORM PORTING GUIDE**
