import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import "../Popups"
import ".."

Rectangle {
    id: root

    // Battery & UPower State Properties
    property int batteryPct: Math.round((UPower.displayDevice?.percentage ?? 0) * 100)
    property int batteryState: UPower.displayDevice?.state ?? UPowerDeviceState.Unknown
    property bool isCharging: batteryState === UPowerDeviceState.Charging || batteryState === UPowerDeviceState.FullyCharged

    // Dynamic Colors based on State
    function getFillColor() {
        if ((batteryPct <= 20) || ((batteryPct >= 75) && isCharging)) return Colors.error
        // if (isCharging) return Colors.primary
        return Colors.primary
    }

    function getTxtColor() {
        if ((batteryPct <= 20) || ((batteryPct >= 75) && isCharging)) return Colors.errorfg
        // if (isCharging) return Colors.primaryfg
        return Colors.primaryfg
    }

    function getBatteryIcon() {
        if (isCharging) return "󰂄"
        if (batteryPct >= 80) return "󰁹"
        if (batteryPct >= 60) return "󰂀"
        if (batteryPct >= 40) return "󰁾"
        if (batteryPct >= 20) return "󰁼"
        return "󰁺"
    }

    // function getBatteryIcon(batteryPct){
    //     if (batteryPct >= 93) return "battery_full";
    //     if (batteryPct >= 78) return "battery_6_bar";
    //     if (batteryPct >= 64) return "battery_5_bar";
    //     if (batteryPct >= 50) return "battery_4_bar";
    //     if (batteryPct >= 35) return "battery_3_bar";
    //     if (batteryPct >= 21) return "battery_2_bar";
    //     if (batteryPct >= 7) return "battery_1_bar";
    //     return "battery_alert"; // Changes to an exclamation mark icon on empty
    // }


    implicitWidth: mainLayout.implicitWidth + 10
    implicitHeight: 35
    color: Colors.module
    radius: 6

    RowLayout {
        id: mainLayout
        anchors.centerIn: parent
        spacing: 1
        anchors.margins: 5

        // Main Horizontal Battery Capsule (Progress Bar)
        Rectangle {
            id: batteryCapsule

            implicitWidth: 60
            implicitHeight: 24
            radius: 8 // High border-radius for full pill shape
            // color: Qt.rgba(Colors.surfacefg.r, Colors.surfacefg.g, Colors.surfacefg.b, 0.4)
            color: Qt.rgba(root.getFillColor().r, root.getFillColor().g, root.getFillColor().b, 0.36)
            border.color: root.getFillColor()
            border.width: 0
            clip: true

            // Inner Animated Progress Fill
            Rectangle {
                id: progressFill

                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                    margins: 0
                }

                // width: Math.max(0, (parent.width+8) * (root.batteryPct / 100.0))
                width: Math.min(parent.width, Math.max(0, (parent.width + 8) * (root.batteryPct / 100.0)))
                radius: 9
                color: root.getFillColor()
                opacity: 1

                Behavior on width {
                    NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
                }
            }

            // Percentage & Icon Overlay Centered Inside Pill
            RowLayout {
                anchors.centerIn: parent
                spacing: 5

                Text {
                    text: root.getBatteryIcon(root.batteryPct)
                    color: root.getTxtColor()
                    font.pixelSize: 13
                    font.family: "Material Icons"
                }

                Text {
                    text: root.batteryPct + "%"
                    color: root.getTxtColor()
                    font.pixelSize: 13
                    font.family: mainFont
                }
            }
        }

        // Small Battery Terminal Dot
        // Rectangle {
        //     implicitWidth: 5
        //     implicitHeight: 8
        //     radius: 3 // Fully rounded dot
        //     color: root.getFillColor()
        // }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: ppd.visible = !ppd.visible
    }

    PPDPopup {
        id: ppd
    }
}
