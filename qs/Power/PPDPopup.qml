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

    implicitHeight: mainCol.implicitHeight + 24
    width: 280
    visible: false
    color: "transparent"

    mask: Region {
        item: ppdPopup.visible ? mainCol : null
    }

    // --- State Properties ---
    property int capacity: 0
    property string status: "Discharging"
    property string power: "N/A"
    property string health: "100%"
    property string powerProfile: "balanced"

    // --- SVG Paths ---
    readonly property string p_zap: "<path d='M13 2 3 14h9l-1 8 10-12h-9l1-8z'/>"
    readonly property string p_leaf: "<path d='M11 20A7 7 0 0 1 9.8 6.1C15.5 5 17 4.48 19 2c1 2 2 4.18 2 8 0 5.5-4.78 10-10 10Z'/><path d='M2 21c0-3 1.85-5.36 5.08-6C9.5 14.52 12 13 13 12'/>"
    readonly property string p_gauge: "<path d='m12 14 4-4'/><path d='M3.34 19a10 10 0 1 1 17.32 0'/>"

    // --- Dynamic CLI Profile Sync ---
    Process {
        id: ppMonitorProc
        command: ["powerprofilesctl", "monitor"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                var line = data.trim();
                if (line.indexOf("Profile:") !== -1) {
                    var parts = line.split(/\s+/);
                    ppdPopup.powerProfile = parts[parts.length - 1];
                } else if (line !== "") {
                    ppdPopup.powerProfile = line;
                }
            }
        }
    }

    Process {
        id: ppGetProc
        command: ["powerprofilesctl", "get"]
        running: true
        stdout: SplitParser {
            onRead: data => ppdPopup.powerProfile = data.trim()
        }
    }

    Process { id: ppSetProc }

    function setProfile(profile) {
        ppdPopup.powerProfile = profile;
        ppSetProc.command = ["powerprofilesctl", "set", profile];
        ppSetProc.running = true;
    }

    onVisibleChanged: {
        if (visible) {
            ppGetProc.running = false;
            ppGetProc.running = true;
            ppMonitorProc.running = false;
            ppMonitorProc.running = true;
        }
    }

    // --- Battery Info Processes ---
    Process {
        id: capProc
        command: ["cat", "/sys/class/power_supply/BAT0/capacity"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var val = parseInt(data.trim()) || 0;
                ppdPopup.capacity = val;
                if (val <= 20 && ppdPopup.status !== "Charging") {
                    ppdPopup.notify("Low Battery Warning", "Battery level is at " + val + "%", "critical");
                }
            }
        }
    }

    Process {
        id: statProc
        command: ["cat", "/sys/class/power_supply/BAT0/status"]
        running: true
        stdout: SplitParser {
            onRead: data => ppdPopup.status = data.trim()
        }
    }

    Process {
        id: pwrProc
        command: ["sh", "-c", "upower -i $(upower -e | grep 'BAT') | grep 'energy-rate' | awk '{print $2}'"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var rate = parseFloat(data.trim());
                ppdPopup.power = (!isNaN(rate) && rate > 0) ? rate.toFixed(1) + " W" : "N/A";
            }
        }
    }

    Process {
        id: healthProc
        command: ["sh", "-c", `
            BAT=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n 1)
            if [ -f "$BAT/energy_full" ] && [ -f "$BAT/energy_full_design" ]; then
                echo $(( ($(cat "$BAT/energy_full") * 100) / $(cat "$BAT/energy_full_design") ))
            elif [ -f "$BAT/charge_full" ] && [ -f "$BAT/charge_full_design" ]; then
                echo $(( ($(cat "$BAT/charge_full") * 100) / $(cat "$BAT/charge_full_design") ))
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

    Timer {
        interval: 4000
        running: true
        repeat: true
        onTriggered: {
            capProc.running = false; capProc.running = true;
            statProc.running = false; statProc.running = true;
            pwrProc.running = false; pwrProc.running = true;
            healthProc.running = false; healthProc.running = true;
        }
    }

    // --- Utilities ---
    function ico(paths, colorValue, size) {
        var hex = colorValue.toString().replace("#", "%23");
        return "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='"
            + (size || 20) + "' height='" + (size || 20)
            + "' viewBox='0 0 24 24' fill='none' stroke='"
            + hex + "' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'>"
            + paths + "</svg>";
    }

    Process { id: notifier }
    function notify(title, msg, urgency) {
        notifier.command = ["notify-send", "-u", urgency || "normal", title, msg];
        notifier.running = true;
    }

    function getBatteryIcon(cap, stat) {
        if (stat === "Charging") return "󰂄";
        if (cap >= 90) return "󰁹";
        if (cap >= 70) return "󰂁";
        if (cap >= 50) return "󰁿";
        if (cap >= 30) return "󰁽";
        if (cap >= 15) return "󰁻";
        return "󰂃";
    }

    // --- UI Structure ---
    Rectangle {
        anchors.fill: parent
        color: Colors.surface
        opacity: 0.96
        radius: 12
        border.color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.2)
        border.width: 1
    }

    ColumnLayout {
        id: mainCol
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 10

        // Battery Information Card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 64
            radius: 10
            color: Colors.module

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Text {
                    text: ppdPopup.getBatteryIcon(ppdPopup.capacity, ppdPopup.status)
                    font.family: mainFont
                    font.pixelSize: 28
                    color: ppdPopup.status === "Charging" ? Colors.primary :
                           ppdPopup.capacity <= 20 ? Colors.error : Colors.primary
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Text {
                            text: ppdPopup.capacity + "%"
                            font.family: mainFont
                            font.pixelSize: 18
                            font.bold: true
                            color: Colors.surfacefg
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: ppdPopup.power
                            font.family: mainFont
                            font.pixelSize: 12
                            font.bold: true
                            color: Colors.outline
                        }
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

        // Power Profiles Label
        Text {
            text: "Power Profile"
            font.family: mainFont
            font.pixelSize: 11
            font.bold: true
            color: Colors.outline
            Layout.leftMargin: 2
        }

        // Profile Selector Controls
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            component ProfileButton : Rectangle {
                id: btn
                property string profileName
                property string label
                property string svgPath

                readonly property bool isActive: ppdPopup.powerProfile === profileName

                Layout.fillWidth: true
                implicitHeight: 40
                radius: 8
                color: isActive ? Colors.primary : Colors.module

                Behavior on color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Image {
                        width: 16
                        height: 16
                        smooth: true
                        source: ppdPopup.ico(btn.svgPath, btn.isActive ? Colors.surface : Colors.surfacefg, 16)
                    }

                    Text {
                        text: btn.label
                        font.family: mainFont
                        font.pixelSize: 11
                        font.bold: btn.isActive
                        color: btn.isActive ? Colors.surface : Colors.surfacefg
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ppdPopup.setProfile(btn.profileName)
                }
            }

            ProfileButton {
                profileName: "power-saver"
                label: "Saver"
                svgPath: ppdPopup.p_leaf
            }

            ProfileButton {
                profileName: "balanced"
                label: "Balanced"
                svgPath: ppdPopup.p_zap
            }

            ProfileButton {
                profileName: "performance"
                label: "Perf"
                svgPath: ppdPopup.p_gauge
            }
        }
    }
}
