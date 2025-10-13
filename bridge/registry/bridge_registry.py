#!/usr/bin/env python3
"""
Bridge Registry System
Implements TLA+ constraint checking and message registration for the bridge system.
"""

import json
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from datetime import datetime, timedelta
from enum import Enum


class Priority(Enum):
    """Message priority levels"""
    CRITICAL = "CRITICAL"
    HIGH = "HIGH"
    NORMAL = "NORMAL"
    INFO = "INFO"


class MessageStatus(Enum):
    """Message status tracking"""
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    ARCHIVED = "archived"


class BridgeRegistry:
    """
    Registry system for bridge messages with TLA+ constraint enforcement.

    Enforces:
    - Maximum top-level directory count
    - Maximum directory depth
    - Maximum dotfiles at root
    - Bridge message consistency
    """

    def __init__(self, base_path: Optional[Path] = None):
        """
        Initialize the bridge registry.

        Args:
            base_path: Path to bridge directory. Defaults to ~/devvyn-meta-project/bridge
        """
        if base_path is None:
            base_path = Path.home() / "devvyn-meta-project" / "bridge"

        self.base = Path(base_path)
        self.registry_file = self.base / "registry" / "registry.json"
        self.registry = self._load_registry()

    def _load_registry(self) -> Dict:
        """Load registry from disk or initialize new one"""
        if self.registry_file.exists():
            try:
                return json.loads(self.registry_file.read_text())
            except json.JSONDecodeError:
                print(f"Warning: Could not parse {self.registry_file}, initializing new registry")
                return self._init_registry()
        return self._init_registry()

    def _init_registry(self) -> Dict:
        """Initialize a new registry with default values"""
        return {
            "version": "1.0.0",
            "paths": {
                "inbox": str(self.base / "inbox"),
                "outbox": str(self.base / "outbox"),
                "context": str(self.base / "context"),
                "archive": str(self.base / "archive"),
                "registry": str(self.base / "registry")
            },
            "constraints": {
                "max_top_level_dirs": 30,
                "max_depth": 10,
                "max_dotfiles_root": 10,
                "max_message_age_days": 90
            },
            "messages": [],
            "last_check": datetime.now().isoformat(),
            "last_cleanup": datetime.now().isoformat()
        }

    def _save_registry(self):
        """Save registry to disk"""
        self.registry_file.parent.mkdir(parents=True, exist_ok=True)
        self.registry_file.write_text(json.dumps(self.registry, indent=2))

    def check_path_constraints(self, path: Path) -> Tuple[bool, Optional[str]]:
        """
        Verify path meets hierarchy constraints from TLA+ spec.

        Args:
            path: Path to check

        Returns:
            Tuple of (is_valid, error_message)
        """
        # Check depth constraint
        depth = len(path.parts)
        max_depth = self.registry["constraints"]["max_depth"]
        if depth > max_depth:
            return False, f"Path depth {depth} exceeds maximum {max_depth}"

        # Check top-level directory count if this is a home-level path
        if len(path.parts) > 0 and path.parts[0] in ["Users", "home"]:
            if path.parent == Path.home():
                top_level_dirs = [d for d in Path.home().iterdir() if d.is_dir()]
                max_top_level = self.registry["constraints"]["max_top_level_dirs"]
                if len(top_level_dirs) >= max_top_level:
                    return False, f"Top-level directory count {len(top_level_dirs)} exceeds maximum {max_top_level}"

        # Check dotfile constraint at root
        if path.parent == Path.home() and path.name.startswith('.'):
            dotfiles = [f for f in Path.home().iterdir() if f.name.startswith('.')]
            max_dotfiles = self.registry["constraints"]["max_dotfiles_root"]
            if len(dotfiles) >= max_dotfiles:
                return False, f"Root dotfile count {len(dotfiles)} exceeds maximum {max_dotfiles}"

        return True, None

    def check_bridge_constraints(self, msg_path: Path) -> Tuple[bool, Optional[str]]:
        """
        Verify bridge message follows proper structure.

        Bridge messages must be in: bridge/{inbox|outbox|context|archive}/namespace/message.md

        Args:
            msg_path: Path to message file

        Returns:
            Tuple of (is_valid, error_message)
        """
        try:
            # Get relative path from bridge base
            rel_path = msg_path.relative_to(self.base)
            parts = rel_path.parts

            # Must have at least 2 parts: directory/message.md
            if len(parts) < 2:
                return False, f"Invalid bridge message path structure: {rel_path}"

            # First part must be valid bridge directory
            valid_dirs = {"inbox", "outbox", "context", "archive"}
            if parts[0] not in valid_dirs:
                return False, f"Message must be in {valid_dirs}, not '{parts[0]}'"

            # Message files should be markdown
            if not msg_path.suffix == '.md':
                return False, f"Message files must be .md format, not {msg_path.suffix}"

            return True, None

        except ValueError:
            return False, f"Path {msg_path} is not under bridge directory {self.base}"

    def register_message(self,
                        msg_type: str,
                        priority: Priority,
                        source: str,
                        target: str,
                        content: str,
                        path: Path) -> str:
        """
        Register a bridge message in the registry.

        Args:
            msg_type: Type of message (e.g., 'task', 'report', 'question')
            priority: Message priority level
            source: Source namespace (e.g., 'chat', 'code')
            target: Target namespace
            content: Message content summary
            path: Path to message file

        Returns:
            Message ID
        """
        # Validate path constraints
        path_valid, path_error = self.check_path_constraints(path)
        if not path_valid:
            raise ValueError(f"Path constraint violation: {path_error}")

        bridge_valid, bridge_error = self.check_bridge_constraints(path)
        if not bridge_valid:
            raise ValueError(f"Bridge constraint violation: {bridge_error}")

        # Create message record
        message_id = f"{datetime.now().isoformat()}-{source}-{target}"
        message = {
            "id": message_id,
            "type": msg_type,
            "priority": priority.value,
            "source": source,
            "target": target,
            "content_summary": content[:200],  # First 200 chars
            "path": str(path),
            "status": MessageStatus.PENDING.value,
            "created": datetime.now().isoformat(),
            "updated": datetime.now().isoformat()
        }

        self.registry["messages"].append(message)
        self.registry["last_check"] = datetime.now().isoformat()
        self._save_registry()

        return message_id

    def update_message_status(self, message_id: str, status: MessageStatus) -> bool:
        """
        Update the status of a message.

        Args:
            message_id: ID of message to update
            status: New status

        Returns:
            True if updated, False if not found
        """
        for msg in self.registry["messages"]:
            if msg["id"] == message_id:
                msg["status"] = status.value
                msg["updated"] = datetime.now().isoformat()
                self._save_registry()
                return True
        return False

    def get_pending_messages(self, target: Optional[str] = None) -> List[Dict]:
        """
        Get all pending messages, optionally filtered by target.

        Args:
            target: Target namespace to filter by (e.g., 'code')

        Returns:
            List of pending messages
        """
        messages = [
            msg for msg in self.registry["messages"]
            if msg["status"] == MessageStatus.PENDING.value
        ]

        if target:
            messages = [msg for msg in messages if msg["target"] == target]

        return sorted(messages, key=lambda m: m["created"])

    def cleanup_old_messages(self, dry_run: bool = False) -> List[str]:
        """
        Archive messages older than max_message_age_days.

        Args:
            dry_run: If True, return what would be archived without doing it

        Returns:
            List of archived message IDs
        """
        max_age = self.registry["constraints"]["max_message_age_days"]
        cutoff = datetime.now() - timedelta(days=max_age)

        archived_ids = []
        new_messages = []

        for msg in self.registry["messages"]:
            msg_date = datetime.fromisoformat(msg["created"])

            if msg_date < cutoff and msg["status"] == MessageStatus.COMPLETED.value:
                archived_ids.append(msg["id"])
                if not dry_run:
                    msg["status"] = MessageStatus.ARCHIVED.value
                    msg["updated"] = datetime.now().isoformat()

            new_messages.append(msg)

        if not dry_run:
            self.registry["messages"] = new_messages
            self.registry["last_cleanup"] = datetime.now().isoformat()
            self._save_registry()

        return archived_ids

    def get_stats(self) -> Dict:
        """Get registry statistics"""
        messages = self.registry["messages"]

        return {
            "total_messages": len(messages),
            "by_status": {
                status.value: len([m for m in messages if m["status"] == status.value])
                for status in MessageStatus
            },
            "by_priority": {
                priority.value: len([m for m in messages if m["priority"] == priority.value])
                for priority in Priority
            },
            "oldest_pending": min(
                (m["created"] for m in messages if m["status"] == MessageStatus.PENDING.value),
                default=None
            ),
            "last_check": self.registry["last_check"],
            "last_cleanup": self.registry["last_cleanup"]
        }


if __name__ == "__main__":
    # Example usage
    registry = BridgeRegistry()

    # Print current stats
    stats = registry.get_stats()
    print("Bridge Registry Statistics:")
    print(json.dumps(stats, indent=2))

    # Check pending messages
    pending = registry.get_pending_messages(target="code")
    if pending:
        print(f"\nFound {len(pending)} pending messages for 'code' namespace")
        for msg in pending:
            print(f"  - {msg['id']}: {msg['content_summary'][:50]}...")
