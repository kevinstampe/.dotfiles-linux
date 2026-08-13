#!/bin/sh
killall btop 2>/dev/null
exec ghostty --class=btop -e btop
