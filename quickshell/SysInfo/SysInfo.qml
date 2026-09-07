import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Rectangle {
    id: pillRoot

    // Styling Properties
    property color bgColor: "#1e1e2e"
    property color borderColor: "#313244"
    property color labelColor: "#cba6f7"
    property color textColor: "#cdd6f4"
    property color alertColor: "#f38ba8"

    // Live Metrics
    property int cpuPct: 0
    property int ramPct: 0
    property int diskPct: 0
    property int netRxKb: 0
    property int netTxKb: 0

    // Internal tracking variables
    property real lastTotalJiffies: 0
    property real lastIdleJiffies: 0
    property real lastRxBytes: 0
    property real lastTxBytes: 0
    property string accumBuffer: ""

    implicitWidth: mainLayout.implicitWidth + 20
    implicitHeight: 30
    radius: height / 2

    color: bgColor
    border.color: borderColor
    border.width: 1

    function formatSpeed(kb) {
        if (kb >= 1024) return (kb / 1024).toFixed(1) + "M/s"
            return kb + "K/s"
    }

    Process {
        id: sysPoller
        // Single atomic shell call outputting clear unique markers
        command: ["/bin/sh", "-c", "echo '---CPU---'; cat /proc/stat; echo '---MEM---'; cat /proc/meminfo; echo '---NET---'; cat /proc/net/dev; echo '---DISK---'; df -k /"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                pillRoot.accumBuffer += data
            }
        }

        onExited: (code, status) => {
            let rawData = pillRoot.accumBuffer
            pillRoot.accumBuffer = "" // Reset buffer immediately

            if (!rawData) return

                // Parse CPU
                let cpuMatch = rawData.match(/---CPU---\s*cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
                if (cpuMatch) {
                    let user = parseFloat(cpuMatch[1]) || 0
                    let nice = parseFloat(cpuMatch[2]) || 0
                    let sys = parseFloat(cpuMatch[3]) || 0
                    let idle = parseFloat(cpuMatch[4]) || 0
                    let iowait = parseFloat(cpuMatch[5]) || 0
                    let irq = parseFloat(cpuMatch[6]) || 0
                    let softirq = parseFloat(cpuMatch[7]) || 0

                    let total = user + nice + sys + idle + iowait + irq + softirq
                    let idleTotal = idle + iowait

                    if (pillRoot.lastTotalJiffies > 0) {
                        let diffTotal = total - pillRoot.lastTotalJiffies
                        let diffIdle = idleTotal - pillRoot.lastIdleJiffies
                        if (diffTotal > 0) {
                            let usage = ((diffTotal - diffIdle) / diffTotal) * 100
                            pillRoot.cpuPct = Math.min(100, Math.max(0, Math.round(usage)))
                        }
                    }
                    pillRoot.lastTotalJiffies = total
                    pillRoot.lastIdleJiffies = idleTotal
                }

                // Parse Memory
                let totalMatch = rawData.match(/MemTotal:\s*(\d+)/)
                let availMatch = rawData.match(/MemAvailable:\s*(\d+)/)
                if (totalMatch && availMatch) {
                    let memTotal = parseInt(totalMatch[1]) || 0
                    let memAvail = parseInt(availMatch[1]) || 0
                    if (memTotal > 0) {
                        pillRoot.ramPct = Math.round(((memTotal - memAvail) / memTotal) * 100)
                    }
                }

                // Parse Network
                let netSection = rawData.split("---NET---")[1]
                if (netSection) {
                    netSection = netSection.split("---DISK---")[0]
                    let netLines = netSection.trim().split("\n")
                    let rxSum = 0
                    let txSum = 0

                    for (let i = 0; i < netLines.length; i++) {
                        let line = netLines[i].trim()
                        if (!line || line.startsWith("Inter-") || line.startsWith("face") || line.startsWith("lo:")) continue

                            let colonIdx = line.indexOf(":")
                            if (colonIdx !== -1) {
                                let stats = line.substring(colonIdx + 1).trim().split(/\s+/)
                                if (stats.length >= 9) {
                                    rxSum += parseFloat(stats[0]) || 0
                                    txSum += parseFloat(stats[8]) || 0
                                }
                            }
                    }

                    if (pillRoot.lastRxBytes > 0) {
                        pillRoot.netRxKb = Math.round(Math.max(0, rxSum - pillRoot.lastRxBytes) / 1024 / 2)
                        pillRoot.netTxKb = Math.round(Math.max(0, txSum - pillRoot.lastTxBytes) / 1024 / 2)
                    }
                    pillRoot.lastRxBytes = rxSum
                    pillRoot.lastTxBytes = txSum
                }

                // Parse Disk
                let diskSection = rawData.split("---DISK---")[1]
                if (diskSection) {
                    let diskMatch = diskSection.match(/(\d+)%\s+/)
                    if (diskMatch) {
                        pillRoot.diskPct = parseInt(diskMatch[1]) || 0
                    }
                }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            // Prevent execution collisions if a run is already active
            if (!sysPoller.running) {
                pillRoot.accumBuffer = ""
                sysPoller.running = true
            }
        }
    }

    RowLayout {
        id: mainLayout
        anchors.centerIn: parent
        spacing: 10

        // CPU
        RowLayout {
            spacing: 4
            Text {
                text: "CPU"
                color: pillRoot.cpuPct >= 85 ? pillRoot.alertColor : pillRoot.labelColor
                font.bold: true
                font.pixelSize: 11
            }
            Text {
                text: pillRoot.cpuPct + "%"
                color: pillRoot.cpuPct >= 85 ? pillRoot.alertColor : pillRoot.textColor
                font.pixelSize: 11
            }
        }

        // Divider
        Rectangle { width: 1; height: 10; color: pillRoot.borderColor }

        // RAM
        RowLayout {
            spacing: 4
            Text {
                text: "RAM"
                color: pillRoot.ramPct >= 85 ? pillRoot.alertColor : pillRoot.labelColor
                font.bold: true
                font.pixelSize: 11
            }
            Text {
                text: pillRoot.ramPct + "%"
                color: pillRoot.ramPct >= 85 ? pillRoot.alertColor : pillRoot.textColor
                font.pixelSize: 11
            }
        }

        // Divider
        Rectangle { width: 1; height: 10; color: pillRoot.borderColor }

        // DISK
        RowLayout {
            spacing: 4
            Text {
                text: "DISK"
                color: pillRoot.diskPct >= 90 ? pillRoot.alertColor : pillRoot.labelColor
                font.bold: true
                font.pixelSize: 11
            }
            Text {
                text: pillRoot.diskPct + "%"
                color: pillRoot.diskPct >= 90 ? pillRoot.alertColor : pillRoot.textColor
                font.pixelSize: 11
            }
        }

        // Divider
        Rectangle { width: 1; height: 10; color: pillRoot.borderColor }

        // NET
        RowLayout {
            spacing: 4
            Text {
                text: "NET"
                color: pillRoot.labelColor
                font.bold: true
                font.pixelSize: 11
            }
            Text {
                text: "↓ " + pillRoot.formatSpeed(pillRoot.netRxKb) + " ↑ " + pillRoot.formatSpeed(pillRoot.netTxKb)
                color: pillRoot.textColor
                font.pixelSize: 11
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            sysStats.visible = !sysStats.visible
        }
    }

    SystemInfoPopup {
        id: sysStats
        visible: false
    }
}
