#!/bin/sh
# Single-instance guard: bail out if a btop window already exists.
if hyprctl -j clients | grep -q 'dev\.tui\.btop'; then
    exit 0
fi
# Lock guards against two near-simultaneous launches racing past the check.
exec flock -n /tmp/btop-launch.lock \
    ghostty --class=dev.tui.btop -e btop
# The class must look like a reverse-DNS app id; ghostty silently ignores a
# bare --class=btop and keeps com.mitchellh.ghostty, which breaks window rules.
