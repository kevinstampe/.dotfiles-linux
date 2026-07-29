#!/usr/bin/env bash

exec &>> /tmp/lid-init.log
echo "=== Script started at $(date) ==="

# Prevent re-entrant runs: disabling/enabling eDP-1 fires monitor.removed/added,
# which re-triggers this script. Skip if an instance is already running.
exec 9>/tmp/lid-init.lock
if ! flock -n 9; then
    echo "lid-init already running; skipping this invocation"
    exit 0
fi

LID_STATE=$(cat /proc/acpi/button/lid/*/state | awk '{print $2}')
INTERNAL="eDP-1"
EXTERNAL=$(hyprctl monitors -j | jq -r ".[] | select(.name != \"$INTERNAL\") | .name" | head -n 1)

# Lua config helpers (hyprctl keyword/legacy-dispatch don't work with the lua parser).
# disabled=false is required to re-enable a monitor previously disabled via disabled=true.
mon_set()     { hyprctl eval "hl.monitor({ output=\"$1\", mode=\"$2\", position=\"$3\", scale=$4, disabled=false })"; }
mon_disable() { hyprctl eval "hl.monitor({ output=\"$1\", disabled=true })"; }
ws_rule()     { hyprctl eval "hl.workspace_rule({ workspace=\"$1\", monitor=\"$2\" })"; }
ws_move()     { hyprctl dispatch "hl.dsp.workspace.move({ workspace=\"$1\", monitor=\"$2\" })"; }
focus_mon()   { hyprctl dispatch "hl.dsp.focus({ monitor=\"$1\" })"; }
focus_ws()    { hyprctl dispatch "hl.dsp.focus({ workspace=$1 })"; }

if [ -z "$EXTERNAL" ]; then
    echo "No external monitor found."
    mon_set "$INTERNAL" "preferred" "0x0" "1.25"
    for i in {1..12}; do
        ws_rule "$i" "$INTERNAL"
        ws_move "$i" "$INTERNAL"
    done
else

    if [[ "$LID_STATE" == "closed" ]]; then
        echo "Lid closed: Sending all to $EXTERNAL"
        mon_disable "$INTERNAL"
        for i in {1..12}; do
            ws_rule "$i" "$EXTERNAL"
            ws_move "$i" "$EXTERNAL"
        done
    else
        echo "Lid open: 1-12 to $EXTERNAL, 13 to $INTERNAL"
        # 1. Re-enable internal monitor
        mon_set "$INTERNAL" "preferred" "0x0" "1"

        # 2. Assign the rules (The "Contract")
        for i in {1..12}; do
            ws_rule "$i" "$EXTERNAL"
        done
        ws_rule "13" "$INTERNAL"

        # 3. Physically move existing workspaces to their homes
        for i in {1..12}; do
            ws_move "$i" "$EXTERNAL"
        done

        # 5. Return focus to the External monitor and Workspace 1
        focus_mon "$EXTERNAL"
        focus_ws 1
    fi
fi

# Final Step: Ensure focus is on the External monitor's first workspace
focus_ws 1

# Re-evaluate waybar output (hide on eDP-1 unless it's the only screen)
~/.config/hypr/waybar-launch.sh

echo "=== Setup Complete ==="
