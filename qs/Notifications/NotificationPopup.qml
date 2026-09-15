import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../"

PanelWindow {
    id: win

    anchors.top: true
    anchors.right: true
    anchors.left: false

    implicitWidth: 380

    readonly property int cardHeight: 100
    readonly property int cardSpacing: 8

    property int maxPanelHeight: win.screen ? (win.screen.height - 120) : 700

    implicitHeight: Math.min(col.implicitHeight + 16, maxPanelHeight)
    color: "transparent"
    visible: NotifService.activePopups.length > 0

    WlrLayershell.namespace: "niriha-notif"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    WlrLayershell.margins.top: 40
    WlrLayershell.margins.right: 15

    property int maxVisibleCards: Math.max(1, Math.floor((maxPanelHeight - 40) / (cardHeight + cardSpacing)))

    Column {
        id: col
        anchors.top: parent.top
        anchors.topMargin: 6
        anchors.right: parent.right
        anchors.rightMargin: 8
        width: parent.width - 16
        spacing: win.cardSpacing

        Repeater {
            model: Math.min(NotifService.activePopups.length, win.maxVisibleCards)

            delegate: Rectangle {
                id: card
                required property int index

                // Notification Object Reference
                property var n: NotifService.activePopups[index]
                property int notifId: n ? (n.id || 0) : 0

                // Safe Property Extraction with fallbacks
                property string appNameText: {
                    if (!n) return "System"
                    return (n.appName && n.appName !== "") ? n.appName : "System"
                }
                property string summaryText: {
                    if (!n) return ""
                    return (n.summary && n.summary !== "") ? n.summary : ((n.title && n.title !== "") ? n.title : "Notification")
                }
                property string bodyText: {
                    if (!n) return ""
                    return (n.body && n.body !== "") ? n.body : ((n.text && n.text !== "") ? n.text : "")
                }
                property string imageSrc: {
                    if (!n) return ""
                    if (n.image && n.image !== "") return n.image
                    if (n.icon && n.icon !== "") return n.icon
                    if (n.appIcon && n.appIcon !== "") return n.appIcon
                    return ""
                }

                width: col.width
                height: win.cardHeight
                radius: 14

                color: Colors.surface
                border.width: 1
                border.color: cardMa.containsMouse ? Colors.primary : Colors.outline
                opacity: 0.98

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    // App / Notification Icon
                    Item {
                        Layout.alignment: Qt.AlignTop
                        width: 36; height: 36

                        IconImage {
                            id: ico
                            anchors.fill: parent
                            smooth: true
                            source: card.imageSrc !== "" ? card.imageSrc : Quickshell.iconPath("dialog-information", true)
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: Colors.module
                            visible: ico.status !== Image.Ready

                            Text {
                                anchors.centerIn: parent
                                text: (card.appNameText || "?").charAt(0).toUpperCase()
                                color: Colors.surfacefg
                                font.pixelSize: 14
                                font.weight: Font.Bold
                            }
                        }
                    }

                    // Card Content
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 2

                        // Header Row: App Name + Close Button
                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: card.appNameText
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
                                    onClicked: NotifService.dismissToast(card.notifId)
                                }
                            }
                        }

                        // Summary / Title
                        Text {
                            text: card.summaryText
                            color: Colors.surfacefg
                            font.family: mainFont
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            Layout.fillWidth: true
                            maximumLineCount: 1
                            elide: Text.ElideRight
                        }

                        // Body Description
                        Text {
                            visible: card.bodyText !== ""
                            text: card.bodyText
                            color: Colors.outline
                            font.family: mainFont
                            font.pixelSize: 12
                            Layout.fillWidth: true
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }

                        // Action Buttons
                        RowLayout {
                            Layout.fillWidth: true
                            visible: card.n && card.n.actions && card.n.actions.length > 0
                            spacing: 6

                            Repeater {
                                model: card.n ? card.n.actions : []

                                Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    height: 22
                                    radius: 6
                                    color: actionMa.containsMouse ? Colors.module_hover : Colors.module
                                    border.width: 1
                                    border.color: Colors.outline

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.text || modelData.label || modelData.id || "Action"
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
                                            if (modelData && typeof modelData.invoke === "function") {
                                                modelData.invoke()
                                            }
                                            NotifService.dismissToast(card.notifId)
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
                    onClicked: NotifService.dismissToast(card.notifId)
                }
            }
        }
    }
}
