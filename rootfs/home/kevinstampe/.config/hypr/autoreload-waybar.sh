#!/usr/bin/env bash
# Reload waybar in-place when its config/style changes.
# Event-based (inotifywait) — no busy loop, no kill/restart, no CPU burn.
# Waybar reloads config + style on SIGUSR2 without restarting.

exec &>> /tmp/autoreload-waybar.log

config=~/.config/waybar/config.jsonc
style=~/.config/waybar/style.css

# -e close_write catches editor saves (incl. atomic write-and-rename).
while inotifywait -e close_write,move,create "$config" "$style"; do
    killall -SIGUSR2 waybar
done
