#!/usr/bin/env bash
# Toggle on-screen keyboard (wvkbd).
# wvkbd runs resident (started hidden). We track visible/hidden state in a
# file and send SIGUSR1 (hide) / SIGUSR2 (show). First invocation launches it.

set -euo pipefail

STATE="${XDG_RUNTIME_DIR:-/tmp}/wvkbd.visible"
HEIGHT=340
LAYERS="landscape,special"

# Nudge waybar's custom/keyboard module to re-read state (SIGRTMIN+8).
# `|| true` so a missing waybar doesn't trip `set -e`.
refresh_bar() { pkill -RTMIN+8 waybar || true; }

if ! pgrep -x wvkbd-mobintl >/dev/null; then
    # Not running: launch hidden, then show.
    wvkbd-mobintl --hidden -L "$HEIGHT" -l "$LAYERS" &
    # Wait for layer surface to register.
    for _ in $(seq 1 20); do
        pgrep -x wvkbd-mobintl >/dev/null && break
        sleep 0.05
    done
    sleep 0.2
    pkill -USR2 -x wvkbd-mobintl
    touch "$STATE"
    refresh_bar
    exit 0
fi

if [[ -f "$STATE" ]]; then
    pkill -USR1 -x wvkbd-mobintl   # hide
    rm -f "$STATE"
    refresh_bar
else
    pkill -USR2 -x wvkbd-mobintl   # show
    touch "$STATE"
    refresh_bar
fi
