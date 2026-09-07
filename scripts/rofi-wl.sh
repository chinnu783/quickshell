#!/bin/bash

WAL_DIR="$HOME/.config/wallpaper"

if [ ! -d "$WAL_DIR" ]; then
    rofi -e "Error: Wallpaper directory '$WAL_DIR' does not exist."
    exit 1
fi

SELECTION_PATH=$(
    for img in "$WAL_DIR"/*; do
        [[ "$img" =~ \.(jpg|jpeg|png|webp|JPG|PNG)$ ]] || continue

        printf "%s\0icon\x1f%s\n" "$(basename "$img")" "$img"
    done | rofi \
        -dmenu \
        -i \
        -show-icons \
        -p " "
)

if [ -n "$SELECTION_PATH" ]; then
    "$HOME/.config/scripts/wl.sh" "$SELECTION_PATH"
    "$HOME/.config/scripts/as.sh"
fi
