# Accessibility Considerations - MS-Related

## Known Challenge

Visual processing/filtering - small UI elements (like + buttons) may be filtered out as insignificant specks.

## Current Strengths

✓ **Terminal-based workflow** - Already using CLI heavily (good!)
✓ **Text-focused** - Markdown, code, terminal output
✓ **Claude Code** - Text-based AI interaction

## Potential Improvements

### 1. Voice Commands (macOS)

**Enable Voice Control:**

```bash
# Open Voice Control settings
open "x-apple.systempreferences:com.apple.preference.universalaccess?Dictation"
```

**Useful voice commands:**

- "Click [button name]"
- "Show numbers" (labels all clickable elements)
- "Press return"
- "Scroll down"

### 2. Increase UI Visibility

**Increase cursor size:**

```bash
# Make cursor larger and easier to track
defaults write com.apple.universalaccess mouseDriverCursorSize -float 2.0
```

**Increase contrast:**

```bash
# Open Accessibility → Display
open "x-apple.systempreferences:com.apple.preference.universalaccess?Seeing_Display"
```

### 3. Keyboard-First Workflows

**Minimize mouse dependence:**

- Tab through interface elements
- Use Spotlight (⌘Space) for everything
- Use keyboard shortcuts exclusively

**Create keyboard shortcuts for everything:**

```bash
# Script to open System Settings → Keyboard directly
echo '#!/bin/zsh
open "x-apple.systempreferences:com.apple.Keyboard-Settings.extension"
' > ~/bin/settings-keyboard
chmod +x ~/bin/settings-keyboard
```

### 4. AppleScript Automation

**Automate UI interactions:**

```bash
# Add keyboard layout via script (if we can determine the right path)
osascript << 'EOF'
tell application "System Settings"
    activate
    # Navigate programmatically
end tell
EOF
```

### 5. Screen Reader Integration

**VoiceOver:**

- Press ⌘F5 to toggle
- Announces all UI elements
- Keyboard navigation

### 6. CLI-First Approach

**Already doing this!** Continue prioritizing:

- Terminal commands over GUI
- Text configuration files
- Scripted automation
- Claude Code for assistance

### 7. Custom Scripts for Common Tasks

Create voice-activated or keyboard shortcut scripts for:

- Opening specific settings
- Managing keyboard layouts
- System configuration

## Immediate Actions

1. **Enable Accessibility Keyboard**
   - Shows on-screen keyboard with large buttons
   - Can be controlled with minimal mouse movement

2. **Increase Display Scale**
   - System Settings → Displays → Use larger text

3. **Enable Zoom**
   - ⌥⌘8 to toggle
   - ⌥⌘= to zoom in
   - ⌥⌘- to zoom out

4. **Use Spotlight for Everything**
   - ⌘Space, type what you want, Enter
   - Avoid hunting through menus

## For Study Station

Consider adding:

- Voice commands to start sessions
- Larger terminal font
- High contrast themes
- Audio feedback for actions
- Text-to-speech for long content

## Resources

- macOS Accessibility: System Settings → Accessibility
- Voice Control Guide: Apple Support
- Keyboard shortcuts: ⌘? in any app
