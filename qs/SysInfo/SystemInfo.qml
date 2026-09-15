import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../"

Rectangle {
    id: pill

    // ── Pill Styling ───────────────────────────────────────────────────
    property color bg: Colors.module
    property color borderCol: Colors.module
    property color labelCol: Colors.primary
    property color valCol: Colors.backgroundfg

    implicitWidth: layout.implicitWidth + 32
    implicitHeight: 40
    radius: 12

    color: bg
    border.color: borderCol
    border.width: 1

    // ── Internal System Statistics Engine ────────────────────────────────
    QtObject {
        id: stats

        property real cpuPct: 0
        property real cpuTemp: 0
        property real ramPct: 0
        property real ramGb: 0
        property real diskPct: 0

        property real loadAvg1: 0.0
        property real loadAvg5: 0.0
        property real loadAvg15: 0.0
        property int procTotal: 0
        property int procRun: 0
        property string uptimeStr: "0m"
        property string hostname: "Linux"
        property string osName: "Linux"
        property string kernelVer: "Kernel"

        property int _cpuPrevIdle: 0
        property int _cpuPrevTotal: 0

        // Sparkline History Buffers
        property var cpuHist: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
        property var tempHist: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
        property var ramHist: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]

        function pushH(arr, val) {
            var a = arr.slice(1);
            a.push(val);
            return a;
        }
    }

    // ── Process & File Monitoring Readers ─────────────────────────────
    FileView {
        id: cpuFv
        path: "/proc/stat"
        watchChanges: true
        onTextChanged: {
            var t = text();
            if (!t) return;
            var line = t.split("\n")[0];
            var f = line.trim().split(/\s+/);
            if (f.length < 8) return;
            var idle = parseInt(f[4]) + parseInt(f[5]);
            var total = 0;
            for (var i = 1; i <= 7; i++) total += parseInt(f[i]);
            var dIdle = idle - stats._cpuPrevIdle;
            var dTotal = total - stats._cpuPrevTotal;
            if (stats._cpuPrevTotal > 0 && dTotal > 0) {
                stats.cpuPct = Math.max(0, Math.min(100, Math.round(100 * (1 - dIdle / dTotal))));
                stats.cpuHist = stats.pushH(stats.cpuHist, stats.cpuPct);
            }
            stats._cpuPrevIdle = idle;
            stats._cpuPrevTotal = total;
        }
    }

    Timer { interval: 1000; running: true; repeat: true; onTriggered: cpuFv.reload() }

    FileView {
        id: ramFv
        path: "/proc/meminfo"
        watchChanges: false
        onTextChanged: {
            var t = text();
            if (!t) return;
            var lines = t.split("\n");
            var total = 0, avail = 0;
            for (var i = 0; i < lines.length; i++) {
                if (lines[i].indexOf("MemTotal:") === 0) total = parseInt(lines[i].split(/\s+/)[1]) || 0;
                if (lines[i].indexOf("MemAvailable:") === 0) avail = parseInt(lines[i].split(/\s+/)[1]) || 0;
            }
            if (total > 0) {
                stats.ramGb = (total - avail) / 1048576.0;
                stats.ramPct = Math.round((total - avail) / total * 100);
                stats.ramHist = stats.pushH(stats.ramHist, stats.ramPct);
            }
        }
    }

    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: ramFv.reload() }

    Process {
        id: diskProc
        command: ["df", "-h", "/"]
        running: false // Managed entirely by the timer below

        // SplitParser intercepts stdout and automatically splits it by line
        stdout: SplitParser {
            onRead: data => {
                if (!data) return;

                // data is already a clean string line passed by SplitParser
                var line = data.trim();
                var parts = line.split(/\s+/);

                // Loop through this specific line's columns looking for the '%' sign
                for (var i = 0; i < parts.length; i++) {
                    if (parts[i].indexOf("%") !== -1) {
                        var pct = parseInt(parts[i].replace("%", "")) || 0;

                        // Ignore the header line ("Use%") and catch the actual number
                        if (!isNaN(pct) && line.indexOf("Filesystem") === -1) {
                            stats.diskPct = pct;
                            break;
                        }
                    }
                }
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            // Toggle the running state to cleanly restart the process
            diskProc.running = false;
            diskProc.running = true;
        }
    }


    Process {
        id: tempProc
        command: ["sh", "-c", "for f in /sys/class/hwmon/hwmon*/temp*_input; do [ -f \"$f\" ] && cat \"$f\" && exit; done; for f in /sys/class/thermal/thermal_zone*/temp; do [ -f \"$f\" ] && cat \"$f\" && exit; done; echo 0"]
        stdout: SplitParser {
            onRead: function(d) {
                var raw = parseFloat(d.trim());
                if (isNaN(raw) || raw <= 0) return;
                var t = raw > 1000 ? raw / 1000.0 : raw;
                if (t > 0 && t < 150) {
                    stats.cpuTemp = Math.round(t);
                    stats.tempHist = stats.pushH(stats.tempHist, stats.cpuTemp);
                }
            }
        }
    }

    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: { tempProc.running = false; tempProc.running = true; } }

    // ── Status Bar Content (Clean Progress Rings) ──────────────────────
    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 16

        // CPU Meter
        RowLayout {
            spacing: 6
            Item {
                implicitWidth: 28
                implicitHeight: 28

                Canvas {
                    anchors.fill: parent
                    property real value: stats.cpuPct / 100.0
                    onValueChanged: requestPaint()

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        var cx = width / 2, cy = height / 2, r = 11;

                        ctx.strokeStyle = Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18);
                        ctx.lineWidth = 2.5;
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, 0, Math.PI * 2);
                        ctx.stroke();

                        ctx.strokeStyle = Colors.primary;
                        ctx.lineWidth = 2.5;
                        ctx.lineCap = "round";
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, -Math.PI / 2, (-Math.PI / 2) + (Math.PI * 2 * value));
                        ctx.stroke();
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰍛"
                    color: pill.labelCol
                    font.pixelSize: 13
                    font.family: mainFont
                }
            }

            Text {
                text: stats.cpuPct + "%"
                color: pill.valCol
                font.bold: true
                font.pixelSize: 13
                font.family: mainFont
            }
        }

        // RAM Meter
        RowLayout {
            spacing: 6
            Item {
                implicitWidth: 28
                implicitHeight: 28

                Canvas {
                    anchors.fill: parent
                    property real value: stats.ramPct / 100.0
                    onValueChanged: requestPaint()

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        var cx = width / 2, cy = height / 2, r = 11;

                        ctx.strokeStyle = Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18);
                        ctx.lineWidth = 2.5;
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, 0, Math.PI * 2);
                        ctx.stroke();

                        ctx.strokeStyle = Colors.primary;
                        ctx.lineWidth = 2.5;
                        ctx.lineCap = "round";
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, -Math.PI / 2, (-Math.PI / 2) + (Math.PI * 2 * value));
                        ctx.stroke();
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰘚"
                    color: pill.labelCol
                    font.pixelSize: 13
                    font.family: mainFont
                }
            }

            Text {
                text: stats.ramPct + "%"
                color: pill.valCol
                font.bold: true
                font.pixelSize: 13
                font.family: mainFont
            }
        }

        // Disk Meter
        RowLayout {
            spacing: 6
            Item {
                implicitWidth: 28
                implicitHeight: 28

                Canvas {
                    anchors.fill: parent
                    property real value: stats.diskPct / 100.0
                    onValueChanged: requestPaint()

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        var cx = width / 2, cy = height / 2, r = 11;

                        ctx.strokeStyle = Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18);
                        ctx.lineWidth = 2.5;
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, 0, Math.PI * 2);
                        ctx.stroke();

                        ctx.strokeStyle = Colors.primary;
                        ctx.lineWidth = 2.5;
                        ctx.lineCap = "round";
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, -Math.PI / 2, (-Math.PI / 2) + (Math.PI * 2 * value));
                        ctx.stroke();
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰋊"
                    color: pill.labelCol
                    font.pixelSize: 13
                    font.family: mainFont
                }
            }

            Text {
                text: stats.diskPct + "%"
                color: pill.valCol
                font.bold: true
                font.pixelSize: 13
                font.family: mainFont
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: sysStatsPopup.visible = !sysStatsPopup.visible
    }

    IpcHandler {
        target: "sysStats"
        function toggle() {
            sysStatsPopup.visible = !sysStatsPopup.visible
        }
    }

    // ── Extended Drop-Down Modal ───────────────────────────────────────
    PanelWindow {
        id: sysStatsPopup

        anchors.top: true
        anchors.left: true
        implicitWidth: 380
        implicitHeight: popupCol.implicitHeight + 28
        color: "transparent"
        visible: false

        mask: Region {
            item: sysStatsPopup.visible ? popupCol : null
        }

        WlrLayershell.namespace: "qs-system-info"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.margins.top: 60
        WlrLayershell.margins.left: 24

        FileView {
            id: loadFv
            path: "/proc/loadavg"
            watchChanges: true
            onTextChanged: {
                var t = text();
                if (!t || !t.trim()) return;
                var p = t.trim().split(/\s+/);
                stats.loadAvg1 = parseFloat(p[0]) || 0;
                stats.loadAvg5 = parseFloat(p[1]) || 0;
                stats.loadAvg15 = parseFloat(p[2]) || 0;
                var tasks = (p[3] || "0/0").split("/");
                stats.procRun = parseInt(tasks[0]) || 0;
                stats.procTotal = parseInt(tasks[1]) || 0;
            }
        }

        Timer {
            interval: 3000
            running: sysStatsPopup.visible
            repeat: true
            triggeredOnStart: true
            onTriggered: loadFv.reload()
        }

        // FileView {
        //     id: uptimeFv
        //     path: "/proc/uptime"
        //     watchChanges: false
        //     onTextChanged: {
        //         var t = text();
        //         if (!t) return;
        //         var secs = Math.floor(parseFloat(t.trim().split(/\s+/)[0]) || 0);
        //         var d = Math.floor(secs / 86400);
        //         secs %= 86400;
        //         var h = Math.floor(secs / 3600);
        //         secs %= 3600;
        //         var m = Math.floor(secs / 60);
        //         stats.uptimeStr = d > 0 ? (d + "d " + h + "h " + m + "m") : h > 0 ? (h + "h " + m + "m") : (m + "m");
        //     }
        // }

        // Timer {
        //     interval: 30000
        //     running: sysStatsPopup.visible
        //     repeat: true
        //     triggeredOnStart: true
        //     onTriggered: uptimeFv.reload()
        // }

        Process {
            id: hostProc
            command: ["hostname"]
            running: sysStatsPopup.visible
            stdout: SplitParser { onRead: d => stats.hostname = d.trim() }
        }

        Process {
            id: kernelProc
            command: ["uname", "-r"]
            running: sysStatsPopup.visible
            stdout: SplitParser { onRead: d => stats.kernelVer = d.trim().split("-")[0] }
        }

        Process {
            id: osProc
            command: ["sh", "-c", "grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '\"'"]
            running: sysStatsPopup.visible
            stdout: SplitParser { onRead: d => stats.osName = d.trim() }
        }

        Rectangle {
            anchors.fill: parent
            color: Colors.surface
            radius: 18
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
        }

        ColumnLayout {
            id: popupCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 14
            }
            spacing: 10

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 64
                radius: 14
                color: Colors.module

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    Rectangle {
                        width: 36; height: 36; radius: 10
                        color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)

                        Text {
                            anchors.centerIn: parent
                            text: "󰌽"
                            font.pixelSize: 18
                            color: Colors.primary
                        }
                    }

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: stats.osName
                            color: Colors.surfacefg
                            font.family: mainFont
                            font.pixelSize: 13
                            font.weight: Font.Bold
                        }
                        Text {
                            text: stats.hostname + " • " + stats.kernelVer
                            color: Colors.outline
                            font.family: mainFont
                            font.pixelSize: 11
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "" //"󱎫 " + stats.uptimeStr
                        color: Colors.primary
                        font.family: mainFont
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 160
                radius: 14
                color: Colors.module

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: "CPU"
                            color: Colors.surfacefg
                            font.family: mainFont
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            Layout.preferredWidth: 36
                        }

                        Text {
                            text: Math.round(stats.cpuPct) + "%"
                            color: Colors.primary
                            font.family: mainFont
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            Layout.preferredWidth: 40
                        }

                        Canvas {
                            Layout.fillWidth: true
                            implicitHeight: 28
                            property var hist: stats.cpuHist
                            onHistChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                ctx.strokeStyle = Colors.primary;
                                ctx.lineWidth = 2;
                                ctx.beginPath();
                                for (var i = 0; i < hist.length; i++) {
                                    var x = (i / (hist.length - 1)) * width;
                                    var y = height - (hist[i] / 100) * height * 0.85;
                                    i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
                                }
                                ctx.stroke();
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: "RAM"
                            color: Colors.surfacefg
                            font.family: mainFont
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            Layout.preferredWidth: 36
                        }

                        Text {
                            text: Math.round(stats.ramPct) + "%"
                            color: Colors.primary
                            font.family: mainFont
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            Layout.preferredWidth: 40
                        }

                        Canvas {
                            Layout.fillWidth: true
                            implicitHeight: 28
                            property var hist: stats.ramHist
                            onHistChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                ctx.strokeStyle = Colors.primary;
                                ctx.lineWidth = 2;
                                ctx.beginPath();
                                for (var i = 0; i < hist.length; i++) {
                                    var x = (i / (hist.length - 1)) * width;
                                    var y = height - (hist[i] / 100) * height * 0.85;
                                    i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
                                }
                                ctx.stroke();
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: "TEMP"
                            color: Colors.surfacefg
                            font.family: mainFont
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            Layout.preferredWidth: 36
                        }

                        Text {
                            text: Math.round(stats.cpuTemp) + "°C"
                            color: Colors.primary
                            font.family: mainFont
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            Layout.preferredWidth: 40
                        }

                        Canvas {
                            Layout.fillWidth: true
                            implicitHeight: 28
                            property var hist: stats.tempHist
                            onHistChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                ctx.strokeStyle = Colors.primary;
                                ctx.lineWidth = 2;
                                ctx.beginPath();
                                for (var i = 0; i < hist.length; i++) {
                                    var x = (i / (hist.length - 1)) * width;
                                    var y = height - (Math.min(hist[i], 100) / 100) * height * 0.85;
                                    i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
                                }
                                ctx.stroke();
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 44
                radius: 14
                color: Colors.module

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12

                    Text {
                        text: "Load:"
                        color: Colors.outline
                        font.family: mainFont
                        font.pixelSize: 11
                    }

                    Text {
                        text: stats.loadAvg1.toFixed(2) + "  " + stats.loadAvg5.toFixed(2) + "  " + stats.loadAvg15.toFixed(2)
                        color: Colors.surfacefg
                        font.family: mainFont
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: stats.procRun + "/" + stats.procTotal + " Tasks"
                        color: Colors.outline
                        font.family: mainFont
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}
