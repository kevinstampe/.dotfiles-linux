#!/bin/bash

# Path to a temporary file to store the current state
STATE_FILE="power-profile.state"

# Initialize state if it doesn't exist
if [ ! -f "$STATE_FILE" ]; then
    echo 0 > "$STATE_FILE"
fi

# Read the current state
STATE=$(cat "$STATE_FILE")

# Run the command based on the state
case $STATE in
    0)
        powerprofilesctl set performance
        notify-send "Performance mode activated"
        NEXT_STATE=1
        ;;
    1)
        powerprofilesctl set balanced
        notify-send "Balanced mode activated"
        NEXT_STATE=2
        ;;
    2)
        powerprofilesctl set power-saver
        notify-send "Power saver mode activated"
        NEXT_STATE=0
        ;;
esac

# Save the next state
echo $NEXT_STATE > "$STATE_FILE"
