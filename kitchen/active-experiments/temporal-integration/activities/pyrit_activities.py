#!/usr/bin/env python3
"""
Temporal Activities for PyRIT Integration

Activities are individual units of work that can be retried, timed out, and monitored.
Each activity wraps a PyRIT operation for durable execution within Temporal workflows.
"""

import logging

# Import from existing PyRIT adapter
import sys
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

sys.path.append(str(Path("~/devvyn-meta-project/agents/redteam").expanduser()))

from pyrit_production_adapter import (
    AdversarialChallenge,
    PyRITProductionAdapter,
)
from temporalio import activity

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@activity.defn(name="initialize_pyrit_adapter")
async def initialize_pyrit_adapter() -> dict[str, Any]:
    """
    Initialize PyRIT adapter and verify API connectivity

    Returns:
        Status information about adapter initialization
    """
    activity.logger.info("Initializing PyRIT production adapter...")

    bridge_root = Path("~/infrastructure/agent-bridge/bridge").expanduser()
    adapter = PyRITProductionAdapter(
        bridge_root=bridge_root,
        fallback_on_error=True,
        max_retries=3,
        retry_delay=5.0,
    )

    return {
        "initialized": True,
        "has_openai": adapter.has_openai,
        "has_azure": adapter.has_azure,
        "fallback_enabled": adapter.fallback_on_error,
        "timestamp": datetime.now(UTC).isoformat(),
    }


@activity.defn(name="run_adversarial_turn")
async def run_adversarial_turn(
    proposal: str,
    strategy: str,
    turn_number: int,
    max_turns: int,
) -> dict[str, Any]:
    """
    Execute a single turn of adversarial testing

    This activity can be retried independently if it fails, providing
    granular error recovery at the turn level.

    Args:
        proposal: The proposal to challenge
        strategy: Attack strategy (crescendo, redteaming)
        turn_number: Current turn number (1-indexed)
        max_turns: Total turns in the challenge

    Returns:
        Turn result with findings
    """
    activity.logger.info(
        f"Running adversarial turn {turn_number}/{max_turns} with strategy: {strategy}"
    )

    # For this prototype, we'll run the full challenge and extract turn results
    # In a production version, we'd implement per-turn PyRIT calls
    bridge_root = Path("~/infrastructure/agent-bridge/bridge").expanduser()
    adapter = PyRITProductionAdapter(
        bridge_root=bridge_root,
        fallback_on_error=True,
        max_retries=1,  # Single retry within activity
    )

    # Run a single-turn challenge (truncated version)
    challenge = await adapter.run_adversarial_challenge_with_retry(
        proposal=proposal,
        strategy=strategy,
        max_turns=1,  # Single turn per activity
    )

    return {
        "turn_number": turn_number,
        "strategy": strategy,
        "vulnerabilities": challenge.vulnerabilities_found,
        "fallback_used": challenge.fallback_used,
        "timestamp": datetime.now(UTC).isoformat(),
    }


@activity.defn(name="aggregate_challenge_results")
async def aggregate_challenge_results(
    proposal: str,
    strategy: str,
    turns: list[dict[str, Any]],
) -> AdversarialChallenge:
    """
    Aggregate results from multiple turns into final challenge

    Args:
        proposal: Original proposal
        strategy: Attack strategy used
        turns: List of turn results

    Returns:
        Complete AdversarialChallenge object
    """
    activity.logger.info(f"Aggregating {len(turns)} turns into final challenge...")

    # Collect all vulnerabilities
    all_vulnerabilities = []
    for turn in turns:
        all_vulnerabilities.extend(turn.get("vulnerabilities", []))

    # Calculate overall score (simple average)
    overall_score = len(all_vulnerabilities) / 10.0 if all_vulnerabilities else 0.0

    # Generate recommendations
    recommendations = _generate_recommendations(all_vulnerabilities)

    # Check if any turn used fallback
    fallback_used = any(turn.get("fallback_used", False) for turn in turns)

    timestamp = datetime.now(UTC)
    challenge_id = f"challenge-{timestamp.strftime('%Y%m%d%H%M%S')}"

    return AdversarialChallenge(
        challenge_id=challenge_id,
        target_proposal=proposal,
        attack_strategy=strategy,
        turns_executed=len(turns),
        vulnerabilities_found=all_vulnerabilities,
        overall_score=overall_score,
        recommendations=recommendations,
        timestamp=timestamp.isoformat(),
        fallback_used=fallback_used,
    )


@activity.defn(name="store_challenge_to_bridge")
async def store_challenge_to_bridge(
    challenge: AdversarialChallenge,
    source_agent: str,
) -> dict[str, str]:
    """
    Store challenge results to bridge event log

    Args:
        challenge: Complete challenge results
        source_agent: Agent that requested the challenge

    Returns:
        Event information (event_id, path)
    """
    activity.logger.info(f"Storing challenge {challenge.challenge_id} to bridge...")

    # Write to bridge events directory
    events_dir = Path("~/infrastructure/agent-bridge/bridge/events").expanduser()
    events_dir.mkdir(parents=True, exist_ok=True)

    timestamp = datetime.now(UTC)
    event_id = (
        f"challenge-{timestamp.strftime('%Y%m%dT%H%M%S')}-{challenge.challenge_id}"
    )
    event_path = events_dir / f"{event_id}.md"

    # Format as bridge event
    event_content = f"""# Adversarial Challenge Event

**Event-Type**: challenge-issued
**Event-ID**: {event_id}
**Challenge-ID**: {challenge.challenge_id}
**Timestamp**: {timestamp.isoformat()}
**Source-Agent**: {source_agent}
**Target-Agent**: redteam

## Challenge Details

**Attack Strategy**: {challenge.attack_strategy}
**Turns Executed**: {challenge.turns_executed}
**Risk Score**: {challenge.overall_score:.2f}/1.0
**Fallback Used**: {'Yes (API unavailable)' if challenge.fallback_used else 'No (Real PyRIT)'}

## Target Proposal

```
{challenge.target_proposal}
```

## Vulnerabilities Found ({len(challenge.vulnerabilities_found)})

"""

    for i, vuln in enumerate(challenge.vulnerabilities_found, 1):
        event_content += f"""
### {i}. [{vuln.get('severity', 'UNKNOWN')}] {vuln.get('attack_type', 'Unknown Attack')}

**Turn**: {vuln.get('turn', '?')}
**Finding**: {vuln.get('finding', 'No details')}
**Prompt**: {vuln.get('adversarial_prompt', 'N/A')}

"""

    event_content += f"""
## Recommendations ({len(challenge.recommendations)})

"""
    for i, rec in enumerate(challenge.recommendations, 1):
        event_content += f"{i}. {rec}\n"

    event_content += """
## Workflow Metadata

- **Workflow**: AdversarialChallengeWorkflow
- **Orchestrator**: Temporal
- **Durability**: Survives process restarts
- **Retry Logic**: Per-turn with Temporal activities

---

**Generated by**: Temporal-integrated PyRIT adapter
"""

    # Write event file
    with event_path.open("w") as f:
        f.write(event_content)

    activity.logger.info(f"Event written to: {event_path}")

    return {
        "event_id": event_id,
        "event_path": str(event_path),
        "timestamp": timestamp.isoformat(),
    }


def _generate_recommendations(vulnerabilities: list[dict]) -> list[str]:
    """Generate actionable recommendations from findings"""
    recommendations = []

    for vuln in vulnerabilities:
        severity = vuln.get("severity", "MEDIUM")
        finding = vuln.get("finding", "")

        if "edge case" in finding.lower():
            recommendations.append(
                f"[{severity}] Add comprehensive edge case handling and input validation"
            )
        if "performance" in finding.lower() or "scaling" in finding.lower():
            recommendations.append(
                f"[{severity}] Define performance benchmarks and scaling strategy"
            )
        if "assumption" in finding.lower():
            recommendations.append(
                f"[{severity}] Document and test critical assumptions"
            )
        if "security" in finding.lower() or "injection" in finding.lower():
            recommendations.append(
                f"[{severity}] Implement security review and input sanitization"
            )
        if "failure" in finding.lower() or "recovery" in finding.lower():
            recommendations.append(
                f"[{severity}] Design failure recovery mechanisms and circuit breakers"
            )

    return list(set(recommendations))  # Deduplicate
