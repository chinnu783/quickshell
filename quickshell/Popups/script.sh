#!/bin/sh

if [ -z "$1" ]; then
    echo "Error: No wallpaper path provided."
    echo "Usage: wl wallpaper.jpg"
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "Error: File '$1' does not exist."
    exit 1
fi

WAL=$1

rm -rf "$HOME/.config/wl/wl.conf"
touch "$HOME/.config/wl/wl.conf"
echo "$WAL" >> "$HOME/.config/wl/wl.conf"
matugen image "$WAL"

# rm -rf /etc/greetd/wal/*
# mkdir -p /etc/greetd/wal
# cp -r "$WAL" /etc/greetd/wal
