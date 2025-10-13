#!/usr/bin/env python3
"""
Live Demo: Adapted PyRIT Quality & Alignment Checking (Auto-run)

Demonstrates constitutional alignment and context quality validation
on a real proposal from the devvyn-meta-project system.
"""

import asyncio
import json
import sys
from datetime import datetime
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from quality_check_demo import (
    print_summary,
    run_constitutional_alignment_check,
    run_context_quality_check,
)


async def main():
    """Run complete quality checking demo (non-interactive)"""

    print("=" * 80)
    print("LIVE DEMO: Adapted PyRIT Quality & Alignment Checking")
    print("=" * 80)
    print()
    print("This demo shows how PyRIT's multi-turn interrogation is adapted from")
    print(
        "security testing to constitutional alignment and context quality validation."
    )
    print()
    print("Proposal Being Checked:")
    print("─" * 80)
    print("Title: Implement ML Pattern Extraction from Event Log")
    print("From: Code Agent")
    print("Priority: HIGH")
    print("Summary: Add unsupervised learning (K-means, DBSCAN) to automatically")
    print("         detect patterns in bridge/events/, trained on 6 months of")
    print("         historical data, deployed as LaunchAgent every 15 minutes.")
    print("=" * 80)
    print()
    print("Starting checks...")
    print()

    # Mock proposal and state
    proposal = """
    Implement automated pattern extraction from event log using ML clustering:
    - Monitor bridge/events/ for new events
    - Use unsupervised learning (K-means, DBSCAN, Isolation Forest)
    - Train on 6 months historical data
    - Auto-add patterns >80% confidence to decision-patterns.md
    - Patterns 60-80% flagged for INVESTIGATOR review
    - Deploy as LaunchAgent running every 15 minutes
    """

    current_state = {
        "moratorium": "30-day meta-work freeze (2025-10-03 to 2025-11-01)",
        "event_sourcing_date": "2025-10-02",
        "current_date": "2025-10-10",
    }

    # Run constitutional alignment check
    constitutional_result = await run_constitutional_alignment_check(
        proposal, current_state
    )

    # Save results
    results_dir = Path(
        "~/devvyn-meta-project/kitchen/active-experiments/pyrit-adversarial-orchestration/demo"
    ).expanduser()
    results_dir.mkdir(parents=True, exist_ok=True)

    constitutional_file = results_dir / f"{constitutional_result.check_id}.json"
    constitutional_file.write_text(json.dumps(asdict(constitutional_result), indent=2))

    print(
        f"✅ Constitutional check complete: {constitutional_result.overall_score:.2f}/5.0"
    )
    print(f"   Status: {constitutional_result.approval_status}")
    print(f"   Results saved: {constitutional_file}")
    print()

    # Run context quality check
    print("─" * 80)
    print()
    context_result = await run_context_quality_check(proposal, current_state)

    context_file = results_dir / f"{context_result.check_id}.json"
    context_file.write_text(json.dumps(asdict(context_result), indent=2))

    print(f"✅ Context quality check complete: {context_result.overall_score:.2f}/5.0")
    print(f"   Status: {context_result.approval_status}")
    print(f"   Results saved: {context_file}")
    print()

    print("─" * 80)
    print()

    # Print summary
    print_summary(constitutional_result, context_result)

    # Save combined report
    combined_report = results_dir / "quality-check-demo-report.md"
    combined_report.write_text(f"""# Quality Check Demo Report

Generated: {datetime.now().isoformat()}

## Proposal
{proposal}

## Constitutional Alignment Check
- Score: {constitutional_result.overall_score:.2f}/5.0
- Status: {constitutional_result.approval_status}
- Violations: {len(constitutional_result.violations)}

## Context Quality Check
- Score: {context_result.overall_score:.2f}/5.0
- Status: {context_result.approval_status}
- Violations: {len(context_result.violations)}

## Combined Decision
Combined Score: {(constitutional_result.overall_score + context_result.overall_score) / 2:.2f}/5.0

## All Recommendations
{chr(10).join('- ' + r for r in set(constitutional_result.recommendations + context_result.recommendations))}
""")

    print(f"📄 Combined report saved: {combined_report}")
    print()
    print("=" * 80)
    print("DEMO COMPLETE")
    print("=" * 80)
    print()


if __name__ == "__main__":
    # Import asdict here to avoid circular imports
    from dataclasses import asdict

    asyncio.run(main())
