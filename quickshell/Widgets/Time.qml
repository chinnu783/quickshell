import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../Popups"
import ".."

Rectangle {
    id: root
    color: Colors.surface
    height: 25
    width: clockPill.width
    bottomLeftRadius: 10
    bottomRightRadius: 10

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // Inner Clock Pill
    Rectangle {
        id: clockPill
        anchors.centerIn: parent
        color: Colors.module
        width: timeText.implicitWidth + 16
        height: timeText.implicitHeight + 10
        radius: 10

        Text {
            id: timeText
            anchors.centerIn: parent
            text: Qt.formatDateTime(clock.date, "hh:mm AP")
            color: Colors.surfacefg
            font.family: mainFont
            font.pixelSize: 16
            font.bold: true
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: calendarPopup.visible = !calendarPopup.visible
    }

    CalendarPopup {
        id: calendarPopup
        visible: false
    }

    IpcHandler {
        target: "cal"
        function toggle() {
            calendarPopup.visible = !calendarPopup.visible
        }
    }
}
