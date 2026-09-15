import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: root
    anchors.left: parent.left
    color: Colors.module
    height: 35
    width: workspaceRow.implicitWidth + 20
    radius: 10

    // Internal workspace data list
    property var workspaces: []

    // Switch focus to a given workspace index
    function focusWorkspace(workspaceId) {
        focusWorkspaceProcess.command = ["niri", "msg", "action", "focus-workspace", workspaceId.toString()]
        focusWorkspaceProcess.running = false
        focusWorkspaceProcess.running = true
    }

    // Process to execute workspace focus commands
    Process {
        id: focusWorkspaceProcess
        running: false
    }

    // Process to listen directly to Niri's event stream
    Process {
        command: ["niri", "msg", "-j", "event-stream"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                try {
                    const event = JSON.parse(data.trim())

                    if (event.WorkspacesChanged) {
                        root.workspaces = [...event.WorkspacesChanged.workspaces].sort((a, b) => a.idx - b.idx)
                    } else if (event.WorkspaceActivated) {
                        const activeId = event.WorkspaceActivated.id
                        let updated = []
                        for (let i = 0; i < root.workspaces.length; i++) {
                            let w = Object.assign({}, root.workspaces[i])
                            w.is_focused = (w.id === activeId)
                            updated.push(w)
                        }
                        root.workspaces = updated
                    }
                } catch (e) {
                    console.log("Error parsing workspace event:", e)
                }
            }
        }
    }

    // Visual layout
    Row {
        id: workspaceRow
        anchors.centerIn: parent
        spacing: 5

        Repeater {
            model: root.workspaces

            delegate: Rectangle {
                required property var modelData

                readonly property bool foc: modelData ? !!modelData.is_focused : false
                readonly property bool occ: modelData ? (modelData.active_window_id !== null && modelData.active_window_id !== undefined) : false
                readonly property int  wid: modelData ? modelData.idx : 1

                width: foc ? 35 : 20
                height: 20
                radius: 15
                color: foc ? Colors.primary : Colors.surfacea

                Behavior on width {
                    NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
                }

                Behavior on color {
                    ColorAnimation { duration: 100 }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.focusWorkspace(wid)
                }
            }
        }
    }
}
