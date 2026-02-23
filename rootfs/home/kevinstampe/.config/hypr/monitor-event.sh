#!/bin/sh

handle() {
  case $1 in
    monitoradded*|monitorremoved*)
      ~/.config/hypr/lid-init.sh
      ;;
  esac
}

# The -u flag in stdbuf ensures the output isn't buffered
stdbuf -oL socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
    handle "$line"
done
