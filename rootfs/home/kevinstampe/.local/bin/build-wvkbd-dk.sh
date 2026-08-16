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

echo ">> Building"
make -C "$SRC" LAYOUT=dk >/dev/null

echo ">> Installing to /usr/local/bin (needs sudo)"
sudo install -Dm755 "$SRC/wvkbd-dk" /usr/local/bin/wvkbd-dk

echo ">> Done. $(command -v wvkbd-dk)"
echo ">> Layers: $(/usr/local/bin/wvkbd-dk --list-layers | tr '\n' ' ')"
echo ">> Restart the keyboard: killall wvkbd-dk   (osk-folio-watch relaunches it)"
