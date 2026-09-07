import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import ".."

PanelWindow {
    id: root

    readonly property int windowWidth: 1140
    readonly property int windowHeight: 560

    visible: false
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Inner container holds opacity for smooth fade animation
    Item {
        id: container
        anchors.fill: parent
        opacity: 0

        Behavior on opacity {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        // Modal background overlay
        Rectangle {
            anchors.fill: parent
            color: "#80000000"

            MouseArea {
                anchors.fill: parent
                onClicked: root.closeSelector()
            }
        }

        // Main centered popup box
        Rectangle {
            anchors.centerIn: parent
            width: root.windowWidth
            height: root.windowHeight
            color: Colors.surface
            radius: 16
            border.color: Colors.outline
            border.width: 1

            MouseArea { anchors.fill: parent }

            Item {
                anchors.fill: parent
                anchors.margins: 20

                GridView {
                    id: grid
                    anchors.fill: parent
                    cellWidth: Math.floor(width / 4)
                    cellHeight: 170
                    clip: true
                    cacheBuffer: 300

                    model: FolderListModel {
                        id: folderModel
                        folder: "file://" + Quickshell.env("HOME").trim() + "/.config/wallpaper"
                        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.JPG", "*.PNG", "*.WEBP"]
                        showDirs: false
                        caseSensitive: false
                    }

                    delegate: Item {
                        width: grid.cellWidth
                        height: grid.cellHeight

                        Rectangle {
                            id: card
                            anchors.fill: parent
                            anchors.margins: 8
                            radius: 12
                            color: Colors.module
                            border.color: Colors.outline
                            border.width: 1

                            // Container for Image + Bar
                            Item {
                                id: contentContainer
                                anchors.fill: parent
                                visible: false

                                Image {
                                    anchors.fill: parent
                                    source: model.fileUrl
                                    fillMode: Image.PreserveAspectCrop
                                    cache: true
                                    asynchronous: true
                                    sourceSize.width: 320
                                    sourceSize.height: 200
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 28
                                    color: Colors.module_hover

                                    Text {
                                        anchors.centerIn: parent
                                        width: parent.width - 12
                                        text: model.fileName
                                        color: Colors.surfacefg
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            // Shared Mask
                            Rectangle {
                                id: maskShape
                                width: contentContainer.width
                                height: contentContainer.height
                                radius: 12
                                color: "black"
                                visible: false
                                layer.enabled: true
                            }

                            // Rounded Corner Clip Effect
                            MultiEffect {
                                anchors.fill: parent
                                source: contentContainer
                                maskEnabled: true
                                maskSource: maskShape
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    var targetPath = model.filePath;
                                    var scriptPath = Quickshell.env("HOME").trim() + "/.config/quickshell/Wallpaper/script.sh";

                                    applyCmd.command = [ scriptPath, targetPath ];
                                    applyCmd.running = true;
                                    root.closeSelector();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Process {
        id: applyCmd
    }

    // Smooth Show / Hide Handlers
    function openSelector() {
        root.visible = true;
        container.opacity = 1;
    }

    function closeSelector() {
        container.opacity = 0;
        closeTimer.start();
    }

    Timer {
        id: closeTimer
        interval: 120
        onTriggered: root.visible = false
    }

    IpcHandler {
        target: "wallpaper"

        function toggle() {
            if (root.visible && container.opacity > 0) {
                root.closeSelector();
            } else {
                root.openSelector();
            }
        }
    }
}
