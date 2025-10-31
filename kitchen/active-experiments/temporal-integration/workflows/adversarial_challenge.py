#!/usr/bin/env python3
"""
Adversarial Challenge Workflow - Temporal Integration

This workflow orchestrates multi-turn PyRIT adversarial testing with:
- Durable execution (survives process restarts)
- Per-turn retry logic and timeout management
- State checkpointing between turns
- Visual debugging in Temporal UI

Key difference from direct execution:
- Each turn is a separate activity (can fail/retry independently)
- Workflow state persisted automatically
- Can pause/resume mid-challenge
- Full execution history available for debugging
"""

from dataclasses import dataclass
from datetime import timedelta

from temporalio import workflow

# Import activity definitions
with workflow.unsafe.imports_passed_through():
    from activities.pyrit_activities import (
        aggregate_challenge_results,
        initialize_pyrit_adapter,
        run_adversarial_turn,
        store_challenge_to_bridge,
    )


@dataclass
class AdversarialChallengeInput:
    """Input parameters for adversarial challenge workflow"""

    proposal: str
    strategy: str = "crescendo"  # crescendo or redteaming
    max_turns: int = 5
    source_agent: str = "chat"  # Agent that requested challenge
    timeout_per_turn: int = 300  # 5 minutes per turn


@dataclass
class AdversarialChallengeResult:
    """Result of adversarial challenge workflow"""

    challenge_id: str
    event_id: str
    event_path: str
    vulnerabilities_count: int
    risk_score: float
    turns_executed: int
    fallback_used: bool
    total_duration_seconds: float


@workflow.defn(name="AdversarialChallengeWorkflow")
class AdversarialChallengeWorkflow:
    """
    Temporal workflow for durable multi-turn adversarial testing

    Benefits over direct execution:
    1. **State preservation**: Workflow state checkpointed after each turn
    2. **Process resilience**: Survives worker crashes/restarts
    3. **Turn isolation**: Each turn can fail/retry independently
    4. **Observability**: Full execution history in Temporal UI
    5. **Timeout management**: Per-turn and overall timeouts
    """

    @workflow.run
    async def run(self, input: AdversarialChallengeInput) -> AdversarialChallengeResult:
        """
        Execute multi-turn adversarial challenge workflow

        Workflow steps:
        1. Initialize PyRIT adapter and verify API access
        2. Execute N turns of adversarial testing (each as separate activity)
        3. Aggregate results from all turns
        4. Store challenge to bridge event log
        5. Return summary result

        Each step is durable - if worker crashes, workflow resumes from last checkpoint.
        """

        workflow.logger.info(
            f"Starting adversarial challenge: strategy={input.strategy}, "
            f"max_turns={input.max_turns}, source={input.source_agent}"
        )

        # Track workflow start time
        start_time = workflow.now()

        # Step 1: Initialize adapter (verify API connectivity)
        adapter_status = await workflow.execute_activity(
            initialize_pyrit_adapter,
            start_to_close_timeout=timedelta(seconds=30),
            retry_policy=workflow.RetryPolicy(
                initial_interval=timedelta(seconds=1),
                maximum_interval=timedelta(seconds=10),
                maximum_attempts=3,
            ),
        )

        workflow.logger.info(
            f"Adapter initialized: openai={adapter_status['has_openai']}, "
            f"azure={adapter_status['has_azure']}"
        )

        # Step 2: Execute turns (each turn is a separate activity)
        turns_results = []

        for turn_number in range(1, input.max_turns + 1):
            workflow.logger.info(f"Executing turn {turn_number}/{input.max_turns}...")

            # Execute turn as activity (can fail/retry independently)
            turn_result = await workflow.execute_activity(
                run_adversarial_turn,
                args=[
                    input.proposal,
                    input.strategy,
                    turn_number,
                    input.max_turns,
                ],
                start_to_close_timeout=timedelta(seconds=input.timeout_per_turn),
                retry_policy=workflow.RetryPolicy(
                    initial_interval=timedelta(seconds=5),
                    maximum_interval=timedelta(seconds=30),
                    maximum_attempts=3,
                ),
            )

            turns_results.append(turn_result)

            workflow.logger.info(
                f"Turn {turn_number} complete: "
                f"{len(turn_result['vulnerabilities'])} vulnerabilities found"
            )

            # State automatically checkpointed here
            # If worker crashes, workflow resumes from next turn

        # Step 3: Aggregate results from all turns
        workflow.logger.info("Aggregating results from all turns...")

        challenge = await workflow.execute_activity(
            aggregate_challenge_results,
            args=[input.proposal, input.strategy, turns_results],
            start_to_close_timeout=timedelta(seconds=60),
        )

        workflow.logger.info(
            f"Challenge complete: {len(challenge.vulnerabilities_found)} total vulnerabilities, "
            f"risk_score={challenge.overall_score:.2f}"
        )

        # Step 4: Store challenge to bridge event log
        workflow.logger.info("Storing challenge to bridge event log...")

        event_info = await workflow.execute_activity(
            store_challenge_to_bridge,
            args=[challenge, input.source_agent],
            start_to_close_timeout=timedelta(seconds=30),
            retry_policy=workflow.RetryPolicy(
                initial_interval=timedelta(seconds=2),
                maximum_interval=timedelta(seconds=10),
                maximum_attempts=5,  # Critical - ensure event is stored
            ),
        )

        # Calculate total duration
        end_time = workflow.now()
        duration_seconds = (end_time - start_time).total_seconds()

        workflow.logger.info(
            f"Workflow complete in {duration_seconds:.1f}s: "
            f"event_id={event_info['event_id']}"
        )

        # Return summary result
        return AdversarialChallengeResult(
            challenge_id=challenge.challenge_id,
            event_id=event_info["event_id"],
            event_path=event_info["event_path"],
            vulnerabilities_count=len(challenge.vulnerabilities_found),
            risk_score=challenge.overall_score,
            turns_executed=len(turns_results),
            fallback_used=challenge.fallback_used,
            total_duration_seconds=duration_seconds,
        )
