# Temporal Integration - Quick Start Guide

Get the hybrid Temporal trial running in 5 minutes.

## Prerequisites

✅ Temporal SDK installed (`temporalio>=1.18.1`)
✅ Temporal dev server running
✅ PyRIT configured (optional - will use simulation fallback)

## Step 1: Start Temporal Server (if not running)

```bash
# Check if already running
ps aux | grep "temporal server" | grep -v grep

# If not running, start it
cd ~/devvyn-meta-project/kitchen/active-experiments/temporal-integration
temporal server start-dev --db-filename logs/temporal.db > logs/temporal-server.log 2>&1 &

# Wait 5 seconds for startup
sleep 5

# Verify
temporal workflow list --namespace default
```

**Temporal UI**: <http://localhost:8233>

## Step 2: Start Temporal Worker

The worker executes workflows and activities.

```bash
cd ~/devvyn-meta-project/kitchen/active-experiments/temporal-integration

# Start worker (leave running in terminal)
python -m workflows.worker
```

You should see:

```
🚀 Worker ready! Waiting for workflows...
   View in Temporal UI: http://localhost:8233
```

## Step 3: Test Adversarial Challenge Workflow

**In a new terminal:**

```bash
cd ~/devvyn-meta-project/kitchen/active-experiments/temporal-integration

# Trigger workflow with demo proposal
python -m workflows.trigger_adversarial_challenge

# Or with custom proposal
python -m workflows.trigger_adversarial_challenge --proposal "Implement feature X with requirements Y and Z"

# Or from file
python -m workflows.trigger_adversarial_challenge /path/to/proposal.md
```

**Watch the magic**:

1. Worker terminal shows activity execution
2. Temporal UI shows workflow progress in real-time
3. Results written to bridge event log

**View results**:

```bash
# Check latest event
ls -lt ~/infrastructure/agent-bridge/bridge/events/ | head -5

# View event details
cat ~/infrastructure/agent-bridge/bridge/events/challenge-*.md | head -50
```

## Step 4: Test Knowledge Digest Workflow

```bash
cd ~/devvyn-meta-project/kitchen/active-experiments/temporal-integration

# Coming soon - workflow trigger script
```

## Step 5: Test Bridge Integration

```bash
cd ~/devvyn-meta-project/kitchen/active-experiments/temporal-integration

# Process bridge inbox (triggers workflows from bridge messages)
python bridge_temporal_adapter.py process-inbox
```

---

## Troubleshooting

### Worker won't start

**Error**: `Failed to connect to Temporal server`

**Fix**:

```bash
# Check if Temporal server is running
ps aux | grep "temporal server"

# Check server logs
tail -50 ~/devvynmurphy/devvyn-meta-project/kitchen/active-experiments/temporal-integration/logs/temporal-server.log

# Restart server
pkill -f "temporal server"
temporal server start-dev --db-filename logs/temporal.db > logs/temporal-server.log 2>&1 &
```

### Workflow hangs

**Check Temporal UI**: <http://localhost:8233>

- View workflow history
- See which activity is stuck
- Check activity timeout settings

**Check worker logs**: Worker terminal shows activity execution progress

### Import errors

**Error**: `ModuleNotFoundError`

**Fix**:

```bash
cd ~/devvyn-meta-project
uv add temporalio
```

---

## Monitoring

### Temporal UI

- **URL**: <http://localhost:8233>
- **Features**: Live workflow execution, history, timeline, retry logs

### Worker Terminal

- Real-time activity execution logs
- Errors and warnings

### Bridge Events

```bash
# Watch for new events
watch -n 2 'ls -lt ~/infrastructure/agent-bridge/bridge/events/ | head -10'
```

---

## Stopping Everything

```bash
# Stop worker (Ctrl+C in worker terminal)

# Stop Temporal server
pkill -f "temporal server"

# Clean up (optional)
rm -rf ~/devvyn-meta-project/kitchen/active-experiments/temporal-integration/logs/temporal.db*
```

---

## Next Steps

1. ✅ **Test workflows**: Run through quickstart
2. ⏳ **Evaluate reliability**: Kill worker mid-workflow, see if it resumes
3. ⏳ **Compare observability**: Temporal UI vs. log files
4. ⏳ **Measure latency**: Temporal overhead vs. direct execution
5. ⏳ **Document decision**: Adopt/selective/abandon

See main README.md for full evaluation criteria.
