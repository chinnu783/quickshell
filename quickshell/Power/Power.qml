import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import "../"

Rectangle {
    id: root
    color: Colors.surface
    height: 25
    // Sizes the outer background container to fit the pill + padding
    width: batteryPill.width + 0
    bottomLeftRadius: 10
    bottomRightRadius: 10

    // Inner battery pill
    Rectangle {
        id: batteryPill
        anchors.centerIn: parent
        color: {
            let state = UPower.displayDevice?.state;
            if (state === UPowerDeviceState.Charging || state === UPowerDeviceState.FullyCharged) {
                return Colors.primary
            }
            else if (Math.round((UPower.displayDevice?.percentage ?? 0) * 100) >= 80) {
                return Colors.error
            }
            else if (Math.round((UPower.displayDevice?.percentage ?? 0) * 100) >= 20) {
                return Colors.primary
            }
            else if (Math.round((UPower.displayDevice?.percentage ?? 0) * 100) <= 20) {
                return Colors.error
            }
            else if (Math.round((UPower.displayDevice?.percentage ?? 0) * 100) <= 100) {
                return "Error Battery will self-destruct.";
            }
        }

        // Dynamically size pill based on text dimensions + padding
        width: powerDisplay.implicitWidth + 14
        height: powerDisplay.implicitHeight + 10
        radius: 10

        Text {
            id: powerDisplay
            anchors.centerIn: parent
            // text: Math.round((UPower.displayDevice?.percentage ?? 0) * 100) + "%" + UPower.onBatt
            text: {
                let state = UPower.displayDevice?.state;
                if (state === UPowerDeviceState.Charging || state === UPowerDeviceState.FullyCharged) {
                    return Math.round((UPower.displayDevice?.percentage ?? 0) * 100) + "%" + " 󰂄 " //"   ";
                }
                else if (Math.round((UPower.displayDevice?.percentage ?? 0) * 100) >= 80) {
                    return Math.round((UPower.displayDevice?.percentage ?? 0) * 100) + "%" + " 󰁹 " //"   ";
                }
                else if (Math.round((UPower.displayDevice?.percentage ?? 0) * 100) >= 60) {
                    return Math.round((UPower.displayDevice?.percentage ?? 0) * 100) + "%" + " 󰂀 " //"   ";
                }
                else if (Math.round((UPower.displayDevice?.percentage ?? 0) * 100) >= 40) {
                    return Math.round((UPower.displayDevice?.percentage ?? 0) * 100) + "%" + " 󰁾 " //"   ";
                }
                else if (Math.round((UPower.displayDevice?.percentage ?? 0) * 100) >= 20) {
                    return Math.round((UPower.displayDevice?.percentage ?? 0) * 100) + "%" + " 󰁼 " //"   ";
                }
                else if (Math.round((UPower.displayDevice?.percentage ?? 0) * 100) <= 20) {
                    return Math.round((UPower.displayDevice?.percentage ?? 0) * 100) + "%" + " 󰁺 " //"   ";
                }
                else if (Math.round((UPower.displayDevice?.percentage ?? 0) * 100) <= 10) {
                    return Math.round((UPower.displayDevice?.percentage ?? 0) * 100) + "%" + " 󰂃 " //"   ";
                }
                else if (Math.round((UPower.displayDevice?.percentage ?? 0) * 100) <= 100) {
                    return "Error Battery will self-destruct.";
                }
            }
            color: {
                let state = UPower.displayDevice?.state;
                if (state === UPowerDeviceState.Charging || state === UPowerDeviceState.FullyCharged) {
                    return Colors.primaryfg
                }
                else if (Math.round((UPower.displayDevice?.percentage ?? 0) * 100) >= 80) {
                    return Colors.errorfg
                }
                else if (Math.round((UPower.displayDevice?.percentage ?? 0) * 100) >= 20) {
                    return Colors.primaryfg
                }
                else if (Math.round((UPower.displayDevice?.percentage ?? 0) * 100) <= 20) {
                    return Colors.errorfg
                }
                else if (Math.round((UPower.displayDevice?.percentage ?? 0) * 100) <= 100) {
                    return "Error Battery will self-destruct.";
                }
            }
            font.family: "Barlow Medium"
            font.pixelSize: 16
            font.weight: Font.Medium
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: ppd.visible = !ppd.visible
    }

    PPDPopup {
        id: ppd
    }
}
