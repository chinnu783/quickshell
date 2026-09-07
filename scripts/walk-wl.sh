#!/bin/bash

WAL_DIR="$HOME/.config/wallpaper"

if [ ! -d "$WAL_DIR" ]; then
    # Walker doesn't have an error popup box built-in like rofi -e, 
    # so we use standard notify-send for errors.
    notify-send "Error" "Wallpaper directory '$WAL_DIR' does not exist."
    exit 1
fi

SELECTION_PATH=$(
    for img in "$WAL_DIR"/*; do
        [[ "$img" =~ \.(jpg|jpeg|png|webp|JPG|PNG)$ ]] || continue

        # Walker format: label||subtext||icon_path
        # We pass the full path as the label so Walker returns the full path upon selection.
        printf "%s\0icon\x1f%s\n" $(basename "$img") "$img"
    done | walker --dmenu
)

if [ -n "$SELECTION_PATH" ]; then
    "$HOME/.config/scripts/wl.sh" "$SELECTION_PATH"
fi
