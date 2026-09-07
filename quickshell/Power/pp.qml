import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Wayland
import ".."

PanelWindow {
    id: ppdPopup

    anchors.top: true
    anchors.right: true

    WlrLayershell.namespace: "ppd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.margins.top: 60
    WlrLayershell.margins.right: 110

    implicitHeight: mainCol.implicitHeight + 20
    width: 260
    visible: true
    color: "transparent"

    Process {
        id: batStats
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT0/capacity /sys/class/power_supply/BAT0/status /sys/class/power_supply/BAT0/power_now /sys/class/power_supply/BAT0/energy_full /sys/class/power_supply/BAT0/energy_full_design /sys/class/power_supply/BAT0/cycle_count 2>/dev/null"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var lines = data.trim().split("\n");
                if (lines.length >= 6) {
                    ppdPopup.capacity = lines[0] + "%";
                    ppdPopup.status = lines[1];
                    ppdPopup.power = (parseInt(lines[2]) / 1000000).toFixed(1) + " W";

                    var full = parseInt(lines[3]);
                    var design = parseInt(lines[4]);
                    ppdPopup.health = Math.round((full / design) * 100) + "%";
                    ppdPopup.cycles = lines[5];
                }
            }
        }
    }

    // Refresh every 5 seconds
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: batStats.running = true
    }

    property string capacity: "0%"
    property string status: "Unknown"
    property string power: "0 W"
    property string health: "0%"
    property string cycles: "0"

    //idk about next procs
    property string powerProfile: "balanced"
    readonly property string p_zap:    "<path d='M13 2 3 14h9l-1 8 10-12h-9l1-8z'/>"
    readonly property string p_chevR:  "<path d='m9 18 6-6-6-6'/>"

    function ico(paths, colorValue, size) {
        // Convert QML color object/string to hex string and replace '#' with '%23'
        var hex = colorValue.toString().replace("#", "%23")

        return "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='"
            + (size || 20) + "' height='" + (size || 20)
            + "' viewBox='0 0 24 24' fill='none' stroke='"
            + hex + "' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'>"
            + paths + "</svg>"
    }

    // Process to get current profile
    Process {
        id: ppGetProc
        command: ["powerprofilesctl", "get"]
        running: true
        stdout: SplitParser {
            onRead: function(d) {
                ppdPopup.powerProfile = d.trim()
            }
        }
    }

    // Process to set profile
    Process {
        id: ppSetProc
    }

    function cyclePP() {
        var profiles = ["power-saver", "balanced", "performance"]
        var nextProfile = profiles[(profiles.indexOf(ppdPopup.powerProfile) + 1) % 3]

        ppdPopup.powerProfile = nextProfile
        ppSetProc.command = ["powerprofilesctl", "set", nextProfile]
        ppSetProc.running = true
    }

    // understanding starts from here
    Rectangle {
        anchors.fill: parent
        color: Colors.surface
        opacity: 0.96
        radius: 8

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 8
            color: Colors.surface
        }
    }

    ColumnLayout {
        id: mainCol

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 10
        }
        spacing: 6

        RowLayout {
            Layout.fillWidth: true

            Rectangle {
                Layout.fillWidth: true
                height: 60
                radius: 8
                color: Colors.surface

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 14
                        rightMargin: 14
                    }
                    spacing: 20

                    Text {
                        font.family: mainFont
                        font.pixelSize: 15
                        font.weight: Font.Medium
                        Layout.fillWidth: true
                        color: Colors.surfacefg
                        text: "a"
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Rectangle {
                Layout.fillWidth: true
                height: 48
                radius: 8
                color: Colors.module

                Text {
                    text: ppdPopup.status === "Charging" ? "󰂄" : "󰁹"
                    font.family: mainFont
                    font.pixelSize: 28
                    color: Colors.primary
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: ppdPopup.capacity
                        font.family: mainFont
                        font.pixelSize: 20
                        font.bold: true
                        color: Colors.surfacefg
                    }
                    Text {
                        text: ppdPopup.status
                        font.family: mainFont
                        font.pixelSize: 12
                        color: Colors.outline
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colors.outline
        }

        RowLayout {
            Layout.fillWidth: true

            Rectangle {
                Layout.fillWidth: true
                height: 48
                radius: 8
                color: Colors.module//"#3c3836"

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 14
                        rightMargin: 14
                    }
                    spacing: 12

                    Image {
                        width: 26
                        height: 26
                        smooth: true
                        source: ppdPopup.ico(
                            ppdPopup.p_zap,
                            ppdPopup.powerProfile === "performance" ? Colors.error ://"%23fe8019" :
                            ppdPopup.powerProfile === "power-saver" ? Colors.primary : //"%2383a598" :
                            Colors.surfacefg, 26 //"%23a89984", 26
                        )
                    }

                    Text {
                        text: ppdPopup.powerProfile === "performance" ? "Performance" :
                              ppdPopup.powerProfile === "power-saver" ? "Power Saver" :
                              "Balanced"

                        color: ppdPopup.powerProfile === "performance" ? Colors.error ://"#fe8019" :
                               ppdPopup.powerProfile === "power-saver" ? Colors.primary : Colors.surfacefg//"#83a598" : "#ebdbb2"

                        font.family: mainFont
                        font.pixelSize: 15
                        font.weight: Font.Medium
                        Layout.fillWidth: true
                    }

                    Image {
                        width: 14
                        height: 14
                        smooth: true
                        source: ppdPopup.ico(ppdPopup.p_chevR, "%23a89984", 14)
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ppdPopup.cyclePP()
                }
            }
        }
    }
}
