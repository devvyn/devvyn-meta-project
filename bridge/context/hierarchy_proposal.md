# Ideal File Hierarchy and TLA+ Registry Specification

## Proposed Directory Structure

```
/Users/devvynmurphy/
├── .config/           # All config files consolidated
│   ├── shell/         # .zshrc, .bashrc, .profile, etc.
│   ├── editors/       # vim, emacs, vscode, windsurf
│   ├── tools/         # git, docker, conda, etc.
│   └── apps/          # app-specific configs
├── .cache/            # All caches (already exists)
├── .local/            # User-specific data
│   └── share/         # Application data
├── Projects/          # Active work
│   ├── active/        # Current projects
│   ├── archived/      # Completed projects
│   └── meta/          # Meta-projects like devvyn-meta-project
├── Documents/         # Personal documents (existing)
├── Development/       # Development environment
│   ├── scripts/       # Shell scripts, utilities
│   ├── dotfiles/      # Dotfiles repo/management
│   └── environments/  # Python venvs, node versions, etc.
└── Desktop, Downloads, etc. (standard macOS dirs)
```

## TLA+ Specification for Directory Constraints

```tla
---------------------------- MODULE FileHierarchy ----------------------------
EXTENDS Integers, Sequences, FiniteSets

CONSTANTS
    MAX_TOP_LEVEL_DIRS,     \* Maximum directories at home level
    MAX_DEPTH,              \* Maximum directory depth
    MAX_DOTFILES_ROOT,      \* Maximum dotfiles at root level
    RESERVED_DIRS           \* System-required directories

VARIABLES
    fileSystem,             \* Current file system state
    topLevelCount,          \* Count of top-level directories
    dotfileCount            \* Count of dotfiles at root

\* Type definitions
Path == Seq(STRING)
FileType == {"file", "directory", "symlink"}

\* Helper functions
IsTopLevel(path) == Len(path) = 1
IsDotfile(name) == SubSeq(name, 1, 1) = "."
IsReserved(name) == name \in RESERVED_DIRS

\* Invariants
TypeInvariant == 
    /\ fileSystem \in [Path -> FileType]
    /\ topLevelCount \in Nat
    /\ dotfileCount \in Nat

\* Hierarchy constraints
HierarchyInvariant ==
    /\ topLevelCount <= MAX_TOP_LEVEL_DIRS
    /\ dotfileCount <= MAX_DOTFILES_ROOT
    /\ \A p \in DOMAIN fileSystem : Len(p) <= MAX_DEPTH

\* Organization rules
OrganizationInvariant ==
    \* All config files should be under .config
    /\ \A p \in DOMAIN fileSystem : 
        (IsDotfile(Head(p)) /\ fileSystem[p] = "file") =>
            (Head(p) = ".config" \/ IsReserved(Head(p)))
    
    \* Project files should be under Projects
    /\ \A p \in DOMAIN fileSystem :
        (SubSeq(Head(p), 1, 4) = "proj") =>
            p[1] = "Projects"

\* Actions
CreateDirectory(path, name) ==
    /\ path \notin DOMAIN fileSystem
    /\ IF IsTopLevel(<<n>>) 
       THEN topLevelCount' = topLevelCount + 1
       ELSE topLevelCount' = topLevelCount
    /\ IF IsDotfile(name) /\ IsTopLevel(<<n>>)
       THEN dotfileCount' = dotfileCount + 1
       ELSE dotfileCount' = dotfileCount
    /\ fileSystem' = fileSystem @@ (<<n>> :> "directory")

MoveFile(source, dest) ==
    /\ source \in DOMAIN fileSystem
    /\ dest \notin DOMAIN fileSystem
    /\ fileSystem' = (fileSystem \ {source}) @@ (dest :> fileSystem[source])
    /\ UpdateCounts(source, dest)

\* Bridge-specific registry
BridgeRegistry == [
    inbox: Path,
    outbox: Path,
    context: Path,
    archive: Path,
    maxMessageAge: Int,
    priorityLevels: {"CRITICAL", "HIGH", "NORMAL", "INFO"}
]

\* Bridge invariants
BridgeInvariant ==
    /\ \A msg \in DOMAIN fileSystem :
        (SubSeq(msg[1], 1, 6) = "bridge") =>
            /\ Len(msg) >= 2
            /\ msg[2] \in {"inbox", "outbox", "context", "archive"}

\* Specification
Init ==
    /\ fileSystem = [p \in RESERVED_DIRS |-> "directory"]
    /\ topLevelCount = Cardinality(RESERVED_DIRS)
    /\ dotfileCount = 0

Next ==
    \/ \E path \in Path, name \in STRING : CreateDirectory(path, name)
    \/ \E source, dest \in Path : MoveFile(source, dest)

Spec == Init /\ [][Next]_<<fileSystem, topLevelCount, dotfileCount>>

\* Properties
NoOvercrowding == topLevelCount <= MAX_TOP_LEVEL_DIRS
ProperOrganization == OrganizationInvariant
BridgeConsistency == BridgeInvariant

================================================================================
```

## Implementation Strategy

### Phase 1: Consolidation (Immediate)
```bash
# Create new structure
mkdir -p ~/.config/{shell,editors,tools,apps}
mkdir -p ~/Development/{scripts,dotfiles,environments}
mkdir -p ~/Projects/{active,archived,meta}

# Move configs gradually
mv ~/.zshrc ~/.config/shell/
mv ~/.vimrc ~/.config/editors/
ln -s ~/.config/shell/.zshrc ~/.zshrc  # Symlink for compatibility
```

### Phase 2: Bridge Registry Implementation
```python
# bridge_registry.py
import json
from pathlib import Path
from typing import Dict, List
from datetime import datetime

class BridgeRegistry:
    def __init__(self, base_path: Path):
        self.base = base_path
        self.registry = self._load_registry()
        
    def _load_registry(self) -> Dict:
        registry_file = self.base / "context" / "registry.json"
        if registry_file.exists():
            return json.loads(registry_file.read_text())
        return self._init_registry()
    
    def _init_registry(self) -> Dict:
        return {
            "paths": {
                "inbox": str(self.base / "inbox"),
                "outbox": str(self.base / "outbox"),
                "context": str(self.base / "context"),
                "archive": str(self.base / "archive")
            },
            "constraints": {
                "max_top_level_dirs": 30,
                "max_depth": 10,
                "max_dotfiles_root": 10
            },
            "messages": [],
            "last_check": datetime.now().isoformat()
        }
    
    def check_constraints(self, path: Path) -> bool:
        """Verify path meets hierarchy constraints"""
        depth = len(path.parts)
        if depth > self.registry["constraints"]["max_depth"]:
            return False
        
        if path.parent == Path.home():
            top_level_count = len(list(Path.home().iterdir()))
            if top_level_count > self.registry["constraints"]["max_top_level_dirs"]:
                return False
        
        return True
    
    def register_message(self, msg_type: str, priority: str, 
                        source: str, target: str, content: str):
        """Register a bridge message in the registry"""
        message = {
            "id": datetime.now().isoformat(),
            "type": msg_type,
            "priority": priority,
            "source": source,
            "target": target,
            "status": "pending",
            "created": datetime.now().isoformat()
        }
        self.registry["messages"].append(message)
        self._save_registry()
        
    def _save_registry(self):
        registry_file = self.base / "context" / "registry.json"
        registry_file.write_text(json.dumps(self.registry, indent=2))
```

### Phase 3: Migration Script
```bash
#!/bin/bash
# migrate_hierarchy.sh

# Function to safely move and link dotfiles
migrate_dotfile() {
    local file=$1
    local dest=$2
    
    if [[ -f "$HOME/$file" ]]; then
        mkdir -p "$(dirname "$dest")"
        mv "$HOME/$file" "$dest"
        ln -s "$dest" "$HOME/$file"
        echo "✓ Migrated $file"
    fi
}

# Migrate shell configs
migrate_dotfile .zshrc .config/shell/zshrc
migrate_dotfile .bashrc .config/shell/bashrc
migrate_dotfile .bash_profile .config/shell/bash_profile

# Migrate editor configs
migrate_dotfile .vimrc .config/editors/vimrc
migrate_dotfile .tmux.conf .config/tools/tmux.conf

echo "Migration complete. Run 'source ~/.zshrc' to reload."
```

## Benefits of This Structure

1. **Reduced Root Clutter**: Top-level directories reduced from 70+ to ~15
2. **Logical Grouping**: Related configurations stay together
3. **Bridge Integration**: Clear communication paths for multi-agent work
4. **TLA+ Verifiable**: Formal constraints prevent future sprawl
5. **Backward Compatible**: Symlinks maintain tool expectations

## Bridge Registry Integration

The TLA+ specification ensures:
- Maximum directory depth (prevents deeply nested structures)
- Top-level directory limits (prevents clutter)
- Bridge message consistency (all messages follow structure)
- Proper categorization (configs, projects, etc. stay organized)

This can be enforced through git hooks or filesystem watchers that check against the TLA+ constraints before allowing new top-level directories.
