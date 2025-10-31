#!/usr/bin/env zsh
# Accessibility helper commands

case "$1" in
    cursor-larger)
        defaults write com.apple.universalaccess mouseDriverCursorSize -float 4.0
        killall Dock
        echo "✓ Cursor size: Extra Large (4x)"
        ;;
    cursor-normal)
        defaults write com.apple.universalaccess mouseDriverCursorSize -float 1.0
        killall Dock
        echo "✓ Cursor size: Normal (1x)"
        ;;
    cursor-medium)
        defaults write com.apple.universalaccess mouseDriverCursorSize -float 2.5
        killall Dock
        echo "✓ Cursor size: Medium (2.5x)"
        ;;
    high-contrast)
        osascript -e 'tell application "System Settings" to quit'
        open "x-apple.systempreferences:com.apple.preference.universalaccess?Seeing_Display"
        echo "Opening Display Accessibility settings..."
        ;;
    zoom-on)
        defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true
        defaults write com.apple.universalaccess HIDScrollZoomModifierMask -int 262144
        echo "✓ Zoom enabled: Hold Option and scroll to zoom"
        echo "  Toggle zoom: Option+Command+8"
        ;;
    voice-control)
        open "x-apple.systempreferences:com.apple.preference.universalaccess?Dictation"
        echo "Opening Voice Control settings..."
        ;;
    keyboard-settings)
        open "x-apple.systempreferences:com.apple.Keyboard-Settings.extension"
        sleep 1
        osascript -e 'tell application "System Events" to tell process "System Settings"
            click menu item "Keyboard" of menu "View" of menu bar 1
        end tell' 2>/dev/null
        echo "Opening Keyboard settings..."
        ;;
    *)
        echo "Accessibility Helpers"
        echo ""
        echo "Commands:"
        echo "  cursor-larger      Make cursor extra large (4x)"
        echo "  cursor-medium      Make cursor medium (2.5x)"
        echo "  cursor-normal      Reset cursor to normal"
        echo "  high-contrast      Open high contrast settings"
        echo "  zoom-on            Enable zoom (Option+scroll)"
        echo "  voice-control      Open voice control settings"
        echo "  keyboard-settings  Open keyboard settings"
        echo ""
        echo "Current cursor size:"
        defaults read com.apple.universalaccess mouseDriverCursorSize 2>/dev/null || echo "1.0 (default)"
        ;;
esac
