import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import ".."

// Optional: import Niri plugin module if available in your Quickshell setup
// import Quickshell.Services.Niri

PanelWindow {
    id: root

    property var screen

    // ── Keyboard selection state ─────────────────────────────────────────────
    property int selectedIndex: -1
    readonly property int buttonCount: 5

    function activateSelected() {
        switch (selectedIndex) {
            case 0: executeAction(procLock, ["loginctl", "lock-session"]); break;
            case 1: executeAction(procSuspend, ["systemctl", "suspend"]); break;
            case 2: executeAction(procHibernate, ["systemctl", "hibernate"]); break;
            case 3: executeAction(procReboot, ["systemctl", "reboot"]); break;
            case 4: executeAction(procShutdown, ["systemctl", "poweroff"]); break;
        }
    }

    // Reset selection / grab focus on visibility change
    Connections {
        target: PowerMenuState
        function onPowerVisibleChanged() {
            if (PowerMenuState.powerVisible)
                powerCard.forceActiveFocus()
            else
                root.selectedIndex = -1
        }
    }

    IpcHandler {
        target: "powermenu"
        function toggle() {
            PowerMenuState.toggle();
        }
    }

    // ── Layer / geometry ─────────────────────────────────────────────────────
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    mask: Region {
        item: PowerMenuState.powerVisible ? maskCover : null
    }

    Item {
        id: maskCover
        anchors.fill: parent
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: PowerMenuState.powerVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "niri-powermenu"

    // ── Slide offset ─────────────────────────────────────────────────────────
    property real slideOffset: PowerMenuState.powerVisible ? 0 : powerCard.width + 8
    Behavior on slideOffset {
        NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
    }

    // ── Process runners / Niri executor ─────────────────────────────────────
    Process {
        id: procLock
        command: ["qs", "ipc", "call", "lock", "toggle"]
    }
    Process {
        id: procSuspend
        command: ["systemctl", "suspend"]
    }
    Process {
        id: procHibernate
        command: ["systemctl", "hibernate"]
    }
    Process {
        id: procReboot
        command: ["systemctl", "reboot"]
    }
    Process {
        id: procShutdown
        command: ["systemctl", "poweroff"]
    }

    function executeAction(procFallback, cmdArray) {
        PowerMenuState.hide();

        // If Niri API bindings exist directly in your Quickshell environment
        if (typeof Niri !== "undefined" && Niri.msg) {
            Niri.msg(["action", "spawn", "--"].concat(cmdArray));
        } else if (procFallback) {
            // Fall back to direct process execution
            procFallback.command = cmdArray;
            procFallback.running = true;
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: PowerMenuState.powerVisible
        onClicked: PowerMenuState.hide()
    }

    // ── Menu card ────────────────────────────────────────────────────────────
    Rectangle {
        id: powerCard

        focus: true

        // ── Key handling ──
        Keys.onPressed: function(event) {
            if (!PowerMenuState.powerVisible) return;
            if (event.key === Qt.Key_Up) {
                root.selectedIndex = (root.selectedIndex - 1 + root.buttonCount) % root.buttonCount;
                event.accepted = true;
            } else if (event.key === Qt.Key_Down) {
                root.selectedIndex = (root.selectedIndex + 1) % root.buttonCount;
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (root.selectedIndex >= 0) root.activateSelected();
                event.accepted = true;
            }
        }
        Keys.onEscapePressed: PowerMenuState.hide()

        anchors.verticalCenter: parent.verticalCenter

        x: -root.slideOffset

        width: 300
        height: menuCol.implicitHeight + 40

        topLeftRadius: 0
        bottomLeftRadius: 0
        topRightRadius: 18
        bottomRightRadius: 18

        color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.99)

        // Border overlay
        Rectangle {
            anchors.fill: parent
            z: 1
            color: "transparent"
            topLeftRadius: 0
            bottomLeftRadius: 0
            topRightRadius: parent.topRightRadius
            bottomRightRadius: parent.bottomRightRadius
            border.color: Qt.alpha(Colors.outline, 0.30)
            border.width: 1
        }

        // Prevent clicks on card from closing overlay
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            id: menuCol
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 16
                topMargin: 16
            }
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: "POWER"
                color: Colors.outline
                font.pixelSize: 10
                font.letterSpacing: 3
                horizontalAlignment: Text.AlignHCenter
            }

            Item { Layout.preferredHeight: 4 }

            PowerButton {
                label: "Lock"
                icon: "󰌾"
                hoverColor: Colors.tertiary
                selected: root.selectedIndex === 0
                onActivated: root.executeAction(procLock, ["qs", "ipc", "call", "lock", "toggle"])
            }
            PowerButton {
                label: "Suspend"
                icon: "󰒲"
                hoverColor: Colors.primary
                selected: root.selectedIndex === 1
                onActivated: root.executeAction(procSuspend, ["systemctl", "suspend"])
            }
            PowerButton {
                label: "Hibernate"
                icon: "󰋊"
                hoverColor: Colors.secondary
                selected: root.selectedIndex === 2
                onActivated: root.executeAction(procHibernate, ["systemctl", "hibernate"])
            }
            PowerButton {
                label: "Reboot"
                icon: "󰜉"
                hoverColor: Colors.tertiary
                selected: root.selectedIndex === 3
                onActivated: root.executeAction(procReboot, ["systemctl", "reboot"])
            }
            PowerButton {
                label: "Shutdown"
                icon: "󰐥"
                hoverColor: Colors.error
                selected: root.selectedIndex === 4
                onActivated: root.executeAction(procShutdown, ["systemctl", "poweroff"])
            }

            Item { Layout.preferredHeight: 5 }
        }
    }

    // ── Inner component: one menu row ────────────────────────────────────────
    component PowerButton: Rectangle {
        id: btn
        required property string label
        required property string icon
        required property color hoverColor
        property bool selected: false
        signal activated

        Layout.fillWidth: true
        height: 66//44
        radius: 10

        color: (ma.containsMouse || selected)
               ? Qt.alpha(hoverColor, 0.20)
               : "transparent"

        Behavior on color { ColorAnimation { duration: 140 } }

        Rectangle {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            width: (ma.containsMouse || btn.selected) ? 3 : 0
            height: 22
            radius: 2
            color: btn.hoverColor
            Behavior on width {
                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
            }
        }

        Row {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: 14
            }
            spacing: 12

            Text {
                text: btn.icon
                color: (ma.containsMouse || btn.selected) ? btn.hoverColor : Colors.primary
                font.pixelSize: 18
                verticalAlignment: Text.AlignVCenter
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: 140 } }
            }
            Text {
                text: btn.label
                color: Colors.backgroundfg
                font.pixelSize: 14
                font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.activated()
        }

        scale: ma.pressed ? 0.96 : 1.0
        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
    }
}
