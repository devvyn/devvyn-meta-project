#!/bin/zsh
# Animated Zen Koi Pond
# Press Ctrl+C to exit

# Hide cursor
tput civis

# Cleanup on exit
trap 'tput cnorm; exit' INT TERM EXIT

# Koi positions cycle through these frames
declare -a koi_frames=(
    # Frame 0
    "      ～     ><>         ～
   ～   🪷      ～    ><>     ～
      ～     ><>    ～         ～
   ～         ～       🪷   ><>    ～    "

    # Frame 1
    "      ～        ><>      ～
   ～   🪷   ><>       ～     ～
      ～         ～    ><>    ～
   ～      ><>    ～   🪷        ～    "

    # Frame 2
    "      ～           ><>   ～
   ～   🪷       ><>    ～     ～
      ～   ><>      ～         ～
   ～         ～   🪷    ><>       ～    "

    # Frame 3
    "      ～              ><> ～
   ～   🪷          ><>   ～     ～
      ～      ><>   ～         ～
   ～    ><>     ～   🪷           ～    "

    # Frame 4
    "      ～         ><>     ～
   ～   🪷             ～ ><>     ～
      ～         ><>～         ～
   ～       ><>  ～   🪷           ～    "

    # Frame 5
    "      ～    ><>          ～
   ～   🪷          ～       ><> ～
      ～            ～  ><>    ～
   ～          ><>～   🪷           ～    "
)

frame=0
ripples=("∘" "○" "◯")
ripple_idx=0

while true; do
    clear

    # Top border
    echo "    ╭─────────────────────────────────────────╮"
    echo "    │    ～～～  Koi Pond  ～～～            │"
    echo "    │                                         │"

    # Current koi frame
    echo "${koi_frames[$frame + 1]}" | while IFS= read -r line; do
        echo "    │$line│"
    done

    # Bottom section with ripples
    echo "    │      ～   ><>    ～      ～             │"
    echo "    │         ～     ～    ${ripples[$ripple_idx + 1]}       ～       │"
    echo "    │                                         │"
    echo "    ╰─────────────────────────────────────────╯"

    # Zen quote beneath
    echo ""
    echo "         💭  The quieter you become..."
    echo ""

    # Update frame counters
    frame=$(( (frame + 1) % 6 ))
    ripple_idx=$(( (ripple_idx + 1) % 3 ))

    sleep 0.8
done
