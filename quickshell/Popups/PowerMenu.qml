import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets // Added to support IconImage if required, or native fallback
import ".."

PanelWindow {
    id: powerMenu
    property bool isOpen: false
    visible: isOpen
    color: "transparent"

    onIsOpenChanged: {
        if (isOpen) {
            list.forceActiveFocus()
        }
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Capture input for the entire screen so outside clicks trigger
    mask: Region {
        item: powerMenu.isOpen ? backgroundOverlay : null
    }

    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: powerMenu.isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-powermenu"

    IpcHandler {
        target: "powermenu"

        function toggle() {
            powerMenu.isOpen = !powerMenu.isOpen
        }
    }

    // ----------------------------------------------------
    // Action Handlers
    // ----------------------------------------------------
    function rootLock() {
        executer.exec(["qs", "ipc", "call", "lock", "toggle"])
        powerMenu.isOpen = false
    }
    function rootSuspend() {
        executer.exec(["systemctl", "suspend"])
        powerMenu.isOpen = false
    }
    function rootPoweroff() {
        executer.exec(["systemctl", "poweroff"])
        powerMenu.isOpen = false
    }
    function rootReboot() {
        executer.exec(["systemctl", "reboot"])
        powerMenu.isOpen = false
    }
    function rootLogout() {
        executer.exec(["loginctl", "terminate-session", "self"])
        powerMenu.isOpen = false
    }

    Process {
        id: executer
    }

    // Full-screen invisible overlay that closes menu on outside click
    Item {
        id: backgroundOverlay
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            onClicked: powerMenu.isOpen = false
        }

        Item {
            id: mainWrapper
            width: bgPanel.width + 48
            height: bgPanel.height + 54
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter

            // Prevent clicks on the menu body from closing the menu
            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            // Left Wing (Concave Corner)
            Canvas {
                id: leftWing
                width: 24
                height: 24
                renderTarget: Canvas.Image
                anchors.top: bgPanel.top
                anchors.right: bgPanel.left

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    ctx.fillStyle = Colors.surface;
                    ctx.beginPath();
                    ctx.moveTo(width, 0);
                    ctx.lineTo(width, height);
                    ctx.arcTo(width, 0, 0, 0, width);
                    ctx.closePath();
                    ctx.fill();
                }
            }

            // Main Panel Body (Horizontal proportions)
            Rectangle {
                id: bgPanel
                width: 382
                height: 80
                anchors.top: parent.top
                anchors.topMargin: 54
                anchors.horizontalCenter: parent.horizontalCenter
                color: Colors.surface

                topLeftRadius: 0
                topRightRadius: 0
                bottomLeftRadius: 24
                bottomRightRadius: 24
            }

            // Right Wing (Concave Corner)
            Canvas {
                id: rightWing
                width: 24
                height: 24
                renderTarget: Canvas.Image
                anchors.top: bgPanel.top
                anchors.left: bgPanel.right

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    ctx.fillStyle = Colors.surface;
                    ctx.beginPath();
                    ctx.moveTo(0, 0);
                    ctx.lineTo(0, height);
                    ctx.arcTo(0, 0, width, 0, width);
                    ctx.closePath();
                    ctx.fill();
                }
            }

            RowLayout {
                width: bgPanel.width - 32
                height: bgPanel.height - 32
                anchors.centerIn: bgPanel

                ListModel {
                    id: powerModel
                    ListElement { name: ""; action: "lock"; isSvg: false }
                    ListElement { name: ""; action: "suspend"; isSvg: false }
                    ListElement { name: ""; action: "logout"; isSvg: false }
                    ListElement { name: "󰑓"; action: "reboot"; isSvg: false }
                    ListElement { name: "poweroff"; action: "poweroff"; isSvg: true }
                }

                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    orientation: ListView.Horizontal
                    clip: true
                    focus: powerMenu.isOpen
                    keyNavigationWraps: true

                    model: powerModel

                    highlightMoveDuration: 80
                    highlight: Rectangle {
                        radius: 16
                        color: Colors.primary //module_hover
                    }

                    delegate: Item {
                        id: delegateRoot
                        required property string name
                        required property string action
                        required property bool isSvg
                        required property int index

                        width: 70
                        height: ListView.view.height

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                list.currentIndex = delegateRoot.index
                                list.triggerAction(delegateRoot.action)
                            }
                        }

                        Text {
                            visible: !delegateRoot.isSvg
                            anchors.centerIn: parent
                            color: list.currentIndex === delegateRoot.index ? Colors.primaryfg : Colors.surfacefg
                            text: delegateRoot.isSvg ? "" : delegateRoot.name
                            font.pointSize: 40
                            font.family: mainFont
                        }

                        Canvas {
                            id: thinPowerIcon
                            visible: delegateRoot.isSvg
                            anchors.centerIn: parent
                            width: 40
                            height: 40
                            renderTarget: Canvas.Image

                            // Define stroke colors based on active index state
                            property color currentStroke: list.currentIndex === delegateRoot.index ? Colors.primaryfg : Colors.surfacefg

                            // Automatically redraw when the selection changes
                            onCurrentStrokeChanged: requestPaint()

                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();

                                ctx.strokeStyle = currentStroke;
                                ctx.lineWidth = 3; // <-- Adjust this value to make it thinner (e.g. 1.0) or thicker
                                ctx.lineCap = "round";

                                var cx = width / 2;
                                var cy = height / 2;
                                var radius = 13;

                                ctx.beginPath();
                                ctx.moveTo(cx, (cy - radius) - 3);
                                ctx.lineTo(cx, (cy - 2) - 3);
                                ctx.stroke();

                                ctx.beginPath();
                                // Math.PI * 1.7 to 1.3 leaves a perfect gap open at the top
                                ctx.arc(cx, cy, radius, Math.PI * 1.7, Math.PI * 1.3, false);
                                ctx.stroke();
                            }
                        }
                    }

                    function triggerAction(act) {
                        if (act === "lock") powerMenu.rootLock()
                        else if (act === "suspend") powerMenu.rootSuspend()
                        else if (act === "poweroff") powerMenu.rootPoweroff()
                        else if (act === "reboot") powerMenu.rootReboot()
                        else if (act === "logout") powerMenu.rootLogout()
                    }

                    Keys.onReturnPressed: {
                        var item = powerModel.get(currentIndex)
                        triggerAction(item.action)
                    }

                    Keys.onEscapePressed: {
                        powerMenu.isOpen = false
                    }
                }
            }
        }
    }
}
