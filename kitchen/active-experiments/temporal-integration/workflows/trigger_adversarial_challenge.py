#!/usr/bin/env python3
"""
Trigger script for Adversarial Challenge Workflow

Usage:
    python -m workflows.trigger_adversarial_challenge [proposal_file]
    python -m workflows.trigger_adversarial_challenge --proposal "inline proposal text"
"""

import asyncio
import logging
import sys
from pathlib import Path

from temporalio.client import Client

sys.path.append(str(Path(__file__).parent.parent))

from workflows.adversarial_challenge import (
    AdversarialChallengeInput,
    AdversarialChallengeResult,
)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

TEMPORAL_HOST = "localhost:7233"
TASK_QUEUE = "adversarial-challenge-queue"


async def trigger_challenge(
    proposal: str,
    strategy: str = "crescendo",
    max_turns: int = 3,
    source_agent: str = "code",
) -> AdversarialChallengeResult:
    """
    Trigger an adversarial challenge workflow

    Args:
        proposal: The proposal text to challenge
        strategy: Attack strategy (crescendo or redteaming)
        max_turns: Number of adversarial turns
        source_agent: Agent requesting the challenge

    Returns:
        Challenge result with event information
    """
    logger.info("=" * 80)
    logger.info("Triggering Adversarial Challenge Workflow")
    logger.info("=" * 80)
    logger.info(f"Proposal length: {len(proposal)} characters")
    logger.info(f"Strategy: {strategy}")
    logger.info(f"Max turns: {max_turns}")
    logger.info(f"Source agent: {source_agent}")
    logger.info("")

    # Connect to Temporal
    client = await Client.connect(TEMPORAL_HOST)
    logger.info(f"✅ Connected to Temporal: {TEMPORAL_HOST}")

    # Create workflow input
    workflow_input = AdversarialChallengeInput(
        proposal=proposal,
        strategy=strategy,
        max_turns=max_turns,
        source_agent=source_agent,
        timeout_per_turn=300,  # 5 minutes per turn
    )

    # Start workflow
    workflow_id = (
        f"adversarial-challenge-{source_agent}-{asyncio.get_event_loop().time()}"
    )

    logger.info(f"🚀 Starting workflow: {workflow_id}")
    logger.info(f"   Task queue: {TASK_QUEUE}")
    logger.info(
        f"   View in UI: http://localhost:8233/namespaces/default/workflows/{workflow_id}"
    )
    logger.info("")

    # Execute workflow (blocks until complete)
    handle = await client.start_workflow(
        "AdversarialChallengeWorkflow",
        workflow_input,
        id=workflow_id,
        task_queue=TASK_QUEUE,
    )

    logger.info("⏳ Workflow started. Waiting for completion...")
    logger.info("   (You can view progress in Temporal UI)")
    logger.info("")

    # Wait for result
    result: AdversarialChallengeResult = await handle.result()

    logger.info("=" * 80)
    logger.info("WORKFLOW COMPLETE")
    logger.info("=" * 80)
    logger.info(f"Challenge ID: {result.challenge_id}")
    logger.info(f"Event ID: {result.event_id}")
    logger.info(f"Event Path: {result.event_path}")
    logger.info(f"Vulnerabilities: {result.vulnerabilities_count}")
    logger.info(f"Risk Score: {result.risk_score:.2f}/1.0")
    logger.info(f"Turns: {result.turns_executed}")
    logger.info(f"Duration: {result.total_duration_seconds:.1f}s")
    logger.info(f"Fallback Used: {'Yes' if result.fallback_used else 'No'}")
    logger.info("")
    logger.info(f"📄 View event: cat {result.event_path}")
    logger.info("")

    return result


async def main():
    """Main entry point"""
    import argparse

    parser = argparse.ArgumentParser(
        description="Trigger adversarial challenge workflow"
    )
    parser.add_argument(
        "proposal_file",
        nargs="?",
        help="Path to file containing proposal (or use --proposal)",
    )
    parser.add_argument(
        "--proposal",
        help="Inline proposal text",
    )
    parser.add_argument(
        "--strategy",
        default="crescendo",
        choices=["crescendo", "redteaming"],
        help="Attack strategy",
    )
    parser.add_argument(
        "--max-turns",
        type=int,
        default=3,
        help="Maximum adversarial turns (default: 3)",
    )
    parser.add_argument(
        "--source-agent",
        default="code",
        help="Source agent name (default: code)",
    )

    args = parser.parse_args()

    # Get proposal text
    if args.proposal:
        proposal = args.proposal
    elif args.proposal_file:
        proposal_path = Path(args.proposal_file)
        if not proposal_path.exists():
            logger.error(f"❌ File not found: {args.proposal_file}")
            return 1
        proposal = proposal_path.read_text()
    else:
        # Use demo proposal
        proposal = """
Implement automated pattern extraction from event log:
- Monitor bridge/events/ for new events
- Use ML clustering (K-means, DBSCAN) to identify patterns
- Auto-add patterns with >80% confidence to decision-patterns.md
- Integration with INVESTIGATOR and HOPPER agents for pattern validation
- Weekly digest generation with pattern summary
        """.strip()
        logger.info("ℹ️  Using demo proposal (no file specified)")
        logger.info("")

    try:
        result = await trigger_challenge(
            proposal=proposal,
            strategy=args.strategy,
            max_turns=args.max_turns,
            source_agent=args.source_agent,
        )
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
