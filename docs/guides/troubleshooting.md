# Troubleshooting Guide

**Quick reference for common issues and their solutions**

---

## Quick Diagnosis

### Symptom: Message not delivered

```bash
# Check if message was sent
./message.sh log | grep "SENT"

# Check inbox
./message.sh inbox <agent>

# Check file permissions
ls -la inbox/<agent>/

# Expected: drwxr-xr-x (755 for directory, 644 for files)
```

**Common causes**:
1. Wrong agent name (case-sensitive)
2. File permissions
3. Disk full
4. Message file corrupted

---

### Symptom: Command not found

```bash
# Check if script is executable
ls -l message.sh
# Should show: -rwxr-xr-x

# Make executable
chmod +x message.sh

# Check PATH (if installed globally)
echo $PATH
which coord  # If using CLI
```

---

### Symptom: Slow performance

```bash
# Check message count
find inbox/ -name "*.msg" | wc -l

# Check event log size
du -h events.log

# Check disk space
df -h .

# Check for lock files
find . -name "*.lock"
```

**Solutions**:
- Archive old messages
- Rotate event log
- Free disk space
- Remove stale locks

---

## Common Issues

### Issue 1: "Permission denied" Error

**Symptom**:
```
./message.sh: Permission denied
```

**Cause**: Script not executable

**Solution**:
```bash
chmod +x message.sh

# If using templates
chmod +x templates/*/message.sh
chmod +x templates/*/workflows/*.sh
```

---

### Issue 2: Agent Name Case Mismatch

**Symptom**:
```bash
./message.sh inbox code  # Works
./message.sh inbox CODE  # Empty inbox (different agent!)
```

**Cause**: Agent names are case-sensitive

**Solution**:
- Use consistent casing (lowercase recommended)
- Document agent names in config.yaml
- Use tab completion if available

---

### Issue 3: Message Files Accumulate

**Symptom**:
- Inbox queries slow down
- Disk space fills up
- Performance degrades

**Cause**: No message cleanup policy

**Solution**:

**Option A: Archive old messages**
```bash
# Archive messages older than 30 days
find inbox/ -name "*.msg" -mtime +30 -exec mv {} archive/ \;

# Or delete
find inbox/ -name "*.msg" -mtime +30 -delete
```

**Option B: Automated cleanup**
```bash
# Add to crontab
crontab -e

# Archive daily at 2am
0 2 * * * find /path/to/inbox -name "*.msg" -mtime +30 -exec mv {} /path/to/archive/ \;
```

---

### Issue 4: Event Log Too Large

**Symptom**:
```bash
du -h events.log
# 500M events.log

time ./message.sh stats
# Takes 30 seconds!
```

**Cause**: Append-only log grows indefinitely

**Solution**:

**Option A: Log rotation**
```bash
# Install logrotate config
cat > /etc/logrotate.d/coordination << EOF
/path/to/events.log {
    daily
    rotate 90
    compress
    delaycompress
    notifempty
    create 0644 user group
}
EOF

# Test
logrotate -f /etc/logrotate.d/coordination
```

**Option B: Manual archive**
```bash
# Keep last 10,000 events
tail -10000 events.log > events.log.tmp
mv events.log.tmp events.log

# Archive old events
cat events.log.1 >> events.log.archive
gzip events.log.archive
```

---

### Issue 5: Concurrent Access Conflicts

**Symptom**:
- Occasional "file already exists" errors
- Messages randomly fail to send
- Intermittent slowness with multiple agents

**Cause**: Race conditions in file creation

**Solution**:

**Option A: Use unique temp files**
```bash
# In message.sh, replace direct write with atomic rename
TMP_FILE=$(mktemp)
cat > "$TMP_FILE" <<EOF
id: $MESSAGE_ID
from: $FROM
to: $TO
...
EOF

# Atomic rename (prevents race conditions)
mv "$TMP_FILE" "inbox/$TO/$MESSAGE_ID.msg"
```

**Option B: Migrate to database**
- PostgreSQL with transactions
- Handles concurrency correctly
- See: [Scale Transition Guide](../scaling/scale-transition-guide.md)

---

### Issue 6: UUID Generation Slow

**Symptom**:
```bash
time ./message.sh send code chat "Test" "Body"
# real 0m0.250s  # Slow!
```

**Cause**: Reading from `/dev/urandom` blocks

**Solution**:

**Use `uuidgen` (faster)**:
```bash
# Check if available
which uuidgen
# /usr/bin/uuidgen

# Benchmark
time for i in {1..1000}; do uuidgen > /dev/null; done
# real 0m2.5s  # ~400 UUIDs/sec
```

**Or pre-generate pool**:
```bash
# Generate UUID pool at startup
UUID_POOL=()
for i in {1..1000}; do
    UUID_POOL+=($(uuidgen))
done

# Use from pool
get_uuid() {
    echo "${UUID_POOL[0]}"
    UUID_POOL=("${UUID_POOL[@]:1}")

    # Refill if low
    if [ ${#UUID_POOL[@]} -lt 100 ]; then
        for i in {1..1000}; do
            UUID_POOL+=($(uuidgen))
        done
    fi
}
```

---

### Issue 7: Bash Script Syntax Errors

**Symptom**:
```
./message.sh: line 42: syntax error near unexpected token `fi'
```

**Common causes**:

**Missing quotes**:
```bash
# Bad
if [ $SUBJECT == "Test" ]; then

# Good
if [ "$SUBJECT" == "Test" ]; then
```

**Unquoted variables with spaces**:
```bash
# Bad
echo $BODY  # Breaks if BODY contains spaces

# Good
echo "$BODY"
```

**Missing `fi`/`done`/`esac`**:
```bash
# Bad
if [ condition ]; then
    do_something
# Missing fi!

# Good
if [ condition ]; then
    do_something
fi
```

---

### Issue 8: Database Migration Fails

**Symptom**:
```
psql: FATAL: database "coordination" does not exist
```

**Solution**:

**Create database**:
```sql
-- Connect as postgres user
psql -U postgres

-- Create database
CREATE DATABASE coordination;

-- Create user
CREATE USER coordination_user WITH PASSWORD 'your_password';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE coordination TO coordination_user;

-- Connect to new database
\c coordination

-- Create schema
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_agent VARCHAR(50) NOT NULL,
    to_agent VARCHAR(50) NOT NULL,
    subject TEXT NOT NULL,
    body TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_to_agent_created ON messages(to_agent, created_at DESC);
CREATE INDEX idx_from_agent_created ON messages(from_agent, created_at DESC);
```

---

### Issue 9: Redis Connection Refused

**Symptom**:
```
redis.exceptions.ConnectionError: Error 61 connecting to localhost:6379. Connection refused.
```

**Solution**:

**Check Redis is running**:
```bash
# macOS
brew services list | grep redis
# linux
systemctl status redis

# Start Redis
brew services start redis  # macOS
sudo systemctl start redis  # Linux
```

**Test connection**:
```bash
redis-cli ping
# PONG (if working)
```

**Check port**:
```bash
lsof -i :6379
# Should show redis-server
```

---

### Issue 10: Git Pre-commit Hooks Fail

**Symptom**:
```
trailing-whitespace................................................Failed
ruff....................................................Failed
```

**Solution**:

**Option A: Auto-fix and retry**:
```bash
# Hooks usually auto-fix
git add -A

# Try commit again
git commit -m "message"
```

**Option B: Skip hooks** (use sparingly):
```bash
git commit --no-verify -m "message"
```

**Option C: Fix issues manually**:
```bash
# Trailing whitespace
find . -type f -name "*.py" -exec sed -i '' 's/[[:space:]]*$//' {} \;

# Ruff issues
ruff check --fix .

# Add and commit
git add -A
git commit -m "message"
```

---

## Platform-Specific Issues

### macOS

#### Issue: `osascript` not found

**Symptom**:
```
./message.sh: line 123: osascript: command not found
```

**Cause**: Trying to use Notes.app integration on non-macOS

**Solution**:
- Use alternative storage (SQLite, PostgreSQL)
- Or: Skip Notes.app integration
- See: [Platform Porting Guide](../platform/platform-porting-guide.md)

---

#### Issue: `launchd` not starting agents

**Symptom**:
```bash
launchctl list | grep coordination
# Nothing found
```

**Solution**:
```bash
# Check plist syntax
plutil -lint ~/Library/LaunchAgents/com.coordination.agent.plist

# Load manually
launchctl load ~/Library/LaunchAgents/com.coordination.agent.plist

# Check errors
tail -f ~/Library/Logs/coordination-agent-stdout.log
tail -f ~/Library/Logs/coordination-agent-stderr.log

# Unload and reload
launchctl unload ~/Library/LaunchAgents/com.coordination.agent.plist
launchctl load ~/Library/LaunchAgents/com.coordination.agent.plist
```

---

### Linux

#### Issue: `systemd` timer not triggering

**Symptom**:
```bash
systemctl status coordination-inbox.timer
# inactive (dead)
```

**Solution**:
```bash
# Enable timer
sudo systemctl enable coordination-inbox.timer

# Start timer
sudo systemctl start coordination-inbox.timer

# Check next trigger
systemctl list-timers | grep coordination

# Check service logs
journalctl -u coordination-inbox.service -f
```

---

#### Issue: File permissions in `/home/`

**Symptom**:
```
Permission denied: /home/user/coordination/inbox/
```

**Solution**:
```bash
# Fix ownership
sudo chown -R $USER:$USER ~/coordination

# Fix permissions
chmod 755 ~/coordination
chmod 755 ~/coordination/inbox
chmod 644 ~/coordination/inbox/*/*.msg
```

---

### Windows (WSL2)

#### Issue: Line ending problems

**Symptom**:
```
: No such file or directory
# (Invisible \r\n characters)
```

**Solution**:
```bash
# Convert CRLF → LF
dos2unix message.sh

# Or with sed
sed -i 's/\r$//' message.sh

# Configure git
git config --global core.autocrlf input
```

---

#### Issue: WSL2 filesystem performance

**Symptom**:
- Very slow file operations
- High latency for message sends

**Cause**: Using Windows filesystem from WSL2 (/mnt/c/)

**Solution**:
- Move coordination system to WSL2 filesystem (`~/coordination`)
- Avoid `/mnt/c/Users/...` paths
- Use `/home/user/coordination` instead

---

### Docker

#### Issue: Volume permissions

**Symptom**:
```
Permission denied: /app/inbox/code/
```

**Solution**:

**Fix in docker-compose.yml**:
```yaml
services:
  coordinator:
    user: "${UID}:${GID}"  # Use host user ID
    volumes:
      - ./inbox:/app/inbox
```

**Or in Dockerfile**:
```dockerfile
RUN chown -R 1000:1000 /app/inbox
USER 1000:1000
```

---

#### Issue: Container cannot resolve `localhost`

**Symptom**:
```
Could not connect to Redis at localhost:6379
```

**Cause**: `localhost` inside container ≠ host localhost

**Solution**:

**Use service names**:
```yaml
services:
  coordinator:
    environment:
      - REDIS_URL=redis://redis:6379  # Use service name, not localhost

  redis:
    image: redis:7
```

**Or use host network** (less isolated):
```yaml
services:
  coordinator:
    network_mode: "host"
```

---

### Kubernetes

#### Issue: Pod crash loop

**Symptom**:
```bash
kubectl get pods
# coordination-api-xxxxx   0/1   CrashLoopBackOff
```

**Solution**:

**Check logs**:
```bash
kubectl logs coordination-api-xxxxx
kubectl describe pod coordination-api-xxxxx
```

**Common causes**:
1. Missing ConfigMap/Secret
2. Database not ready
3. Resource limits too low
4. Health check failing

**Fix resource limits**:
```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "2000m"
```

---

#### Issue: Service not accessible

**Symptom**:
```bash
curl http://coordination-api.local
# Connection refused
```

**Solution**:

**Check service**:
```bash
kubectl get svc -n coordination
kubectl describe svc coordination-api -n coordination
```

**Check endpoints**:
```bash
kubectl get endpoints -n coordination
# Should list pod IPs
```

**Port-forward for testing**:
```bash
kubectl port-forward svc/coordination-api 8080:80 -n coordination
curl http://localhost:8080
```

---

## Performance Troubleshooting

### Slow Message Send

**Measure**:
```bash
time ./message.sh send code chat "Test" "Body"
```

**If > 100ms**:

1. **Check disk I/O**:
   ```bash
   iostat -x 1
   # Look for high %util
   ```

2. **Check for disk full**:
   ```bash
   df -h .
   # Should have > 10% free
   ```

3. **Optimize UUID generation** (see Issue 6)

4. **Enable batching** (trades latency for throughput)

---

### Slow Inbox Query

**Measure**:
```bash
time ./message.sh inbox code
```

**If > 1 second**:

1. **Check message count**:
   ```bash
   find inbox/code/ -name "*.msg" | wc -l
   ```

2. **Archive old messages** (see Issue 3)

3. **Add Redis caching**:
   ```python
   from redis import Redis
   cache = Redis(host='localhost', port=6379)

   def get_inbox(agent):
       cached = cache.get(f"inbox:{agent}")
       if cached:
           return json.loads(cached)

       messages = read_inbox_from_disk(agent)
       cache.setex(f"inbox:{agent}", 60, json.dumps(messages))
       return messages
   ```

---

## Debugging Tips

### Enable Debug Logging

**In Bash scripts**:
```bash
# Add to top of script
set -x  # Print commands as they execute
set -e  # Exit on error
set -u  # Exit on undefined variable

# Run
./message.sh send code chat "Test" "Body"
# Prints every command executed
```

**In Python**:
```python
import logging
logging.basicConfig(level=logging.DEBUG)

logger = logging.getLogger(__name__)
logger.debug(f"Sending message: {message_id}")
```

---

### Trace Message Flow

**Follow a message through the system**:
```bash
MESSAGE_ID="2025-10-30T12:34:56-06:00-code-abc123"

# Check event log
grep "$MESSAGE_ID" events.log

# Check if file exists
find inbox/ -name "*${MESSAGE_ID}*"

# Check database (if using PostgreSQL)
psql -U coordination_user -d coordination -c \
  "SELECT * FROM messages WHERE id = '$MESSAGE_ID';"
```

---

### Verify Event Log Integrity

**Check for tampering**:
```python
# See security-privacy-audit.md for full implementation
from audit_log import TamperProofAuditLog

audit = TamperProofAuditLog()
audit.load_from_file("events.log")

verified, message = audit.verify_integrity()
print(f"Integrity check: {message}")
```

---

## Getting Help

### Before Asking

1. **Check this troubleshooting guide** (you're here!)
2. **Search existing issues**: https://github.com/devvyn/coordination-system/issues
3. **Enable debug logging** (see above)
4. **Collect relevant information**:
   - Platform (macOS/Linux/Windows)
   - Version (`git rev-parse HEAD`)
   - Error messages (full text)
   - Steps to reproduce

### Where to Ask

- **GitHub Issues**: https://github.com/devvyn/coordination-system/issues
- **Discussions**: https://github.com/devvyn/coordination-system/discussions
- **Email**: devvyn@example.com (for private issues)

### What to Include

```markdown
### Environment
- OS: macOS 14.0 / Ubuntu 22.04 / Windows 11
- Bash version: `bash --version`
- Coordination system version: `git rev-parse HEAD`

### Expected Behavior
What should happen?

### Actual Behavior
What actually happens?

### Steps to Reproduce
1. Step one
2. Step two
3. ...

### Error Messages
```
Full error output here
```

### Debug Logs
```
Debug output with set -x
```
```

---

## Emergency Procedures

### System Completely Broken

**Backup first**:
```bash
# Backup everything
tar -czf coordination-backup-$(date +%Y%m%d).tar.gz \
    inbox/ events.log config.yaml

# Move to safe location
mv coordination-backup-*.tar.gz ~/backups/
```

**Fresh start**:
```bash
# Remove everything except backups
rm -rf inbox/ events.log

# Reinitialize
./message.sh init

# Restore from backup if needed
tar -xzf ~/backups/coordination-backup-20251030.tar.gz
```

---

### Data Loss Prevention

**Daily backups** (cron):
```bash
# Add to crontab
crontab -e

# Backup daily at 3am
0 3 * * * cd /path/to/coordination && \
  tar -czf ~/backups/coordination-$(date +\%Y\%m\%d).tar.gz \
    inbox/ events.log config.yaml
```

**Retention policy**:
```bash
# Keep only last 30 days
find ~/backups/coordination-*.tar.gz -mtime +30 -delete
```

---

**Last updated**: 2025-10-30
**Maintainer**: CODE agent
