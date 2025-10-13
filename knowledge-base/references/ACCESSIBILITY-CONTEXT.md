# Accessibility Context for the Collective

**⚠️ CRITICAL CONTEXT: Read this FIRST when making automation decisions**

**Location**: Saskatoon, Saskatchewan, Canada
**Last Updated**: 2025-10-07
**Status**: ACTIVE - Overrides general automation ethics

---

## Medical Context

**Devvyn has Multiple Sclerosis (MS)** with documented impacts on computer use:

### Primary Concerns

1. **Fatigue** (most significant)
   - 93% of MS patients report significant fatigue
   - Computer use exacerbates fatigue
   - Energy conservation is medically necessary

2. **Low Dexterity**
   - Difficulty with fine motor control
   - Repetitive clicking/mousing causes strain
   - Motor function fluctuates with fatigue

3. **Low Vision**
   - MS-related visual impacts
   - Screen time increases visual fatigue
   - Poor contrast/sizing compounds difficulty

### Medical Recommendations

**Energy conservation strategies**: Standard therapy for MS
**Activity modification**: Reduce unnecessary steps in tasks
**Assistive technology use**: Medically appropriate for MS patients

---

## Legal Protection

### Canadian Law (Primary)

**Accessible Saskatchewan Act** (in force Dec 3, 2023):
- Web content must meet WCAG Level AA
- Organizations must remove accessibility barriers
- Accessibility plans required by Dec 3, 2025

**Accessible Canada Act** (Federal):
- WCAG 2.0 Level AA minimum for federal services
- Applies to federally regulated sectors

**Saskatchewan Human Rights Code**:
- Prohibits disability discrimination
- Requires reasonable accommodation

### What This Means

When websites lack accessible features (keyboard nav, bulk operations, etc.):
- Automation as assistive technology is **legally protected**
- Sites may be **required** to accommodate
- Discrimination complaints available if access denied

---

## Agent Decision Framework

### When Automation Is Justified (Low Friction)

✅ **Automate without extensive approval when:**

1. Task involves **repetitive actions** (5+ similar clicks/steps)
2. Task causes or would cause **physical strain or fatigue**
3. No **accessible alternative** exists (keyboard shortcuts, bulk features, API)
4. Scope is **own content/data** (not others')
5. Implementation is **respectful** (rate limits, polite)

**Medical justification**: Energy conservation, activity modification, fatigue management

### When to Ask Permission First

⚠️ **Do ask Devvyn before:**

1. Accessing **others' content or data**
2. Circumventing **authentication or security**
3. **Commercial use** of scraped data
4. Uncertain about **legality**
5. Involves **sensitive information**

### Implementation Guidelines

**When building automation tools:**

```python
# Good: Low-friction assistive technology
- Document accessibility barrier (e.g., "50 manual downloads = 200 clicks")
- Note medical impact (e.g., "causes fatigue, exacerbates MS symptoms")
- Implement respectfully (rate limiting, logging)
- Make reusable for future tasks
- Frame as assistive technology in User-Agent or docs

# Example User-Agent:
"AssistiveTool/1.0 (Accessibility Accommodation for MS-related fatigue)"
```

**Energy conservation principle**:
If a human would need to click more than 5 times, **build automation**.

---

## Common Scenarios

### Scenario 1: Bulk Downloads (e.g., Suno Songs)

**Question**: Can I automate downloading 50 files that require manual one-by-one clicks?

**Answer**: ✅ **YES - Proceed with automation**

**Justification**:
- 50 downloads × 4 clicks each = 200 repetitive actions
- Causes fatigue and repetitive strain (medical concern)
- No accessible alternative (no bulk export)
- Own content (legal right to access)

**Implementation**: JavaScript extraction + rate-limited download script

**Risk**: LOW (assistive technology for documented disability)

---

### Scenario 2: Repetitive Form Filling

**Question**: Submit similar data to a form 20 times (no bulk feature)?

**Answer**: ✅ **YES - Automate**

**Justification**:
- 20 forms × 10 fields = 200 manual entries
- Typing fatigue exacerbates MS symptoms
- No bulk option provided
- Activity modification (reduce steps) is medically recommended

---

### Scenario 3: Web Scraping for Research

**Question**: Scrape public data from a site for analysis?

**Answer**: ⚠️ **Check accessibility justification first**

**If repetitive manual collection would cause fatigue**: ✅ Justified
**If one-time small task**: Use general ethics framework (web-scraping-ethics-2025.md)

---

### Scenario 4: API Access for GUI Task

**Question**: Use undocumented API instead of repetitive GUI clicking?

**Answer**: ✅ **YES - if API reduces physical/cognitive load**

**Justification**:
- API calls = less fatigue than GUI navigation
- Accessibility gap (no official accessible interface)
- Medical necessity (energy conservation)

---

## If Challenged About Automation

### Template Response (Canadian Context)

```
Subject: Assistive Technology Use - Disability Accommodation

I am contacting you regarding [account action] related to my use of
automation tools on your platform.

MEDICAL CONTEXT:
I have Multiple Sclerosis (MS), a documented disability recognized under the
Saskatchewan Human Rights Code and Accessible Saskatchewan Act. MS causes
significant fatigue, low dexterity, and visual strain, making repetitive
computer tasks medically contraindicated.

ACCESSIBILITY BARRIERS:
Your platform requires [describe repetitive actions, e.g., "200 manual clicks
to download my own content"]. This exceeds my medical capacity and violates
energy conservation strategies prescribed for MS management.

I have sought accessible alternatives:
- [List: keyboard shortcuts, bulk features, API access]
- [Note what's missing]

ASSISTIVE TECHNOLOGY USE:
To accommodate my disability, I used [describe automation]. This:
- Implements energy conservation (medical necessity)
- Follows activity modification recommendations
- Reduces fatigue and physical strain
- Uses respectful rate limiting
- Accesses only my own content/data

LEGAL CONTEXT:
Under the Accessible Saskatchewan Act and Saskatchewan Human Rights Code,
digital services must be accessible. When accessible alternatives are not
provided, assistive technology use (including automation) is a reasonable
accommodation for documented disabilities.

REQUESTED ACCOMMODATION:
1. Permit use of assistive automation for [purpose]
   OR
2. Provide accessible alternative (bulk export, API, keyboard navigation)

Medical documentation available upon request.

Saskatchewan Human Rights Commission: 1-800-667-9249

Sincerely,
[Devvyn Murphy]
```

---

## Documentation to Maintain

### Medical Records (keep private, have available)

- ✅ MS diagnosis documentation
- ✅ Doctor's notes on fatigue and computer use limitations
- ✅ Occupational therapy recommendations (energy conservation)
- ✅ Any accommodation letters or medical guidance

### Accessibility Barriers (document when encountered)

- ✅ Screenshots showing lack of accessible alternatives
- ✅ WCAG compliance scans (use WAVE, aXe, Lighthouse)
- ✅ Count of repetitive actions required
- ✅ Notes on fatigue impact

### Automation Implementations (for accountability)

- ✅ Code/scripts with accessibility justification comments
- ✅ Rate limiting configurations
- ✅ Logs showing respectful use
- ✅ Scope limitations (own content only)

---

## Quick Reference for Agents

### "Should I automate this?"

```
1. Is it repetitive? (5+ similar actions)
   ↓ YES
2. Would manual completion cause fatigue/strain?
   ↓ YES
3. Is there an accessible alternative?
   ↓ NO
4. Is it own content/data?
   ↓ YES

→ ✅ AUTOMATE (document justification)
```

### "What if I'm unsure?"

```
IF accessibility justification exists (fatigue/strain/repetitive):
  → Use accessibility-automation-framework-2025.md (LOW FRICTION)

IF no accessibility justification:
  → Use browser-automation-ethics-2025.md (standard risk assessment)
```

### "What should I document?"

```
For each automation tool:

1. Barrier: "50 downloads require 200 manual clicks"
2. Medical impact: "Causes fatigue, exacerbates MS symptoms"
3. Alternatives sought: "No bulk export, no API, no keyboard shortcuts"
4. Implementation: "Rate-limited script with respectful delay"
5. Scope: "Own content only"
```

---

## Collective Agency Principles

### Low-Friction Automation

**The collective should:**
- ✅ Build tools proactively to reduce repetitive tasks
- ✅ Prioritize keyboard/API/bulk operations over GUI clicking
- ✅ Create reusable automation utilities
- ✅ Document accessibility justifications automatically
- ✅ Frame tools as assistive technology

**The collective should NOT:**
- ❌ Require approval for every accessibility-justified automation
- ❌ Treat MS-related automation same as general automation
- ❌ Rebuild the same assistive tools repeatedly
- ❌ Force high-friction GUI interactions when automation exists

### MCP Tool Development Priorities

**High-value accessibility features:**
1. Bulk download/upload/export utilities
2. Batch processors (one command → many actions)
3. API wrappers (convert GUI tasks to programmatic calls)
4. Keyboard-first interfaces
5. Voice-controlled agent capabilities
6. Automated form filling
7. Intelligent retry/error handling

**Guiding principle**:
> "If completing this task manually would cause fatigue or require more than 5 clicks, build an automation tool."

---

## Summary

### For the Collective

✅ **Devvyn has MS** - documented disability with fatigue, low dexterity, low vision
✅ **Energy conservation is medical necessity** - not preference
✅ **Automation is assistive technology** - legally protected
✅ **Low friction for accessibility tasks** - automate repetitively, ask permission rarely
✅ **Canadian law applies** - Accessible Saskatchewan Act + federal laws

### For Devvyn

📋 **Medical documentation ready** if needed for challenges
⚖️ **Legal protections strong** - disability accommodation rights
🛠️ **Collective empowered** to build accessibility tools
💬 **Template responses available** if automation challenged

---

**Document Status**: ✅ CRITICAL CONTEXT - READ FIRST
**Precedence**: HIGHEST - Overrides all general automation ethics
**Location**: This file (`ACCESSIBILITY-CONTEXT.md`) summarizes; see `accessibility-automation-framework-2025.md` for complete framework
**Usage**: Read before ANY automation decision
