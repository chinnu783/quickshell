import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland
import Quickshell.Widgets
import "../Time"
import "../"

PanelWindow {
    id: cc

    anchors.top: true
    anchors.left: false
    anchors.right: false

    implicitWidth: 600
    implicitHeight: mainCol.implicitHeight + 24
    color: "transparent"
    visible: false

    WlrLayershell.namespace: "cc"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.margins.top: 60

    // ── State ────────────────────────────────────────────────────────
    property string hostname: ""
    property string uptime: ""
    property string displayName: ""
    property bool editingName: false
    property string avatarEmoji: "😊"
    property bool editingAvatar: false

    readonly property var player: {
        var v = Mpris.players.values;
        for (var i = 0; i < v.length; i++) {
            if (v[i].trackTitle && v[i].trackTitle !== "")
                return v[i];
        }
        return v.length > 0 ? v[0] : null;
    }
    property real mediaPos: 0
    property real mediaLen: 0

    FrameAnimation {
        running: cc.player !== null
        onTriggered: {
            if (cc.player) {
                cc.player.positionChanged();
                cc.mediaPos = cc.player.position;
                cc.mediaLen = cc.player.length;
            }
        }
    }
    readonly property bool hasMedia: player !== null

    // Lucide SVG paths
    readonly property string p_power: "<path d='M12 2v10'/><path d='M18.4 6.6a9 9 0 1 1-12.77.04'/>"
    readonly property string p_x: "<path d='M18 6 6 18'/><path d='m6 6 12 12'/>"
    readonly property string p_pencil: "<path d='M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z'/><path d='m15 5 4 4'/>"
    readonly property string p_play: "<polygon points='6 3 20 12 6 21 6 3'/>"
    readonly property string p_pause: "<rect x='14' y='4' width='4' height='16' rx='1'/><rect x='6' y='4' width='4' height='16' rx='1'/>"
    readonly property string p_skipB: "<polygon points='19 20 9 12 19 4 19 20'/><line x1='5' x2='5' y1='19' y2='5'/>"
    readonly property string p_skipF: "<polygon points='5 4 15 12 5 20 5 4'/><line x1='19' x2='19' y1='5' y2='19'/>"
    readonly property string p_repeat: "<path d='m2 9 3-3 3 3'/><path d='M13 18H7a2 2 0 0 1-2-2V6'/><path d='m22 15-3 3-3-3'/><path d='M11 6h6a2 2 0 0 1 2 2v10'/>"
    readonly property string p_shuf: "<path d='M2 18h1.4c1.3 0 2.5-.6 3.3-1.7l6.1-8.6c.7-1.1 2-1.7 3.3-1.7H22'/><path d='m18 2 4 4-4 4'/><path d='M2 6h1.9c1.5 0 2.9.9 3.6 2.2'/><path d='M22 18h-5.9c-1.3 0-2.6-.7-3.3-1.8l-.5-.8'/><path d='m18 14 4 4-4 4'/>"
    readonly property string p_music: "<path d='M9 18V5l12-2v13'/><circle cx='6' cy='18' r='3'/><circle cx='18' cy='16' r='3'/>"
    readonly property string p_cal: "<path d='M8 2v4'/><path d='M16 2v4'/><rect width='18' height='18' x='3' y='4' rx='2'/><path d='M3 10h18'/><path d='M8 14h.01'/><path d='M12 14h.01'/><path d='M16 14h.01'/><path d='M8 18h.01'/><path d='M12 18h.01'/><path d='M16 18h.01'/>"
    readonly property string p_user: "<path d='M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2'/><circle cx='12' cy='7' r='4'/>"

    function formatTime(sec) {
        var s = Math.floor(sec || 0);
        return Math.floor(s / 60) + ":" + ("0" + (s % 60)).slice(-2);
    }

    function ico(paths, color, size) {
        return "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='" + (size || 20) + "' height='" + (size || 20) + "' viewBox='0 0 24 24' fill='none' stroke='" + color + "' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'>" + paths + "</svg>";
    }

    onVisibleChanged: {
        if (visible) {
            refreshAll();
        }
    }

    function refreshAll() {
        sysProc.running = false;
        sysProc.running = true;
    }

    Process {
        id: sysProc
        command: ["sh", "-c", "hostname && uptime -p | sed 's/up //'"]

        stdout: SplitParser {
            property int _l: 0

            onRead: function(d) {
                if (_l === 0) {
                    cc.hostname = d.trim();
                    if (!cc.displayName)
                        cc.displayName = d.trim();
                    _l = 1;
                } else {
                    cc.uptime = d.trim();
                    _l = 0;
                }
            }
            Component.onCompleted: _l = 0
        }
    }

    // ── Background ────────────────────────────────────────────────────
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
            topMargin: 10
        }
        spacing: 6

        // ── Header (User Info) ───────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                width: 42
                height: 42
                radius: 8
                color: Colors.module
                clip: true

                // Default lucide user icon
                Image {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    smooth: true
                    visible: cc.avatarEmoji === "😊" || cc.editingAvatar
                    source: cc.ico(cc.p_user, Colors.surfacefg, 24)
                }

                // Custom emoji
                Text {
                    anchors.centerIn: parent
                    text: cc.avatarEmoji
                    font.pixelSize: 22
                    visible: cc.avatarEmoji !== "😊" && !cc.editingAvatar
                }

                // Pencil badge on hover
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    width: 14
                    height: 14
                    radius: 3
                    color: Colors.module_hover
                    visible: avatMa.containsMouse

                    Image {
                        anchors.centerIn: parent
                        width: 9
                        height: 9
                        smooth: true
                        source: cc.ico(cc.p_pencil, Colors.surfacefg, 9)
                    }
                }

                MouseArea {
                    id: avatMa

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onDoubleClicked: cc.editingAvatar = !cc.editingAvatar
                }

                // Emoji picker
                Rectangle {
                    visible: cc.editingAvatar
                    anchors.top: parent.bottom
                    anchors.topMargin: 4
                    anchors.left: parent.left
                    width: 220
                    height: 44
                    radius: 8
                    color: Colors.module
                    z: 10
                    border.width: 1
                    border.color: Colors.outline

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Repeater {
                            model: ["😊", "😎", "🦊", "🐧", "🌙", "⭐", "🎮", "🔥"]

                            Text {
                                required property var modelData

                                text: modelData
                                font.pixelSize: 20

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        cc.avatarEmoji = parent.text;
                                        cc.editingAvatar = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                spacing: 2
                visible: !cc.editingName

                Text {
                    text: cc.displayName || cc.hostname || "niriha"
                    color: Colors.surfacefg
                    font.family: mainFont
                    font.pixelSize: 15
                    font.weight: Font.Medium

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onDoubleClicked: {
                            cc.editingName = true;
                            nameEdit.text = cc.displayName || cc.hostname;
                            nameEdit.forceActiveFocus();
                        }
                    }
                }

                Text {
                    text: "uptime " + (cc.uptime || "")
                    color: Colors.outline
                    font.family: mainFont
                    font.pixelSize: 11
                    visible: cc.uptime !== ""
                }
            }

            Rectangle {
                visible: cc.editingName
                height: 28
                width: 120
                radius: 6
                color: Colors.module_hover

                TextInput {
                    id: nameEdit

                    anchors {
                        fill: parent
                        leftMargin: 8
                        rightMargin: 8
                        verticalCenter: parent.verticalCenter
                    }
                    color: Colors.surfacefg
                    font.family: mainFont
                    font.pixelSize: 13
                    verticalAlignment: TextInput.AlignVCenter

                    Keys.onReturnPressed: {
                        cc.displayName = text;
                        cc.editingName = false;
                    }
                    Keys.onEscapePressed: cc.editingName = false
                }
            }

            Item {
                Layout.fillWidth: true
            }

            // Header icon capsule — calendar > power > close
            Rectangle {
                height: 38
                radius: 8
                color: Colors.module
                implicitWidth: hBtns.implicitWidth + 12

                Row {
                    id: hBtns

                    anchors.centerIn: parent
                    spacing: 3

                    Item {
                        width: 36
                        height: 36

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: calMa.containsMouse ? Colors.module_hover : "transparent"

                            Behavior on color {
                                ColorAnimation {
                                    duration: 80
                                }
                            }
                        }

                        Image {
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            smooth: true
                            source: cc.ico(cc.p_cal, Colors.surfacefg, 16)
                        }

                        MouseArea {
                            id: calMa

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cal.visible=!cal.visible//Qt.createQmlObject('import Quickshell.Io; Process{command:["qs","ipc","-c","niriha","call","calendar","toggle"]; running:true}', cc, "cal")
                        }
                        CalendarPopup {
                            id:cal
                        }
                    }

                    Rectangle {
                        width: 1
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter
                        color: Colors.outline
                        opacity: 0.5
                    }

                    Item {
                        width: 36
                        height: 36

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: poMa.containsMouse ? Colors.error : "transparent"

                            Behavior on color {
                                ColorAnimation {
                                    duration: 80
                                }
                            }
                        }

                        Image {
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            smooth: true
                            source: cc.ico(cc.p_power, poMa.containsMouse ? Colors.errorfg : Colors.surfacefg, 16)
                        }

                        MouseArea {
                            id: poMa

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.createQmlObject('import Quickshell.Io; Process{command:["systemctl","poweroff"]; running:true}', cc, "po")
                        }
                    }

                    Rectangle {
                        width: 1
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter
                        color: Colors.outline
                        opacity: 0.5
                    }

                    Item {
                        width: 36
                        height: 36

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: clMa.containsMouse ? Colors.module_hover : "transparent"

                            Behavior on color {
                                ColorAnimation {
                                    duration: 80
                                }
                            }
                        }

                        Image {
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            smooth: true
                            source: cc.ico(cc.p_x, clMa.containsMouse ? Colors.error : Colors.surfacefg, 16)
                        }

                        MouseArea {
                            id: clMa

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cc.visible = false
                        }
                    }
                }
            }
        }

        // ── Media ────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            visible: cc.hasMedia
            height: visible ? 192 : 0
            radius: 10
            color: Colors.module

            RowLayout {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 12
                }
                spacing: 14

                // Big album art
                Rectangle {
                    width: 92
                    height: 92
                    radius: 8
                    color: Colors.module_hover
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: cc.player ? (cc.player.trackArtUrl || "") : ""
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        asynchronous: true
                        visible: status === Image.Ready
                    }

                    Image {
                        anchors.centerIn: parent
                        width: 28
                        height: 28
                        smooth: true
                        visible: !cc.player || (cc.player.trackArtUrl || "") === ""
                        source: cc.ico(cc.p_music, Colors.outline, 28)
                    }
                }

                // Controls column (right of art)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    // play/skip row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Item {
                            Layout.fillWidth: true
                        }

                        // skip back
                        Item {
                            width: 40
                            height: 40

                            Rectangle {
                                anchors.fill: parent
                                radius: 20
                                color: sbMa.containsMouse ? Colors.module_hover : "transparent"

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 80
                                    }
                                }
                            }

                            Image {
                                anchors.centerIn: parent
                                width: 18
                                height: 18
                                smooth: true
                                source: cc.ico(cc.p_skipB, Colors.surfacefg, 18)
                            }

                            MouseArea {
                                id: sbMa

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (cc.player)
                                cc.player.previous()
                            }
                        }

                        // play/pause big
                        Item {
                            width: 52
                            height: 52

                            Rectangle {
                                anchors.fill: parent
                                radius: 26
                                color: Colors.primary

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 80
                                    }
                                }
                            }

                            Image {
                                anchors.centerIn: parent
                                width: 22
                                height: 22
                                smooth: true
                                source: cc.ico(cc.player && cc.player.isPlaying ? cc.p_pause : cc.p_play, Colors.primaryfg, 22)
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (cc.player)
                                cc.player.togglePlaying()
                            }
                        }

                        // skip fwd
                        Item {
                            width: 40
                            height: 40

                            Rectangle {
                                anchors.fill: parent
                                radius: 20
                                color: sfMa.containsMouse ? Colors.module_hover : "transparent"

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 80
                                    }
                                }
                            }

                            Image {
                                anchors.centerIn: parent
                                width: 18
                                height: 18
                                smooth: true
                                source: cc.ico(cc.p_skipF, Colors.surfacefg, 18)
                            }

                            MouseArea {
                                id: sfMa

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (cc.player)
                                cc.player.next()
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }
                    }

                    // shuffle + repeat row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Item {
                            Layout.fillWidth: true
                        }

                        Item {
                            width: 32
                            height: 32

                            Image {
                                anchors.centerIn: parent
                                width: 16
                                height: 16
                                smooth: true
                                source: cc.ico(cc.p_shuf, Colors.outline, 16)
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                            }
                        }

                        Item {
                            width: 32
                            height: 32

                            Image {
                                anchors.centerIn: parent
                                width: 16
                                height: 16
                                smooth: true
                                source: cc.ico(cc.p_repeat, Colors.outline, 16)
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // Track info + progress below the art+controls row
            ColumnLayout {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: 12
                }
                spacing: 6

                Text {
                    text: cc.player ? (cc.player.trackTitle || "Unknown") : ""
                    color: Colors.surfacefg
                    font.family: mainFont
                    font.pixelSize: 16
                    font.weight: Font.Medium
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: cc.player ? ((cc.player.trackArtist || "") + (cc.player.trackAlbum ? " · " + cc.player.trackAlbum : "")) : ""
                    color: Colors.outline
                    font.family: mainFont
                    font.pixelSize: 13
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    visible: text !== ""
                }

                // Progress bar with timestamps
                Item {
                    Layout.fillWidth: true
                    height: 20

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: cc.mediaLen > 0 ? formatTime(cc.mediaPos) : "0:00"
                        color: Colors.outline
                        font.family: mainFont
                        font.pixelSize: 11
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: cc.mediaLen > 0 ? formatTime(cc.mediaLen) : "0:00"
                        color: Colors.outline
                        font.family: mainFont
                        font.pixelSize: 11
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - 56
                        height: 6
                        radius: 3
                        color: Colors.surfacea

                        Rectangle {
                            width: cc.mediaLen > 0 ? parent.width * (cc.mediaPos / cc.mediaLen) : 0
                            height: parent.height
                            radius: 3
                            color: Colors.primary

                            Behavior on width {
                                NumberAnimation {
                                    duration: 400
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
