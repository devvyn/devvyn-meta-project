#!/bin/zsh
# Zen Garden Terminal Aesthetic
# Usage: source this in your shell config or run directly

zen_koi_pond() {
    cat << 'EOF'
    ╭─────────────────────────────────────────╮
    │    ～～～  Koi Pond  ～～～            │
    │                                         │
    │      ～     ><>         ～              │
    │   ～   🪷      ～    ><>     ～         │
    │      ～     ><>    ～         ～        │
    │   ～         ～       🪷   ><>    ～    │
    │      ～   ><>    ～      ～             │
    │         ～     ～    ><>       ～       │
    │                                         │
    ╰─────────────────────────────────────────╯
EOF
}

zen_rock_garden() {
    cat << 'EOF'
    ╭─────────────────────────────────────────╮
    │         Zen Rock Garden                 │
    │                                         │
    │    ░░░░░░    ◯    ░░░░░░░              │
    │  ░░░░░░░░░  ◯ ◯  ░░░░░░░░░            │
    │    ░░░░  ◯ ◯   ◯ ◯  ░░░░              │
    │  ░░░░░░░    ◯ ◯    ░░░░░░░            │
    │    ░░░░░░░  ◯ ◯  ░░░░░░░              │
    │  ░░░░░░░░░░     ░░░░░░░░░░            │
    │                                         │
    ╰─────────────────────────────────────────╯
EOF
}

zen_bamboo() {
    cat << 'EOF'
    │││  Bamboo Grove  │││

    ║ ║      ║ ║      ║ ║
    ║ ║  🍃  ║ ║  🍃  ║ ║
    ║ ║      ║ ║      ║ ║
    ║ ║  🍃  ║ ║  🍃  ║ ║
    ║ ║      ║ ║      ║ ║
    ▓▓▓      ▓▓▓      ▓▓▓
EOF
}

zen_moon_gate() {
    cat << 'EOF'
         ╭─────────╮
        ╱           ╲
       │    ○ ○ ○    │
      │               │
     │     Gateway     │
      │               │
       │             │
        ╲           ╱
         ╰─────────╯
         ▓▓▓▓▓▓▓▓▓
EOF
}

zen_meditation_quote() {
    local quotes=(
        "The obstacle is the path."
        "Empty your mind. Be formless, shapeless."
        "In the beginner's mind there are many possibilities."
        "The quieter you become, the more you can hear."
        "Let go or be dragged."
        "Flow with whatever may happen."
    )

    local quote="${quotes[$(($RANDOM % ${#quotes[@]} + 1))]}"
    echo "\n    💭  $quote\n"
}

zen_ripple() {
    cat << 'EOF'
           o
         o   o
       o   ∘   o
     o   ∘   ∘   o
       o   ∘   o
         o   o
           o
EOF
}

# Full Zen Garden Display
zen_garden() {
    clear
    echo ""
    zen_koi_pond
    echo ""
    zen_meditation_quote
    echo ""
    zen_rock_garden
    echo ""
}

# Animated Koi (call repeatedly for motion)
zen_koi_swim() {
    local frame=$1
    local positions=(
        "     ><>              "
        "        ><>           "
        "           ><>        "
        "              ><>     "
        "           ><>        "
        "        ><>           "
    )

    echo "${positions[$(($frame % 6 + 1))]}"
}

# If sourced, just define functions. If executed, show garden
if [[ "${ZSH_EVAL_CONTEXT}" == "toplevel" ]]; then
    zen_garden
fi
