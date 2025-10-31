#!/usr/bin/env python3
"""
Temporal Activities for Knowledge Digest Workflow

Activities for automated knowledge extraction and digest generation from
the event log and collective intelligence systems.
"""

import logging
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import Any

from temporalio import activity

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@activity.defn(name="check_event_log_for_new_events")
async def check_event_log_for_new_events(since_hours: int = 168) -> dict[str, Any]:
    """
    Check event log for new events since last digest

    Args:
        since_hours: Look back this many hours (default: 168 = 7 days)

    Returns:
        Event statistics and file list
    """
    activity.logger.info(
        f"Checking event log for events in last {since_hours} hours..."
    )

    events_dir = Path("~/infrastructure/agent-bridge/bridge/events").expanduser()

    if not events_dir.exists():
        activity.logger.warning(f"Events directory not found: {events_dir}")
        return {
            "has_new_events": False,
            "event_count": 0,
            "events": [],
            "checked_at": datetime.now(UTC).isoformat(),
        }

    # Find events newer than cutoff time
    cutoff_time = datetime.now(UTC) - timedelta(hours=since_hours)

    new_events = []
    for event_file in events_dir.glob("*.md"):
        # Check file modification time
        mtime = datetime.fromtimestamp(event_file.stat().st_mtime, tz=UTC)

        if mtime > cutoff_time:
            new_events.append(
                {
                    "file": event_file.name,
                    "path": str(event_file),
                    "modified": mtime.isoformat(),
                }
            )

    activity.logger.info(f"Found {len(new_events)} new events")

    return {
        "has_new_events": len(new_events) > 0,
        "event_count": len(new_events),
        "events": new_events,
        "checked_at": datetime.now(UTC).isoformat(),
        "cutoff_time": cutoff_time.isoformat(),
    }


@activity.defn(name="extract_patterns_from_events")
async def extract_patterns_from_events(events: list[dict[str, Any]]) -> dict[str, Any]:
    """
    Extract patterns from event list

    This is a simplified version. In production, would use:
    - ML clustering (K-means, DBSCAN)
    - NLP for semantic similarity
    - Pattern confidence scoring

    Args:
        events: List of event metadata

    Returns:
        Extracted patterns with confidence scores
    """
    activity.logger.info(f"Extracting patterns from {len(events)} events...")

    # Simulate pattern extraction (in production, would analyze event content)
    patterns = []

    # Pattern 1: Challenge frequency
    challenge_events = [e for e in events if "challenge" in e["file"].lower()]
    if len(challenge_events) > 2:
        patterns.append(
            {
                "type": "frequency",
                "name": "High adversarial challenge activity",
                "confidence": min(len(challenge_events) / 10.0, 1.0),
                "evidence_count": len(challenge_events),
                "description": f"Observed {len(challenge_events)} challenge events in digest period",
            }
        )

    # Pattern 2: Agent coordination
    if len(events) > 5:
        patterns.append(
            {
                "type": "coordination",
                "name": "Active multi-agent coordination",
                "confidence": 0.85,
                "evidence_count": len(events),
                "description": f"High event volume ({len(events)} events) indicates active coordination",
            }
        )

    # Pattern 3: Time-based patterns
    # (Would analyze event timing in production)
    patterns.append(
        {
            "type": "temporal",
            "name": "Continuous system activity",
            "confidence": 0.75,
            "evidence_count": len(events),
            "description": "Event distribution suggests continuous operation",
        }
    )

    activity.logger.info(f"Extracted {len(patterns)} patterns")

    return {
        "patterns": patterns,
        "pattern_count": len(patterns),
        "analyzed_events": len(events),
        "extracted_at": datetime.now(UTC).isoformat(),
    }


@activity.defn(name="generate_knowledge_digest")
async def generate_knowledge_digest(
    events_data: dict[str, Any],
    patterns_data: dict[str, Any],
) -> dict[str, Any]:
    """
    Generate markdown digest from events and patterns

    Args:
        events_data: Event statistics
        patterns_data: Extracted patterns

    Returns:
        Digest metadata and file path
    """
    activity.logger.info("Generating knowledge digest...")

    timestamp = datetime.now(UTC)
    digest_id = f"digest-{timestamp.strftime('%Y%m%d-%H%M%S')}"

    digest_dir = Path(
        "~/devvyn-meta-project/knowledge-base/tools/coordination-kb-pipeline"
    ).expanduser()
    digest_dir.mkdir(parents=True, exist_ok=True)

    digest_path = digest_dir / f"{digest_id}.md"

    # Generate digest content
    digest_content = f"""# Knowledge Digest: {timestamp.strftime('%Y-%m-%d')}

**Generated**: {timestamp.isoformat()}
**Digest ID**: {digest_id}
**Period**: Last 7 days
**Generator**: Temporal KnowledgeDigestWorkflow

---

## Event Summary

**Total Events**: {events_data['event_count']}
**Time Range**: {events_data.get('cutoff_time', 'N/A')} to {events_data['checked_at']}

### Recent Events

"""

    for i, event in enumerate(events_data["events"][:10], 1):
        digest_content += f"{i}. `{event['file']}` (modified: {event['modified']})\n"

    if events_data["event_count"] > 10:
        digest_content += f"\n... and {events_data['event_count'] - 10} more events\n"

    digest_content += f"""

---

## Patterns Identified ({patterns_data['pattern_count']})

"""

    for i, pattern in enumerate(patterns_data["patterns"], 1):
        digest_content += f"""
### {i}. {pattern['name']}

**Type**: {pattern['type']}
**Confidence**: {pattern['confidence']:.0%}
**Evidence**: {pattern['evidence_count']} events
**Description**: {pattern['description']}

"""

    digest_content += """
---

## Recommendations

"""

    # Generate recommendations based on patterns
    if patterns_data["pattern_count"] > 0:
        digest_content += """
1. **Pattern Validation**: Review high-confidence patterns for addition to decision-patterns.md
2. **Agent Coordination**: Current activity levels suggest effective multi-agent coordination
3. **Continuous Monitoring**: Maintain event log monitoring for emerging patterns

"""
    else:
        digest_content += """
1. **Low Activity**: Consider increasing agent coordination frequency
2. **Pattern Detection**: Current sample size may be too small for reliable patterns

"""

    digest_content += f"""
---

## Next Actions

- [ ] Review patterns with INVESTIGATOR agent
- [ ] Add validated patterns to decision-patterns.md
- [ ] Update collective-memory.md with insights
- [ ] Schedule next digest (7 days)

---

**Generated by**: Temporal KnowledgeDigestWorkflow
**Workflow Durability**: Survives process restarts
**Next Digest**: {(timestamp + timedelta(days=7)).strftime('%Y-%m-%d')}
"""

    # Write digest
    with digest_path.open("w") as f:
        f.write(digest_content)

    activity.logger.info(f"Digest written to: {digest_path}")

    return {
        "digest_id": digest_id,
        "digest_path": str(digest_path),
        "patterns_count": patterns_data["pattern_count"],
        "events_analyzed": events_data["event_count"],
        "generated_at": timestamp.isoformat(),
    }


@activity.defn(name="update_collective_memory")
async def update_collective_memory(
    digest_data: dict[str, Any],
    patterns_data: dict[str, Any],
) -> dict[str, Any]:
    """
    Update collective memory with new insights from digest

    Args:
        digest_data: Digest metadata
        patterns_data: Pattern data

    Returns:
        Update status
    """
    activity.logger.info("Updating collective memory...")

    memory_path = Path(
        "~/devvyn-meta-project/knowledge-base/collective-memory.md"
    ).expanduser()

    if not memory_path.exists():
        activity.logger.warning(f"Collective memory not found: {memory_path}")
        return {
            "updated": False,
            "reason": "collective-memory.md not found",
        }

    # Read current memory
    memory_content = memory_path.read_text()

    # Append insights section
    timestamp = datetime.now(UTC)
    insights_section = f"""

---

## Digest Update: {timestamp.strftime('%Y-%m-%d')}

**Source**: {digest_data['digest_id']}
**Patterns Identified**: {patterns_data['pattern_count']}
**Events Analyzed**: {digest_data['events_analyzed']}

### Key Insights

"""

    for pattern in patterns_data["patterns"]:
        if pattern["confidence"] > 0.8:  # Only high-confidence patterns
            insights_section += f"- **{pattern['name']}**: {pattern['description']} (confidence: {pattern['confidence']:.0%})\n"

    insights_section += f"""

**Full Digest**: `{digest_data['digest_path']}`

"""

    # Append to memory
    updated_content = memory_content + insights_section

    # Write updated memory
    with memory_path.open("w") as f:
        f.write(updated_content)

    activity.logger.info(f"Collective memory updated: {memory_path}")

    return {
        "updated": True,
        "memory_path": str(memory_path),
        "patterns_added": sum(
            1 for p in patterns_data["patterns"] if p["confidence"] > 0.8
        ),
        "updated_at": timestamp.isoformat(),
    }
