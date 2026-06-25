#!/usr/bin/env bash
# Toggle gsimplecal in the top-right of the currently focused monitor.
# windowrule `move` doesn't stick (gsimplecal resizes after map -> Hyprland
# re-centers it), so we launch it and reposition via dispatch.
# setsid detaches it so it survives this launcher exiting.

set -euo pipefail

if pgrep -x gsimplecal >/dev/null; then
    pkill -x gsimplecal
    exit 0
fi

setsid env LC_TIME=da_DK.UTF-8 gsimplecal >/dev/null 2>&1 &

# Pre-compute target from the focused monitor while the window spawns.
read -r MX MY MW <<<"$(hyprctl monitors -j | jq -r '.[] | select(.focused) | "\(.x) \(.y) \(.width)"')"
MARGIN=10
BAR=45

# Move the instant the window appears (animation disabled via windowrule).
for _ in $(seq 1 200); do
    WW=$(hyprctl clients -j | jq -r '.[] | select(.class=="gsimplecal") | .size[0]' | head -n1)
    if [[ -n "$WW" && "$WW" != "null" ]]; then
        X=$(( MX + MW - WW - MARGIN ))
        Y=$(( MY + BAR ))
        hyprctl dispatch movewindowpixel "exact ${X} ${Y},class:gsimplecal" >/dev/null
        break
    fi
    sleep 0.01
done
