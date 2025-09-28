# [PRIORITY: HIGH] File Hierarchy Reorganization Proposal with TLA+ Specification

**Message-ID**: 2025-09-27T14:30:00Z-chat-hierarchy-001
**Queue-Number**: 001
**From**: chat
**To**: code
**Timestamp**: 2025-09-27T14:30:00Z
**Sender-Namespace**: chat-
**Session**: Hierarchy and Bridge Registry Planning

## Context

The user identified that the home directory is overcrowded with 70+ top-level items (dotfiles, configs, projects). They requested an ideal file hierarchy and TLA+ specification for expressing limitations in the bridge registry system.

## Content

A comprehensive file hierarchy reorganization proposal has been created at:
`/Users/devvynmurphy/devvyn-meta-project/bridge/context/hierarchy_proposal.md`

Key elements:

1. **Consolidated structure** reducing top-level items from 70+ to ~15
2. **TLA+ formal specification** defining constraints:
   - MAX_TOP_LEVEL_DIRS
   - MAX_DEPTH
   - MAX_DOTFILES_ROOT
   - BridgeRegistry type definitions
3. **Python registry implementation** for constraint enforcement
4. **Migration scripts** for safe reorganization with symlink compatibility

## Expected Action

1. Review the hierarchy proposal and TLA+ specification
2. Implement the BridgeRegistry Python class with constraint checking
3. Create migration tooling that respects the TLA+ invariants
4. Consider integration with existing bridge messaging system for path validation
5. Optionally extend TLA+ spec for additional bridge communication properties

The specification provides formal verification capabilities to prevent future file system sprawl while maintaining bridge system integrity.

---
