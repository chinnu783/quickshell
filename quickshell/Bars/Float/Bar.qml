import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../Time"
import "../../Widgets"
import "../../Power"
import "../../SysInfo"
import "../../Notifications"
import "../../Vol_Bri"
import "../.."

PanelWindow {
    id: bar
    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: 6
        right: 2
        left: 2
    }
    implicitHeight: 50
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: Colors.surface
        radius: 16

        // left
        RowLayout {
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                leftMargin: 15
            }
            Loader { active: true; sourceComponent: SystemInfo {} }
        }
        // center
        RowLayout {
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            }
            Loader { active: true; sourceComponent: Workspaces {} }
        }
        // right
        RowLayout {
            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
                rightMargin: 15
            }
            spacing: 5
            Loader { active: true; sourceComponent: Power {} }
            Loader { active: true; sourceComponent: Time {} }
        }
    }
}
