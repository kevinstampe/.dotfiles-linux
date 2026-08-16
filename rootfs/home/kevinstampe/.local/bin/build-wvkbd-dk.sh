#!/usr/bin/env bash
# Build wvkbd with a custom Danish 3-layer layout and install it to
# /usr/local/bin so it takes PATH precedence over the pacman package
# (/usr/bin) and survives upgrades.
#
# The layout is a self-contained set (make LAYOUT=dk) living in
# ~/.config/wvkbd/, modelled on the iOS Danish keyboard:
#
#   Letters:  q..p å / a..l æ ø / ⇧ z..m ⌫ / 123 Esc space ⏎ ⌄
#   Numbers:  1..0 / - / : ; ( ) ` & @ " / #+= . , ? ! ' ⌫ / ABC Esc space ⏎ ⌄
#   Symbols:  [ ] { } # % ^ * + = / _ \ | ~ < > € $ £ • / 123 ← ↓ ↑ → ⌫ / ...
#
# Only one thing still has to be patched into upstream C: a Hide key type, so
# the ⌄ key can dismiss the keyboard. Everything else is plain layout files, so
# there are no fragile regex anchors into upstream's layout arrays.
#
# Re-run this after a wvkbd release if you want to track a new version (bump
# WVKBD_VER). The C patch is idempotent and aborts loudly if its anchors move.

set -euo pipefail

WVKBD_VER="0.20"
SRC_URL="https://git.sr.ht/~proycon/wvkbd/archive/v${WVKBD_VER}.tar.gz"
LAYOUT_DIR="$HOME/.config/wvkbd"
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

for f in layout.dk.h keymap.dk.h config.dk.h; do
    [[ -f "$LAYOUT_DIR/$f" ]] || { echo "missing $LAYOUT_DIR/$f" >&2; exit 1; }
done

echo ">> Downloading wvkbd ${WVKBD_VER}"
curl -fsSL "$SRC_URL" -o "$BUILD_DIR/wvkbd.tar.gz"
tar xzf "$BUILD_DIR/wvkbd.tar.gz" -C "$BUILD_DIR"
SRC="$BUILD_DIR/wvkbd-v${WVKBD_VER}"

echo ">> Installing dk layout set"
cp "$LAYOUT_DIR"/layout.dk.h "$LAYOUT_DIR"/keymap.dk.h "$LAYOUT_DIR"/config.dk.h "$SRC/"

echo ">> Patching in the Hide key type"
python3 - "$SRC" <<'PY'
import sys, re, os

src_dir = sys.argv[1]
kh_path = os.path.join(src_dir, "keyboard.h")
kc_path = os.path.join(src_dir, "keyboard.c")

kh = open(kh_path, encoding="utf-8").read()
kc = open(kc_path, encoding="utf-8").read()

if "HIDE-PATCH" in kh:
    print("   already patched, skipping")
    sys.exit(0)

# New key type. Must be inserted before `Last`, which terminates a layout.
kh, n = re.subn(r"(\n\tEndRow,[^\n]*\n)",
                r"\1\tHide,      // Hide the keyboard /* HIDE-PATCH */\n",
                kh, count=1)
if n != 1:
    raise SystemExit("keyboard.h: EndRow anchor not found")

# Handle it. wvkbd already consumes SIGUSR1 through a signalfd in its main loop
# and calls hide(), so raising it on ourselves reuses that path - hide() itself
# is static to main.c and not reachable from here.
kc, n = re.subn(r"(\n[ \t]*case NextLayer:)",
                "\n    case Hide: /* HIDE-PATCH */\n"
                "        raise(SIGUSR1);\n"
                "        break;\n"
                r"\1",
                kc, count=1)
if n != 1:
    raise SystemExit("keyboard.c: NextLayer anchor not found")

if "#include <signal.h>" not in kc:
    kc, n = re.subn(r"(#include <stdio\.h>\n)",
                    r"\1#include <signal.h> /* HIDE-PATCH */\n",
                    kc, count=1)
    if n != 1:
        raise SystemExit("keyboard.c: include anchor not found")

open(kh_path, "w", encoding="utf-8").write(kh)
open(kc_path, "w", encoding="utf-8").write(kc)
print("   added Hide key type")
PY

echo ">> Patching the keymap upload leak"
python3 - "$SRC" <<'PY'
import sys, os

src_dir = sys.argv[1]
kc_path = os.path.join(src_dir, "keyboard.c")
kc = open(kc_path, encoding="utf-8").read()

if "LEAK-PATCH" in kc:
    print("   already patched, skipping")
    sys.exit(0)

# create_and_upload_keymap() mmaps the keymap and never unmaps it, leaking
# ~51KB every time it runs. It runs on every Copy key press, so a few thousand
# presses of å/æ/ø or €/£/• adds up. libwayland takes ownership of the fd and
# closes it after sending, so only the mapping needs cleaning up.
old = """    zwp_virtual_keyboard_v1_keymap(kb->vkbd, WL_KEYBOARD_KEYMAP_FORMAT_XKB_V1,
                                   keymap_fd, keymap_size);
    free((void *)keymap_str);"""
new = """    zwp_virtual_keyboard_v1_keymap(kb->vkbd, WL_KEYBOARD_KEYMAP_FORMAT_XKB_V1,
                                   keymap_fd, keymap_size);
    munmap(ptr, keymap_size); /* LEAK-PATCH */
    free((void *)keymap_str);"""

if old not in kc:
    raise SystemExit("keyboard.c: keymap upload anchor not found")

kc = kc.replace(old, new, 1)
open(kc_path, "w", encoding="utf-8").write(kc)
print("   added munmap after keymap upload")
PY

echo ">> Patching the stuck-key-on-hide bug"
python3 - "$SRC" <<'PY'
import sys, os

src_dir = sys.argv[1]
mc_path = os.path.join(src_dir, "main.c")
mc = open(mc_path, encoding="utf-8").read()

if "STUCK-PATCH" in mc:
    print("   already patched, skipping")
    sys.exit(0)

# hide() tears the surfaces down and clears layer_surface_configured, but never
# releases a key that is still held. wl_touch_up() bails out early when the
# surface is not configured, so the release never happens and the compositor
# auto-repeats the key forever.
#
# This is reachable whenever the keyboard is hidden between touch-down and
# touch-up, which --auto makes routine: deleting the last character of a field
# deactivates the input method, which hides the keyboard while backspace is
# still held. Releasing before teardown is enough, and must happen first
# because kbd_unpress_key() redraws.
old = """hide()
{
    if (!layer_surface) {
        return;
    }
"""
new = """hide()
{
    if (!layer_surface) {
        return;
    }

    /* STUCK-PATCH: never leave a key held across teardown */
    kbd_unpress_key(&keyboard, 0);
"""

if old not in mc:
    raise SystemExit("main.c: hide() anchor not found")

mc = mc.replace(old, new, 1)
open(mc_path, "w", encoding="utf-8").write(mc)
print("   release held key before hiding")
PY

echo ">> Building"

make -C "$SRC" LAYOUT=dk >/dev/null

echo ">> Installing to /usr/local/bin (needs sudo)"
sudo install -Dm755 "$SRC/wvkbd-dk" /usr/local/bin/wvkbd-dk

echo ">> Done. $(command -v wvkbd-dk)"
echo ">> Layers: $(/usr/local/bin/wvkbd-dk --list-layers | tr '\n' ' ')"
echo ">> Restart the keyboard: killall wvkbd-dk   (osk-folio-watch relaunches it)"
