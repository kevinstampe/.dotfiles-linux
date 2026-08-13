#!/usr/bin/env bash

exec &>> /tmp/lid-init.log
echo "=== Script started at $(date) ==="

INTERNAL="eDP-1"
LOCK="/tmp/lid-init.lock"
PENDING="/tmp/lid-init.pending"
STATE="/tmp/lid-init.state"

# Coalesce re-entrant runs instead of dropping them.
#
# Disabling/enabling eDP-1 fires monitor.removed/added, which re-triggers this
# script; so does a slow-to-enumerate external (e.g. the USB-C dock monitor,
# which appears AFTER the startup invocation has already begun). The old
# `flock -n ... || exit` discarded those invocations outright, so a monitor that
# showed up mid-run never got its workspaces assigned.
#
# Now: if a run is in progress, drop a pending marker and exit. The holder
# re-runs after it finishes, so late events are always honoured exactly once.
exec 9>"$LOCK"
if ! flock -n 9; then
    echo "lid-init already running; queuing a re-run"
    : > "$PENDING"
    exit 0
fi

# Lua config helpers (hyprctl keyword/legacy-dispatch don't work with the lua parser).
# disabled=false is required to re-enable a monitor previously disabled via disabled=true.
mon_set()     { hyprctl eval "hl.monitor({ output=\"$1\", mode=\"$2\", position=\"$3\", scale=$4, disabled=false })"; }
mon_disable() { hyprctl eval "hl.monitor({ output=\"$1\", disabled=true })"; }
ws_rule()     { hyprctl eval "hl.workspace_rule({ workspace=\"$1\", monitor=\"$2\" })"; }
ws_move()     { hyprctl dispatch "hl.dsp.workspace.move({ workspace=\"$1\", monitor=\"$2\" })"; }
focus_mon()   { hyprctl dispatch "hl.dsp.focus({ monitor=\"$1\" })"; }
focus_ws()    { hyprctl dispatch "hl.dsp.focus({ workspace=$1 })"; }

apply() {
    local lid_state external desired previous

    lid_state=$(cat /proc/acpi/button/lid/*/state | awk '{print $2}')
    external=$(hyprctl monitors -j | jq -r ".[] | select(.name != \"$INTERNAL\") | .name" | head -n 1)

    # Skip if the layout already matches what we last applied. Keeps the extra
    # coalesced pass cheap and stops the self-triggered monitor events from
    # causing an endless disable/enable + waybar-restart loop.
    desired="${external}|${lid_state}"
    previous=$(cat "$STATE" 2>/dev/null)
    if [[ "$desired" == "$previous" ]]; then
        echo "Layout unchanged ($desired); nothing to do."
        return 0
    fi

    if [ -z "$external" ]; then
        echo "No external monitor found."
        mon_set "$INTERNAL" "preferred" "0x0" "1.25"
        for i in {1..12}; do
            ws_rule "$i" "$INTERNAL"
            ws_move "$i" "$INTERNAL"
        done
    elif [[ "$lid_state" == "closed" ]]; then
        echo "Lid closed: Sending all to $external"
        mon_disable "$INTERNAL"
        for i in {1..12}; do
            ws_rule "$i" "$external"
            ws_move "$i" "$external"
        done
    else
        echo "Lid open: 1-12 to $external, 13 to $INTERNAL"
        # 1. Re-enable internal monitor
        mon_set "$INTERNAL" "preferred" "0x0" "1"

        # 2. Assign the rules (The "Contract")
        for i in {1..12}; do
            ws_rule "$i" "$external"
        done
        ws_rule "13" "$INTERNAL"

        # 3. Physically move existing workspaces to their homes
        for i in {1..12}; do
            ws_move "$i" "$external"
        done

        # 5. Return focus to the External monitor and Workspace 1
        focus_mon "$external"
    fi

    # Final Step: Ensure focus is on the External monitor's first workspace
    focus_ws 1

    # Re-evaluate waybar output (hide on eDP-1 unless it's the only screen)
    ~/.config/hypr/waybar-launch.sh

    printf '%s' "$desired" > "$STATE"
}

while :; do
    rm -f "$PENDING"
    apply
    [ -e "$PENDING" ] || break
    echo "--- pending re-run requested, looping ---"
done

echo "=== Setup Complete ==="
