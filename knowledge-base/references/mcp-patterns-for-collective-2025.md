# MCP Patterns for the Collective (2025)

**Source**: OpenAI Cookbook - MCP-Powered Voice Agents
**Date**: 2025-10-08
**Applies To**: Collective agent coordination, automation, mouse elimination
**Priority**: HIGH - Practical implementation patterns

---

## Key Insight

OpenAI's MCP cookbook shows **production-ready patterns** for building MCP servers and agent coordination. These patterns are directly applicable to the collective's needs, especially for **mouse elimination** and **automation**.

**Core concept**: MCP servers expose tools that agents can invoke. This is perfect for:
- Click automation (expose "click elimination" tools)
- Workflow automation (multi-step GUI tasks)
- File operations (batch processing)
- Web automation (Puppeteer/Playwright as MCP tools)

---

## Part 1: MCP Server Implementation Pattern

### Basic Structure

```python
from mcp import Server, Tool

# Create MCP server
mcp = Server("collective-automation")

# Expose tools via decorator
@mcp.tool()
def batch_download(urls: list[str], output_dir: str) -> str:
    """Download multiple files without clicking"""
    # Implementation
    results = []
    for url in urls:
        download_file(url, output_dir)
        results.append(f"Downloaded: {url}")
    return "\n".join(results)

@mcp.tool()
def automate_form_filling(form_url: str, data_csv: str) -> str:
    """Fill form repeatedly from CSV data (no clicking)"""
    # Puppeteer automation
    browser = launch_browser()
    for row in read_csv(data_csv):
        navigate(form_url)
        fill_form(row)
        submit()
    return f"Submitted {len(rows)} forms"
```

**Key pattern**:
- Decorator-based tool registration (`@mcp.tool()`)
- Type hints for validation
- Docstrings become tool descriptions
- Return structured results

---

## Part 2: Agent Coordination Pattern

### Agent Definition

```python
from agent import Agent

# Define agent with MCP servers
automation_agent = Agent(
    name="ClickEliminator",
    instructions="""
    You help eliminate mouse clicking by automating repetitive tasks.
    Use available tools to handle bulk operations, web automation,
    and file processing. Always prefer automation over manual clicking.
    """,
    mcp_servers=[
        automation_server,  # Click elimination tools
        file_ops_server,    # Batch file operations
        web_server         # Browser automation
    ],
    model="gpt-4o-mini"  # Fast model for quick responses
)
```

**Key pattern**:
- Agent has instructions (system prompt)
- Multiple MCP servers can be attached
- Each server exposes related tools
- Agent chooses appropriate tools based on task

---

## Part 3: Application to Mouse Elimination

### Use Case 1: Suno Downloads (Already Built)

**Traditional approach** (what we did):
- Standalone scripts
- Manual execution

**MCP approach** (evolution):
```python
@mcp.tool()
def download_suno_library(output_dir: str = "~/Music/Suno") -> str:
    """Download all songs from Suno library (eliminates 200+ clicks)"""
    # Use existing scripts
    extract_urls()
    download_files(urls, output_dir, rate_limit=2)
    return f"Downloaded {len(urls)} songs to {output_dir}"
```

**Benefit**: Agent can invoke this tool naturally
```
User: "Agent, download my Suno library"
Agent: *invokes download_suno_library tool*
Agent: "Downloaded 50 songs to ~/Music/Suno"
```

---

### Use Case 2: Batch File Operations

**Problem**: Organizing Downloads folder requires lots of clicking

**MCP Solution**:
```python
@mcp.tool()
def organize_downloads(source_dir: str = "~/Downloads") -> str:
    """Organize files by type without clicking"""
    stats = {
        'pdfs': 0,
        'images': 0,
        'videos': 0,
        'docs': 0
    }

    # Move files to organized folders
    for file in scan_directory(source_dir):
        category = classify_file(file)
        destination = f"{source_dir}/{category}/"
        move_file(file, destination)
        stats[category] += 1

    return f"Organized: {stats}"

@mcp.tool()
def batch_rename_files(directory: str, pattern: str) -> str:
    """Rename multiple files by pattern (no clicking each one)"""
    files = glob.glob(f"{directory}/*")
    renamed = []
    for i, file in enumerate(files):
        new_name = pattern.format(index=i, original=Path(file).stem)
        os.rename(file, new_name)
        renamed.append(new_name)
    return f"Renamed {len(renamed)} files"
```

---

### Use Case 3: Web Automation

**Problem**: Repetitive web form filling, navigation, data extraction

**MCP Solution**:
```python
@mcp.tool()
def automate_web_workflow(workflow_description: str) -> str:
    """Execute multi-step web workflow without clicking"""
    # Parse workflow (could use LLM to interpret)
    steps = parse_workflow(workflow_description)

    browser = launch_puppeteer()
    for step in steps:
        if step.type == "navigate":
            browser.goto(step.url)
        elif step.type == "click":
            browser.click(step.selector)
        elif step.type == "fill":
            browser.fill(step.selector, step.value)
        elif step.type == "submit":
            browser.submit(step.selector)

    return "Workflow completed"

@mcp.tool()
def extract_data_from_pages(urls: list[str], selector: str) -> str:
    """Extract data from multiple pages (no manual clicking)"""
    results = []
    for url in urls:
        page = fetch_page(url)
        data = page.select(selector)
        results.append(data)
    return json.dumps(results)
```

---

## Part 4: Collective-Specific Architecture

### Proposed MCP Server Structure

```
collective-automation/
├── servers/
│   ├── click_elimination_server.py     # Puppeteer/Playwright tools
│   ├── file_operations_server.py       # Batch file ops
│   ├── download_server.py              # Bulk downloads
│   ├── form_automation_server.py       # Form filling
│   └── state_monitoring_server.py      # Fatigue detection (future)
│
├── agents/
│   ├── click_eliminator_agent.py       # Mouse reduction specialist
│   ├── code_agent.py                   # Existing Code Agent
│   └── chat_agent.py                   # Existing Chat Agent
│
└── config/
    ├── mcp_config.json                 # Server configurations
    └── agent_instructions/             # System prompts
```

### Integration with Existing Bridge

**Hybrid approach** (best of both worlds):

```python
# MCP server that uses existing bridge scripts
@mcp.tool()
def bridge_send_message(to_agent: str, subject: str, content: str) -> str:
    """Send message via existing bridge system"""
    import subprocess
    subprocess.run([
        "~/devvyn-meta-project/scripts/bridge-send.sh",
        "code", to_agent, "NORMAL", subject, content
    ])
    return f"Message sent to {to_agent}"

@mcp.tool()
def bridge_check_messages() -> str:
    """Check for incoming messages via bridge"""
    result = subprocess.run([
        "~/devvyn-meta-project/scripts/bridge-receive.sh",
        "code"
    ], capture_output=True, text=True)
    return result.stdout
```

**Benefit**: MCP agents can use existing bridge infrastructure while we build out MCP-native features.

---

## Part 5: Voice Integration (Optional, for Future)

### Pattern from Cookbook

```python
# Voice workflow chain (when needed later)
def voice_agent_pipeline(audio_input):
    # 1. Speech-to-Text
    text = transcribe_audio(audio_input)

    # 2. Agent planning and tool invocation
    response = agent.run(text)

    # 3. Text-to-Speech
    audio_output = synthesize_speech(response)

    return audio_output
```

**Current priority**: LOW (keyboard is working, focus on mouse reduction)

**Future application**: When voice is needed, this pattern is ready.

---

## Part 6: Practical Implementation Steps

### Phase 1: MCP Server for Mouse Elimination (2-3 weeks)

**Week 1: Setup**
```bash
# Install MCP Python SDK
uv add anthropic-mcp

# Create server structure
mkdir -p ~/devvyn-meta-project/mcp/servers
mkdir -p ~/devvyn-meta-project/mcp/agents
```

**Week 2: Build Core Tools**

Implement 5-10 high-impact tools:
```python
1. batch_download()           # Replace clicking "Save" repeatedly
2. organize_files()           # Replace manual Finder dragging
3. automate_form_filling()    # Replace repetitive form clicks
4. batch_rename()             # Replace right-click → rename × N
5. web_data_extraction()      # Replace manual copy-paste clicking
6. pdf_operations()           # Replace Adobe clicking
7. git_operations()           # Replace GUI git client clicks
8. bulk_image_processing()    # Replace Photoshop clicking
9. screenshot_automation()    # Replace manual screenshot clicks
10. clipboard_workflows()     # Replace copy-paste clicking
```

**Week 3: Agent Integration**

Create ClickEliminator agent that uses these tools.

---

### Phase 2: Real-World Testing (1-2 weeks)

**Track clicking patterns**:
```python
@mcp.tool()
def log_clicking_task(description: str, estimated_clicks: int) -> str:
    """Log when you encounter a clicking task"""
    log_entry = {
        "timestamp": datetime.now(),
        "description": description,
        "estimated_clicks": estimated_clicks,
        "automated": False
    }
    append_to_log("clicking_tasks.json", log_entry)
    return "Logged for future automation"
```

**Build automations for logged tasks**:
- Review clicking_tasks.json weekly
- Create MCP tools for top patterns
- Measure click reduction

---

### Phase 3: Advanced Features (2-3 weeks)

**State-aware automation**:
```python
@mcp.tool()
def adaptive_automation(task: str, fatigue_level: str = "normal") -> str:
    """Adjust automation based on current state"""
    if fatigue_level == "high":
        # Use more automation, less confirmation
        auto_confirm = True
    else:
        # Ask before automating
        auto_confirm = False

    execute_task(task, auto_confirm)
```

**Learning from patterns**:
```python
@mcp.tool()
def suggest_automation_for_task(task_description: str) -> str:
    """Analyze task and suggest automation approach"""
    # Use LLM to understand task
    # Match to existing tools
    # Suggest new tool if needed
    return suggestions
```

---

## Part 7: Success Metrics

### Quantitative

**Week 1**:
- ✅ 5 MCP tools implemented
- ✅ Basic ClickEliminator agent functional
- ✅ Can automate 1-2 common clicking tasks

**Week 4**:
- ✅ 10+ MCP tools available
- ✅ Agent handles most repetitive clicking tasks
- ✅ 50% reduction in daily clicking measured

**Week 8**:
- ✅ 20+ MCP tools
- ✅ 80% of repetitive clicking automated
- ✅ Reusable toolkit documented

### Qualitative

- ✅ Natural language → automation ("Agent, organize my downloads")
- ✅ No need to remember script names
- ✅ Agent suggests automation for new clicking patterns
- ✅ Reduced hand/wrist pain (self-reported)

---

## Part 8: Key Advantages of MCP Approach

### vs. Standalone Scripts

**Standalone** (current Suno toolkit):
```bash
# Must remember script names
./02-download.sh urls.txt

# Must manually coordinate steps
./extract-urls.js
pbpaste > urls.txt
./download.sh urls.txt
```

**MCP** (future):
```
User: "Download my Suno library"
Agent: *automatically coordinates tools*
Agent: "Downloaded 50 songs"
```

### vs. Direct Agent Calls

**Direct** (agent writes code on the fly):
- Slower (generates code each time)
- Less reliable (might have bugs)
- No reusability

**MCP** (predefined tools):
- Fast (pre-built, tested)
- Reliable (used repeatedly)
- Reusable (other agents can use same tools)

---

## Part 9: OpenAI Cookbook Patterns Applied

### Pattern 1: Low-Latency Models

**From cookbook**: Use "gpt-4o-mini" for fast responses

**Applied to collective**:
```python
# Quick responses for automation tasks
quick_agent = Agent(
    model="gpt-4o-mini",  # Fast
    mcp_servers=[automation_server]
)

# Deep thinking for complex problems
research_agent = Agent(
    model="claude-sonnet-4-5",  # Thorough
    mcp_servers=[research_server]
)
```

### Pattern 2: Modular Server Design

**From cookbook**: Separate servers for different capabilities

**Applied to collective**:
```
search_server     → Web search tools
sql_server        → Database queries
automation_server → Click elimination
file_ops_server   → Batch file operations
```

### Pattern 3: Tool Composition

**From cookbook**: Chain tools for complex workflows

**Applied to collective**:
```python
# Agent can compose tools:
# 1. extract_urls()
# 2. batch_download()
# 3. organize_files()
# → Complete workflow without clicking
```

---

## Part 10: Immediate Next Steps

### This Week

1. **Install MCP SDK**:
   ```bash
   uv add anthropic-mcp
   ```

2. **Create prototype MCP server**:
   ```python
   # ~/devvyn-meta-project/mcp/servers/prototype.py
   from mcp import Server

   mcp = Server("prototype")

   @mcp.tool()
   def test_automation(task: str) -> str:
       return f"Would automate: {task}"
   ```

3. **Test with Claude Code**:
   - Run MCP server
   - Invoke tool from Code Agent
   - Verify integration works

### Next 2 Weeks

4. **Build 5 mouse-elimination tools**:
   - batch_download
   - organize_files
   - batch_rename
   - web_automation
   - pdf_operations

5. **Create ClickEliminator agent**

6. **Test on real tasks** (log results)

---

## Part 11: Learning from OpenAI's Approach

### What They Got Right

✅ **MCP as standardization layer**: One protocol, many tools
✅ **Decorator-based registration**: Clean, Pythonic
✅ **Agent-server separation**: Agents use tools, don't implement them
✅ **Low-latency emphasis**: Fast models for voice/automation
✅ **Production-ready patterns**: Actually deployable code

### What We Can Improve

✅ **Accessibility focus**: OpenAI's example is general-purpose; ours is medical-necessity
✅ **Mouse elimination**: They focus on voice; we focus on clicking reduction
✅ **Bridge integration**: Hybrid approach leverages existing infrastructure
✅ **State awareness**: Fatigue-aware automation (not in their example)

---

## Summary

**Key Takeaway**: OpenAI's MCP cookbook validates that MCP is production-ready for building automation tools. The patterns are directly applicable to mouse elimination.

**Recommended Path**:
1. **Week 1-2**: Build prototype MCP server with 5 tools
2. **Week 3-4**: Create ClickEliminator agent, test on real tasks
3. **Week 5-8**: Expand toolkit, measure click reduction
4. **Month 3+**: Advanced features (state awareness, learning)

**Expected Impact**:
- 50% click reduction in 4 weeks
- 80% click reduction in 8 weeks
- Natural language automation ("Agent, do X")
- Reusable toolkit for collective

**This is Track 2** (technical thrills) that **enables Track 1** (accessibility). Building MCP infrastructure is interesting technical work that directly reduces forced mousing difficulty.

---

**Document Status**: ✅ ACTIVE - Practical implementation guide
**Source**: OpenAI Cookbook + Collective needs synthesis
**Next Action**: Install MCP SDK, build prototype
**Priority**: HIGH - Directly addresses mouse elimination
