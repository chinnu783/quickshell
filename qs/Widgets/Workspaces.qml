import QtQuick
import Quickshell
import Quickshell.Io
import "../"

Rectangle {
    id: root
    anchors.left: parent.left
    color: Colors.module
    height: 35
    width: workspaceRow.implicitWidth + 20
    radius: 10

    // Track the active workspace manually
    property int activeWorkspace: 1
    property int totalWorkspaces: 5

    // Fetch workspace state directly via niri IPC
    Process {
        id: niriIpc
        command: ["niri", "msg", "--json", "workspaces"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                try {
                    let workspaces = JSON.parse(data);
                    for (let i = 0; i < workspaces.length; i++) {
                        if (workspaces[i].is_active) {
                            root.activeWorkspace = workspaces[i].idx;
                            break;
                        }
                    }
                } catch (e) {}
            }
        }
    }

    // Process executor for switching workspaces
    Process {
        id: workspaceSwitcher
    }

    function focusWorkspace(index) {
        workspaceSwitcher.command = ["niri", "msg", "action", "focus-workspace", index.toString()];
        workspaceSwitcher.running = true;
        root.activeWorkspace = index; // Optimistic update
    }

    Row {
        id: workspaceRow
        anchors.centerIn: parent
        spacing: 5

        Repeater {
            model: root.totalWorkspaces

            Rectangle {
                // index is 0-based, workspaces are 1-based
                property bool isActive: (index + 1) === root.activeWorkspace

                width: isActive ? 35 : 20
                height: 20
                radius: 15
                color: isActive ? Colors.primary : Colors.surfacea

                Behavior on width {
                    NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.focusWorkspace(index + 1)
                }
            }
        }
    }
}
