import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../"

PanelWindow {
    id: cal

    anchors.top: true
    anchors.left: false
    anchors.right: true

    implicitWidth: 360
    implicitHeight: 490
    color: "transparent"
    visible: false

    // Input mask restricts clickable bounds to active layout content
    mask: Region {
        item: cal.visible ? mainCol : null
    }

    WlrLayershell.namespace: "qs-cal"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.margins.top: 60
    WlrLayershell.margins.right: 20

    // ── State ─────────────────────────────────────────────────────────
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

    function daysInMonth(y, m) {
        return new Date(y, m, 0).getDate()
    }

    function firstWeekday(y, m) {
        var d = new Date(y, m - 1, 1).getDay()
        return (d + 6) % 7 // Monday start index
    }

    function prevMonth() {
        if (cal.viewMonth === 1) {
            cal.viewMonth = 12
            cal.viewYear--
        } else {
            cal.viewMonth--
        }
    }

    function nextMonth() {
        if (cal.viewMonth === 12) {
            cal.viewMonth = 1
            cal.viewYear++
        } else {
            cal.viewMonth++
        }
    }

    onVisibleChanged: {
        if (visible) {
            var now = new Date()
            viewYear = now.getFullYear()
            viewMonth = now.getMonth() + 1
        }
    }

    // Outer Card Container
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

        // ── Clock & Date Header Header ──────────────────────────────────────
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

                // Today Pill Badge
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

        // ── Calendar Body Card ──────────────────────────────────────────────
        Rectangle {
            id: calCard
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 14
            color: Colors.module

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // Month Navigation Header
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: cal.months[cal.viewMonth - 1] + " " + cal.viewYear
                        color: Colors.surfacefg
                        font.family: mainFont
                        font.pixelSize: 17
                        font.weight: Font.Bold
                    }

                    // Navigation Button Left
                    Rectangle {
                        width: 32; height: 32; radius: 10
                        color: arL.containsMouse ? Colors.module_hover : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "󰅁" // Optional Material/FontAwesome symbol or chevron standard string
                            font.pixelSize: 16
                            color: arL.containsMouse ? Colors.surfacefg : Colors.surfacea
                        }

                        MouseArea {
                            id: arL
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cal.prevMonth()
                        }
                    }

                    // Navigation Button Right
                    Rectangle {
                        width: 32; height: 32; radius: 10
                        color: arR.containsMouse ? Colors.module_hover : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "󰅂"
                            font.pixelSize: 16
                            color: arR.containsMouse ? Colors.surfacefg : Colors.surfacea
                        }

                        MouseArea {
                            id: arR
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cal.nextMonth()
                        }
                    }
                }

                // Days of Week Header
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
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Colors.outline
                    opacity: 0.15
                }

                // Days Grid (6 Weeks * 7 Days = 42 Cells)
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
                            height: 38

                            // Calendar logic math
                            property int dayNum: index - daysGrid.startOff + 1
                            property bool isCurrentMonth: dayNum >= 1 && dayNum <= daysGrid.totalDays

                            // Day string resolution (fills previous/next month placeholders gracefully)
                            property string displayDay: {
                                if (isCurrentMonth) return dayNum.toString()
                                if (dayNum < 1) return (daysGrid.prevTotalDays + dayNum).toString()
                                return (dayNum - daysGrid.totalDays).toString()
                            }

                            property bool isToday: isCurrentMonth &&
                                                   dayNum === daysGrid.todayDay &&
                                                   cal.viewMonth === daysGrid.todayMonth &&
                                                   cal.viewYear === daysGrid.todayYear

                            Rectangle {
                                id: dayBg
                                anchors.centerIn: parent
                                width: 32; height: 32; radius: 16
                                color: isToday ? Colors.primary : (dMa.containsMouse && isCurrentMonth ? Colors.module_hover : "transparent")
                                scale: dMa.containsMouse && isCurrentMonth ? 1.05 : 1.0

                                Behavior on color { ColorAnimation { duration: 120 } }
                                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: parent.displayDay
                                color: parent.isToday ? Colors.primaryfg : (parent.isCurrentMonth ? Colors.backgroundfg : Colors.outline)
                                opacity: parent.isCurrentMonth ? 1.0 : 0.35
                                font.family: mainFont
                                font.pixelSize: 13
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
    }
}
