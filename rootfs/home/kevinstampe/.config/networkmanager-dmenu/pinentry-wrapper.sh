#!/usr/bin/env bash
# pinentry wrapper for networkmanager_dmenu.
#
# Problem: networkmanager_dmenu:681-684 calls get_passphrase() and passes the
# result to set_new_connection() with no cancellation check. get_passphrase()
# returns "" both when the user types nothing AND when the user cancels the
# pinentry dialog, so cancelling silently saves a new connection profile with
# an empty PSK.
#
# nmdm ignores our exit status and only parses stdout, so returning an error is
# not enough to stop it. Instead we detect the cancel, emit nothing, and kill
# the calling nmdm process so it never reaches set_new_connection().
#
# Assumes it is spawned directly by nmdm (subprocess.run -> we are the child),
# so $PPID is the nmdm process.

out=$(pinentry-gtk 2>/dev/null)

# A successful entry yields an assuan data line: "D <passphrase>".
# Cancel yields "ERR 83886179 Operation cancelled" and no D line.
if grep -q '^D ' <<<"$out"; then
    printf '%s\n' "$out"
    exit 0
fi

kill -TERM "$PPID" 2>/dev/null
exit 1
