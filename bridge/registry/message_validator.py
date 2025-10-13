#!/usr/bin/env python3
"""
Message Validator
Integrates BridgeRegistry path validation with bridge messaging system.
"""

import json
import re
from pathlib import Path
from typing import Optional, Dict, List, Tuple
from datetime import datetime

from bridge_registry import BridgeRegistry, Priority, MessageStatus


class MessageValidator:
    """
    Validates and registers bridge messages with constraint checking.

    Use this when creating new bridge messages to ensure they comply with
    TLA+ hierarchy constraints.
    """

    def __init__(self, registry: Optional[BridgeRegistry] = None):
        """
        Initialize message validator.

        Args:
            registry: BridgeRegistry instance. Creates new one if not provided.
        """
        self.registry = registry or BridgeRegistry()
        self.bridge_base = self.registry.base

    def parse_message_header(self, content: str) -> Optional[Dict]:
        """
        Parse message header from markdown content.

        Expected format:
        **Message-ID**: ...
        **Queue-Number**: ...
        **From**: ...
        **To**: ...
        **Timestamp**: ...
        **Priority**: ... (optional, defaults to NORMAL)

        Args:
            content: Message content

        Returns:
            Dict with header fields or None if invalid
        """
        header = {}

        # Parse each field
        patterns = {
            'message_id': r'\*\*Message-ID\*\*:\s*(.+)',
            'queue_number': r'\*\*Queue-Number\*\*:\s*(\d+)',
            'from': r'\*\*From\*\*:\s*(\w+)',
            'to': r'\*\*To\*\*:\s*(\w+)',
            'timestamp': r'\*\*Timestamp\*\*:\s*(.+)',
            'priority': r'\*\*Priority\*\*:\s*(CRITICAL|HIGH|NORMAL|INFO)'
        }

        for field, pattern in patterns.items():
            match = re.search(pattern, content, re.MULTILINE)
            if match:
                header[field] = match.group(1).strip()
            elif field != 'priority':  # Priority is optional
                return None

        # Default priority if not specified
        if 'priority' not in header:
            header['priority'] = 'NORMAL'

        return header

    def validate_message_file(self, message_path: Path) -> Tuple[bool, Optional[str], Optional[Dict]]:
        """
        Validate a message file for proper format and constraints.

        Args:
            message_path: Path to message file

        Returns:
            Tuple of (is_valid, error_message, parsed_header)
        """
        # Check if file exists
        if not message_path.exists():
            return False, f"Message file does not exist: {message_path}", None

        # Check bridge constraints
        bridge_valid, bridge_error = self.registry.check_bridge_constraints(message_path)
        if not bridge_valid:
            return False, bridge_error, None

        # Check path constraints
        path_valid, path_error = self.registry.check_path_constraints(message_path)
        if not path_valid:
            return False, path_error, None

        # Parse message content
        try:
            content = message_path.read_text()
        except Exception as e:
            return False, f"Could not read message file: {e}", None

        # Parse header
        header = self.parse_message_header(content)
        if not header:
            return False, "Invalid or incomplete message header", None

        return True, None, header

    def register_message_from_file(self, message_path: Path) -> Tuple[bool, Optional[str]]:
        """
        Validate and register a message from a file.

        Args:
            message_path: Path to message file

        Returns:
            Tuple of (success, message_id_or_error)
        """
        # Validate message
        is_valid, error, header = self.validate_message_file(message_path)
        if not is_valid:
            return False, error

        # Extract content summary
        content = message_path.read_text()

        # Find content section (after header)
        content_match = re.search(r'## Content\s*\n(.+?)(?:\n##|\Z)', content, re.DOTALL)
        content_summary = content_match.group(1).strip() if content_match else "No content summary"

        # Register in registry
        try:
            priority = Priority[header['priority']]
            message_id = self.registry.register_message(
                msg_type="bridge_message",
                priority=priority,
                source=header['from'],
                target=header['to'],
                content=content_summary,
                path=message_path
            )
            return True, message_id
        except Exception as e:
            return False, f"Failed to register message: {e}"

    def create_message(self,
                      msg_from: str,
                      msg_to: str,
                      subject: str,
                      content: str,
                      priority: Priority = Priority.NORMAL,
                      queue_number: Optional[int] = None) -> Tuple[bool, str, Optional[Path]]:
        """
        Create a new bridge message with validation.

        Args:
            msg_from: Source namespace
            msg_to: Target namespace (code, chat, cursor, windsurf)
            subject: Message subject
            content: Message content
            priority: Message priority
            queue_number: Optional queue number

        Returns:
            Tuple of (success, message_or_error, path)
        """
        # Determine destination directory
        dest_dir = self.bridge_base / "inbox" / msg_to
        dest_dir.mkdir(parents=True, exist_ok=True)

        # Generate filename from subject
        safe_subject = re.sub(r'[^\w\s-]', '', subject).strip().lower()
        safe_subject = re.sub(r'[-\s]+', '-', safe_subject)
        timestamp = datetime.now().strftime("%Y-%m-%d")
        filename = f"{safe_subject}-{timestamp}.md"

        message_path = dest_dir / filename

        # Check if file already exists
        if message_path.exists():
            return False, f"Message file already exists: {message_path}", None

        # Validate path constraints before creating
        path_valid, path_error = self.registry.check_path_constraints(message_path)
        if not path_valid:
            return False, f"Path constraint violation: {path_error}", None

        bridge_valid, bridge_error = self.registry.check_bridge_constraints(message_path)
        if not bridge_valid:
            return False, f"Bridge constraint violation: {bridge_error}", None

        # Determine queue number if not provided
        if queue_number is None:
            existing_messages = list(dest_dir.glob("*.md"))
            queue_number = len(existing_messages) + 1

        # Create message content
        message_id = f"{datetime.now().isoformat()}-{msg_from}-{msg_to}"

        message_content = f"""# {subject}

**Message-ID**: {message_id}
**Queue-Number**: {queue_number:03d}
**From**: {msg_from}
**To**: {msg_to}
**Timestamp**: {datetime.now().isoformat()}
**Priority**: {priority.value}

## Content

{content}

---
"""

        # Write message file
        try:
            message_path.write_text(message_content)
        except Exception as e:
            return False, f"Failed to write message: {e}", None

        # Register in registry
        try:
            registered_id = self.registry.register_message(
                msg_type="bridge_message",
                priority=priority,
                source=msg_from,
                target=msg_to,
                content=content,
                path=message_path
            )
            return True, registered_id, message_path
        except Exception as e:
            # Clean up file if registration fails
            message_path.unlink()
            return False, f"Failed to register: {e}", None

    def scan_inbox(self, target: str = "code") -> List[Dict]:
        """
        Scan inbox directory and validate/register any unregistered messages.

        Args:
            target: Target namespace to scan

        Returns:
            List of messages with their validation status
        """
        inbox_dir = self.bridge_base / "inbox" / target
        if not inbox_dir.exists():
            return []

        results = []

        for msg_file in inbox_dir.glob("*.md"):
            # Skip example files
            if msg_file.name.startswith("_"):
                continue

            is_valid, error, header = self.validate_message_file(msg_file)

            result = {
                "path": str(msg_file),
                "filename": msg_file.name,
                "valid": is_valid,
                "error": error,
                "header": header
            }

            # Try to register if valid and not already registered
            if is_valid and header:
                # Check if already in registry
                existing = [
                    m for m in self.registry.registry["messages"]
                    if m["path"] == str(msg_file)
                ]

                if not existing:
                    success, msg_id = self.register_message_from_file(msg_file)
                    result["registered"] = success
                    result["message_id"] = msg_id if success else None
                else:
                    result["registered"] = True
                    result["message_id"] = existing[0]["id"]

            results.append(result)

        return results


if __name__ == "__main__":
    # Example: Scan and validate inbox
    validator = MessageValidator()

    print("Scanning bridge inbox for code namespace...")
    results = validator.scan_inbox("code")

    print(f"\nFound {len(results)} messages:")
    for r in results:
        status = "✓" if r["valid"] else "✗"
        print(f"{status} {r['filename']}")
        if not r["valid"]:
            print(f"  Error: {r['error']}")
        elif "registered" in r:
            reg_status = "registered" if r["registered"] else "failed to register"
            print(f"  Status: {reg_status}")

    # Show registry stats
    print("\n" + "="*50)
    stats = validator.registry.get_stats()
    print("Registry Statistics:")
    print(json.dumps(stats, indent=2))
