# Context Command - Agent Rapid Contextualization

**Purpose**: Rapidly contextualize agent in current workspace using CAQT

**Usage**: `/context` or `claude context`

**Philosophy**: Proactive configuration of contingent context - prepare answers to questions the agent doesn't yet know to ask.

---

## Command Execution

When this command is invoked, run:

```bash
~/devvyn-meta-project/scripts/caqt-agent-context.sh \
    --mode quick \
    --top 20 \
    --save-context
```

This generates:
1. **20 critical architectural questions** (TIER 1)
2. **Codebase overview** (files, languages, entry points)
3. **Detected patterns** (MVC, async, React, etc.)
4. **Proactive next steps** for agent exploration

Output saved to `.caqt-context.md` for reuse in future sessions.

---

## Integration with Session Startup

Add to your session startup workflow:

```markdown
## Session Startup Checklist
1. ✅ Register with bridge (if in meta-project)
2. ✅ Check messages
3. ✅ **Run /context** (if unfamiliar with codebase)
4. ✅ Review critical questions
5. ✅ Explore entry points
```

---

## Human Observer Mode

If uncertain about project context, invoke with human guidance:

```bash
~/devvyn-meta-project/scripts/caqt-agent-context.sh \
    --mode interactive \
    --human-guided
```

This prompts human to answer:
- What type of project?
- What should agent focus on?
- Any known issues?

Agent receives tailored contextualization based on human input.

---

## Output Format (JITS Tier 1)

```markdown
# Agent Contextualization: Architecture Questions

## Codebase Overview
- **Total Files**: 127
- **Total Lines**: 15,432
- **Languages**: .py, .js, .md
- **Entry Points**: `src/main.py`, `src/app.js`

## Critical Architectural Questions (TIER 1)

### Q1: Why does 'DataProcessor' have 23 methods?
- **Category**: Design
- **Location**: `src/data_processor.py:45`
- **Rationale**: Potential SRP violation
- **Cognitive Level**: Evaluate

[... 19 more critical questions ...]

## Next Steps for Agent
1. Read entry points
2. Answer TIER1 questions through exploration
3. Document findings
```

---

## When to Use

**Always use when**:
- First time in a new codebase
- Returning after long break (>1 week)
- Asked to work on unfamiliar module
- Human says "just explore and figure it out"

**Optional when**:
- Already familiar with codebase
- Working on well-understood module
- Human provides explicit context

---

## Abstraction: Beyond Code

The questioning pattern applies to any complex system:

```python
# Abstract interface
class ContextQuestionGenerator:
    def analyze(self, target) -> List[Question]:
        """Generate questions about target"""
        raise NotImplementedError

# Concrete implementations
class CodeQuestionGenerator(ContextQuestionGenerator):
    """Questions about code"""

class DataQuestionGenerator(ContextQuestionGenerator):
    """Questions about datasets"""

class SystemQuestionGenerator(ContextQuestionGenerator):
    """Questions about deployed systems"""
```

---

## Example: Extend for Data Science

```bash
# Analyze dataset instead of code
./caqt-generate.py --type dataset data/specimens.csv

# Generated questions:
# - Why are 15% of 'locality' fields empty?
# - What's the date range of this dataset?
# - Are there duplicate records?
# - What coordinate system is used?
```

---

## Related Commands

- `/session-handoff` - Pass context to another agent
- `/surface-discover` - Find publication interfaces
- `/bridge-send` - Send questions to domain expert

---

**Principle**: An agent in an unfamiliar environment needs questions, not answers. Questions guide exploration, answers emerge from investigation.
