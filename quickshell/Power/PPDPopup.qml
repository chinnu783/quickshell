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
    visible: false
    color: "transparent"

    property string capacity: "--%"
    property string status: "Unknown"
    property string power: "0.0 W"
    property string health: "--%"
    property string powerProfile: "balanced"

    readonly property string p_zap: "<path d='M13 2 3 14h9l-1 8 10-12h-9l1-8z'/>"
    readonly property string p_chevR: "<path d='m9 18 6-6-6-6'/>"

    // 1. Capacity
    Process {
        id: capProc
        command: ["cat", "/sys/class/power_supply/BAT0/capacity"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var val = parseInt(data.trim())
                ppdPopup.capacity = val
                if (val <= 20 && ppdPopup.status !== "Charging") {
                    ppdPopup.notify("Low Battery Warning!", "Battery level is at " + val, "critical")
                }
                else if (val >= 75 && ppdPopup.status === "Charging") {
                    ppdPopup.notify("High Battery Warning!", "Battery level is at " + val, "critical")
                }
            }
        }
    }

    // 2. Status
    Process {
        id: statProc
        command: ["cat", "/sys/class/power_supply/BAT0/status"]
        running: true
        stdout: SplitParser {
            onRead: data => ppdPopup.status = data.trim()
        }
    }

    // 3. Power Consumption Rate (tries power_now, falls back to current_now * voltage_now)
    Process {
        id: pwrProc
        command: ["sh", "-c", "upower -i $(upower -e | grep 'BAT') | grep 'energy-rate' | awk '{print $2}'"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var rate = parseFloat(data.trim());
                if (!isNaN(rate) && rate > 0) {
                    ppdPopup.power = rate.toFixed(1) + " W";
                } else {
                    ppdPopup.power = "N/A";
                }
            }
        }
    }

    // 4. Battery Health (returns single line percentage)
    Process {
        id: healthProc
        command: ["sh", "-c", `
            BAT=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n 1)
            if [ -f "$BAT/energy_full" ] && [ -f "$BAT/energy_full_design" ]; then
                f=$(cat "$BAT/energy_full")
                d=$(cat "$BAT/energy_full_design")
                echo $(( (f * 100) / d ))
            elif [ -f "$BAT/charge_full" ] && [ -f "$BAT/charge_full_design" ]; then
                f=$(cat "$BAT/charge_full")
                d=$(cat "$BAT/charge_full_design")
                echo $(( (f * 100) / d ))
            else
                echo "N/A"
            fi
        `]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var h = data.trim();
                ppdPopup.health = (h !== "N/A" && h !== "") ? h + "%" : "N/A";
            }
        }
    }

    // Timer to update values every 3 seconds
    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            capProc.running = true;
            statProc.running = true;
            pwrProc.running = true;
            healthProc.running = true;
        }
    }

    function ico(paths, colorValue, size) {
        var hex = colorValue.toString().replace("#", "%23");
        return "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='"
            + (size || 20) + "' height='" + (size || 20)
            + "' viewBox='0 0 24 24' fill='none' stroke='"
            + hex + "' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'>"
            + paths + "</svg>";
    }

    Process {
        id: notifier
    }
    function notify(title, msg, urgency) {
        notifier.command = ["notify-send", "-u", urgency || "normal", title, msg]
        notifier.running = true
    }

    // Power Profiles Handler
    Process {
        id: ppGetProc
        command: ["powerprofilesctl", "get"]
        running: true
        stdout: SplitParser {
            onRead: data => ppdPopup.powerProfile = data.trim()
        }
    }
    Process { id: ppSetProc }
    function cyclePP() {
        var profiles = ["power-saver", "balanced", "performance"];
        var nextProfile = profiles[(profiles.indexOf(ppdPopup.powerProfile) + 1) % 3];
        ppdPopup.powerProfile = nextProfile;
        ppSetProc.command = ["powerprofilesctl", "set", nextProfile];
        ppSetProc.running = true;
    }
    function getBatteryIcon(capacityStr, statusStr) {
        if (statusStr === "Charging") {
            return "󰂄" // Charging icon
        }
        var cap = parseInt(capacityStr.replace("%", "")) || 0
        if (cap >= 90) return "󰁹"      // 90-100%
        else if (cap >= 80) return "󰂂" // 80-89%
        else if (cap >= 70) return "󰂁" // 70-79%
        else if (cap >= 60) return "󰂀" // 60-69%
        else if (cap >= 50) return "󰁿" // 50-59%
        else if (cap >= 40) return "󰁾" // 40-49%
        else if (cap >= 30) return "󰁽" // 30-39%
        else if (cap >= 20) return "󰁼" // 20-29%
        else if (cap >= 10) return "󰁻" // 10-19%
        else return "󰂃"                // <10% (Low/Critical)
    }

    // Background Container
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

        // Power Draw Card
        RowLayout {
            Layout.fillWidth: true

            Rectangle {
                Layout.fillWidth: true
                height: 44
                radius: 8
                color: Colors.module

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 14
                        rightMargin: 14
                    }
                    spacing: 12

                    Text {
                        font.family: mainFont
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: Colors.outline
                        text: "Power Usage"
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        font.family: mainFont
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        color: Colors.surfacefg
                        text: ppdPopup.power
                    }
                }
            }
        }

        // Battery Status Card
        RowLayout {
            Layout.fillWidth: true

            Rectangle {
                Layout.fillWidth: true
                height: 56
                radius: 8
                color: Colors.module

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 14
                        rightMargin: 14
                    }
                    spacing: 14

                    Text {
                        text: ppdPopup.getBatteryIcon(ppdPopup.capacity, ppdPopup.status)
                        font.family: mainFont
                        font.pixelSize: 26
                        color: Colors.primary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: ppdPopup.capacity + "%"
                            font.family: mainFont
                            font.pixelSize: 18
                            font.bold: true
                            color: Colors.surfacefg
                        }
                        Text {
                            text: ppdPopup.status + " • Health: " + ppdPopup.health
                            font.family: mainFont
                            font.pixelSize: 11
                            color: Colors.outline
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colors.outline
        }

        // Power Profile Card
        RowLayout {
            Layout.fillWidth: true

            Rectangle {
                Layout.fillWidth: true
                height: 48
                radius: 8
                color: Colors.module

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 14
                        rightMargin: 14
                    }
                    spacing: 12

                    Image {
                        width: 24
                        height: 24
                        smooth: true
                        source: ppdPopup.ico(
                            ppdPopup.p_zap,
                            ppdPopup.powerProfile === "performance" ? Colors.error :
                            ppdPopup.powerProfile === "power-saver" ? Colors.primary :
                            Colors.surfacefg, 24
                        )
                    }

                    Text {
                        text: ppdPopup.powerProfile === "performance" ? "Performance" :
                              ppdPopup.powerProfile === "power-saver" ? "Power Saver" :
                              "Balanced"

                        color: ppdPopup.powerProfile === "performance" ? Colors.error :
                               ppdPopup.powerProfile === "power-saver" ? Colors.primary :
                               Colors.surfacefg

                        font.family: mainFont
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        Layout.fillWidth: true
                    }

                    Image {
                        width: 14
                        height: 14
                        smooth: true
                        source: ppdPopup.ico(ppdPopup.p_chevR, Colors.outline, 14)
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
