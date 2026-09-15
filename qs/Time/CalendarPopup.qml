import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../"

PanelWindow {
    id: cal

    anchors.top: true
    anchors.bottom: true
    anchors.left: false
    anchors.right: true

    width: 380
    color: "transparent"
    visible: false

    WlrLayershell.namespace: "qs-cal"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.margins.top: 60
    WlrLayershell.margins.bottom: 20
    WlrLayershell.margins.right: 20

    // ── Calendar State ───────────────────────────────────────────────────
    property int viewYear: 0
    property int viewMonth: 0

    readonly property var days: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
    readonly property var months: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    readonly property var dayNames: [
        "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
    ]

    property string clockH: "00"
    property string clockM: "00"
    property string clockS: "00"
    property string dayName: ""
    property string dateStr: ""

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var now = new Date()
            var h24 = now.getHours()
            var h12 = h24 % 12
            if (h12 === 0) h12 = 12
            cal.clockH = h12.toString().padStart(2, '0')
            cal.clockM = now.getMinutes().toString().padStart(2, '0')
            cal.clockS = now.getSeconds().toString().padStart(2, '0')
            cal.dayName = cal.dayNames[now.getDay()]
            var mo = cal.months[now.getMonth()]
            cal.dateStr = mo + " " + now.getDate()
            if (cal.viewYear === 0) {
                cal.viewYear = now.getFullYear()
                cal.viewMonth = now.getMonth() + 1
            }
        }
    }

    function daysInMonth(y, m) { return new Date(y, m, 0).getDate() }
    function firstWeekday(y, m) { return (new Date(y, m - 1, 1).getDay() + 6) % 7 }

    function prevMonth() {
        if (cal.viewMonth === 1) { cal.viewMonth = 12; cal.viewYear--; }
        else { cal.viewMonth--; }
    }

    function nextMonth() {
        if (cal.viewMonth === 12) { cal.viewMonth = 1; cal.viewYear++; }
        else { cal.viewMonth++; }
    }

    Rectangle {
        id: bgContainer
        anchors.fill: parent
        color: Colors.surface
        radius: 20
        border.color: Qt.rgba(1, 1, 1, 0.08)
        border.width: 1
    }

    ColumnLayout {
        id: mainCol
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Header Clock
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 84
            radius: 14
            color: Colors.module

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                ColumnLayout {
                    spacing: 2
                    RowLayout {
                        spacing: 4
                        Text {
                            text: cal.clockH + ":" + cal.clockM
                            color: Colors.surfacefg
                            font.family: mainFont
                            font.pixelSize: 34
                            font.weight: Font.Bold
                        }
                        Text {
                            text: cal.clockS
                            color: Colors.primary
                            font.family: mainFont
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            Layout.alignment: Qt.AlignTop
                            Layout.topMargin: 6
                        }
                    }
                    Text {
                        text: cal.dayName
                        color: Colors.surfacea || Colors.outline
                        font.family: mainFont
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitWidth: dateTxt.implicitWidth + 20
                    implicitHeight: 32
                    radius: 16
                    color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
                    border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.3)
                    border.width: 1

                    Text {
                        id: dateTxt
                        anchors.centerIn: parent
                        text: cal.dateStr
                        color: Colors.primary
                        font.family: mainFont
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }
                }
            }
        }

        // Calendar Card
        Rectangle {
            id: calCard
            Layout.fillWidth: true
            implicitHeight: 280
            radius: 14
            color: Colors.module

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: cal.months[cal.viewMonth - 1] + " " + cal.viewYear
                        color: Colors.surfacefg
                        font.family: mainFont
                        font.pixelSize: 16
                        font.weight: Font.Bold
                    }
                    Rectangle {
                        width: 28; height: 28; radius: 8
                        color: arL.containsMouse ? Colors.module_hover : "transparent"
                        Text { anchors.centerIn: parent; text: "󰅁"; font.pixelSize: 14; color: arL.containsMouse ? Colors.surfacefg : Colors.surfacea }
                        MouseArea { id: arL; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: cal.prevMonth() }
                    }
                    Rectangle {
                        width: 28; height: 28; radius: 8
                        color: arR.containsMouse ? Colors.module_hover : "transparent"
                        Text { anchors.centerIn: parent; text: "󰅂"; font.pixelSize: 14; color: arR.containsMouse ? Colors.surfacefg : Colors.surfacea }
                        MouseArea { id: arR; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: cal.nextMonth() }
                    }
                }

                Row {
                    Layout.fillWidth: true
                    Repeater {
                        model: cal.days
                        Text {
                            required property var modelData
                            width: (calCard.width - 28) / 7
                            text: modelData
                            color: Colors.outline
                            font.family: mainFont
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Colors.outline; opacity: 0.15 }

                Grid {
                    id: daysGrid
                    Layout.fillWidth: true
                    columns: 7
                    spacing: 0

                    property int totalDays: cal.daysInMonth(cal.viewYear, cal.viewMonth)
                    property int prevTotalDays: cal.daysInMonth(cal.viewYear, cal.viewMonth === 1 ? 12 : cal.viewMonth - 1)
                    property int startOff: cal.firstWeekday(cal.viewYear, cal.viewMonth)
                    property int todayDay: new Date().getDate()
                    property int todayMonth: new Date().getMonth() + 1
                    property int todayYear: new Date().getFullYear()
                    property real cellW: (calCard.width - 28) / 7

                    Repeater {
                        model: 42
                        delegate: Item {
                            required property int index
                            width: daysGrid.cellW
                            height: 32

                            property int dayNum: index - daysGrid.startOff + 1
                            property bool isCurrentMonth: dayNum >= 1 && dayNum <= daysGrid.totalDays
                            property string displayDay: isCurrentMonth ? dayNum.toString() : (dayNum < 1 ? (daysGrid.prevTotalDays + dayNum).toString() : (dayNum - daysGrid.totalDays).toString())
                            property bool isToday: isCurrentMonth && dayNum === daysGrid.todayDay && cal.viewMonth === daysGrid.todayMonth && cal.viewYear === daysGrid.todayYear

                            Rectangle {
                                anchors.centerIn: parent
                                width: 28; height: 28; radius: 14
                                color: isToday ? Colors.primary : (dMa.containsMouse && isCurrentMonth ? Colors.module_hover : "transparent")
                            }

                            Text {
                                anchors.centerIn: parent
                                text: parent.displayDay
                                color: parent.isToday ? Colors.primaryfg : (parent.isCurrentMonth ? Colors.backgroundfg : Colors.outline)
                                opacity: parent.isCurrentMonth ? 1.0 : 0.35
                                font.family: mainFont
                                font.pixelSize: 12
                                font.weight: parent.isToday ? Font.Bold : Font.Normal
                            }

                            MouseArea {
                                id: dMa
                                anchors.fill: parent
                                hoverEnabled: parent.isCurrentMonth
                                cursorShape: parent.isCurrentMonth ? Qt.PointingHandCursor : Qt.ArrowCursor
                            }
                        }
                    }
                }
            }
        }

        // Notification Center Container
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 14
            color: Colors.module

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                // Header Row
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "Notifications"
                        color: Colors.surfacefg
                        font.family: mainFont
                        font.pixelSize: 14
                        font.weight: Font.Bold
                    }

                    Rectangle {
                        visible: NotifService.list.length > 0
                        implicitWidth: notifBadge.implicitWidth + 12
                        implicitHeight: 18
                        radius: 9
                        color: Colors.primary

                        Text {
                            id: notifBadge
                            anchors.centerIn: parent
                            text: NotifService.list.length
                            color: Colors.primaryfg
                            font.family: mainFont
                            font.pixelSize: 10
                            font.weight: Font.Bold
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        visible: NotifService.list.length > 0
                        implicitWidth: clearTxt.implicitWidth + 16
                        implicitHeight: 24
                        radius: 12
                        color: clearMa.containsMouse ? Colors.module_hover : "transparent"

                        Text {
                            id: clearTxt
                            anchors.centerIn: parent
                            text: "Clear All"
                            color: Colors.primary
                            font.family: mainFont
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: clearMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NotifService.dismissAll()
                        }
                    }
                }

                // Empty State
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: NotifService.list.length === 0
                    spacing: 6

                    Item { Layout.fillHeight: true }

                    Text {
                        text: "󰂜"
                        font.pixelSize: 32
                        color: Colors.outline
                        opacity: 0.5
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "No New Notifications"
                        color: Colors.outline
                        font.family: mainFont
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Item { Layout.fillHeight: true }
                }

                // Notification Stream
                Flickable {
                    id: notifFlickable
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: NotifService.list.length > 0
                    contentHeight: notifCol.implicitHeight
                    clip: true

                    ColumnLayout {
                        id: notifCol
                        width: notifFlickable.width
                        spacing: 8

                        Repeater {
                            model: NotifService.list

                            delegate: Rectangle {
                                id: notifCard
                                required property var modelData

                                Layout.fillWidth: true
                                implicitHeight: cardCol.implicitHeight + 16
                                radius: 10
                                color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.6)
                                border.color: Qt.rgba(1, 1, 1, 0.05)
                                border.width: 1

                                ColumnLayout {
                                    id: cardCol
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        top: parent.top
                                        margins: 8
                                    }
                                    spacing: 4

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.appName ? modelData.appName : "System"
                                            color: Colors.outline
                                            font.family: mainFont
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }

                                        Rectangle {
                                            width: 18; height: 18; radius: 9
                                            color: closeMa.containsMouse ? Colors.module_hover : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "✕"
                                                font.pixelSize: 10
                                                color: Colors.outline
                                            }

                                            MouseArea {
                                                id: closeMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: modelData.dismiss()
                                            }
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.summary ? modelData.summary : ""
                                        visible: text !== ""
                                        color: Colors.surfacefg
                                        font.family: mainFont
                                        font.pixelSize: 12
                                        font.weight: Font.Bold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.body ? modelData.body : ""
                                        visible: text !== ""
                                        color: Colors.surfacefg
                                        opacity: 0.8
                                        font.family: mainFont
                                        font.pixelSize: 11
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 3
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
