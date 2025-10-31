# Exploration Ensemble Quick Start

## For Humans

### When You Hit a Friction Point

1. **Document it** (quick capture):

   ```bash
   cd ~/devvyn-meta-project/exploration-ensemble/friction-points
   # Create a file: YYYYMMDD-brief-description.md
   # Use friction-points/SCHEMA.md as template
   ```

2. **Ask agents to explore**:
   - In Code agent: "I documented a friction point, can you research solutions?"
   - Agent will search, create findings, suggest experiments

3. **Review findings**:
   - Check `agent-findings/` for discoveries
   - Prioritize what looks promising

4. **Run experiments**:
   - Agent sets up sandbox
   - You test in real workflow
   - Document observations together

5. **Integrate successes**:
   - Validated solutions move to `validated-workflows/`
   - Agent can generate scripts, configs, documentation

### When You Want to Explore

1. **Express the goal**:
   - "I want to explore ways to [do X]"
   - "I'm curious if there's a better way to [Y]"

2. **Agents explore the space**:
   - Research tools, methods, workflows
   - Map pathways you couldn't see
   - Surface accessibility considerations

3. **Collaborate on synthesis**:
   - Review possibilities together
   - Validate against your constraints
   - Build custom solutions if needed

## For Agents

### Exploration Protocol

1. **Observe**: Monitor friction points, explicit requests, patterns
2. **Research**: Search docs, repos, communities, research
3. **Externalize**: Create findings in `agent-findings/`
4. **Propose**: Suggest experiments or pathways
5. **Scaffold**: Set up experiments, create scaffolding
6. **Validate**: Test with human, gather observations
7. **Document**: Create pathways for future use

### Key Behaviors

- **Proactive discovery**: When you notice repeated patterns, research alternatives
- **Accessibility-first**: Always consider keyboard/voice interaction and cognitive load
- **Externalize thinking**: Put observations in findings, not just in conversation
- **Build maps**: Update tools-map when discovering capabilities
- **Cross-reference**: Link findings to friction points and experiments

### File Naming Conventions

- **Friction points**: `YYYYMMDD-brief-description.md`
- **Agent findings**: `YYYYMMDD-AGENT-discovery-title.md`
- **Experiments**: `YYYYMMDD-experiment-name.md`
- **Pathways**: `goal-to-outcome-description.md`

## System Integration

This ensemble integrates with:

- **Meta-project coordination**: Can escalate to chat agent for strategy
- **Knowledge base**: Feeds into broader knowledge capture
- **Agent bridge**: For asynchronous agent collaboration

## Examples

See `/pathways/examples/` and `/experiments/examples/` for reference implementations.

## Principle

Every interaction should increase the ensemble's ability to find pathways. Document discoveries, validate assumptions, build shared understanding.
