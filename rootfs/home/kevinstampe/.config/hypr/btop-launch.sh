#!/bin/sh
killall btop 2>/dev/null
exec ghostty --class=btop --font-size=16 -e btop
