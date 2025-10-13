# Pattern: Streaming Event Architecture with Early Validation

**Pattern ID:** streaming-event-architecture
**Category:** Architecture, Monitoring, Quality Assurance
**Source Project:** AAFC Herbarium DWC Extraction
**Date Discovered:** 2025-10-10
**Status:** Production-validated

## Problem

**Delayed Failure Discovery:**
- Long-running batch processes (hours/days) complete entirely before discovering systematic failures
- No real-time progress visibility beyond basic logging
- 4-day delay to discover 0% success rate in production extraction (Oct 6 failure discovered Oct 10)
- Wasted compute resources processing 2,885 specimens when first 5 would have revealed the issue

**Root Cause:**
- Batch-first architecture: collect all results, then process
- End-of-run validation only
- No streaming output
- No early checkpoints

## Solution

**Hybrid Event Bus with Early Validation:**
- In-memory pub/sub for real-time event delivery
- Persistent JSONL event log for debugging
- Early validation checkpoints (e.g., after 5 items)
- Streaming results with immediate flush
- Progressive validation at intervals

## Implementation

### Core Components

```python
# 1. Event Bus (src/events/bus.py)
class HybridEventBus:
    """In-memory pub/sub + persistent event log"""

    def emit(self, event_type: str, data: dict) -> None:
        # Write to log immediately
        if self.event_log_file:
            self.event_log_file.write(json.dumps(event) + "\n")
            self.event_log_file.flush()

        # Notify subscribers
        for handler in self.subscribers[event_type]:
            handler(Event(event_type, data))

# 2. Validation Consumer (src/events/consumers.py)
class ValidationConsumer:
    """Fail fast on quality issues"""

    def __init__(self, bus, early_checkpoint=5, threshold=0.5):
        self.early_checkpoint = early_checkpoint
        self.threshold = threshold
        bus.subscribe(ExtractionEvent.SPECIMEN_COMPLETED, self.on_specimen)

    def on_specimen(self, event: Event):
        if event.data['sequence'] == self.early_checkpoint:
            if event.data['success_rate'] < self.threshold:
                raise EarlyValidationError(
                    f"Failed: {event.data['success_rate']:.0%} < {self.threshold:.0%}"
                )

# 3. Streaming Output Pattern
with open(output_file, "w") as f:
    for i, item in enumerate(items):
        result = process_item(item)

        # Stream immediately
        f.write(json.dumps(result) + "\n")
        f.flush()  # Force disk write

        # Emit event
        bus.emit("item.completed", {
            "sequence": i + 1,
            "result": result,
            "metrics": calculate_metrics()
        })
```

### Event Types

```python
class ExtractionEvent:
    STARTED = "extraction.started"
    SPECIMEN_QUEUED = "specimen.queued"
    SPECIMEN_PROCESSING = "specimen.processing"
    SPECIMEN_COMPLETED = "specimen.completed"
    SPECIMEN_FAILED = "specimen.failed"
    VALIDATION_CHECKPOINT = "validation.checkpoint"
    VALIDATION_WARNING = "validation.warning"
    EXTRACTION_COMPLETED = "extraction.completed"
    EXTRACTION_FAILED = "extraction.failed"
```

## Results

**Before:**
- Failure detection: 4 days (96 hours)
- Wasted compute: 2,885 specimens × 30 seconds = 24 hours
- Progress visibility: None (end-of-run summary only)

**After:**
- Failure detection: 2.5 minutes (5 specimens × 30 seconds)
- Wasted compute: 5 specimens = 2.5 minutes
- Progress visibility: Real-time streaming + event log
- Improvement: **98.9% faster** failure detection

**Production Validation:**
- Early validation checkpoint: ✅ PASSED (5/5 specimens = 100%)
- Continued processing with 93.5% success rate (72/77 specimens)
- Event log captured all processing steps for debugging
- Performance overhead: <0.001% (negligible)

## Benefits

1. **Fast Failure Detection:** Catch issues in minutes, not days
2. **Resource Efficiency:** Stop bad runs early, save compute
3. **Real-time Monitoring:** Stream results as they're generated
4. **Debug Capability:** Full event log for post-mortem analysis
5. **Zero Dependencies:** No Redis, Kafka, or external services needed
6. **Negligible Overhead:** <0.001% performance impact

## Anti-Patterns

❌ **Batch-First Architecture:**
```python
# BAD: Collect all, then process
results = [process(item) for item in items]  # No streaming
with open(output, "w") as f:
    f.write(json.dumps(results))  # Write at end only
```

❌ **No Early Validation:**
```python
# BAD: Only validate at end
for item in items:
    process(item)
# Check success rate here - too late!
```

❌ **Buffered Output:**
```python
# BAD: Results sit in buffer
with open(output, "w") as f:
    for item in items:
        f.write(json.dumps(process(item)))
        # No f.flush() - writes delayed
```

## When to Apply

✅ **Apply this pattern when:**
- Long-running batch processes (>30 minutes)
- High cost of processing all items (compute, API costs, time)
- Need for real-time progress monitoring
- Debugging failed runs is difficult

❌ **Skip this pattern when:**
- Quick processes (<5 minutes total)
- Items must be processed atomically
- Streaming would complicate logic significantly
- External event system already available (e.g., Kafka, Redis)

## Variations

### Minimal Version (No Event Bus)
```python
# Just streaming + early validation
successful = 0
with open(output, "w") as f:
    for i, item in enumerate(items):
        result = process(item)
        f.write(json.dumps(result) + "\n")
        f.flush()

        if result['success']:
            successful += 1

        # Early checkpoint
        if i == 4 and successful / 5 < 0.5:
            raise EarlyValidationError()
```

### Enterprise Version (External Event System)
```python
# Use Redis pub/sub or Kafka for events
redis_client.publish('extraction.completed', json.dumps(event))
```

## Related Patterns

- **Circuit Breaker:** Stop processing on repeated failures
- **Progressive Validation:** Validate at multiple checkpoints (5, 50, 100...)
- **Metric Aggregation:** Track success rate, throughput, error types
- **Event Sourcing:** Reconstruct state from event log

## References

- Implementation: `src/events/` (AAFC Herbarium project)
- Design Doc: `docs/architecture/STREAMING_EVENT_ARCHITECTURE.md`
- Integration Guide: `docs/architecture/EVENT_BUS_INTEGRATION_GUIDE.md`
- Production Report: `docs/status/2025-10-10-production-status.md`

## Tags

`architecture` `events` `monitoring` `validation` `streaming` `quality-assurance` `fast-fail`
