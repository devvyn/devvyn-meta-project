# 🎓 Conmigo Terminal - AI-Powered Learning Station

> *"With me" in learning - A terminal-based study companion inspired by Khan Academy's Khanmigo*

## Philosophy

**Learn through discovery, not answers.**

Like Khan Academy's Khanmigo, this system uses the Socratic method - guiding you to discover solutions through questions rather than providing direct answers. It's Git for your learning journey.

## Quick Start

### 1. Add to PATH

```bash
echo 'export PATH="$HOME/devvyn-meta-project/study-station/scripts:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### 2. Start Your First Session

```bash
study start python-decorators
```

### 3. Ask Questions

```bash
study ask "How do decorators modify function behavior?"
```

### 4. Get Guided Help

```bash
# In Claude Code, use:
/study

# For practice exercises:
/practice

# For review sessions:
/review
```

## Core Commands

### Session Management

```bash
study start <topic> [mode]      # Start new session
study status                    # Check current session
study list                      # List all sessions
study export [session]          # Export to browser
```

### Learning Interaction

```bash
study ask <question>            # Ask a question (logs to session)
study hint [1-4]                # Request hint (escalating levels)
study practice <topic>          # Start practice mode
study review                    # Review previous learning
study mastery <topic>           # Check mastery level
```

## Learning Modes

### 🔍 Explore

Open-ended exploration of a topic

```bash
study start rust-ownership explore
```

### 💪 Practice

Structured exercises with guided feedback

```bash
study practice python-async
```

### 🔄 Review

Spaced repetition review of previous concepts

```bash
study review
```

### 🐛 Debug

Debug code with AI guidance (no direct answers!)

```bash
study start "bug-hunting" debug
```

### 🏗️ Build

Build a project with milestone tracking

```bash
study start "rest-api" build
```

## Hint System

When stuck, request escalating levels of help:

- **Level 1 - Nudge**: Subtle pointer

  ```bash
  study hint 1
  ```

  *"What happens if you try...?"*

- **Level 2 - Clarify**: Concept explanation

  ```bash
  study hint 2
  ```

  *"Let's think about how [concept] works..."*

- **Level 3 - Example**: Similar case

  ```bash
  study hint 3
  ```

  *"Here's an analogous situation..."*

- **Level 4 - Walkthrough**: Step-by-step (last resort!)

  ```bash
  study hint 4
  ```

  *"Let's work through this together..."*

## Claude Code Integration

### Slash Commands

- **/study** - Activate Socratic learning mode
- **/practice** - Generate practice exercises
- **/review** - Conduct spaced repetition review

### Workflow

1. Start a session in terminal:

   ```bash
   study start databases
   ```

2. Open the session file in your editor

   ```bash
   open ~/devvyn-meta-project/study-station/sessions/[latest].md
   ```

3. In Claude Code, type:

   ```
   /study
   ```

4. Ask questions and explore - Claude will guide you through discovery!

## Directory Structure

```
~/devvyn-meta-project/study-station/
├── config.yaml              # Configuration
├── sessions/                # Individual study sessions
│   └── YYYYMMDDHHMMSS-topic.md
├── topics/                  # Organized by subject
│   └── python/
│       ├── decorators/
│       └── async/
├── progress/                # Learning progress tracking
│   └── topic/
│       └── mastery.yaml
├── templates/               # Session templates
│   ├── socratic-prompt.md
│   └── exercise-template.md
├── artifacts/               # Generated code, exercises
│   └── topic/
└── scripts/                 # CLI tools
    └── study
```

## Progress Tracking

### Mastery Levels

1. 🌱 **Learning** - Just introduced
2. 🌿 **Familiar** - Can recognize concepts
3. 🌳 **Comfortable** - Can explain clearly
4. ⭐ **Confident** - Can apply independently
5. 🏆 **Mastered** - Can teach others

### Spaced Repetition

The system tracks when you last studied each topic and suggests review intervals:

- Learning → Review in **1 day**
- Familiar → Review in **3 days**
- Comfortable → Review in **7 days**
- Confident → Review in **14 days**
- Mastered → Review in **30 days**

```bash
study mastery rust-lifetimes
```

## Example Session

```bash
# Start session
$ study start "rust-lifetimes" explore

✓ Started new explore session: rust-lifetimes

# Ask question
$ study ask "Why do we need lifetime annotations?"

Question logged: Why do we need lifetime annotations?

🤔 Instead of answering directly, let me guide you...

# Open in Claude Code with /study command
# Claude guides through discovery with questions like:
# "What problem occurs when you have multiple references?"
# "Try this: create two string slices and return one..."
# "What does the compiler error tell you?"

# Request hint when stuck
$ study hint 2

Level 2: Clarify - Concept clarification
Ask Claude Code to clarify the underlying concept.

# Check progress
$ study status

Active Session
─────────────────────────────────────
Topic:    rust-lifetimes
Session:  20251013160000-rust-lifetimes
Lines:    45
Questions: 3

# Export when done
$ study export
✓ Exported to browser
```

## Best Practices

### 🎯 Set Clear Learning Objectives

Start each session knowing what you want to learn:

```markdown
## Learning Objectives

- Understand when lifetime annotations are needed
- Practice writing lifetime syntax
- Debug common lifetime errors
```

### 🧪 Experiment Before Asking

Try things! Make mistakes! The best learning comes from exploration:

1. Form a hypothesis
2. Test it
3. Observe results
4. Ask guided questions

### 📝 Document Insights

Capture "aha!" moments in your session:

```markdown
## Key Insights

- Lifetime annotations don't change how long objects live
- They tell the compiler about relationships between references
- Most of the time, the compiler infers lifetimes
```

### 🔄 Review Regularly

Use spaced repetition:

```bash
study review
```

### 🚫 Resist Direct Answers

The system won't give you answers - that's a feature!

- Struggle is part of learning
- Discovery creates deeper understanding
- Questions lead to insights

## Configuration

Edit `~/devvyn-meta-project/study-station/config.yaml`:

```yaml
ai_behavior:
  never_give_direct_answers: true  # Core principle!
  ask_guiding_questions: true
  encourage_discovery: true

progress_tracking:
  use_spaced_repetition: true
  track_mastery_level: true
  review_intervals: [1, 3, 7, 14, 30]
```

## Integration with Knowledge Base

Sessions can reference your knowledge base:

```bash
# Session notes link to KB articles
See also: ~/devvyn-meta-project/knowledge-base/programming/rust/lifetimes.md
```

## Tips for Effective Learning

### For New Topics

1. Start with "explore" mode
2. Ask lots of "why" and "how" questions
3. Build small experiments
4. Document discoveries

### For Skill Building

1. Use "practice" mode
2. Do progressively harder exercises
3. Apply concepts in different contexts
4. Review error messages carefully

### For Review

1. Use "review" mode regularly
2. Try to recall before looking
3. Test yourself with examples
4. Teach concepts back to Claude

### For Debugging

1. Use "debug" mode
2. Describe what you observe
3. Form hypotheses
4. Test systematically
5. Learn from error messages

## Troubleshooting

### Session file not created?

```bash
# Check directory exists
ls ~/devvyn-meta-project/study-station/sessions/

# Check permissions
ls -la ~/devvyn-meta-project/study-station/
```

### Slash commands not working?

```bash
# Verify commands are installed
ls -la ~/.claude/commands/

# Should see: study.md, practice.md, review.md
```

### Can't find study command?

```bash
# Add to PATH
echo 'export PATH="$HOME/devvyn-meta-project/study-station/scripts:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## Advanced Features

### Custom Learning Modes

Create your own in `config.yaml`:

```yaml
learning_modes:
  deep_dive:
    description: "Intensive deep dive into complex topic"
    prompt_style: "detailed"
    requires_prerequisites: true
```

### Session Templates

Create templates in `templates/` directory for repeated workflows.

### Progress Analytics

Track your learning journey:

```bash
# View all progress
find ~/devvyn-meta-project/study-station/progress -name "*.yaml"

# Analyze patterns
rg "mastery_level:" ~/devvyn-meta-project/study-station/progress/
```

## Philosophy & Research

This system is inspired by:

- **Khanmigo** (Khan Academy) - Socratic tutoring
- **Spaced Repetition** - Optimize review timing
- **Active Learning** - Learn by doing
- **Growth Mindset** - Embrace challenge

## Contributing

Improve your learning system:

1. Add new learning modes to `config.yaml`
2. Create session templates
3. Build custom commands
4. Share successful patterns

## Resources

- [Khan Academy - Khanmigo](https://www.khanmigo.ai)
- [Socratic Method](https://en.wikipedia.org/wiki/Socratic_method)
- [Spaced Repetition](https://en.wikipedia.org/wiki/Spaced_repetition)
- [Active Learning Research](https://www.pnas.org/doi/10.1073/pnas.1319030111)

---

**Version:** 0.1.0
**Created:** 2025-10-13
**License:** Personal use

*Happy learning! 🚀*
