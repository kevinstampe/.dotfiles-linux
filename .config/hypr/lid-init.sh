#!/usr/bin/env bash

exec &>> /tmp/lid-init.log

echo "=== Script started at $(date) ==="
echo "PATH=$PATH"

LID_STATE=$(cat /proc/acpi/button/lid/LID/state | awk '{print $2}')

echo "LID_STATE=$LID_STATE"

if [[ "$LID_STATE" == "closed" ]]; then
    hyprctl keyword monitor "eDP-1, disable"
    echo "test1"
else
    hyprctl keyword monitor "eDP-1, preferred, auto, 1.875"
    echo "test2"
fi

