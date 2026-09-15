pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

QtObject {
    id: root

    // Exposed color properties for your UI
    property color primary: "#c9bfff"
    property color primaryfg: "#312560"
    property color background: "#141318"
    property color backgroundfg: "#e5e1e9"

    property color surface: "#141318"
    property color surfacefg: "#e5e1e9"
    property color surfacea: "#48454e"
    property color outline: "#938f99"

    property color tertiary: "#edb8cd"
    property color tertiaryfg: "#492536"

    property color secondary: "#c9c3dc"
    property color secondaryfg: "#312e41"

    property color error: "#ffb4ab"
    property color errorfg: "#690005"

    property color module: "#201f25"
    property color module_hover: "#2b2930"

    // Quickshell FileView with JsonAdapter
    property FileView colorFile: FileView {
        path: Quickshell.configPath("colors.json")
        watchChanges: true
        onFileChanged: this.reload()

        JsonAdapter {
            property string primary: "#c9bfff"
            property string primaryfg: "#312560"
            property string background: "#141318"
            property string backgroundfg: "#e5e1e9"

            property string surface: "#141318"
            property string surfacefg: "#e5e1e9"
            property string surfacea: "#48454e"
            property string outline: "#938f99"

            property string tertiary: "#edb8cd"
            property string tertiaryfg: "#492536"

            property string secondary: "#c9c3dc"
            property string secondaryfg: "#312e41"

            property string error: "#ffb4ab"
            property string errorfg: "#690005"

            property string module: "#201f25"
            property string module_hover: "#2b2930"

            onPrimaryChanged: root.primary = primary
            onPrimaryfgChanged: root.primaryfg = primaryfg
            onBackgroundChanged: root.background = background
            onBackgroundfgChanged: root.backgroundfg = backgroundfg
            onSurfaceChanged: root.surface = surface
            onSurfacefgChanged: root.surfacefg = surfacefg
            onSurfaceaChanged: root.surfacea = surfacea
            onOutlineChanged: root.outline = outline
            onTertiaryChanged: root.tertiary = tertiary
            onTertiaryfgChanged: root.tertiaryfg = tertiaryfg
            onSecondaryChanged: root.secondary = secondary
            onSecondaryfgChanged: root.secondaryfg = secondaryfg
            onErrorChanged: root.error = error
            onErrorfgChanged: root.errorfg = errorfg
            onModuleChanged: root.module = module
            onModule_hoverChanged: root.module_hover = module_hover
        }
    }
}
