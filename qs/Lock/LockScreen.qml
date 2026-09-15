import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Io
import Qt5Compat.GraphicalEffects
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

    WlSessionLock {
        locked: root.locked

        WlSessionLockSurface {
            color: "#11111b"

            // Wallpaper Background Image
            Image {
                id: bgImage
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                smooth: true
                source: root.currentWallpaper !== "" ? "file://" + root.wallpaperDir + root.currentWallpaper : ""
                visible: false
            }
            FastBlur {
                anchors.fill: bgImage
                source: bgImage
                radius: 32 // Higher number = more blur (32-64 is strong)
                cached: true
            }
            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: 0.4
            }

            Column {
                anchors.centerIn: parent
                spacing: 20
                z: 1

                opacity: 1

                transform: Translate {
                    id: slideTransform
                    y: 0
                }

                // Trigger animation explicitly when the Wayland surface finishes rendering
                Connections {
                    target: mainContainer.Window.window

                    function onVisibleChanged() {
                        if (mainContainer.Window.window && mainContainer.Window.window.visible) {
                            slideUpAnim.restart()
                        }
                    }
                }

                Component.onCompleted: {
                    slideUpAnim.restart()
                }

                // Direct explicit animation sequence
                SequentialAnimation {
                    id: slideUpAnim

                    // Step 1: Instantly snap to hidden/offset starting position
                    PropertyAction { target: mainContainer; property: "opacity"; value: 0 }
                    PropertyAction { target: slideTransform; property: "y"; value: 250 }

                    // Step 2: Smoothly animate into view
                    ParallelAnimation {
                        NumberAnimation {
                            target: slideTransform
                            property: "y"
                            from: 250
                            to: 0
                            duration: 850
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: mainContainer
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: 650
                            easing.type: Easing.OutCubic
                        }
                    }

                    // Step 3: Focus input field after animation finishes
                    ScriptAction {
                        script: {
                            if (typeof passwordField !== "undefined") {
                                passwordField.forceActiveFocus()
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Colors.surface || "#1e1e2e"
                    radius: 9999
                    border.color: Colors.outline
                    border.width: 0

                    // Dynamic sizing around children with internal padding
                    implicitWidth: innerLayout.implicitWidth + 100
                    implicitHeight: innerLayout.implicitWidth + 100

                    ColumnLayout {
                        id: innerLayout
                        anchors.centerIn: parent
                        spacing: 20
                        Rectangle {
                            id: time
                            Layout.alignment: Qt.AlignHCenter
                            color: "transparent"
                            radius: 16

                            implicitWidth: timelayout.implicitWidth + 40
                            implicitHeight: timelayout.implicitHeight + 10

                            ColumnLayout {
                                id: timelayout
                                anchors.centerIn: parent
                                spacing: -10

                                property date currentTime: new Date()

                                Timer {
                                    interval: 1000
                                    running: root.locked
                                    repeat: true
                                    onTriggered: timelayout.currentTime = new Date()
                                }

                                // Helper functions for 12-hour format & AM/PM split
                                function get12Hour() {
                                    var h = timelayout.currentTime.getHours() % 12
                                    if (h === 0) h = 12
                                    return h < 10 ? "0" + h : "" + h
                                }

                                function getAmPmChar(index) {
                                    var ap = timelayout.currentTime.getHours() >= 12 ? "PM" : "AM"
                                    return ap.charAt(index)
                                }

                                // Line 1: Hours + 1st Letter (e.g. "08 P")
                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 0

                                    Text {
                                        text: timelayout.get12Hour() + " "
                                        color: Colors.surfacefg || "#11111b"
                                        font.pixelSize: 70
                                        font.weight: Font.Medium
                                        font.family: mainFont
                                    }

                                    Text {
                                        text: timelayout.getAmPmChar(0)
                                        color: Colors.surfacefg || "#11111b"
                                        font.pixelSize: 70
                                        font.weight: Font.Medium
                                        font.family: mainFont
                                    }
                                }

                                // Line 2: Minutes + 2nd Letter with Colon Offset (e.g. ":01 M")
                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 0

                                    Text {
                                        text: Qt.formatDateTime(timelayout.currentTime, "mm") + " "
                                        color: Colors.surfacefg || "#11111b"
                                        font.pixelSize: 70
                                        font.weight: Font.Medium
                                        font.family: mainFont
                                    }

                                    Text {
                                        text: timelayout.getAmPmChar(1)
                                        color: Colors.surfacefg || "#11111b"
                                        font.pixelSize: 70
                                        font.weight: Font.Medium
                                        font.family: mainFont
                                    }
                                }

                                // Line 3: Date
                                Text {
                                    id: dateText
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.topMargin: 10
                                    text: Qt.formatDate(timelayout.currentTime, "dddd, MMMM d")
                                    color: Colors.outline || "#11111b"
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                    font.family: mainFont
                                }
                            }
                        }

                        // 2. Password Input Box
                        TextField {
                            id: passwordField
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 300
                            implicitHeight: 55
                            echoMode: TextInput.Password
                            placeholderText: "Enter Password"
                            placeholderTextColor: Colors.surfacefg ? Qt.alpha(Colors.surfacefg, 0.5) : "#888888"
                            color: Colors.surfacefg || "#ffffff"
                            font.pixelSize: 15
                            font.family: mainFont
                            focus: root.locked
                            enabled: !pam.active

                            leftPadding: 20
                            rightPadding: 20
                            topPadding: 14
                            bottomPadding: 14

                            background: Rectangle {
                                color: Colors.surface || "#222222"
                                radius: 30
                                border.color: passwordField.activeFocus ? (Colors.primary || "#89b4fa") : "transparent"
                                border.width: 2

                                Behavior on border.color {
                                    ColorAnimation { duration: 150 }
                                }
                            }

                            onAccepted: {
                                if (passwordField.text.length > 0) {
                                    passwordField.placeholderText = "Authenticating..."
                                    pam.start()
                                }
                            }
                        }

                        Item { height: 20 }
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
