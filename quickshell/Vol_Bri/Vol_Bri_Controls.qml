import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
// import "."
import "../"

PanelWindow {
    id: root

    property var modelData
    screen: modelData

    property bool open: Vol_Bri_Controls_State.panelVisible
    property int  brightnessValue: 50
    property int  maxBrightness:   1000

    // ── IPC ────────────────────────────────────────────────────────────────
    IpcHandler {
        target: "vol-bri-controls"
        function toggle() {
            Vol_Bri_Controls_State.toggle();
        }
    }

    // ── Layer shell ────────────────────────────────────────────────────────
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace:     "qs-volbri-noanim"
    WlrLayershell.exclusiveZone: 0

    anchors.right:  true
    anchors.top:    true
    anchors.bottom: true

    implicitWidth: 140

    // magic code :)
    mask: Region {
        item: panelCard
    }

    color: "transparent"

    // ── Slide ──────────────────────────────────────────────────────────────
    property real slideOffset: open ? 0 : panelCard.width
    Behavior on slideOffset {
        NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
    }

    // ── Detect backlight device once at startup ─────────────────────────────
    Process {
        id: backlightDeviceProc
        command: ["sh", "-c", "ls /sys/class/backlight | head -n1"]
        running: true
        stdout: StdioCollector {
            id: backlightDevice
            onStreamFinished: {
                maxBrightnessProc.running = true
            }
        }
    }

    // ── Read max brightness once (doesn't change at runtime) ───────────────
    Process {
        id: maxBrightnessProc
        running: false
        command: ["cat", "/sys/class/backlight/" + backlightDevice.text.trim() + "/max_brightness"]
        stdout: StdioCollector {
            onStreamFinished: {
                const mx = parseInt(text.trim())
                if (!isNaN(mx) && mx > 0) {
                    root.maxBrightness = mx
                }
                brightnessWatcher.reload()
            }
        }
    }

    // ── Live brightness watcher ─────────────────────────────────────────────
    FileView {
        id: brightnessWatcher
        path: backlightDevice.text.trim().length > 0
              ? "/sys/class/backlight/" + backlightDevice.text.trim() + "/brightness"
              : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const cur = parseInt(text().trim())
            if (!isNaN(cur) && root.maxBrightness > 0) {
                root.brightnessValue = Math.round(cur / root.maxBrightness * 100)
            }
        }
    }

    function setBrightness(percent) {
        root.brightnessValue = percent
        const proc = Qt.createQmlObject('import Quickshell.Io; Process {}', root)
        proc.command = ["brightnessctl", "set", percent + "%"]
        proc.running = true
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  Panel card — docked flush to the right screen edge
    // ═══════════════════════════════════════════════════════════════════════
    Rectangle {
        id: panelCard

        width:  140
        height: 340
        anchors.verticalCenter: parent.verticalCenter

        x: root.slideOffset

        color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.99)

        // Left corners rounded, right corners flush with screen edge
        topLeftRadius:     16
        bottomLeftRadius:  16
        topRightRadius:    0
        bottomRightRadius: 0

        // Border — only on left + top + bottom, not the docked right edge
        Rectangle {
            anchors.fill: parent
            z: 1
            color: "transparent"
            topLeftRadius:     parent.topLeftRadius
            bottomLeftRadius:  parent.bottomLeftRadius
            topRightRadius:    0
            bottomRightRadius: 0
            border.color: Qt.alpha(Colors.outline, 0.30)
            border.width: 1
        }

        RowLayout {
            anchors { fill: parent; margins: 18 }
            spacing: 12

            // ── Volume ─────────────────────────────────────────────────────
            VSliderBlock {
                Layout.fillHeight: true
                Layout.fillWidth:  true

                iconText:    Vol_Bri_Controls_State.volumeMuted         ? "\uf026"
                             : Vol_Bri_Controls_State.volumeLevel > 60  ? "\uf028"
                             :                                            "\uf027"
                label:       "Vol"
                sliderValue: Vol_Bri_Controls_State.volumeLevel
                muted:       Vol_Bri_Controls_State.volumeMuted
                stepSize: 5

                onSlide:   val => Vol_Bri_Controls_State.setVolume(val)
                onIconTap: Vol_Bri_Controls_State.toggleMute()
            }

            Rectangle {
                width: 1; Layout.fillHeight: true
                color: Qt.alpha(Colors.surfacea, 0.5)
            }

            // ── Brightness ─────────────────────────────────────────────────
            VSliderBlock {
                Layout.fillHeight: true
                Layout.fillWidth:  true

                iconText:    "\uf185"
                label:       "Bri"
                sliderValue: root.brightnessValue
                muted:       false
                stepSize: 5

                onSlide:   val => root.setBrightness(val)
                onIconTap: {}
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  VSliderBlock  —  fully custom, no Qt Quick Controls
    // ═══════════════════════════════════════════════════════════════════════
    component VSliderBlock: ColumnLayout {
        id: block

        property string iconText:    ""
        property string label:       ""
        property int    sliderValue: 50
        property bool   muted:       false
        property int    stepSize:    1

        signal slide(int value)
        signal iconTap()

        spacing: 8

        // Icon button
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 34; height: 34; radius: 10
            color: block.muted ? Qt.alpha(Colors.error, 0.25)
                               : Qt.alpha(Colors.primary, 0.20)
            Behavior on color { ColorAnimation { duration: 180 } }

            Text {
                anchors.centerIn: parent
                text: block.iconText; font.pixelSize: 16
                color: block.muted ? Colors.error : Colors.primary
                Behavior on color { ColorAnimation { duration: 180 } }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape:  Qt.PointingHandCursor
                onClicked:    block.iconTap()
            }
        }

        // Value readout
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: block.sliderValue + "%"
            font.pixelSize: 11
            color: Colors.outline
        }

        // ── Custom vertical slider ─────────────────────────────────────────
        Item {
            id: sliderItem
            Layout.fillHeight: true
            Layout.alignment:  Qt.AlignHCenter
            implicitWidth:     40

            readonly property int trackH:    height - handle.height
            readonly property real fraction: Math.max(0, Math.min(1, block.sliderValue / 100.0))

            // Track background
            Rectangle {
                id: track
                width:  4
                height: sliderItem.trackH
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                radius: 2
                color: Qt.alpha(Colors.module, 0.8)

                // Fill — grows from bottom
                Rectangle {
                    width:          parent.width
                    height:         sliderItem.fraction * parent.height
                    anchors.bottom: parent.bottom
                    radius:         parent.radius
                    color:          block.muted ? Colors.error : Colors.primary
                    Behavior on height { NumberAnimation { duration: 40  } }
                    Behavior on color  { ColorAnimation  { duration: 200 } }
                }
            }

            // Handle
            Rectangle {
                id: handle
                width: 16; height: 16; radius: 8
                anchors.horizontalCenter: parent.horizontalCenter
                y: (1.0 - sliderItem.fraction) * sliderItem.trackH
                color: dragArea.pressed ? Colors.tertiary
                       : block.muted    ? Colors.error
                       :                  Colors.primary
                scale: dragArea.pressed ? 1.25 : 1.0
                Behavior on color { ColorAnimation  { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 90  } }
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent

                function valueFromY(my) {
                    const clamped = Math.max(handle.height / 2,
                                    Math.min(sliderItem.height - handle.height / 2, my))
                    const ratio   = 1.0 - (clamped - handle.height / 2) / sliderItem.trackH
                    const rawVal  = Math.round(ratio * 100)

                    // Snap to nearest step (e.g., 5)
                    const step = Math.max(1, block.stepSize)
                    const snapped = Math.round(rawVal / step) * step
                    return Math.max(0, Math.min(100, snapped))
                }

                onPressed:         mouse => block.slide(valueFromY(mouse.y))
                onPositionChanged: mouse => { if (pressed) block.slide(valueFromY(mouse.y)) }
            }
        }

        // Label
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: block.label; font.pixelSize: 11; font.weight: Font.Medium
            color: Colors.backgroundfg
        }
    }
}
