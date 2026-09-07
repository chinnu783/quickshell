#!/bin/bash

if [ -z "$1" ]; then
    echo "Error: No wallpaper path provided."
    echo "Usage: wl wallpaper.jpg"
    exit 1
fi

WAL=$1
WAL_PATH=$(realpath "$HOME/.config/wallpaper/$WAL")

if [ ! -f "$WAL_PATH" ]; then
    echo "Error: File '$WAL_PATH' does not exist."
    exit 1
fi

# Ensure our target wlust storage tree is alive
mkdir -p "$HOME/.cache/wlust"

# Create the configuration folder if it does not exist yet
mkdir -p "$HOME/.config/wl"

# Save this absolute path so the autostart script can read it on boot
echo "$WAL" > "$HOME/.cache/matugen/current_wal"
echo "\$wallpaper = $WAL_PATH" > "$HOME/.config/wl/wl.conf"

# Ensure the awww daemon is running before calling commands
if ! pgrep -x "awww-daemon" >/dev/null; then
    echo "Initializing awww daemon..."
    awww-daemon &
    sleep 0.5
fi

# Handle background layers using awww
# (Optional: Swap '--transition-type simple' out for 'outer', 'wipe', 'random', etc.)
awww img "$WAL_PATH" --transition-type random --transition-fps 60 >/dev/null 2>&1

# Execute Matugen
matugen image "$WAL_PATH" --source-color-index 0

cp "$WAL_PATH" "$HOME/.cache/matugen/current_wal"

# Reload UI configurations safely
#"$HOME/.config/scripts/as.sh"

notify-send "Theme" "Changed successfully to $(basename "$WAL_PATH")" -i "$WAL_PATH"
