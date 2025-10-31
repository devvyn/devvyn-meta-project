#!/usr/bin/env python3
"""
Temporal Worker for Adversarial Challenge Workflows

The worker connects to the Temporal server and executes workflows and activities.
Multiple workers can run in parallel for high availability and load distribution.

Usage:
    python -m workflows.worker
"""

import asyncio
import logging
import sys
from pathlib import Path

from temporalio.client import Client
from temporalio.worker import Worker

# Import workflows and activities
sys.path.append(str(Path(__file__).parent.parent))

from activities.pyrit_activities import (
    aggregate_challenge_results,
    initialize_pyrit_adapter,
    run_adversarial_turn,
    store_challenge_to_bridge,
)
from workflows.adversarial_challenge import AdversarialChallengeWorkflow

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

# Temporal configuration
TEMPORAL_HOST = "localhost:7233"
TASK_QUEUE = "adversarial-challenge-queue"


async def main():
    """Start Temporal worker"""
    logger.info("=" * 80)
    logger.info("Starting Temporal Worker for Adversarial Challenge Workflows")
    logger.info("=" * 80)
    logger.info(f"Temporal Server: {TEMPORAL_HOST}")
    logger.info(f"Task Queue: {TASK_QUEUE}")
    logger.info("")

    # Connect to Temporal server
    try:
        client = await Client.connect(TEMPORAL_HOST)
        logger.info("✅ Connected to Temporal server")
    except Exception as e:
        logger.error(f"❌ Failed to connect to Temporal server: {e}")
        logger.error("   Make sure Temporal dev server is running:")
        logger.error("   temporal server start-dev")
        return 1

    # Create worker
    worker = Worker(
        client,
        task_queue=TASK_QUEUE,
        workflows=[AdversarialChallengeWorkflow],
        activities=[
            initialize_pyrit_adapter,
            run_adversarial_turn,
            aggregate_challenge_results,
            store_challenge_to_bridge,
        ],
        # Worker configuration
        max_concurrent_workflow_tasks=5,  # Process up to 5 workflows concurrently
        max_concurrent_activities=10,  # Process up to 10 activities concurrently
    )

    logger.info("✅ Worker configured with:")
    logger.info("   - 1 workflow type (AdversarialChallengeWorkflow)")
    logger.info("   - 4 activity types")
    logger.info("   - Max concurrent workflows: 5")
    logger.info("   - Max concurrent activities: 10")
    logger.info("")
    logger.info("🚀 Worker ready! Waiting for workflows...")
    logger.info("   View in Temporal UI: http://localhost:8233")
    logger.info("")

    # Run worker (blocks until shutdown)
    try:
        await worker.run()
    except KeyboardInterrupt:
        logger.info("")
        logger.info("🛑 Shutdown signal received")
        logger.info("   Worker stopping gracefully...")
        return 0
    except Exception as e:
        logger.error(f"❌ Worker error: {e}", exc_info=True)
        return 1


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
