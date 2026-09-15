import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../Notifications"
import "../Widgets"
import "../.."

PanelWindow {
    id: bar
    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: 0
        right: 0
        left: 0
    }
    implicitHeight: 50
    color: "transparent"

    mask: Region {
        item: barContain
    }
    Rectangle {
        id: barContain
        anchors.fill: parent
        color: Colors.surface

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
