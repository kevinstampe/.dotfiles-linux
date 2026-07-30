#!/usr/bin/env bash
# Wrapper around wofi for networkmanager_dmenu.
#
# networkmanager_dmenu hardcodes its menu entries (see the action list in
# /usr/bin/networkmanager_dmenu), so there is no config option to hide them.
# It does however pipe the whole menu through $dmenu_command on stdin and read
# the chosen line back from stdout -- so we filter here instead of patching the
# package, which would be reverted on every update.
#
# We keep ONLY actual wifi networks and drop every action row ("Disable WiFi",
# "Launch Connection Manager", "Saved connections", wired/VPN entries, etc).
#
# How the filter works: every wifi row is rendered with a signal-strength icon
# from the `wifi_icons` option in config.ini; action rows never contain one.
# Matching on those glyphs is therefore more robust than blacklisting labels,
# which change wording depending on current state (Enable vs Disable).
#
# If you ever change `wifi_icons` in config.ini, update ICONS to match.

ICONS='󰤯󰤟󰤢󰤥󰤨'

grep "[$ICONS]" | wofi --dmenu -i "$@"
