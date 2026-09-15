import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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

    // Fixed card height and spacing configuration
    readonly property int cardHeight: 100
    readonly property int cardSpacing: 8

    // Maximum available panel height based on monitor resolution
    property int maxPanelHeight: win.screen ? (win.screen.height - 120) : 700

    // Fit panel height to match the exact number of visible uniform cards
    implicitHeight: Math.min(col.implicitHeight + 16, maxPanelHeight)

    color: "transparent"
    visible: notifModel.count > 0

    WlrLayershell.namespace: "niriha-notif"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    WlrLayershell.margins.top: 40
    WlrLayershell.margins.right: 15

    ListModel {
        id: notifModel
    }

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

            var image = ""
            if (notif.image) {
                image = notif.image
            } else if (notif.appIcon) {
                image = notif.appIcon
            }

            notifModel.insert(0, {
                "notifId": id,
                "appName": appName,
                "summary": summary,
                "body": body,
                "image": image,
                "obj": notif
            })

            var ms = notif.urgency === Notification.Critical ? 8000 : 4000

            var t = Qt.createQmlObject(
                'import QtQuick; Timer { interval: ' + ms + '; running: true; repeat: false }',
                win, "notifTimer_" + id
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

    // Calculate exactly how many fixed-size cards can fit without going off-screen
    property int maxVisibleCards: Math.max(1, Math.floor((maxPanelHeight - 40) / (cardHeight + cardSpacing)))
    property int hiddenCount: Math.max(0, notifModel.count - maxVisibleCards)

    Column {
        id: col
        anchors.top: parent.top
        anchors.topMargin: 6
        anchors.right: parent.right
        anchors.rightMargin: 8
        width: parent.width - 16
        spacing: win.cardSpacing

        Repeater {
            model: Math.min(notifModel.count, win.maxVisibleCards)

            delegate: Rectangle {
                id: card

                required property int index

                property var itemData: notifModel.get(index)
                property int notifId: itemData ? itemData.notifId : 0
                property string appName: itemData ? itemData.appName : ""
                property string summary: itemData ? itemData.summary : ""
                property string body: itemData ? itemData.body : ""
                property string image: itemData ? itemData.image : ""
                property var obj: itemData ? itemData.obj : null

                width: col.width
                // Uniform height for every notification card
                height: win.cardHeight
                radius: 14

                color: Colors.surface
                border.width: 1
                border.color: cardMa.containsMouse ? Colors.primary : Colors.outline
                opacity: 0.98

                Behavior on border.color {
                    ColorAnimation { duration: 150 }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    // Icon (Fixed Size)
                    Item {
                        Layout.alignment: Qt.AlignTop
                        width: 36; height: 36

                        IconImage {
                            id: ico
                            anchors.fill: parent
                            smooth: true
                            source: card.image !== "" ? card.image : Quickshell.iconPath("dialog-information", true)
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: Colors.module
                            visible: ico.status !== Image.Ready

                            Text {
                                anchors.centerIn: parent
                                text: (card.appName || "?").charAt(0).toUpperCase()
                                color: Colors.surfacefg
                                font.pixelSize: 14; font.weight: Font.Bold
                            }
                        }
                    }

                    // Notification Content
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 2

                        // Header Row (App Name & Close Button)
                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: card.appName || "System"
                                color: Colors.outline
                                font.family: mainFont
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Item {
                                width: 18; height: 18

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    color: closeMa.containsMouse ? Colors.primary : Colors.outline
                                    font.pixelSize: 12
                                }

                                MouseArea {
                                    id: closeMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: win.removeNotif(card.notifId)
                                }
                            }
                        }

                        // Summary Text (Strict 1 line)
                        Text {
                            visible: card.summary !== ""
                            text: card.summary
                            color: Colors.surfacefg
                            font.family: mainFont
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            Layout.fillWidth: true
                            maximumLineCount: 1
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                        }

                        // Body Text (Strict 2 lines)
                        Text {
                            visible: card.body !== ""
                            text: card.body
                            color: Colors.outline
                            font.family: mainFont
                            font.pixelSize: 12
                            Layout.fillWidth: true
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                        }

                        // Action Buttons (Fixed Row at bottom)
                        RowLayout {
                            Layout.fillWidth: true
                            visible: card.obj && card.obj.actions && card.obj.actions.length > 0
                            spacing: 6

                            Repeater {
                                model: card.obj ? card.obj.actions : []

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 22
                                    radius: 6
                                    color: actionMa.containsMouse ? Colors.module_hover : Colors.module
                                    border.width: 1
                                    border.color: Colors.outline

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.text || modelData.id
                                        color: Colors.surfacefg
                                        font.pixelSize: 10
                                        font.weight: Font.Medium
                                    }

                                    MouseArea {
                                        id: actionMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (card.obj && typeof card.obj.invokeAction === "function") {
                                                card.obj.invokeAction(modelData.id)
                                            }
                                            win.removeNotif(card.notifId)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    id: cardMa
                    anchors.fill: parent
                    z: -1
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.removeNotif(card.notifId)
                }
            }
        }

        // Overflow Indicator Pill
        Rectangle {
            width: col.width
            height: 30
            radius: 10
            visible: win.hiddenCount > 0
            color: Colors.module
            border.width: 1
            border.color: Colors.outline

            Text {
                anchors.centerIn: parent
                text: "+" + win.hiddenCount + " more notification" + (win.hiddenCount > 1 ? "s" : "")
                color: Colors.surfacefg
                font.family: mainFont
                font.pixelSize: 12
                font.weight: Font.Medium
            }
        }
    }
}
