import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Io
import ".."

PanelWindow {
    id: osdWin

    property string icon: "󰕾"
    property int value: 0
    property string title: "Volume"
    property int lastVol: -1
    property bool lastMute: false
    property int lastBrightness: -1

    anchors.top: true
    anchors.left: false
    anchors.right: true

    implicitWidth: 300
    implicitHeight: 70
    color: "transparent"
    visible: osdTimer.running

    // FIX 1: Restrict input region so OSD does not intercept mouse clicks
    mask: Region {
        item: osdWin.visible ? osdCard : null
    }

    WlrLayershell.namespace: "niriha-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.margins.top: 60
    WlrLayershell.margins.right: 10

    // Auto-hide OSD after 2 seconds
    Timer {
        id: osdTimer
        interval: 2000
        repeat: false
        onTriggered: osdWin.visible = false
    }

    function show(newTitle, newIcon, newValue) {
        osdWin.title = newTitle
        osdWin.icon = newIcon
        osdWin.value = Math.min(100, Math.max(0, newValue))

        // Force visible to true and restart auto-hide countdown
        osdWin.visible = true
        osdTimer.restart()
    }

    // ----------------------------------------------------
    // 1. PIPEWIRE VOLUME LISTENER
    // ----------------------------------------------------
    PwObjectTracker {
        objects: Pipewire.defaultAudioSink ? [ Pipewire.defaultAudioSink ] : []
    }

    Connections {
        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

        function onVolumeChanged() {
            var sink = Pipewire.defaultAudioSink
            if (!sink || !sink.audio) return

            var vol = Math.round(sink.audio.volume * 100)
            var isMuted = sink.audio.muted

            // Ignore initial startup signal to prevent popup on launcher load
            if (osdWin.lastVol === -1) {
                osdWin.lastVol = vol
                osdWin.lastMute = isMuted
                return
            }

            if (vol !== osdWin.lastVol || isMuted !== osdWin.lastMute) {
                osdWin.lastVol = vol
                osdWin.lastMute = isMuted
                var ico = isMuted ? "󰝟" : (vol > 50 ? "󰕾" : vol > 0 ? "󰖀" : "󰕿")
                osdWin.show("Volume", ico, isMuted ? 0 : vol)
            }
        }

        function onMutedChanged() {
            onVolumeChanged()
        }
    }

    // ----------------------------------------------------
    // 2. BRIGHTNESS POLLING LISTENER
    // ----------------------------------------------------
    Timer {
        interval: 300
        running: true
        repeat: true
        onTriggered: {
            // FIX 2: Ensure process isn't already running before re-triggering
            if (!brightnessProc.running) {
                brightnessProc.running = true
            }
        }
    }

    Process {
        id: brightnessProc
        command: ["brightnessctl", "-m"]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(",")
                if (parts.length >= 4) {
                    var pctStr = parts[3].replace("%", "")
                    var pct = parseInt(pctStr)

                    if (!isNaN(pct)) {
                        if (osdWin.lastBrightness === -1) {
                            osdWin.lastBrightness = pct
                            return
                        }

                        if (pct !== osdWin.lastBrightness) {
                            osdWin.lastBrightness = pct
                            osdWin.show("Brightness", "󰃠", pct)
                        }
                    }
                }
            }
        }
    }

    // ----------------------------------------------------
    // 3. MAIN OSD CARD UI
    // ----------------------------------------------------
    Rectangle {
        id: osdCard
        anchors.fill: parent
        radius: 16
        color: Colors.surface
        border.width: 1
        border.color: Colors.outline

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Text {
                text: osdWin.icon
                color: Colors.primary
                font.pixelSize: 22
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: osdWin.title
                        color: Colors.surfacefg
                        font.family: mainFont
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        Layout.fillWidth: true
                    }
                    Text {
                        text: osdWin.value + "%"
                        color: Colors.outline
                        font.family: mainFont
                        font.pixelSize: 12
                    }
                }

                // Progress Bar Track
                Rectangle {
                    Layout.fillWidth: true
                    height: 6
                    radius: 3
                    color: Colors.module

                    // Fill Bar
                    Rectangle {
                        width: parent.width * (osdWin.value / 100)
                        height: parent.height
                        radius: 3
                        color: Colors.primary

                        Behavior on width {
                            NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }
        }
    }
}
