import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import ".."

PanelWindow {
    id: root

    implicitWidth: 1140
    implicitHeight: 560
    visible: false

    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Inner container holds the opacity and smooth fade animation
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
            width: root.implicitWidth
            height: root.implicitHeight
            color: Colors.surface
            radius: 16
            border.color: Colors.outline
            border.width: 1

            MouseArea { anchors.fill: parent }

            Column {
                anchors.fill: parent
                anchors.margins: 30
                spacing: 18

                // Text {
                //     text: "Select Wallpaper"
                //     color: Colors.primary
                //     font.pixelSize: 22
                //     font.bold: true
                // }

                GridView {
                    id: grid
                    width: parent.width
                    height: parent.height - 10
                    cellWidth: Math.floor(width / 4)
                    cellHeight: 170
                    clip: true

                    // Light buffer for smooth scroll without main-thread freezes
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
                            anchors.fill: parent
                            anchors.margins: 8
                            radius: 12
                            color: Colors.module
                            border.color: Colors.outline
                            border.width: 1

                            // Container for image + bottom bar that gets masked with rounded corners
                            Item {
                                id: contentContainer
                                anchors.fill: parent
                                visible: false // Hidden because MultiEffect renders it with rounded corners

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

                            // Clips the entire contentContainer to a 12px corner radius
                            MultiEffect {
                                anchors.fill: parent
                                source: contentContainer
                                maskEnabled: true
                                maskSource: mask

                                Item {
                                    id: mask
                                    width: parent.width
                                    height: parent.height
                                    layer.enabled: true
                                    visible: false

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 12
                                        color: "black"
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    var targetPath = model.filePath;
                                    var configPath = Quickshell.env("HOME").trim() + "/.config/wl/wl.conf";

                                    // applyCmd.command = [
                                    //     "sh", "-c",
                                    //     "echo \"" + targetPath + "\" > \"" + configPath + "\" && matugen image \"" + targetPath + "\" --source-color-index 0 && rm -r /etc/greetd/wal && mkdir /etc/greetd/wal && cp \"" + targetPath + "\" /etc/greetd/wal/"
                                    // ];
                                    applyCmd.command = [ "/home/dev/.config/quickshell/Wallpaper/script.sh " + targetPath ]
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

    // Functions to handle smooth show/hide transitions
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
