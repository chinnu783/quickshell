#!/bin/bash

WAYBAR_DIR="$HOME/.config/waybar"
CURRENT="$WAYBAR_DIR/style.css"
# ALT="$WAYBAR_DIR/style-alt.css"
# TEMP="$WAYBAR_DIR/style-temp.css"

# # Swap the files cleanly using a temporary holder file
# mv "$CURRENT" "$TEMP"
# mv "$ALT" "$CURRENT"
# mv "$TEMP" "$ALT"

# Kill old waybar instance and force boot with the updated configuration layout
pkill waybar
# waybar -c "$WAYBAR_DIR/config.jsonc" -s "$CURRENT" &
waybar >/dev/null 2>&1 &
