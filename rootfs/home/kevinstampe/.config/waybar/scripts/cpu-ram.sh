#!/bin/sh
# CPU usage (sampled over 1s) + RAM usage, combined for waybar custom module.

read -r _ a b c d e f g h _ </proc/stat
idle1=$((d + e))
total1=$((a + b + c + d + e + f + g + h))
sleep 1
read -r _ a b c d e f g h _ </proc/stat
idle2=$((d + e))
total2=$((a + b + c + d + e + f + g + h))

didle=$((idle2 - idle1))
dtotal=$((total2 - total1))
if [ "$dtotal" -gt 0 ]; then
  cpu=$(( (100 * (dtotal - didle) + dtotal / 2) / dtotal ))
else
  cpu=0
fi

ram=$(awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf "%d", (t-a)*100/t + 0.5}' /proc/meminfo)

printf "<span size='13000' foreground='#6666ff'>󰍛 </span>%03d%%<span foreground='#665c54'>|</span>%03d%% \n" "$cpu" "$ram"
