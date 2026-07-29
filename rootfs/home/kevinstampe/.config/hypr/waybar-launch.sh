#!/usr/bin/env bash
# Launch/relaunch waybar with the correct output filter:
#   - external monitor present -> show on everything EXCEPT eDP-1
#   - eDP-1 is the only screen  -> show on eDP-1
# Base config (~/.config/waybar/config.jsonc) is left untouched; runtime
# configs just `include` it and add the `output` key.

exec &>> /tmp/waybar-launch.log
echo "=== waybar-launch at $(date) ==="

# Serialize concurrent launches (startup + monitor events) so we never spawn 2 bars.
exec 8>/tmp/waybar-launch.lock
flock 8

INTERNAL="eDP-1"
BASE="$HOME/.config/waybar/config.jsonc"
EXT_CFG="/tmp/waybar-external.jsonc"
EDP_CFG="/tmp/waybar-edp.jsonc"

printf '{ "include": ["%s"], "output": "!%s" }\n' "$BASE" "$INTERNAL" > "$EXT_CFG"
printf '{ "include": ["%s"], "output": "%s" }\n'  "$BASE" "$INTERNAL" > "$EDP_CFG"

MONITORS_JSON=$(hyprctl monitors -j 2>/dev/null)
if ! echo "$MONITORS_JSON" | jq empty >/dev/null 2>&1; then
    echo "ERROR: could not read hyprctl monitors (not in a Hyprland session?). Aborting, waybar left untouched."
    exit 1
fi

EXTERNAL=$(echo "$MONITORS_JSON" | jq -r ".[] | select(.name != \"$INTERNAL\") | .name" | head -n 1)

if [ -z "$EXTERNAL" ]; then
    CFG="$EDP_CFG"
    echo "No external: waybar on $INTERNAL"
else
    CFG="$EXT_CFG"
    echo "External $EXTERNAL present: waybar hidden on $INTERNAL"
fi

killall -q waybar
while pgrep -x waybar >/dev/null; do sleep 0.1; done

# Close inherited lock fds (8 = ours, 9 = lid-init's) so the long-lived waybar
# process does NOT keep the flock held after we exit.
setsid waybar -c "$CFG" 8>&- 9>&- &
echo "=== launched with $CFG ==="
