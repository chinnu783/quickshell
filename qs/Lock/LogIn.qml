import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Greetd
import Quickshell.Io
import "../"

Scope {
    id: root

    // Change this to your primary Linux username
    property string targetUser: "dev"

    // Session states parsed from .desktop files
    property var sessionList: []
    property string selectedExec: "niri-session" // Default fallback

    // Dynamic wallpaper state
    property string wallpaperPath: ""

    // 1. Scan /etc/greetd/wal/ for wallpaper file
    Process {
        command: [
            "sh", "-c",
            "ls -1 /etc/greetd/wal/* 2>/dev/null | head -n 1"
        ]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var foundPath = data.trim()
                if (foundPath.length > 0) {
                    root.wallpaperPath = "file://" + foundPath
                }
            }
        }
    }

    // 2. Parse all /usr/share/wayland-sessions/*.desktop files
    Process {
        command: [
            "sh", "-c",
            "for f in /usr/share/wayland-sessions/*.desktop; do " +
            "  [ -f \"$f\" ] || continue; " +
            "  name=$(awk -F'=' '/^Name=/{print $2; exit}' \"$f\"); " +
            "  exec=$(awk -F'=' '/^Exec=/{print $2; exit}' \"$f\" | sed 's/%[a-zA-Z]//g'); " +
            "  echo \"$name|$exec\"; " +
            "done"
        ]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (line.length === 0) return

                var parts = line.split("|")
                if (parts.length >= 2) {
                    var name = parts[0].trim()
                    var execCmd = parts[1].trim()

                    var currentSessions = root.sessionList.slice()
                    currentSessions.push({ "name": name, "exec": execCmd })
                    root.sessionList = currentSessions

                    // Auto-select Niri if present
                    if (name.toLowerCase().includes("niri") || execCmd.toLowerCase().includes("niri")) {
                        root.selectedExec = execCmd
                        sessionSelector.currentIndex = currentSessions.length - 1
                    }
                }
            }
        }
    }

    PanelWindow {
        id: window

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        screen: Quickshell.screens[0]
        visible: true
        color: Colors.background

        Item {
            anchors.fill: parent

            // Background Image
            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                smooth: true
                source: root.wallpaperPath
                opacity: 0.4

                Rectangle {
                    anchors.fill: parent
                    color: Colors.background
                    opacity: 0.3
                }
            }

            // Center UI Layout
            Column {
                anchors.centerIn: parent
                spacing: 20
                z: 1

                // Time Display
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Colors.primary
                    radius: 16
                    implicitWidth: timeText.implicitWidth + 40
                    implicitHeight: timeText.implicitHeight + 20

                    Text {
                        id: timeText
                        anchors.centerIn: parent
                        text: Qt.formatDateTime(new Date(), "hh:mm AP")
                        color: Colors.primaryfg
                        font.pixelSize: 70
                        font.bold: true
                    }
                }

                // Password Field
                TextField {
                    id: passwordField
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 300
                    height: 60
                    echoMode: TextInput.Password
                    placeholderText: "Enter Password"
                    placeholderTextColor: Colors.outline
                    color: Colors.surfacefg
                    font.pixelSize: 14
                    focus: true
                    enabled: Greetd.state !== GreetdState.Authenticating

                    leftPadding: 20
                    rightPadding: 20
                    topPadding: 16
                    bottomPadding: 16

                    background: Rectangle {
                        color: Colors.module
                        radius: 12
                        border.color: passwordField.activeFocus ? Colors.primary : "transparent"
                        border.width: 2

                        Behavior on border.color {
                            ColorAnimation { duration: 150 }
                        }
                    }

                    onAccepted: {
                        if (passwordField.text.length > 0 && Greetd.available) {
                            passwordField.placeholderText = "Authenticating..."
                            Greetd.createSession(root.targetUser)
                        }
                    }
                }

                // Wayland Session Selector Dropdown
                ComboBox {
                    id: sessionSelector
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 300
                    height: 45
                    textRole: "name"
                    model: root.sessionList

                    background: Rectangle {
                        color: Colors.module
                        radius: 10
                        border.color: Colors.surfacea
                        border.width: 1
                    }

                    contentItem: Text {
                        leftPadding: 15
                        text: sessionSelector.displayText
                        color: Colors.secondary
                        font.pixelSize: 14
                        verticalAlignment: Text.AlignVCenter
                    }

                    onActivated: index => {
                        var item = root.sessionList[index]
                        if (item && item.exec) {
                            root.selectedExec = item.exec
                        }
                    }
                }
            }
        }
    }

    // Greetd Authentication Handler
    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) {
                Greetd.respond(passwordField.text)
            }
        }

        function onReadyToLaunch() {
            passwordField.placeholderText = "Launching session..."
            // Executes the command extracted directly from the selected .desktop file
            Greetd.launch(["sh", "-c", root.selectedExec])
        }

        function onAuthFailure(message) {
            passwordField.text = ""
            passwordField.placeholderText = "Incorrect Password"
            Greetd.cancelSession()
        }
    }
}
