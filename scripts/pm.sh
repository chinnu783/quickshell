#!/bin/bash

# Font Awesome 6 Free Solid equivalents
LOCK=""      # lock
LOGOUT=""    # sign-out-alt
SUSPEND=""   # moon
REBOOT="󰑓"    # cycle / sync (or use  for redo/refresh)
SHUTDOWN=""  # power-off

CHOSEN=$(printf "$LOCK\n$LOGOUT\n$SUSPEND\n$REBOOT\n$SHUTDOWN" | rofi -dmenu -theme ~/.config/rofi/pm.rasi)

case "$CHOSEN" in
    *""*) hyprlock ;;
    *""*) loginctl terminate-user "$USER" ;;
    *""*) systemctl suspend ;;
    *"󰑓"*|*""*) systemctl reboot ;;
    *""*) systemctl poweroff ;;
esac
