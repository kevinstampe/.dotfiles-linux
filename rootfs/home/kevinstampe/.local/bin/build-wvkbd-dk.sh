#!/usr/bin/env bash
# Build a Danish-patched wvkbd and install it to /usr/local/bin so it takes
# PATH precedence over the pacman package (/usr/bin) and survives upgrades.
#
# Adds dedicated æ ø å keys (typed as real Unicode, independent of the system
# keymap) to the landscape and full (portrait) layouts:
#   top row    : ... o p [å]
#   home row   : ... k l [æ] [ø] '
#
# Re-run this after a wvkbd package upgrade if you want to track a new version
# (bump WVKBD_VER). Idempotent: refuses to double-inject.

set -euo pipefail

WVKBD_VER="0.19.4"
SRC_URL="https://git.sr.ht/~proycon/wvkbd/archive/v${WVKBD_VER}.tar.gz"
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

echo ">> Downloading wvkbd ${WVKBD_VER}"
curl -fsSL "$SRC_URL" -o "$BUILD_DIR/wvkbd.tar.gz"
tar xzf "$BUILD_DIR/wvkbd.tar.gz" -C "$BUILD_DIR"
SRC="$BUILD_DIR/wvkbd-v${WVKBD_VER}"

echo ">> Injecting Danish keys"
python3 - "$SRC/layout.mobintl.h" <<'PY'
import sys, re

path = sys.argv[1]
src = open(path, encoding="utf-8").read()

if "DK-PATCH" in src:
    print("   already patched, skipping")
    sys.exit(0)

# Unicode-emitting keys (work regardless of the system keymap).
AA = '  {"\u00e5", "\u00c5", 1.0, Copy, 0x00E5, 0, 0x00C5}, /* DK-PATCH */\n'
AE = '  {"\u00e6", "\u00c6", 1.0, Copy, 0x00E6, 0, 0x00C6}, /* DK-PATCH */\n'
OE = '  {"\u00f8", "\u00d8", 1.0, Copy, 0x00F8, 0, 0x00D8}, /* DK-PATCH */\n'

def patch_array(text, array_name):
    # Isolate one keys_<name>[] = { ... }; block and inject within it.
    m = re.search(r"(static struct key %s\[\]\s*=\s*\{)(.*?)(\n\};)" % re.escape(array_name),
                  text, re.S)
    if not m:
        raise SystemExit("array %s not found" % array_name)
    head, body, tail = m.group(1), m.group(2), m.group(3)

    # å right after the 'p' key.
    body, n1 = re.subn(r'(\n[ \t]*\{"p", "P",[^\n]*\n)', r'\1' + AA, body, count=1)
    # æ and ø right after the 'l' key.
    body, n2 = re.subn(r'(\n[ \t]*\{"l", "L",[^\n]*\n)', r'\1' + AE + OE, body, count=1)

    if n1 != 1 or n2 != 1:
        raise SystemExit("injection anchors not found in %s (p=%d l=%d)" % (array_name, n1, n2))
    return text[:m.start()] + head + body + tail + text[m.end():]

src = patch_array(src, "keys_landscape")
src = patch_array(src, "keys_full")

open(path, "w", encoding="utf-8").write(src)
print("   patched keys_landscape and keys_full")
PY

echo ">> Building"
make -C "$SRC" wvkbd-mobintl >/dev/null

echo ">> Installing to /usr/local/bin (needs sudo)"
sudo install -Dm755 "$SRC/wvkbd-mobintl" /usr/local/bin/wvkbd-mobintl

echo ">> Done. $(command -v wvkbd-mobintl) -> $(/usr/local/bin/wvkbd-mobintl --version 2>/dev/null || echo ok)"
echo ">> Restart the keyboard: killall wvkbd-mobintl"
