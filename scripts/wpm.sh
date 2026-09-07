#!/bin/sh

# Font Awesome 6 Free Solid equivalents
LOCK=" Lock Screen"      # lock
LOGOUT=" Logout"    # sign-out-alt
SUSPEND=" Sleep"   # moon
REBOOT="󰑓 Reboot"    # cycle / sync (or use  for redo/refresh)
SHUTDOWN=" Power Off"  # power-off

CHOSEN=$(printf "$LOCK\n$LOGOUT\n$SUSPEND\n$REBOOT\n$SHUTDOWN" | walker \
--dmenu \
--nosearch \
--width 90 \
--height 250)

# case "$CHOSEN" in
#     *""*) hyprlock ;;
#     *""*) loginctl terminate-user "$USER" ;;
#     *""*) systemctl suspend ;;
#     *"󰑓"*|*""*) systemctl reboot ;;
#     *""*) systemctl poweroff ;;
# esac
# 
case "$CHOSEN" in
    *"$LOCK"*) 
        uwsm app -- hyprlock ;;
    *"$LOGOUT"*) 
        uwsm stop ;;
    *"$SUSPEND"*) 
        systemctl suspend ;;
    *"$REBOOT"*) 
        systemctl reboot ;;
    *"$SHUTDOWN"*) 
        systemctl poweroff ;;
esac
