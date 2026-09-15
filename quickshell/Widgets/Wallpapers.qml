import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../Popups"
import ".."

Scope {
    id: wallpaperScope

    readonly property string wallpaperDir: Quickshell.env("HOME") + "/.config/wallpaper/"
    readonly property string configFilePath: Quickshell.env("HOME") + "/.config/wl/wl.conf"

    property string currentWallpaper: ""

    // Tail the config file continuously
    Process {
        id: configWatcher
        command: [
            "sh", "-c",
            "mkdir -p '$HOME/.config/wl' && touch '" + wallpaperScope.configFilePath + "' && tail -F -n 1 '" + wallpaperScope.configFilePath + "'"
        ]
        running: true

        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (line.length === 0) return

                // Extract filename from lines like "$wallpaper = /path/to/wal25.jpg" or "wal25.jpg"
                var cleanName = line
                if (cleanName.includes("=")) {
                    cleanName = cleanName.split("=")[1].trim()
                }

                cleanName = cleanName.substring(cleanName.lastIndexOf("/") + 1).replace(/['"]/g, "")

                // Only update if the wallpaper name actually changed
                if (cleanName.length > 0 && cleanName !== wallpaperScope.currentWallpaper) {
                    wallpaperScope.currentWallpaper = cleanName
                }
            }
        }
    }

    // Render wallpaper on all screens with smooth crossfade
    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                required property var modelData
                screen: modelData

                WlrLayershell.layer: WlrLayer.Background
                WlrLayershell.namespace: "wallpaper"
                exclusionMode: ExclusionMode.Ignore

                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }

                // Ensure proper file:// URL format
                property string targetSource: wallpaperScope.currentWallpaper !== ""
                    ? "file://" + wallpaperScope.wallpaperDir + wallpaperScope.currentWallpaper
                    : ""
                property bool showFront: false

                onTargetSourceChanged: {
                    if (targetSource === "") return

                    if (showFront) {
                        backImage.source = targetSource
                        showFront = false
                    } else {
                        frontImage.source = targetSource
                        showFront = true
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: "#000000"

                    Image {
                        id: backImage
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        asynchronous: true // Prevents UI micro-stutters during heavy image decodes
                        opacity: !showFront ? 1.0 : 0.0

                        Behavior on opacity {
                            NumberAnimation { duration: 600; easing.type: Easing.InOutQuad }
                        }
                    }

                    Image {
                        id: frontImage
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        asynchronous: true // Prevents UI micro-stutters during heavy image decodes
                        opacity: showFront ? 1.0 : 0.0

                        Behavior on opacity {
                            NumberAnimation { duration: 600; easing.type: Easing.InOutQuad }
                        }
                    }
                }
            }
        }
    }
}
