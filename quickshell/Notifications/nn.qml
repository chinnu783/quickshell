import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "../"

PanelWindow {
    id: win

    anchors.top: true
    anchors.right: true
    anchors.left: false

    implicitWidth: 380
    implicitHeight: col.implicitHeight + 16
    color: "transparent"
    visible: notifModel.count > 0

    WlrLayershell.namespace: "niriha-notif"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    WlrLayershell.margins.top: 40
    WlrLayershell.margins.right: 15

    // Local notification model (Crash-Proof)
    ListModel {
        id: notifModel
    }

    // Direct listener on Quickshell's NotificationServer
    NotificationServer {
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        imageSupported: true

        onNotification: notif => {
            var id = notif.id
            var appName = notif.appName || "System"
            var summary = notif.summary || ""
            var body = notif.body || ""
            var image = notif.image || notif.appIcon || ""

            notifModel.append({
                "notifId": id,
                "appName": appName,
                "summary": summary,
                "body": body,
                "image": image,
                "obj": notif
            })

            var ms = notif.urgency === Notification.Critical ? 6000 : 3000

            // Auto-dismiss timer
            var t = Qt.createQmlObject(
                'import QtQuick; Timer { interval: ' + ms + '; running: true; repeat: false }',
                win, "notifTimer"
            )
            t.triggered.connect(function() {
                removeNotif(id)
                t.destroy()
            })
        }
    }

    function removeNotif(id) {
        for (var i = 0; i < notifModel.count; i++) {
            if (notifModel.get(i).notifId === id) {
                var item = notifModel.get(i)
                if (item.obj && typeof item.obj.dismiss === "function") {
                    try { item.obj.dismiss(); } catch(e) {}
                }
                notifModel.remove(i)
                break
            }
        }
    }

    Column {
        id: col
        anchors.top: parent.top
        anchors.topMargin: 6
        anchors.right: parent.right
        anchors.rightMargin: 8
        width: parent.width - 16
        spacing: 8

        Repeater {
            model: notifModel

            Rectangle {
                id: card

                width: col.width
                height: row.implicitHeight + 16
                radius: 12

                color: Colors.surface
                border.width: 1
                border.color: Colors.outline
                opacity: 0.95

                RowLayout {
                    id: row
                    anchors {
                        left: parent.left; leftMargin: 12
                        right: parent.right; rightMargin: 10
                        top: parent.top; topMargin: 8
                    }
                    spacing: 10

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
                            color: Colors.module
                            visible: ico.status !== Image.Ready

                            Text {
                                anchors.centerIn: parent
                                text: (model.appName || "?").charAt(0).toUpperCase()
                                color: Colors.surfacefg
                                font.pixelSize: 14; font.weight: Font.Bold
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: model.appName || "System"
                                color: Colors.outline; font.family: "Google Sans"; font.pixelSize: 11
                                Layout.fillWidth: true; elide: Text.ElideRight
                            }

                            Text {
                                text: "✕"; color: closeMa.containsMouse ? Colors.primary : Colors.outline
                                font.pixelSize: 12

                                MouseArea {
                                    id: closeMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: win.removeNotif(model.notifId)
                                }
                            }
                        }

                        Text {
                            visible: model.summary !== ""
                            text: model.summary
                            color: Colors.surfacefg; font.family: "Google Sans"
                            font.pixelSize: 14; font.weight: Font.Medium
                            Layout.fillWidth: true; wrapMode: Text.WordWrap
                            maximumLineCount: 2; elide: Text.ElideRight
                            textFormat: Text.PlainText
                        }

                        Text {
                            visible: model.body !== ""
                            text: model.body
                            color: Colors.outline; font.family: "Google Sans"; font.pixelSize: 12
                            Layout.fillWidth: true; wrapMode: Text.WordWrap
                            maximumLineCount: 3; elide: Text.ElideRight
                            textFormat: Text.PlainText
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.removeNotif(model.notifId)
                }
            }
        }
    }
}
