#!/bin/sh
# Matugen Foot OSC Color Reload
for t in /dev/pts/[0-9]*; do
  {
    # Special Colors (Background, Foreground, Cursor)
    printf "\033]10;#{{colors.on_surface.default.hex_stripped}}\033\\"
    printf "\033]11;#{{colors.surface.default.hex_stripped}}\033\\"
    printf "\033]12;#{{colors.primary.default.hex_stripped}}\033\\"

    # Normal Colors (0-7)
    printf "\033]4;0;#{{colors.surface_container_highest.default.hex_stripped}}\033\\"
    printf "\033]4;1;#{{colors.error.default.hex_stripped}}\033\\"
    printf "\033]4;2;#{{colors.primary.default.hex_stripped}}\033\\"
    printf "\033]4;3;#{{colors.tertiary.default.hex_stripped}}\033\\"
    printf "\033]4;4;#{{colors.secondary.default.hex_stripped}}\033\\"
    printf "\033]4;5;#{{colors.primary_container.default.hex_stripped}}\033\\"
    printf "\033]4;6;#{{colors.outline.default.hex_stripped}}\033\\"
    printf "\033]4;7;#{{colors.on_surface_variant.default.hex_stripped}}\033\\"

    # Bright Colors (8-15)
    printf "\033]4;8;#{{colors.outline_variant.default.hex_stripped}}\033\\"
    printf "\033]4;9;#{{colors.error.default.hex_stripped}}\033\\"
    printf "\033]4;10;#{{colors.primary.default.hex_stripped}}\033\\"
    printf "\033]4;11;#{{colors.tertiary.default.hex_stripped}}\033\\"
    printf "\033]4;12;#{{colors.secondary.default.hex_stripped}}\033\\"
    printf "\033]4;13;#{{colors.primary_container.default.hex_stripped}}\033\\"
    printf "\033]4;14;#{{colors.outline.default.hex_stripped}}\033\\"
    printf "\033]4;15;#{{colors.on_surface.default.hex_stripped}}\033\\"
  } > "$t" 2>/dev/null
done
