#!/usr/bin/env bash
# Toggle on-screen keyboard (wvkbd).
#
# wvkbd runs resident and hidden; SIGUSR1 hides, SIGUSR2 shows. Visibility is
# read back from the compositor (osk-visible) rather than tracked in a file,
# because --auto lets wvkbd show/hide itself and any file would go stale.
#
# --auto (show/hide on text-field focus, via zwp_input_method_v2) is only used
# when the keyboard folio is detached - with a real keyboard attached the
# popups are just noise. Requires wvkbd >= 0.20; see build-wvkbd-dk.sh.
# osk-folio-watch normally owns the wvkbd process and re-launches it when the
# folio is attached/detached; the launch below is only a cold-start fallback.

set -euo pipefail

HEIGHT=340

# Absolute paths: Hyprland's PATH may not include ~/.local/bin.
BIN="$HOME/.local/bin"

# Nudge waybar's custom/keyboard module to re-read state (SIGRTMIN+8).
# `|| true` so a missing waybar doesn't trip `set -e`.
refresh_bar() { pkill -RTMIN+8 waybar || true; }

if ! pgrep -x wvkbd-dk >/dev/null; then
    # Not running: launch hidden, then show.
    if "$BIN/folio-attached"; then
        wvkbd-dk --hidden -L "$HEIGHT" &
    else
        wvkbd-dk --hidden --auto -L "$HEIGHT" &
    fi

    # Wait for layer surface to register.
    for _ in $(seq 1 20); do
        pgrep -x wvkbd-dk >/dev/null && break
        sleep 0.05
    done
    sleep 0.2
    pkill -USR2 -x wvkbd-dk
    refresh_bar
    exit 0
fi

if "$BIN/osk-visible"; then
    pkill -USR1 -x wvkbd-dk   # hide
else
    pkill -USR2 -x wvkbd-dk   # show
fi

refresh_bar
