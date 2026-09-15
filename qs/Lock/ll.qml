import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Io
import "../"

Scope {
    id: root

    property bool locked: false

    readonly property string wallpaperDir: Quickshell.env("HOME") + "/.config/wallpaper/"
    readonly property string configFilePath: Quickshell.env("HOME") + "/.config/wl/wl.conf"
    property string currentWallpaper: ""

    // Read wallpaper config automatically
    Process {
        id: configWatcher
        command: [
            "sh", "-c",
            "mkdir -p '$HOME/.config/wl' && touch '" + root.configFilePath + "' && tail -F -n +1 '" + root.configFilePath + "'"
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

    Process {
        id: logindListener
        command: [
            "gdbus", "monitor",
            "--system",
            "--dest", "org.freedesktop.login1",
            "--object-path", "/org/freedesktop/login1/session/self"
        ]
        running: true

        stdout: SplitParser {
            onRead: data => {
                // Check if systemd fired the Lock signal
                if (data.includes("Lock()")) {
                    root.locked = true
                } else if (data.includes("Unlock()")) {
                    root.locked = false
                }
            }
        }
    }

    WlSessionLock {
        locked: root.locked

        WlSessionLockSurface {
            color: "#11111b"

            // Wallpaper Background Image
            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                smooth: true
                source: root.currentWallpaper !== "" ? "file://" + root.wallpaperDir + root.currentWallpaper : ""
                opacity: 0.4

                // Optional slight dimming for text readability
                Rectangle {
                    anchors.fill: parent
                    color: "#000000"
                    opacity: 0.3
                }
            }

            Item {
                id: card
                width: 320
                height: contentColumn.height
                anchors.centerIn: parent

                property real baseX: (parent.width - width) / 2
                property real animOffsetX: 0

                transform: Translate { x: card.animOffsetX }

                // Smooth scale and subtle vertical float transition
                opacity: LockScreenState.locked ? 1 : 0
                scale: LockScreenState.locked ? 1.0 : 0.92
                y: LockScreenState.locked ? (parent.height - height) / 2 : (parent.height - height) / 2 + 15

                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on scale {
                    NumberAnimation {
                        duration: 350
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.2
                    }
                }
                Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

                SequentialAnimation {
                    id: shakeAnim
                    loops: 1
                    NumberAnimation { target: card; property: "animOffsetX"; to: -12; duration: 50; easing.type: Easing.OutQuad }
                    NumberAnimation { target: card; property: "animOffsetX"; to: 12; duration: 50; easing.type: Easing.OutQuad }
                    NumberAnimation { target: card; property: "animOffsetX"; to: -8; duration: 50; easing.type: Easing.OutQuad }
                    NumberAnimation { target: card; property: "animOffsetX"; to: 8; duration: 50; easing.type: Easing.OutQuad }
                    NumberAnimation { target: card; property: "animOffsetX"; to: 0; duration: 50; easing.type: Easing.OutQuad }
                }

                Column {
                    id: contentColumn
                    width: parent.width
                    spacing: 20

                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 4

                        Text {
                            id: clockText
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatTime(currentTime, "hh:mm")
                            font.pixelSize: 80
                            font.weight: Font.Thin
                            color: "#FFFFFF"

                            property date currentTime: new Date()

                            Timer {
                                interval: 1000
                                running: true
                                repeat: true
                                onTriggered: clockText.currentTime = new Date()
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDate(new Date(), "dddd, MMMM d")
                            font.pixelSize: 16
                            font.weight: Font.Medium
                            color: Qt.rgba(1, 1, 1, 0.75)
                        }
                    }

                    Item { height: 12; width: 1 }

                    Rectangle {
                        id: fieldWrap
                        width: parent.width
                        height: 50
                        radius: 14
                        color: Qt.rgba(0, 0, 0, 0.5)
                        border.width: pwField.activeFocus ? 2 : (LockScreenState.authFailed ? 2 : 1)
                        border.color: LockScreenState.authFailed
                            ? Colors.colRed
                            : (pwField.activeFocus ? Colors.colFg : Qt.rgba(1, 1, 1, 0.15))

                        Behavior on border.color { ColorAnimation { duration: 200 } }
                        Behavior on border.width { NumberAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 10

                            TextField {
                                id: pwField
                                Layout.fillWidth: true
                                echoMode: TextInput.Password
                                enabled: !LockScreenState.authenticating
                                placeholderText: LockScreenState.authenticating ? "Verifying..." : "Enter Password"
                                placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)
                                color: "#FFFFFF"
                                background: null
                                font.pixelSize: 15
                                verticalAlignment: TextInput.AlignVCenter

                                onAccepted: {
                                    if (text.length > 0)
                                        LockScreenState.authenticate(text)
                                }
                            }

                            BusyIndicator {
                                visible: LockScreenState.authenticating
                                running: LockScreenState.authenticating
                                implicitWidth: 18
                                implicitHeight: 18
                            }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Incorrect password"
                        color: Colors.colRed
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        opacity: LockScreenState.authFailed ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation { duration: 200; easing.type: Easing.InOutSine }
                        }
                    }
                }
            }

            PamContext {
                id: pam
                config: "login"

                onResponseRequiredChanged: {
                    if (pam.responseRequired) {
                        if (!pam.responseVisible) {
                            pam.respond(passwordField.text)
                        } else {
                            pam.respond(Quickshell.env("USER"))
                        }
                    }
                }

                onCompleted: result => {
                    if (result === PamResult.Success) {
                        root.locked = false
                        passwordField.text = ""
                        passwordField.placeholderText = ""
                    } else {
                        passwordField.text = ""
                        passwordField.placeholderText = "Incorrect Password"
                    }
                }
            }
        }
    }
}
