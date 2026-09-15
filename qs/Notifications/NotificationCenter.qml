import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import ".."

PanelWindow {
    id: root

    readonly property int panelWidth: 420
    readonly property int panelHeight: 680

    visible: true
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Dynamic Input Mask: Drops to null when hidden so clicks/scrolls pass through to apps below
    mask: Region {
        item: (container.opacity > 0) ? fullClickOverlay : null
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: container.opacity > 0 ? WlrLayer.Top : WlrLayer.Background
    WlrLayershell.namespace: "qs-notification-center"
    WlrLayershell.keyboardFocus: container.opacity > 0 ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Item {
        id: container
        anchors.fill: parent
        opacity: 0
        visible: opacity > 0.001

        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        // Fullscreen overlay to capture clicks outside the drawer
        Item {
            id: fullClickOverlay
            anchors.fill: parent

            MouseArea {
                anchors.fill: parent
                onClicked: root.closeCenter()
            }

            // ── THE NOTIFICATION DRAWER CONTAINER ──────────────────────────────
            Item {
                id: mainWrapper
                width: bgPanel.width + 48
                height: bgPanel.height + 54
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.rightMargin: 20

                focus: true
                Keys.onEscapePressed: root.closeCenter()

                // Left Flaring Concave Corner
                Canvas {
                    id: leftWing
                    width: 24
                    height: 24
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

                // Main Drawer Body
                Rectangle {
                    id: bgPanel
                    width: root.panelWidth
                    height: root.panelHeight
                    anchors.top: parent.top
                    anchors.topMargin: 54
                    anchors.right: parent.right
                    color: Colors.surface
                    radius: 16

                    // Prevent click leakage inside the drawer
                    MouseArea {
                        anchors.fill: parent
                        propagateComposedEvents: false
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 16

                        // Header Bar
                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "Notifications"
                                color: Colors.surfacefg
                                font.pixelSize: 18
                                font.bold: true
                                Layout.fillWidth: true
                            }

                            // Clear All Button
                            Rectangle {
                                width: 80
                                height: 30
                                radius: 8
                                color: clearMouse.containsMouse ? Colors.module_hover : Colors.module

                                Text {
                                    anchors.centerIn: parent
                                    text: "Clear All"
                                    color: Colors.surfacefg
                                    font.pixelSize: 12
                                }

                                MouseArea {
                                    id: clearMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        for (var i = NotificationServer.notifications.values.length - 1; i >= 0; i--) {
                                            NotificationServer.notifications.values[i].dismiss();
                                        }
                                    }
                                }
                            }
                        }

                        // Notification List
                        ListView {
                            id: notifList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 10

                            model: NotificationServer.notifications.values

                            delegate: Rectangle {
                                width: notifList.width
                                height: 80
                                radius: 12
                                color: Colors.module

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 12

                                    // App Icon / Image placeholder
                                    Rectangle {
                                        width: 40
                                        height: 40
                                        radius: 8
                                        color: Colors.surface

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰂚"
                                            color: Colors.surfacefg
                                            font.pixelSize: 20
                                        }
                                    }

                                    // Summary & Body
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            text: modelData.summary || "Notification"
                                            color: Colors.surfacefg
                                            font.pixelSize: 13
                                            font.bold: true
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: modelData.body || ""
                                            color: Colors.surfacefg
                                            font.pixelSize: 11
                                            opacity: 0.8
                                            elide: Text.ElideRight
                                            maxLineCount: 2
                                            Layout.fillWidth: true
                                        }
                                    }

                                    // Close Single Notification
                                    MouseArea {
                                        width: 24
                                        height: 24
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: modelData.dismiss()

                                        Text {
                                            anchors.centerIn: parent
                                            text: "✕"
                                            color: Colors.surfacefg
                                            font.pixelSize: 12
                                            opacity: 0.6
                                        }
                                    }
                                }
                            }

                            // Empty State
                            Item {
                                anchors.centerIn: parent
                                visible: notifList.count === 0

                                Text {
                                    anchors.centerIn: parent
                                    text: "No New Notifications"
                                    color: Colors.surfacefg
                                    font.pixelSize: 14
                                    opacity: 0.5
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function openCenter() {
        container.opacity = 1;
        mainWrapper.forceActiveFocus();
    }

    function closeCenter() {
        container.opacity = 0;
    }

    // Listens specifically to notification IPC commands
    IpcHandler {
        target: "notif"

        function toggle() {
            if (container.opacity > 0) {
                root.closeCenter();
            } else {
                root.openCenter();
            }
        }
    }
}
