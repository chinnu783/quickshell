pragma Singleton
import QtQuick

QtObject {
    // Primary & Background
    readonly property color primary: "{{colors.primary.default.hex}}"
    readonly property color primaryfg: "{{colors.on_primary.default.hex}}"
    readonly property color background: "{{colors.background.default.hex}}"
    readonly property color backgroundfg: "{{colors.on_background.default.hex}}"
    
    // Surfaces & Accents
    readonly property color surface: "{{colors.surface.default.hex}}"
    readonly property color surfacefg: "{{colors.on_surface.default.hex}}"
    readonly property color surfacea: "{{colors.surface_variant.default.hex}}"
    readonly property color outline: "{{colors.outline.default.hex}}"

    readonly property color tertiary: "{{colors.tertiary.default.hex}}"
    readonly property color tertiaryfg: "{{colors.on_tertiary.default.hex}}"

    readonly property color secondary: "{{colors.secondary.default.hex}}"
    readonly property color secondaryfg: "{{colors.on_secondary.default.hex}}"

    readonly property color error: "{{colors.error.default.hex}}"
    readonly property color errorfg: "{{colors.on_error.default.hex}}"

    readonly property color module: "{{colors.surface_container.default.hex}}"
    readonly property color module_hover: "{{colors.surface_container_high.default.hex}}"


}
