# Secure API Access Pattern

**Category**: Security & Operations
**Maturity**: Established
**Last Updated**: 2025-10-11
**Related**: `~/devvyn-meta-project/private/credentials-refs.md`

## Problem

Agents need to use API credentials (Anthropic, OpenAI, AWS, etc.) for batch processing and automation, but must never expose the actual secret values.

When credentials are needed, agents should move forward autonomously without requiring human intervention for routine access.

## Solution

Use environment variables as the interface between code and credentials. The framework already exists - agents just need to use it correctly.

## Quick Reference

```bash
# 1. Check credential location
cat ~/devvyn-meta-project/private/credentials-refs.md

# 2. Reference in code (never read the actual value)
import os
api_key = os.environ.get("ANTHROPIC_API_KEY")

# 3. Document requirement in project README
echo "Required: ANTHROPIC_API_KEY environment variable" >> README.md

# 4. Move forward - no approval needed for env var references
```

## Pattern: Safe API Client Initialization

### ✅ Correct Pattern

```python
import os
from anthropic import Anthropic

def create_client():
    """Create Anthropic client using environment variable."""
    api_key = os.environ.get("ANTHROPIC_API_KEY")

    if not api_key:
        raise ValueError(
            "ANTHROPIC_API_KEY environment variable not set. "
            "See README for setup instructions."
        )

    return Anthropic(api_key=api_key)

# Use it
client = create_client()
batch = client.messages.batches.create(
    requests=[...],
    # API key used internally, never logged
)
```

**Why this works**:

- References env var by name only
- Never prints/logs the actual key
- Fails fast with helpful error if not set
- Standard Python pattern (safe for live streaming)

### ❌ Anti-Patterns (Never Do This)

```python
# DON'T: Read .env files directly
with open(".env") as f:
    key = f.read()  # ❌ Exposes secret to agent context

# DON'T: Print for debugging
print(f"Using key: {api_key}")  # ❌ Secret appears in logs

# DON'T: Check file contents
if Path("~/.anthropic/key").exists():
    key = Path("~/.anthropic/key").read_text()  # ❌ Secret in memory

# DON'T: Block unnecessarily
raise Exception("Need approval for API access")  # ❌ Framework already exists!
```

## Credential Reference Map

**Location**: `~/devvyn-meta-project/private/credentials-refs.md`

This file contains:

- Environment variable names (safe to reference)
- Storage locations (paths only, not contents)
- Which services use which credentials
- Security notes

**Agents can and should**:

- ✅ Read `credentials-refs.md` to find variable names
- ✅ Reference env vars in code
- ✅ Document env var requirements in README
- ✅ Move forward autonomously

**Agents must never**:

- ❌ Read actual credential files (`.env`, `~/.aws/credentials`, etc.)
- ❌ Print/log credential values
- ❌ Expose secrets in code or output

## Example: Anthropic Batch API

```python
"""
Batch processing script for Claude API.

Setup:
    export ANTHROPIC_API_KEY="your-key-here"
"""

import os
from anthropic import Anthropic

def submit_batch(requests: list):
    """Submit batch requests to Claude API."""
    client = Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))

    batch = client.messages.batches.create(
        requests=requests
    )

    return batch.id

def check_batch_status(batch_id: str):
    """Check status of batch job."""
    client = Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))

    batch = client.messages.batches.retrieve(batch_id)
    return batch.processing_status

# Usage
if __name__ == "__main__":
    # Credentials loaded from environment automatically
    batch_id = submit_batch([...])
    status = check_batch_status(batch_id)
```

## Example: OpenAI Batch API

```python
"""
Batch processing for OpenAI GPT models.

Setup:
    export OPENAI_API_KEY="your-key-here"
"""

import os
from openai import OpenAI

def create_batch_job(input_file_id: str):
    """Create OpenAI batch job."""
    client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))

    batch = client.batches.create(
        input_file_id=input_file_id,
        endpoint="/v1/chat/completions",
        completion_window="24h"
    )

    return batch.id
```

## Example: AWS S3 Access

```python
"""
S3 operations for AAFC Herbarium project.

Setup:
    # Option 1: Environment variables
    export AWS_ACCESS_KEY_ID="your-key-id"
    export AWS_SECRET_ACCESS_KEY="your-secret"

    # Option 2: AWS credentials file (preferred)
    # boto3 reads ~/.aws/credentials automatically
"""

import boto3
import os

def get_s3_client():
    """Get S3 client using default credential chain."""
    # boto3 handles credentials automatically:
    # 1. Environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
    # 2. ~/.aws/credentials file
    # 3. IAM role (in production)

    return boto3.client('s3')

def upload_to_s3(file_path: str, bucket: str, key: str):
    """Upload file to S3."""
    s3 = get_s3_client()
    s3.upload_file(file_path, bucket, key)
```

## Documentation Template

Add this to project README when API credentials are needed:

```markdown
## API Credentials

This project requires API credentials to be set as environment variables:

### Required
- `ANTHROPIC_API_KEY` - Claude API access for batch processing
- `OPENAI_API_KEY` - GPT model access for OCR fallback

### Optional
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` - S3 image storage

### Setup

```bash
# Add to ~/.zshrc or ~/.bashrc
export ANTHROPIC_API_KEY="your-key-here"
export OPENAI_API_KEY="your-key-here"

# Or use project-specific .env file (git-ignored)
cp .env.example .env
# Edit .env with your credentials
```

**Security Notes**:

- Never commit credentials to git
- Use `.env` files (git-ignored) for local development
- Use IAM roles in production (no static keys)
- Rotate credentials regularly

```

## When to Use Approval Workflow

The approval workflow (`~/infrastructure/agent-bridge/bridge/approval-requests/`) is for:

- **SECRET file access** (reading `.env`, `~/.aws/credentials`, etc.)
- **Writing to credential stores**
- **Modifying security configurations**
- **Accessing private infrastructure**

**NOT needed for**:
- ✅ Referencing env var names in code
- ✅ Reading `credentials-refs.md`
- ✅ Writing code that uses `os.environ.get()`
- ✅ Documenting credential requirements

## Live Streaming Considerations

Since work sessions may be live streamed:

1. **Environment variables are safe** - they're in the shell, not in code/output
2. **API responses are safe** - SDKs handle credentials internally
3. **Code is safe** - as long as we reference vars, not read secrets
4. **Logs are safe** - if we never print credential values

**Safe for streaming**:
```python
api_key = os.environ.get("ANTHROPIC_API_KEY")  # ✅ Var name only
client = Anthropic(api_key=api_key)  # ✅ SDK handles internally
response = client.messages.create(...)  # ✅ Response is public data
```

**Not safe for streaming**:

```python
print(f"Key: {api_key}")  # ❌ Secret visible
Path(".env").read_text()  # ❌ Secret in output
```

## Agent Autonomy

Agents should:

1. **Check `credentials-refs.md` first** before declaring blockers
2. **Write code using env vars** without asking permission
3. **Document requirements** in project README
4. **Move forward confidently** - the framework exists for this

This pattern enables agents to work autonomously with credentials while maintaining security, even during live streaming.

## Related Patterns

- [Documentation Quality Gates](./documentation-quality-gates.md) - For documenting credential setup
- [Git Commit Protocol](../../CLAUDE.md) - For handling credentials in commits

## References

- Credentials map: `~/devvyn-meta-project/private/credentials-refs.md`
- Approval template: `~/infrastructure/agent-bridge/bridge/approval-requests/_template-secret-access.md`
- Security guidelines: `~/devvyn-meta-project/CLAUDE.md` (Security Boundaries section)
