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
        top: 5
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
        color: "transparent"

        // left
        RowLayout {
            // anchors {
            //     verticalCenter: parent.verticalCenter
            //     left: parent.left
            //     leftMargin: 15
            // }
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: 0
                }
                height: 50
                width: l.implicitWidth + 40
                color: Colors.surface
                radius: 14
                RowLayout {
                    id: l
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 12
                    Loader { active: true; sourceComponent: SystemInfo {} }
                }
            }
        }
        // center
        RowLayout {
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                height: 50
                width: c.implicitWidth + 20
                color: Colors.surface
                radius: 14
                RowLayout {
                    id: c
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 12
                    Loader { active: true; sourceComponent: Workspaces {} }
                }
            }
        }
        // right
        RowLayout {
            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
                rightMargin: 0
            }
            spacing: 5
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                height: 50
                width: r.implicitWidth + 40
                color: Colors.surface
                radius: 14
                RowLayout {
                    id: r
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 12
                    Loader { active: true; sourceComponent: Power {} }
                    Loader { active: true; sourceComponent: Time {} }
                }
            }
        }
    }
}
