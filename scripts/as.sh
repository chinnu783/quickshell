#!/bin/bash

# Walker
pkill elephant
pkill walker
walker --gapplication-service >/dev/null 2>&1 &
elephant >/dev/null 2>&1 &

# SwayIDLE
pkill swayidle
swayidle -w \
  timeout 240 'brightnessctl -s set 10' \
  resume 'brightnessctl -r' \
  timeout 295 'notify-send "Security" "Locking screen in 5 seconds..." -i security-high' \
  timeout 299 'brightnessctl -r' \
  timeout 300 'hyprlock &' \
  timeout 420 'systemctl suspend'
  resume 'notify-send "Security" "Welcome Back!!!"' >/dev/null 2>&1 &

# Waybar
pkill waybar
waybar >/dev/null 2>&1 &

# SwayOSD
pkill swayosd-server
swayosd-server >/dev/null 2>&1 &

# SwayNC
pkill swaync
swaync >/dev/null 2>&1 &
sleep 2
swaync-client -rs

# Define a fallback wallpaper path if the pointer file doesn't exist yet
DEFAULT_WAL="wal10.png"
CACHE_FILE="$HOME/.cache/matugen/current_wal"

# Check if a saved wallpaper exists; if so, read it. Otherwise, use the fallback.
if [ -f "$CACHE_FILE" ]; then
    CURRENT_WAL=$(cat "$CACHE_FILE")
    # Verify the cached file still physically exists on disk
    if [ ! -f "$CURRENT_WAL" ]; then
        CURRENT_WAL=$DEFAULT_WAL
    fi
else
    CURRENT_WAL=$DEFAULT_WAL
fi

# /home/dev/.config/scripts/wl.sh "$CURRENT_WAL"
