#!/usr/bin/env python3
"""
Knowledge Digest Workflow - Temporal Integration

Automated knowledge extraction and digest generation workflow.

Key features:
- Runs continuously (long-lived workflow)
- Scheduled digest generation (weekly)
- Conditional execution (trigger on event threshold)
- Human-in-the-loop via signals
- Survives process restarts
"""

from dataclasses import dataclass
from datetime import timedelta
from typing import Any

from temporalio import workflow

# Import activities
with workflow.unsafe.imports_passed_through():
    from activities.knowledge_activities import (
        check_event_log_for_new_events,
        extract_patterns_from_events,
        generate_knowledge_digest,
        update_collective_memory,
    )


@dataclass
class DigestWorkflowConfig:
    """Configuration for digest workflow"""

    schedule_interval_days: int = 7  # Weekly digests
    event_threshold: int = 10  # Generate digest if this many new events
    lookback_hours: int = 168  # 7 days
    auto_update_memory: bool = True


@dataclass
class DigestResult:
    """Result of digest generation"""

    digest_id: str
    digest_path: str
    patterns_count: int
    events_analyzed: int
    memory_updated: bool
    generated_at: str


@workflow.defn(name="KnowledgeDigestWorkflow")
class KnowledgeDigestWorkflow:
    """
    Continuous workflow for automated knowledge digest generation

    This workflow runs indefinitely, generating digests on schedule or
    when triggered by conditions (event threshold, manual signal).

    Benefits over LaunchAgent:
    1. **Visual monitoring**: See workflow state in Temporal UI
    2. **Durable scheduling**: Survives system restarts
    3. **Human signals**: Pause, resume, force-generate via UI
    4. **Condition monitoring**: React to event thresholds
    5. **Complete history**: Every digest tracked
    """

    def __init__(self) -> None:
        self.config = DigestWorkflowConfig()
        self.last_digest_time = workflow.now()
        self.manual_trigger = False

    @workflow.run
    async def run(self, config: DigestWorkflowConfig | None = None) -> None:
        """
        Run continuous digest generation workflow

        This workflow never completes - it runs until explicitly stopped.
        Use signals to control behavior (pause, force-generate, etc.).
        """

        if config:
            self.config = config

        workflow.logger.info(
            f"Starting knowledge digest workflow "
            f"(schedule: every {self.config.schedule_interval_days} days)"
        )

        digest_count = 0

        # Continuous loop
        while True:
            # Calculate next scheduled digest time
            next_digest_time = self.last_digest_time + timedelta(
                days=self.config.schedule_interval_days
            )

            # Wait for condition: scheduled time OR event threshold OR manual trigger
            await workflow.wait_condition(
                lambda: (workflow.now() >= next_digest_time or self.manual_trigger),
                timeout=timedelta(hours=1),  # Check every hour
            )

            # Check if we should generate digest
            should_generate = False
            trigger_reason = ""

            if workflow.now() >= next_digest_time:
                should_generate = True
                trigger_reason = "scheduled"
            elif self.manual_trigger:
                should_generate = True
                trigger_reason = "manual_trigger"
                self.manual_trigger = False  # Reset flag

            if should_generate:
                workflow.logger.info(
                    f"Generating digest #{digest_count + 1} (trigger: {trigger_reason})"
                )

                try:
                    # Generate digest
                    result = await self._generate_digest()

                    digest_count += 1
                    self.last_digest_time = workflow.now()

                    workflow.logger.info(
                        f"Digest #{digest_count} complete: {result.digest_id} "
                        f"({result.patterns_count} patterns, {result.events_analyzed} events)"
                    )

                except Exception as e:
                    workflow.logger.error(f"Digest generation failed: {e}")
                    # Continue loop - don't crash workflow

    async def _generate_digest(self) -> DigestResult:
        """Generate a single digest (internal helper)"""

        # Step 1: Check for new events
        workflow.logger.info("Checking for new events...")

        events_data = await workflow.execute_activity(
            check_event_log_for_new_events,
            args=[self.config.lookback_hours],
            start_to_close_timeout=timedelta(seconds=30),
        )

        workflow.logger.info(
            f"Found {events_data['event_count']} events "
            f"(threshold: {self.config.event_threshold})"
        )

        # If no new events and not scheduled time, skip
        if not events_data["has_new_events"]:
            workflow.logger.info("No new events, skipping digest generation")
            return DigestResult(
                digest_id="skipped",
                digest_path="",
                patterns_count=0,
                events_analyzed=0,
                memory_updated=False,
                generated_at=workflow.now().isoformat(),
            )

        # Step 2: Extract patterns from events
        workflow.logger.info("Extracting patterns...")

        patterns_data = await workflow.execute_activity(
            extract_patterns_from_events,
            args=[events_data["events"]],
            start_to_close_timeout=timedelta(minutes=5),
            retry_policy=workflow.RetryPolicy(
                initial_interval=timedelta(seconds=5),
                maximum_interval=timedelta(seconds=30),
                maximum_attempts=3,
            ),
        )

        workflow.logger.info(f"Extracted {patterns_data['pattern_count']} patterns")

        # Step 3: Generate digest
        workflow.logger.info("Generating digest document...")

        digest_data = await workflow.execute_activity(
            generate_knowledge_digest,
            args=[events_data, patterns_data],
            start_to_close_timeout=timedelta(minutes=2),
            retry_policy=workflow.RetryPolicy(
                initial_interval=timedelta(seconds=2),
                maximum_interval=timedelta(seconds=10),
                maximum_attempts=5,  # Critical - ensure digest is created
            ),
        )

        workflow.logger.info(f"Digest generated: {digest_data['digest_path']}")

        # Step 4: Update collective memory (if configured)
        memory_updated = False

        if self.config.auto_update_memory:
            workflow.logger.info("Updating collective memory...")

            memory_result = await workflow.execute_activity(
                update_collective_memory,
                args=[digest_data, patterns_data],
                start_to_close_timeout=timedelta(seconds=30),
            )

            memory_updated = memory_result["updated"]
            workflow.logger.info(f"Memory updated: {memory_updated}")

        return DigestResult(
            digest_id=digest_data["digest_id"],
            digest_path=digest_data["digest_path"],
            patterns_count=patterns_data["pattern_count"],
            events_analyzed=events_data["event_count"],
            memory_updated=memory_updated,
            generated_at=digest_data["generated_at"],
        )

    @workflow.signal
    def force_generate(self) -> None:
        """Signal: Force digest generation immediately"""
        workflow.logger.info("Signal received: force_generate")
        self.manual_trigger = True

    @workflow.signal
    def update_config(self, config: DigestWorkflowConfig) -> None:
        """Signal: Update workflow configuration"""
        workflow.logger.info("Signal received: update_config")
        self.config = config

    @workflow.query
    def get_status(self) -> dict[str, Any]:
        """Query: Get current workflow status"""
        return {
            "last_digest": self.last_digest_time.isoformat(),
            "next_digest": (
                self.last_digest_time
                + timedelta(days=self.config.schedule_interval_days)
            ).isoformat(),
            "schedule_days": self.config.schedule_interval_days,
            "event_threshold": self.config.event_threshold,
            "auto_update_memory": self.config.auto_update_memory,
        }
