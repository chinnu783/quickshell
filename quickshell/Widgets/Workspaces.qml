import QtQuick
import Quickshell
import "../"

Rectangle {
    id: root
    anchors.left: parent.left
    color: Colors.module //"#666666"
    height: 35
    // Dynamically calculate width based on the row content + 20px padding
    width: workspaceRow.implicitWidth + 20
    bottomLeftRadius: 10
    bottomRightRadius: 10
    topLeftRadius: 10
    topRightRadius: 10

    Row {
        id: workspaceRow
        anchors.centerIn: parent
        spacing: 5

        Repeater {
            model: niri.workspaces

            Rectangle {
                width: model.isActive ? 35 : 20
                height: 20
                radius: 15
                color: model.isActive ? Colors.primary : Colors.surfacea //"#000000" : "#333333"

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: niri.focusWorkspaceById(model.id)
                }
            }
        }
    }
}
