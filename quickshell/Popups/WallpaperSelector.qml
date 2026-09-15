import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
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

    // Mask the entire screen only when visible to handle click-outside-to-close.
    // When hidden, set an empty Region so scrolling/clicking in underlying apps works.
    mask: Region {
        item: root.visible ? container : null
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "qs-wallpaper-selector"

    WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Inner container holds opacity for smooth fade animation
    Item {
        id: container
        anchors.fill: parent
        opacity: 0

        Behavior on opacity {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        // ── BACKDROP CLICK & SCROLL PASS-THROUGH ──────────────────────────────
        Item {
            anchors.fill: parent

            MouseArea {
                anchors.fill: parent

                // Close selector when clicking empty backdrop space
                onClicked: root.closeSelector()

                // Crucial: Pass scroll wheel events down to underlying apps
                onWheel: (wheel) => {
                    wheel.accepted = false;
                }
            }
        }

        // ── THE VISUAL WRAPPER ──────────────────────────────────────────────
        Item {
            id: mainWrapper
            width: bgPanel.width + 48
            height: bgPanel.height + 54
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter

            focus: true
            Keys.onEscapePressed: root.closeSelector()

            // Left Flaring Concave Corner )
            Canvas {
                id: leftWing
                width: 24
                height: 24
                renderTarget: Canvas.Image
                anchors.top: bgPanel.top
                anchors.right: bgPanel.left

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    ctx.fillStyle = Colors.surface;

                    ctx.beginPath();
                    ctx.moveTo(width, 0);
                    ctx.lineTo(width, height);
                    ctx.arcTo(width, 0, 0, 0, width);
                    ctx.closePath();
                    ctx.fill();
                }
            }

            // Main Selector Panel Body ───────
            Rectangle {
                id: bgPanel
                width: root.windowWidth
                height: root.windowHeight
                anchors.top: parent.top
                anchors.topMargin: 54
                anchors.horizontalCenter: parent.horizontalCenter
                color: Colors.surface

                topLeftRadius: 0
                topRightRadius: 0
                bottomLeftRadius: 16
                bottomRightRadius: 16

                // Prevent clicks inside the selector box from triggering the backdrop close
                MouseArea {
                    anchors.fill: parent
                    propagateComposedEvents: false
                }
            }

            // Right Flaring Concave Corner (
            Canvas {
                id: rightWing
                width: 24
                height: 24
                renderTarget: Canvas.Image
                anchors.top: bgPanel.top
                anchors.left: bgPanel.right

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    ctx.fillStyle = Colors.surface;

                    ctx.beginPath();
                    ctx.moveTo(0, 0);
                    ctx.lineTo(0, height);
                    ctx.arcTo(0, 0, width, 0, width);
                    ctx.closePath();
                    ctx.fill();
                }
            }

            // ── Content Layout Nested inside mainWrapper ──
            Item {
                width: bgPanel.width - 40
                height: bgPanel.height - 40
                anchors.centerIn: bgPanel

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
                                        font.family: mainFont
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            Rectangle {
                                id: maskShape
                                width: contentContainer.width
                                height: contentContainer.height
                                radius: 12
                                color: "black"
                                visible: false
                                layer.enabled: true
                            }

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
                                    var scriptPath = Quickshell.env("HOME").trim() + "/.config/quickshell/Popups/script.sh";

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

    function openSelector() {
        root.visible = true;
        container.opacity = 1;
        mainWrapper.forceActiveFocus();
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
