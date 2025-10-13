#!/usr/bin/env python3
"""
RED TEAM Inbox Processor - LaunchAgent entry point

Monitors bridge/inbox/redteam/ and processes adversarial review requests
"""

import asyncio
import json
import logging
import sys
from dataclasses import asdict
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root / "agents" / "redteam"))
pyrit_path = (
    project_root
    / "kitchen"
    / "active-experiments"
    / "pyrit-adversarial-orchestration"
    / "bridge-adapter"
)
sys.path.insert(0, str(pyrit_path))

from pyrit_bridge_adapter import PyRITBridgeAdapter  # noqa: E402
from pyrit_production_adapter import PyRITProductionAdapter  # noqa: E402

# Configure logging
log_file = project_root / "logs" / "redteam.log"
log_file.parent.mkdir(exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[logging.FileHandler(log_file), logging.StreamHandler()],
)
logger = logging.getLogger(__name__)


async def process_inbox() -> None:
    """Process all messages in RED TEAM inbox"""
    try:
        # Initialize adapter
        bridge_path = Path("~/infrastructure/agent-bridge/bridge").expanduser()
        adapter = PyRITProductionAdapter(
            bridge_root=bridge_path,
            fallback_on_error=True,
            max_retries=3,
        )

        inbox_path = adapter.inbox

        # Get all unprocessed messages
        messages = list(inbox_path.glob("*.md"))

        if not messages:
            logger.info("No messages in inbox")
            return

        logger.info("Processing %d message(s)", len(messages))

        for msg_file in messages:
            try:
                logger.info("Processing: %s", msg_file.name)

                # Parse message
                parser = PyRITBridgeAdapter(adapter.bridge_root, adapter.agent_name)
                msg = parser.parse_bridge_message(msg_file)

                # Run adversarial challenge with retry
                challenge = await adapter.run_adversarial_challenge_with_retry(
                    proposal=msg.content,
                    strategy="crescendo",
                    max_turns=5,
                )

                # Format response
                response_content = parser.format_challenge_as_bridge_message(
                    challenge, msg
                )

                # Save to outbox
                response_file = adapter.outbox / f"{challenge.challenge_id}.md"
                response_file.write_text(response_content)

                # Save detailed results
                results_file = adapter.results_dir / f"{challenge.challenge_id}.json"
                results_file.write_text(json.dumps(asdict(challenge), indent=2))

                # Archive processed message
                archive_dir = adapter.bridge_root / "archive" / adapter.agent_name
                archive_dir.mkdir(parents=True, exist_ok=True)
                msg_file.rename(archive_dir / msg_file.name)

                logger.info("✓ Processed: %s", msg_file.name)
                logger.info("  Challenge ID: %s", challenge.challenge_id)
                logger.info(
                    "  Vulnerabilities: %d",
                    len(challenge.vulnerabilities_found),
                )
                logger.info("  Risk Score: %.2f", challenge.overall_score)

            except Exception:
                logger.exception("Failed to process %s", msg_file.name)
                # Don't archive failed messages - retry on next run

    except Exception:
        logger.exception("Inbox processing failed")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(process_inbox())
