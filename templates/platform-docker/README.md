# Docker Compose Coordination Template

**Platform**: Docker / Docker Compose

**Use Case**: Run coordination system in containers for portability and reproducibility

---

## Quick Start

```bash
# 1. Copy template
cp -r templates/platform-docker ~/my-coordination

# 2. Configure
cd ~/my-coordination
vi .env

# 3. Start
docker-compose up -d

# 4. Send message
docker-compose exec coordinator ./message.sh send code chat "Hello from Docker" "System is running!"

# 5. Check inbox
docker-compose exec coordinator ./message.sh inbox chat
```

---

## Services

### coordinator
- **Image**: `alpine:3.18` (minimal)
- **Purpose**: Run coordination scripts
- **Volumes**: `./inbox`, `./events.log`
- **Dependencies**: None (self-contained)

### postgres (optional)
- **Image**: `postgres:16-alpine`
- **Purpose**: Event sourcing database (for high-volume deployments)
- **Volumes**: `./pg_data`

### redis (optional)
- **Image**: `redis:7-alpine`
- **Purpose**: Message queue (for async processing)
- **Volumes**: `./redis_data`

---

## Architecture

```
┌─────────────────────┐
│   coordinator       │
│   (Alpine Linux)    │
│                     │
│   - message.sh      │
│   - workflows/      │
│   - inbox/          │
│   - events.log      │
└─────────────────────┘
         │
         ├── PostgreSQL (optional, for scale)
         └── Redis (optional, for queues)
```

---

## Benefits

✅ **Portable**: Runs anywhere Docker runs
✅ **Reproducible**: Identical environment every time
✅ **Isolated**: No host dependencies
✅ **Scalable**: Add services as needed
✅ **Version controlled**: docker-compose.yml in git

---

## Configuration Files

### docker-compose.yml

```yaml
version: '3.8'

services:
  coordinator:
    image: alpine:3.18
    container_name: coordination-system
    volumes:
      - ./message.sh:/app/message.sh:ro
      - ./inbox:/app/inbox
      - ./events.log:/app/events.log
    working_dir: /app
    command: tail -f /dev/null  # Keep running
    environment:
      - TZ=America/Regina  # Saskatoon time
    networks:
      - coordination-net

networks:
  coordination-net:
    driver: bridge
```

### .env

```bash
# Timezone
TZ=America/Regina

# Agent names
AGENT_CODE=code
AGENT_CHAT=chat
AGENT_HUMAN=human

# Performance
MAX_WORKERS=4
CACHE_SIZE_MB=100
```

---

**Version**: 1.0
**Platform**: Docker
**Last Updated**: 2025-10-30
