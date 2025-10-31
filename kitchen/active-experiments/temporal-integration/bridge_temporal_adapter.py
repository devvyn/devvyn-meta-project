#!/usr/bin/env python3
"""
Bridge-to-Temporal Adapter

Integrates Temporal workflows with the existing bridge communication system.
Bridge messages can trigger Temporal workflows without changing the bridge protocol.

Architecture:
    Bridge Message → Adapter → Temporal Workflow → Event Log → Bridge

Usage:
    # As a bridge message processor (LaunchAgent integration)
    python bridge_temporal_adapter.py process-inbox

    # Trigger from bridge message file
    python bridge_temporal_adapter.py trigger-from-message /path/to/message.md
"""

import asyncio
import logging
import re
import sys
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

from temporalio.client import Client

sys.path.append(str(Path(__file__).parent))

from workflows.adversarial_challenge import (
    AdversarialChallengeInput,
    AdversarialChallengeResult,
)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

TEMPORAL_HOST = "localhost:7233"
TASK_QUEUE = "adversarial-challenge-queue"
BRIDGE_ROOT = Path("~/infrastructure/agent-bridge/bridge").expanduser()


class BridgeTemporalAdapter:
    """Adapter between bridge communication system and Temporal workflows"""

    def __init__(
        self,
        bridge_root: Path = BRIDGE_ROOT,
        temporal_host: str = TEMPORAL_HOST,
        task_queue: str = TASK_QUEUE,
    ):
        self.bridge_root = bridge_root
        self.temporal_host = temporal_host
        self.task_queue = task_queue
        self.redteam_inbox = bridge_root / "inbox" / "redteam"
        self.client: Client | None = None

    async def connect(self) -> None:
        """Connect to Temporal server"""
        if self.client is None:
            self.client = await Client.connect(self.temporal_host)
            logger.info(f"✅ Connected to Temporal: {self.temporal_host}")

    async def parse_bridge_message(self, message_path: Path) -> dict[str, Any]:
        """
        Parse bridge message from markdown file

        Returns:
            Dictionary with message metadata and content
        """
        content = message_path.read_text()

        # Extract metadata using regex
        priority_match = re.search(r"^\[PRIORITY:\s*(\w+)\]", content, re.MULTILINE)
        from_match = re.search(r"^\*\*From\*\*:\s*(.+)$", content, re.MULTILINE)
        to_match = re.search(r"^\*\*To\*\*:\s*(.+)$", content, re.MULTILINE)

        # Extract proposal (content section)
        content_section = re.search(
            r"##\s*Content\s*\n(.+?)(?=\n##|\Z)", content, re.DOTALL | re.MULTILINE
        )
        proposal = content_section.group(1).strip() if content_section else content

        return {
            "message_path": str(message_path),
            "priority": priority_match.group(1) if priority_match else "NORMAL",
            "from_agent": from_match.group(1).strip() if from_match else "unknown",
            "to_agent": to_match.group(1).strip() if to_match else "redteam",
            "proposal": proposal,
        }

    async def trigger_adversarial_workflow(
        self,
        proposal: str,
        source_agent: str,
        strategy: str = "crescendo",
        max_turns: int = 3,
    ) -> AdversarialChallengeResult:
        """
        Trigger adversarial challenge workflow from bridge message

        Args:
            proposal: Proposal text to challenge
            source_agent: Agent that sent the message
            strategy: Attack strategy
            max_turns: Number of turns

        Returns:
            Workflow result
        """
        await self.connect()

        if self.client is None:
            raise RuntimeError("Not connected to Temporal")

        # Create workflow input
        workflow_input = AdversarialChallengeInput(
            proposal=proposal,
            strategy=strategy,
            max_turns=max_turns,
            source_agent=source_agent,
            timeout_per_turn=300,
        )

        # Generate workflow ID
        timestamp = datetime.now(UTC).strftime("%Y%m%d%H%M%S")
        workflow_id = f"adversarial-challenge-{source_agent}-{timestamp}"

        logger.info(f"🚀 Starting workflow: {workflow_id}")
        logger.info(f"   Source: {source_agent}")
        logger.info(f"   Strategy: {strategy}")
        logger.info(f"   Max turns: {max_turns}")
        logger.info(
            f"   UI: http://localhost:8233/namespaces/default/workflows/{workflow_id}"
        )

        # Start workflow
        handle = await self.client.start_workflow(
            "AdversarialChallengeWorkflow",
            workflow_input,
            id=workflow_id,
            task_queue=self.task_queue,
        )

        # Wait for result
        logger.info("⏳ Waiting for workflow completion...")
        result: AdversarialChallengeResult = await handle.result()

        logger.info(f"✅ Workflow complete: {result.challenge_id}")
        logger.info(f"   Vulnerabilities: {result.vulnerabilities_count}")
        logger.info(f"   Risk score: {result.risk_score:.2f}/1.0")
        logger.info(f"   Event: {result.event_path}")

        return result

    async def process_inbox_message(self, message_path: Path) -> None:
        """
        Process a single bridge message and trigger workflow

        Args:
            message_path: Path to bridge message file
        """
        logger.info(f"📥 Processing bridge message: {message_path.name}")

        # Parse message
        message = await self.parse_bridge_message(message_path)

        logger.info(f"   From: {message['from_agent']}")
        logger.info(f"   Priority: {message['priority']}")
        logger.info(f"   Proposal length: {len(message['proposal'])} characters")

        # Trigger workflow
        result = await self.trigger_adversarial_workflow(
            proposal=message["proposal"],
            source_agent=message["from_agent"],
            strategy="crescendo",  # Could parse from message
            max_turns=3,  # Could parse from message or use priority mapping
        )

        # Archive processed message
        archive_dir = self.bridge_root / "archive" / "redteam-processed"
        archive_dir.mkdir(parents=True, exist_ok=True)
        archive_path = archive_dir / message_path.name

        message_path.rename(archive_path)
        logger.info(f"📦 Archived message to: {archive_path}")

        # Optionally send response back via bridge
        # (For now, results are in event log which bridge monitors)

    async def process_inbox(self) -> int:
        """
        Process all messages in RED TEAM inbox

        Returns:
            Number of messages processed
        """
        logger.info("=" * 80)
        logger.info("Bridge-to-Temporal Adapter - Inbox Processor")
        logger.info("=" * 80)
        logger.info(f"Bridge root: {self.bridge_root}")
        logger.info(f"RED TEAM inbox: {self.redteam_inbox}")
        logger.info("")

        # Ensure inbox exists
        if not self.redteam_inbox.exists():
            logger.warning(f"⚠️  Inbox not found: {self.redteam_inbox}")
            logger.info("   Creating inbox directory...")
            self.redteam_inbox.mkdir(parents=True, exist_ok=True)
            return 0

        # Find messages
        messages = sorted(self.redteam_inbox.glob("*.md"))

        if not messages:
            logger.info("ℹ️  No messages in inbox")
            return 0

        logger.info(f"📬 Found {len(messages)} message(s)")
        logger.info("")

        # Process each message
        processed = 0
        for message_path in messages:
            try:
                await self.process_inbox_message(message_path)
                processed += 1
                logger.info("")
            except Exception as e:
                logger.error(
                    f"❌ Error processing {message_path.name}: {e}", exc_info=True
                )
                # Move to error directory
                error_dir = self.bridge_root / "archive" / "redteam-errors"
                error_dir.mkdir(parents=True, exist_ok=True)
                message_path.rename(error_dir / message_path.name)

        logger.info(f"✅ Processed {processed}/{len(messages)} messages")
        return processed


async def main():
    """CLI entry point"""
    import argparse

    parser = argparse.ArgumentParser(description="Bridge-to-Temporal adapter")
    parser.add_argument(
        "command",
        choices=["process-inbox", "trigger-from-message"],
        help="Command to execute",
    )
    parser.add_argument(
        "message_file",
        nargs="?",
        help="Message file (for trigger-from-message)",
    )

    args = parser.parse_args()

    adapter = BridgeTemporalAdapter()

    try:
        if args.command == "process-inbox":
            await adapter.process_inbox()
            return 0

        if args.command == "trigger-from-message":
            if not args.message_file:
                logger.error("❌ message_file required for trigger-from-message")
                return 1

            message_path = Path(args.message_file)
            if not message_path.exists():
                logger.error(f"❌ File not found: {args.message_file}")
                return 1

            await adapter.process_inbox_message(message_path)
            return 0

    except KeyboardInterrupt:
        logger.info("")
        logger.info("🛑 Interrupted by user")
        return 130
    except Exception as e:
        logger.error(f"❌ Error: {e}", exc_info=True)
        return 1


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
