pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    // Explicit properties initialized to 0 (never undefined)
    property int cpuPct:  0
    property int cpuTemp: 0
    property int ramPct:  0
    property real ramGb:  0.0
    property int diskPct: 0
    property real diskGb: 0.0
    property real rxKb:   0.0
    property real txKb:   0.0

    property int  _cpuPrevIdle:  0
    property int  _cpuPrevTotal: 0
    property real _netPrevRx:    0
    property real _netPrevTx:    0
    property real _netPrevTs:    0

    // ── CPU Usage ───────────────────────────────────────────────────────
    property var _cpuFv: FileView {
        id: cpuFv
        path: "/proc/stat"
        watchChanges: false
        onTextChanged: {
            var t = text()
            if (!t) return
                var line = t.split("\n")[0]
                var f = line.trim().split(/\s+/)
                if (f.length < 8) return

                    var idle  = parseInt(f[4]) + parseInt(f[5])
                    var total = 0
                    for (var i = 1; i <= 7; i++) total += parseInt(f[i])

                        var dIdle  = idle  - root._cpuPrevIdle
                        var dTotal = total - root._cpuPrevTotal

                        if (root._cpuPrevTotal > 0 && dTotal > 0) {
                            var calc = Math.round(100 * (1 - dIdle / dTotal))
                            root.cpuPct = Math.max(0, Math.min(100, isNaN(calc) ? 0 : calc))
                        }

                        root._cpuPrevIdle  = idle
                        root._cpuPrevTotal = total
        }
    }
    property var _cpuTimer: Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: cpuFv.reload()
    }

    // ── RAM Usage ───────────────────────────────────────────────────────
    property var _ramFv: FileView {
        id: ramFv
        path: "/proc/meminfo"
        watchChanges: false
        onTextChanged: {
            var t = text()
            if (!t) return
                var lines = t.split("\n")
                var total = 0, avail = 0
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].indexOf("MemTotal:")     === 0) total = parseInt(lines[i].split(/\s+/)[1]) || 0
                        if (lines[i].indexOf("MemAvailable:") === 0) avail = parseInt(lines[i].split(/\s+/)[1]) || 0
                }
                if (total > 0) {
                    root.ramGb  = Math.max(0, (total - avail) / 1048576.0)
                    root.ramPct = Math.max(0, Math.min(100, Math.round((total - avail) / total * 100)))
                }
        }
    }
    property var _ramTimer: Timer {
        interval: 1500; running: true; repeat: true; triggeredOnStart: true
        onTriggered: ramFv.reload()
    }

    // ── Disk Usage ──────────────────────────────────────────────────────
    property var _diskProc: Process {
        id: diskProc
        command: ["sh", "-c", "df -k / | tail -n 1"]
        stdout: SplitParser {
            onRead: function(d) {
                if (!d) return
                    var fields = d.trim().split(/\s+/)
                    if (fields.length >= 5) {
                        var totalKb = parseFloat(fields[1]) || 0
                        var usedKb = parseFloat(fields[2]) || 0
                        if (totalKb > 0) {
                            root.diskGb = Math.max(0, usedKb / 1048576.0)
                            root.diskPct = Math.max(0, Math.min(100, Math.round((usedKb / totalKb) * 100)))
                        }
                    }
            }
        }
    }
    property var _diskTimer: Timer {
        interval: 5000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { diskProc.running = false; diskProc.running = true }
    }

    // ── CPU Temperature ─────────────────────────────────────────────────
    property var _tempProc: Process {
        id: tempProc
        command: ["sh", "-c",
        "for f in /sys/class/hwmon/hwmon*/temp*_input; do [ -f \"$f\" ] && cat \"$f\" && exit; done; " +
        "for f in /sys/class/thermal/thermal_zone*/temp; do [ -f \"$f\" ] && cat \"$f\" && exit; done; echo 0"]
        stdout: SplitParser {
            onRead: function(d) {
                var raw = parseFloat(d.trim())
                if (isNaN(raw) || raw <= 0) return
                    var t = raw > 1000 ? raw / 1000.0 : raw
                    if (t > 0 && t < 150) root.cpuTemp = Math.round(t)
            }
        }
    }
    property var _tempTimer: Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { tempProc.running = false; tempProc.running = true }
    }
}
