#!/usr/bin/env bash

exec &>> /tmp/lid-init.log
echo "=== Script started at $(date) ==="

LID_STATE=$(cat /proc/acpi/button/lid/*/state | awk '{print $2}')
INTERNAL="eDP-1"
EXTERNAL=$(hyprctl monitors -j | jq -r ".[] | select(.name != \"$INTERNAL\") | .name" | head -n 1)

if [ -z "$EXTERNAL" ]; then
    echo "No external monitor found."
    hyprctl keyword monitor "$INTERNAL, preferred, 0x0, 1.25"
    for i in {1..12}; do
        hyprctl keyword workspace "$i, monitor:$INTERNAL"
        hyprctl dispatch moveworkspacetomonitor "$i $INTERNAL"
    done
else

    if [[ "$LID_STATE" == "closed" ]]; then
        echo "Lid closed: Sending all to $EXTERNAL"
        hyprctl keyword monitor "$INTERNAL, disable"
        for i in {1..12}; do
            hyprctl keyword workspace "$i, monitor:$EXTERNAL"
            hyprctl dispatch moveworkspacetomonitor "$i $EXTERNAL"
        done
    else
        echo "Lid open: 1-12 to $EXTERNAL, 13 to $INTERNAL"
        # 1. Re-enable internal monitor
        hyprctl keyword monitor "$INTERNAL, preferred, 0x0, 1.25"
        
        # 2. Assign the rules (The "Contract")
        for i in {1..12}; do
            hyprctl keyword workspace "$i, monitor:$EXTERNAL"
        done
        hyprctl keyword workspace "13, monitor:$INTERNAL"

        # 3. Physically move existing workspaces to their homes
        for i in {1..12}; do
            hyprctl dispatch moveworkspacetomonitor "$i $EXTERNAL"
        done
        
        # 5. Return focus to the External monitor and Workspace 1
        hyprctl dispatch focusmonitor "$EXTERNAL"
        hyprctl dispatch workspace 1
    fi
fi

# Final Step: Ensure focus is on the External monitor's first workspace
hyprctl dispatch workspace 1
echo "=== Setup Complete ==="
