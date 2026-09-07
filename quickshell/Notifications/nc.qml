import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "../"

PanelWindow {
    id: centerWin

    // Toggle property to show/hide the panel
    property bool open: false

    // Position panel on the right side of the screen
    anchors.top: true
    anchors.bottom: true
    anchors.right: true
    anchors.left: false

    implicitWidth: 380
    color: "transparent"
    visible: open

    WlrLayershell.namespace: "niriha-notif-center"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.exclusionMode: ExclusionMode.Normal
    WlrLayershell.margins.top: 10
    WlrLayershell.margins.bottom: 0
    WlrLayershell.margins.right: 0

    // Notification storage model
    ListModel {
        id: historyModel
    }

    // Capture incoming notifications and keep them in history
    NotificationServer {
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        imageSupported: true

        onNotification: notif => {
            historyModel.insert(0, {
                "notifId": notif.id,
                "appName": notif.appName || "System",
                "summary": notif.summary || "",
                "body": notif.body || "",
                "image": notif.image || notif.appIcon || "",
                "obj": notif
            })
        }
    }

    function removeSingle(id) {
        for (var i = 0; i < historyModel.count; i++) {
            if (historyModel.get(i).notifId === id) {
                var item = historyModel.get(i)
                if (item.obj && typeof item.obj.dismiss === "function") {
                    try { item.obj.dismiss(); } catch(e) {}
                }
                historyModel.remove(i)
                break
            }
        }
    }

    function clearAll() {
        for (var i = 0; i < historyModel.count; i++) {
            var item = historyModel.get(i)
            if (item.obj && typeof item.obj.dismiss === "function") {
                try { item.obj.dismiss(); } catch(e) {}
            }
        }
        historyModel.clear()
    }

    // Main background container
    Rectangle {
        anchors.fill: parent
        radius: 16
        color: Colors.surface
        border.width: 1
        border.color: Colors.outline

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Header Row: Title & Clear All Button
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Notifications"
                    color: Colors.surfacefg
                    font.family: mainFont
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    Layout.fillWidth: true
                }

                // Clear All Button
                Rectangle {
                    width: 80
                    height: 28
                    radius: 8
                    color: clearMa.containsMouse ? Colors.module : "transparent"
                    border.width: 1
                    border.color: Colors.outline
                    visible: historyModel.count > 0

                    Text {
                        anchors.centerIn: parent
                        text: "Clear All"
                        color: Colors.surfacefg
                        font.family: mainFont
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: clearMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: centerWin.clearAll()
                    }
                }

                // Close Panel Button
                Rectangle {
                    width: 28
                    height: 28
                    radius: 8
                    color: closePanelMa.containsMouse ? Colors.module : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: Colors.surfacefg
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: closePanelMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: centerWin.open = false
                    }
                }
            }

            // Divider Line
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colors.outline
                opacity: 0.3
            }

            // Empty State Notice
            Text {
                visible: historyModel.count === 0
                text: "No Notifications"
                color: Colors.outline
                font.family: mainFont
                font.pixelSize: 14
                Layout.alignment: Qt.AlignCenter
                Layout.fillHeight: true
            }

            // Notification List
            ListView {
                id: notifList
                visible: historyModel.count > 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10
                clip: true

                model: historyModel

                delegate: Rectangle {
                    width: notifList.width
                    height: cardRow.implicitHeight + 16
                    radius: 12
                    color: Colors.module
                    border.width: 1
                    border.color: Colors.outline

                    RowLayout {
                        id: cardRow
                        anchors {
                            left: parent.left; leftMargin: 10
                            right: parent.right; rightMargin: 10
                            top: parent.top; topMargin: 8
                        }
                        spacing: 10

                        // App Icon
                        Item {
                            Layout.alignment: Qt.AlignTop
                            width: 32; height: 32

                            IconImage {
                                id: ico
                                anchors.fill: parent
                                smooth: true
                                source: model.image !== "" ? model.image : Quickshell.iconPath(model.image, true)
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                color: Colors.surface
                                visible: ico.status !== Image.Ready

                                Text {
                                    anchors.centerIn: parent
                                    text: (model.appName || "?").charAt(0).toUpperCase()
                                    color: Colors.surfacefg
                                    font.pixelSize: 14; font.weight: Font.Bold
                                }
                            }
                        }

                        // Text Area
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: model.appName || "System"
                                    color: Colors.outline
                                    font.family: mainFont
                                    font.pixelSize: 11
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: "✕"
                                    color: itemCloseMa.containsMouse ? Colors.primary : Colors.outline
                                    font.pixelSize: 11

                                    MouseArea {
                                        id: itemCloseMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: centerWin.removeSingle(model.notifId)
                                    }
                                }
                            }

                            Text {
                                visible: model.summary !== ""
                                text: model.summary
                                color: Colors.surfacefg
                                font.family: mainFont
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: model.body !== ""
                                text: model.body
                                color: Colors.outline
                                font.family: mainFont
                                font.pixelSize: 11
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                maximumLineCount: 4
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}
