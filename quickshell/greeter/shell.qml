import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Greetd
import Quickshell.Io
import "../"
import "."

Scope {
    id: root

    property string targetUser: Quickshell.env("USER") || "dev"

    readonly property string wallpaperDir: "/etc/greetd/wallpapers/"
    readonly property string configFilePath: "/etc/greetd/wl.conf"
    property string currentWallpaper: ""

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
                    root.wallpaperDir = "file://" + foundPath
                }
            }
        }
    }

    // Read wallpaper config automatically
    Process {
        id: configWatcher
        command: [
            "sh", "-c",
            "mkdir -p '/etc/greetd' && touch '" + root.configFilePath + "' && tail -F -n +1 '" + root.configFilePath + "'"
        ]
        running: true

        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (line.length === 0) return

                var cleanName = line
                if (cleanName.includes("=")) {
                    cleanName = cleanName.split("=")[1].trim()
                }

                cleanName = cleanName.substring(cleanName.lastIndexOf("/") + 1).replace(/['"]/g, "")

                if (cleanName.length > 0) {
                    root.currentWallpaper = cleanName
                }
            }
        }
    }

    PanelWindow {
        id: win
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: Colors.surface

        // Wallpaper Background Image
        Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            smooth: true
            source: root.currentWallpaper !== "" ? root.wallpaperDir : "" // + root.currentWallpaper : ""
            opacity: 0.4

            // Optional slight dimming for text readability
            Rectangle {
                anchors.fill: parent
                color: Colors.surface
                opacity: 0.3
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 20
            z: 1

            // 1. Time Box Styled with Matugen Colors
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                color: Colors.primary
                radius: 16

                // Size the box automatically based on text dimensions + padding
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

            // 2. TextField Styled with Matugen Colors
            TextField {
                id: passwordField
                anchors.horizontalCenter: parent.horizontalCenter
                width: 300
                height: 60
                echoMode: TextInput.Password
                placeholderText: "Enter Password"
                placeholderTextColor: Qt.alpha(Colors.surfacefg, 0.5)
                color: Colors.surfacefg
                font.pixelSize: 14
                focus: true
                enabled: Greetd.state !== GreetdState.Authenticating

                leftPadding: 20
                rightPadding: 20
                topPadding: 16
                bottomPadding: 16

                // Custom Matugen Background Styling
                background: Rectangle {
                    color: Colors.surface
                    radius: 12
                    border.color: passwordField.activeFocus ? Colors.primary : Qt.rgba(0, 0, 0, 0)
                    border.width: 2

                    Behavior on border.color {
                        ColorAnimation { duration: 150 }
                    }
                }

                onAccepted: {
                    if (passwordField.text.length > 0) {
                        passwordField.placeholderText = "Authenticating..."
                        Greetd.createSession(root.targetUser)
                    }
                }
            }

            // 3. Status/Error Message Text Styled with Matugen Colors
            Text {
                id: statusText
                anchors.horizontalCenter: parent.horizontalCenter
                text: passwordField.placeholderText
                color: Greetd.state === GreetdState.AuthFailed ? Colors.errorfg : Colors.surfacefg
                font.pixelSize: 14
                visible: text !== ""
            }
        }

        // Greetd Authentication Context
        Connections {
            target: Greetd

            function onAuthMessage(message, error) {
                Greetd.respond(passwordField.text)
            }

            function onAuthSuccess() {
                Greetd.startSession(["niri-session"])
            }

            function onAuthFailure() {
                passwordField.text = ""
                passwordField.placeholderText = "Incorrect Password"
            }
        }
    }
}
