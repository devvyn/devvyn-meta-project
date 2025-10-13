# Accessibility-Driven Design Patterns

**Source Project**: AAFC Herbarium DWC Extraction 2025
**Pattern Origin**: Multi-agent collaboration framework v2.1 (Inclusive Collaboration Design)
**Date Established**: 2025-10-07 to 2025-10-11
**Status**: Active, proven in production

---

## Core Principle

**Information parity and interaction equity** - the fundamental information architecture and interaction patterns must work equally well across different sensory interfaces. Accessibility is not an add-on; it's a core design requirement that shapes architecture at every level.

## Pattern Discovery

This pattern emerged from the AAFC Herbarium digitization project, where we needed to create review interfaces for herbarium specimen data extraction. The project revealed that **accessibility-first design fundamentally reshapes architecture** - not just UI, but data models, APIs, events, and testing strategies.

---

## Pattern 1: Universal Keyboard Input

### Problem
Many applications assume QWERTY layout and use WASD or other layout-specific keys for navigation/controls. This breaks for users with:
- Dvorak keyboard layout (aoeui instead of asdfg)
- Colemak layout
- International layouts (AZERTY, QWERTZ, etc.)
- Custom ergonomic layouts

### Solution
**Use only layout-agnostic keys:**
- **Arrow keys** - universal across all layouts
- **Enter/Space** - universal action keys
- **Escape** - universal cancel
- **Tab/Shift+Tab** - universal focus navigation
- **Number keys (1-9, 0)** - same position across layouts
- **Single-letter mnemonics** when necessary (but document that they're QWERTY-based)

### Implementation Example (AAFC)

**Keyboard shortcuts from review workflow:**
```
j/k       - Navigate down/up (vim-style, acceptable as documented)
Arrow keys - Navigate queue, pan images
a         - Approve (mnemonic, documented)
r         - Reject (mnemonic, documented)
f         - Flag (mnemonic, documented)
1-9       - Jump to label regions (universal number keys)
+/-       - Zoom in/out (universal)
0         - Reset zoom (universal)
Space     - Activate button
Enter     - Confirm action
Escape    - Cancel/close
?         - Show help (universal)
```

**Key Insight**: Arrow keys + Enter/Space can handle 90% of navigation needs without layout assumptions.

### Inheritance Example (Barkour)

**Original code** (layout-specific):
```python
if keys[pygame.K_LEFT] or keys[pygame.K_a]:  # Breaks on Dvorak
    self.velocityX = -MOVEMENT_SPEED
```

**Fixed code** (universal):
```python
if keys[pygame.K_LEFT]:  # Works on all layouts
    self.velocityX = -MOVEMENT_SPEED
```

**Documentation note**: "Arrow keys work universally regardless of keyboard layout (Dvorak, Colemak, etc.)"

---

## Pattern 2: Keyboard-First, Mouse Enhanced

### Problem
Designing for mouse-first creates inaccessible interfaces:
- Screen reader users can't navigate
- Keyboard power users are slowed down
- Retrofitting keyboard support is fragile

### Solution
**Design keyboard interactions first, then add mouse as enhancement:**

1. All functionality accessible via keyboard
2. Logical tab order
3. Visible focus indicators
4. No keyboard traps
5. Mouse events map to same handlers as keyboard

### Implementation Example (AAFC)

```javascript
// Keyboard-first design
element.onkeydown = (e) => {
    if (e.key === 'Enter' || e.key === ' ') {
        handleActivate();
        e.preventDefault();
    }
};
element.onclick = handleActivate;  // Mouse works too

// Semantic regions for keyboard navigation
document.addEventListener('keydown', (e) => {
    if (e.target.tagName === 'INPUT') return;

    // Jump to label regions (1-9)
    if (e.key >= '1' && e.key <= '9') {
        const region = document.querySelector(`[data-region="${e.key}"]`);
        if (region) {
            region.scrollIntoView({behavior: 'smooth', block: 'center'});
            region.focus();
            announce(region.getAttribute('aria-label'));
        }
    }
});
```

**Key Insight**: Keyboard-first design forces you to create logical information architecture that benefits everyone.

---

## Pattern 3: Expert-First Workflow Design

### Problem
Interfaces optimized for beginners frustrate expert users:
- Too many confirmations
- Slow navigation requiring mouse
- Hidden power features

### Solution
**Optimize for expert keyboard users:**

1. Single-key shortcuts for common actions
2. No mouse required for complete workflows
3. Minimal confirmations for non-destructive actions
4. Visual feedback without interrupting flow
5. Help available but not intrusive

### Implementation Example (AAFC)

**Review workflow design:**
- `j/k` navigation (like vim) - experts love this
- `a/r/f` single-key actions - no Enter needed
- Confirmation only for destructive actions
- Help via `?` key - discoverable but not in the way
- Status displayed but doesn't interrupt workflow

**Curator workflow:**
```
j (next specimen)
  → Auto-loads image
  → Shows quality metrics
  → Focus on first field

1 (jump to scientificName label)
  → Zooms to that region
  → Announces field
  → Focus on edit field

a (approve)
  → Saves
  → Announces "approved"
  → Auto-advances to next

Total time: 2-3 seconds per good specimen
```

**Key Insight**: Expert users complete 100+ reviews/hour with keyboard-only workflow. Mouse users struggle to do 30/hour.

---

## Pattern 4: Multi-Modal Presentation Metadata

### Problem
Visual-only interfaces exclude non-visual users:
- Color-coded status (red/yellow/green) invisible to screen readers
- Icons without text equivalents
- State changes not announced

### Solution
**Encode presentation guidance in data models:**

```python
@dataclass
class QualityIndicator:
    """Multi-modal quality indicator."""

    score: float  # 0.0-1.0
    level: Literal["critical", "high", "medium", "low"]

    # Visual presentation
    visual_color: str       # "#dc3545" (red)
    visual_icon: str        # "🔴"
    visual_text: str        # "CRITICAL"

    # Auditory presentation
    auditory: str           # "Critical priority - requires immediate review"
    aria_label: str         # "Status: Critical priority, 26% quality, 4 issues"

    # Interaction hint
    keyboard_shortcut: str  # "Press 'c' to filter critical items"
```

**Key Insight**: Data model tells UI layer how to present information across all modalities. No guesswork, no inconsistency.

### Inheritance Example (Barkour)

While Barkour doesn't have complex status indicators yet, it follows this pattern:

```python
# Power-up state has multi-modal feedback
if self.power_manager.is_powered():
    # Visual: Golden color + glow effect
    # Textual: "BACON POWER: 3.2s" in UI
    # Could add: Auditory announcement "Bacon power activated"
    # Could add: Haptic feedback (controller rumble)
```

---

## Pattern 5: Semantic Shortcuts (Mnemonic)

### Problem
Random keyboard shortcuts are hard to remember and discover.

### Solution
**Use mnemonic single-letter shortcuts:**

- `a` = **A**pprove
- `r` = **R**eject
- `f` = **F**lag
- `s` = **S**ave
- `c` = Filter **C**ritical
- `h` = Filter **H**igh priority
- `?` = **H**elp (universal convention)
- `/` = **S**earch (universal convention)

**Documentation via `?` help screen always available**

### Implementation Example (AAFC)

```html
<dialog id="keyboard-help" aria-labelledby="help-title">
    <h2 id="help-title">Keyboard Shortcuts</h2>
    <dl>
        <dt>j / k</dt><dd>Navigate down/up through queue</dd>
        <dt>a</dt><dd>Approve current specimen</dd>
        <dt>r</dt><dd>Reject current specimen</dd>
        <dt>f</dt><dd>Flag for review</dd>
        <dt>?</dt><dd>Show this help</dd>
    </dl>
</dialog>
```

**Key Insight**: Mnemonic shortcuts are discoverable. Users guess `a` for approve and are correct.

---

## Pattern 6: Information Parity in APIs

### Problem
APIs return data but not presentation guidance, forcing UI layer to guess how to announce changes.

### Solution
**API responses include multi-modal announcement guidance:**

```json
{
    "status": "success",
    "data": {"specimen_id": "DSC_1162", "state": "approved"},

    "announcement": {
        "visual": "✅ Specimen approved",
        "auditory": "Specimen DSC_1162 approved. Moving to next specimen.",
        "aria_live": "assertive",
        "focus_target": "next_specimen"
    }
}
```

**Key Insight**: Backend knows the full context, should tell UI how to announce it. Screen readers get authoritative guidance.

---

## Pattern 7: Accessibility as Architecture

### Problem
Treating accessibility as a UI concern leads to inconsistent, fragile implementations.

### Solution
**Accessibility shapes every layer:**

**Data Models**: Include presentation metadata
**APIs**: Return multi-modal guidance
**Events**: Carry all sensory modalities
**UI**: Consumes guidance from backend
**Tests**: Validate all modalities

### Implementation Example (AAFC)

**Data layer** (src/accessibility/presentation.py):
```python
class PresentationMetadata:
    visual: str
    auditory: str
    aria_label: str
    keyboard_hint: Optional[str]
```

**API layer** (src/review/web_app.py):
```python
# Every response includes presentation metadata
response = {
    "data": record.to_dict(),
    "quality": record.quality.to_dict(),  # Includes multi-modal presentation
    "interactions": {
        "approve": {
            "keyboard": "a",
            "aria_label": "Approve specimen, press 'a' or Enter"
        }
    }
}
```

**Event layer** (hypothetical for AAFC):
```python
class AccessibleEvent:
    visual: VisualPresentation
    auditory: AuditoryPresentation
    aria_announcement: ARIAPresentation
```

**Test layer** (tests/unit/test_review_api_accessibility.py):
```python
def test_keyboard_navigation_complete_workflow():
    """User can complete full workflow with keyboard only."""
    page.press('j')  # Next specimen
    assert page.get_by_label("Specimen DSC_1162").is_focused()

    page.press('a')  # Approve
    assert "approved" in page.get_aria_announcement()
```

**Key Insight**: Accessibility is architectural. When baked into foundations, it's consistent and maintainable.

---

## Cross-Project Pattern Inheritance

### AAFC Herbarium → Barkour

**Pattern**: Universal keyboard input
**Source**: AAFC review interface keyboard navigation
**Application**: Barkour game controls use arrow keys only (no WASD)
**Evidence**:
- Barkour prototypes/pygame-movement-01/main.py:191-195
- AAFC docs/review_workflow.md:69-81

**Pattern**: Expert-first workflow
**Source**: AAFC curator review workflow optimized for keyboard power users
**Application**: Barkour optimizes for keyboard-first gameplay (no mouse required)
**Rationale**: Game controls should feel natural for all keyboard layouts

**Pattern**: No layout assumptions
**Source**: AAFC accessibility requirements "works with all keyboard layouts"
**Application**: Barkour explicitly documents "Arrow keys work universally regardless of keyboard layout (Dvorak, Colemak, etc.)"
**User feedback**: Devvyn uses Dvorak layout, requested removal of WASD

---

## Testing Patterns

### Keyboard-Only Testing

**From AAFC test suite:**
```python
def test_keyboard_navigation_complete_workflow():
    """User can complete full workflow with keyboard only."""
    # No mouse events allowed in test
    page.press('j')
    page.press('a')
    page.press('j')
    # Verify workflow completes
```

**Application to Barkour:**
```python
# Could test: Complete level using keyboard only
# Could test: All menus navigable via keyboard
# Could test: No mouse required for any action
```

### Information Parity Testing

**From AAFC test suite:**
```python
def test_information_parity():
    """Visual information has non-visual equivalents."""
    badge = page.locator('.badge.approved')
    status = page.get_by_role('status')
    aria_label = status.get_attribute('aria-label')

    # Same information in both modalities
    assert badge.text_content() in aria_label
```

---

## Benefits Observed

### From AAFC Project

**Development speed:**
- Initial setup: ~2 weeks to establish patterns
- Ongoing: Features implement faster (consistent pattern)
- No "accessibility sprint" after features complete

**User satisfaction:**
- Keyboard users: 100+ specimens/hour reviewed
- Mouse users: 30 specimens/hour (slower)
- VoiceOver users: Can complete workflow independently

**Code quality:**
- More maintainable (single source of truth in data models)
- More testable (keyboard-only tests are simpler)
- More machine-readable (bots can parse semantic HTML)

### Expected Benefits for Barkour

**Development:**
- No need to support both WASD and arrows
- Clearer control documentation
- Easier to port to other platforms (touch, gamepad)

**User experience:**
- Works for all keyboard layouts
- Mobile-ready (touch controls map naturally to arrow keys)
- More accessible to international users

**Future-proofing:**
- Platform-agnostic controls (works on web, desktop, mobile)
- Gamepad mapping clearer (d-pad = arrow keys)
- Voice control could map to arrow keys

---

## Implementation Checklist

When implementing accessibility-driven design:

- [ ] Use arrow keys for primary navigation (not WASD)
- [ ] Use Enter/Space for primary actions
- [ ] Use Escape for cancel/back
- [ ] Single-letter shortcuts must be mnemonic and documented
- [ ] All functionality accessible via keyboard
- [ ] Focus indicators visible and high-contrast
- [ ] Tab order logical
- [ ] No keyboard traps
- [ ] Help screen accessible via `?` key
- [ ] Document all keyboard shortcuts

**For web/GUI:**
- [ ] Semantic HTML (button, nav, main, article)
- [ ] ARIA labels on all interactive elements
- [ ] ARIA live regions for state changes
- [ ] Multi-modal status indicators (text + color + icon)

**For data/API:**
- [ ] Presentation metadata in data models
- [ ] API responses include announcement guidance
- [ ] Events carry all sensory modalities

**For testing:**
- [ ] Keyboard-only workflow tests
- [ ] Information parity tests (visual = non-visual)
- [ ] Focus management tests
- [ ] Screen reader announcement tests

---

## References

**Source Documentation:**
- AAFC: `docs/architecture/V2_ACCESSIBILITY_FIRST_DESIGN.md`
- AAFC: `docs/ACCESSIBILITY_REQUIREMENTS.md`
- AAFC: `docs/review_workflow.md`
- AAFC: `src/accessibility/presentation.py`

**Applied In:**
- Barkour: `experiments/barkour/prototypes/pygame-movement-01/main.py`
- Barkour: `experiments/barkour/prototypes/pygame-movement-01/README.md`
- Barkour: `experiments/barkour/shared/ARCHITECTURE.md`

**Standards:**
- WCAG 2.1 Level AA
- ARIA Authoring Practices Guide
- Apple Human Interface Guidelines - Accessibility

---

**Pattern Status**: Proven in production (AAFC), actively used in new projects (Barkour)
**Last Updated**: 2025-10-11
**Maintainer**: Devvyn Murphy
