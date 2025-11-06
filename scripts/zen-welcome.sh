#!/bin/zsh
# Zen Terminal Welcome
# Add to your .zshrc: source ~/devvyn-meta-project/scripts/zen-welcome.sh

zen_welcome() {
    local hour=$(date +%H)
    local greeting

    # Time-appropriate greeting
    if (( hour >= 5 && hour < 12 )); then
        greeting="Good morning"
    elif (( hour >= 12 && hour < 17 )); then
        greeting="Good afternoon"
    elif (( hour >= 17 && hour < 21 )); then
        greeting="Good evening"
    else
        greeting="Late night wisdom"
    fi

    # The Five Agreements + Zen wisdom
    local agreements=(
        "Be impeccable with your word"
        "Don't take anything personally"
        "Don't make assumptions"
        "Always do your best"
        "Be skeptical, but learn to listen"
    )

    local zen_wisdom=(
        "The obstacle is the path"
        "Empty your mind. Be formless"
        "In the beginner's mind, many possibilities"
        "Flow with whatever may happen"
        "Let go or be dragged"
        "The quieter you become, the more you hear"
        "This too shall pass"
        "When you realize nothing is lacking, the whole world belongs to you"
    )

    # Pick a random wisdom
    local agreement="${agreements[$(($RANDOM % ${#agreements[@]} + 1))]}"
    local zen="${zen_wisdom[$(($RANDOM % ${#zen_wisdom[@]} + 1))]}"

    cat << EOF

    ╭─────────────────────────────────────────╮
    │    ～～～  $greeting  ～～～
    │                                         │
    │      ～     ><>         ～              │
    │   ～   🪷      ～    ><>     ～         │
    │      ～     ><>    ～         ～        │
    │   ～         ～       🪷   ><>    ～    │
    │                                         │
    ╰─────────────────────────────────────────╯

         📿  $agreement
         🧘  $zen

    ╭─────────────────────────────────────────╮
    │         Zen Rock Garden                 │
    │                                         │
    │    ░░░░░░    ◯    ░░░░░░░              │
    │  ░░░░░░░░░  ◯ ◯  ░░░░░░░░░            │
    │    ░░░░  ◯ ◯   ◯ ◯  ░░░░              │
    │  ░░░░░░░    ◯ ◯    ░░░░░░░            │
    │    ░░░░░░░  ◯ ◯  ░░░░░░░              │
    │                                         │
    ╰─────────────────────────────────────────╯

EOF
}

# Quick commands for later use
alias koi='~/devvyn-meta-project/scripts/zen-koi-animate.sh'
alias garden='~/devvyn-meta-project/scripts/zen-garden.sh'
alias zen='zen_welcome'

# Show on login (comment out if too much)
zen_welcome
