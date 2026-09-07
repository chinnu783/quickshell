import QtQuick
import Quickshell
import Quickshell.Wayland

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

            // Path to your current wallpaper
            property string currentSource: "file://" + Quickshell.env("HOME") + "/.config/wallpaper/wal21.jpg"
            property string oldSource: ""
            property bool showFront: true

            onCurrentSourceChanged: {
                if (showFront) {
                    backImage.source = currentSource
                    showFront = false
                } else {
                    frontImage.source = currentSource
                    showFront = true
                }
            }

            // Base container
            Rectangle {
                anchors.fill: parent
                color: "#000000"

                // Background layer
                Image {
                    id: backImage
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    opacity: !showFront ? 1.0 : 0.0

                    Behavior on opacity {
                        NumberAnimation { duration: 600; easing.type: Easing.InOutQuad }
                    }
                }

                // Foreground layer
                Image {
                    id: frontImage
                    anchors.fill: parent
                    source: currentSource
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    opacity: showFront ? 1.0 : 0.0

                    Behavior on opacity {
                        NumberAnimation { duration: 600; easing.type: Easing.InOutQuad }
                    }
                }
            }
        }
    }
}
