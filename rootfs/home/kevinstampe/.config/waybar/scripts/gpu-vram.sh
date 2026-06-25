#!/bin/sh
# GPU busy % + VRAM usage %, combined for waybar custom module.

dev=/sys/class/drm/card1/device

gpu=$(cat "$dev/gpu_busy_percent" 2>/dev/null)
[ -z "$gpu" ] && gpu=0

used=$(cat "$dev/mem_info_vram_used" 2>/dev/null)
total=$(cat "$dev/mem_info_vram_total" 2>/dev/null)
vram=$(awk -v u="$used" -v t="$total" 'BEGIN{ if (t>0) printf "%d", u*100/t + 0.5; else print 0 }')

printf "<span size='13000' foreground='#fe8019'>󰾲 </span>%03d%%<span foreground='#665c54'>|</span>%03d%% \n" "$gpu" "$vram"
