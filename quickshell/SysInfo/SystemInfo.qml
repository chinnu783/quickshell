import "."
import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import "../"

Rectangle {
    id: pill

    // Styling properties
    property color bg: Colors.module//"#1e1e2e"
    property color borderCol: Colors.module//"#313244"
    property color labelCol: Colors.primary//"#cba6f7"
    property color valCol: Colors.backgroundfg//"#cdd6f4"

    implicitWidth: layout.implicitWidth + 40
    implicitHeight: 37
    radius: height / 3

    color: bg
    border.color: borderCol
    border.width: 1

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 10

        // CPU
        RowLayout {
            spacing: 4
            Text { text: SystemStats.cpuPct + "%"; color: pill.valCol; font.bold: true; font.pixelSize: 14; font.family: mainFont }
            Text { text: "⚙"; color: pill.labelCol; font.bold: true; font.pixelSize: 19; font.family: mainFont }
        }

        // TEMP
        // RowLayout {
        //     spacing: 4
        //     Text { text: SystemStats.cpuTemp + "°C"; color: pill.valCol; font.pixelSize: 14 }
        //     Text { text: "🌡"; color: pill.labelCol; font.bold: true; font.pixelSize: 13 }
        // }

        // RAM
        RowLayout {
            spacing: 4
            Text { text: SystemStats.ramPct + "%"; color: pill.valCol; font.bold: true; font.pixelSize: 14; font.family: mainFont }
            Text { text: "󰒋" /*"󰓅"""*/; color: pill.labelCol; font.bold: true; font.pixelSize: 19; font.family: mainFont }
        }

        // NET
        RowLayout {
            spacing: 4
            Text {
                text: "↓ " + SystemStats.fmtNet(SystemStats.rxKb) + " ↑ " + SystemStats.fmtNet(SystemStats.txKb)
                color: pill.valCol
                font.pixelSize: 14
                font.family: mainFont
                font.bold: true
            }
            Text { text: "⇄"; color: pill.labelCol; font.bold: true; font.pixelSize: 19; font.family: mainFont }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            sysStats.visible = !sysStats.visible
        }
    }

    SystemInfoPopup {
        id: sysStats
        visible: false
    }

    IpcHandler {
        target: "sysStats"
        function toggle() {
            sysStats.visible = !sysStats.visible
        }
    }
}
