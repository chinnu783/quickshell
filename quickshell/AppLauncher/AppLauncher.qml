import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.LocalStorage
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Io
import ".."

PanelWindow {
    id: launcher
    property bool isOpen: false
    visible: isOpen
    color: "transparent"

    // Maintain full screen boundaries so our wings and background mask don't clip
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Safely capture mouse inputs only over the background panel and wings
    mask: Region {
        item: launcher.isOpen ? mainWrapper : null
    }

    // Prevents pushing standard workspace app windows downward
    exclusionMode: ExclusionMode.Ignore

    // Keeps launcher layout right under status bars but cleanly above main applications
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: launcher.isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-launcher"

    property string query: ""

    function launchSelected() {
        if (list.currentItem && list.currentItem.modelData) {
            list.currentItem.modelData.execute();
            launcher.isOpen = false
        }
    }

    IpcHandler {
        target: "applauncher"
        function toggle() {
            launcher.isOpen = !launcher.isOpen
            if (launcher.isOpen) {
                input.forceActiveFocus()
            }
        }
    }

    // Click outside wrapper → close launcher safely
    MouseArea {
        anchors.fill: parent
        onClicked: launcher.isOpen = false
    }

    // ── THE VISUAL WRAPPER ──────────────────────────────────────────────
    Item {
        id: mainWrapper
        width: bgPanel.width + 48 // Accommodates left and right wings (24px each)
        height: bgPanel.height + 54 // Accommodates topMargin space
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        // Left Flaring Concave Corner )
        Canvas {
            id: leftWing
            width: 24
            height: 24
            anchors.top: bgPanel.top
            anchors.right: bgPanel.left

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.fillStyle = Colors.surface;

                ctx.beginPath();
                ctx.moveTo(width, 0);
                ctx.lineTo(width, height);
                ctx.arcTo(width, 0, 0, 0, width);
                ctx.closePath();
                ctx.fill();
            }
        }

        // Main Launcher Panel Body ───────
        Rectangle {
            id: bgPanel
            width: 560
            height: 360
            anchors.top: parent.top
            anchors.topMargin: 54 // Change this number to match your exact top status bar height!
            anchors.horizontalCenter: parent.horizontalCenter
            color: Colors.surface

            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: 24
            bottomRightRadius: 24
        }

        // Right Flaring Concave Corner (
        Canvas {
            id: rightWing
            width: 24
            height: 24
            anchors.top: bgPanel.top
            anchors.left: bgPanel.right

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.fillStyle = Colors.surface;

                ctx.beginPath();
                ctx.moveTo(0, 0);
                ctx.lineTo(0, height);
                ctx.arcTo(0, 0, width, 0, width);
                ctx.closePath();
                ctx.fill();
            }
        }

        // ── Content Layout (FIXED: Moved INSIDE mainWrapper so it can anchor to bgPanel) ──
        ColumnLayout {
            spacing: 8
            width: bgPanel.width - 32
            height: bgPanel.height - 32

            anchors.top: bgPanel.top
            anchors.horizontalCenter: bgPanel.horizontalCenter
            anchors.topMargin: 16

            // Filtered model: only items matching the query
            ScriptModel {
                id: filtered
                values: {
                    const allEntries = [...DesktopEntries.applications.values];
                    const q = launcher.query.trim();

                    if (q === "") {
                        return allEntries;
                    } else {
                        return allEntries.filter(d => d.name && d.name.toLowerCase().includes(q));
                    }
                }
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: filtered.values
                currentIndex: filtered.values.length > 0 ? 0 : -1
                keyNavigationWraps: true
                preferredHighlightBegin: 0
                preferredHighlightEnd: height
                highlightRangeMode: ListView.ApplyRange
                highlightMoveDuration: 80
                highlight: Rectangle {
                    radius: 16
                    opacity: 1
                    color: Colors.module_hover
                }

                delegate: Item {
                    id: entry
                    required property var modelData
                    required property int index
                    width: ListView.view.width
                    height: 50

                    MouseArea {
                        anchors.fill: parent
                        onClicked: list.currentIndex = entry.index
                        onDoubleClicked: launcher.launchSelected()
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: 8
                        anchors.topMargin: 16
                        spacing: 10

                        IconImage {
                            source: Quickshell.iconPath(modelData.icon, true)
                            width: 23
                            height: 23
                        }
                        Text {
                            id: label
                            color: Colors.surfacefg
                            text: modelData.name
                            font.pointSize: 12
                            font.family: mainFont
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                Keys.onReturnPressed: launcher.launchSelected()
            }

            RowLayout {
                TextField {
                    id: input
                    Layout.fillWidth: true
                    placeholderText: ""
                    font.pixelSize: 16
                    font.family: mainFont
                    color: Colors.surfacefg
                    focus: true
                    padding: 15

                    onTextChanged: {
                        launcher.query = text;
                        list.currentIndex = filtered.values.length > 0 ? 0 : -1;
                    }

                    background: Rectangle {
                        border.width: 0
                        color: Colors.module
                        radius: 16
                    }

                    Keys.onEscapePressed: {
                        launcher.isOpen = false
                    }
                    Keys.onPressed: event => {
                        const ctrl = event.modifiers & Qt.ControlModifier;
                        if (event.key == Qt.Key_Up || event.key == Qt.Key_P && ctrl) {
                            event.accepted = true;
                            if (list.currentIndex > 0)
                                list.currentIndex--;
                    } else if (event.key == Qt.Key_Down || event.key == Qt.Key_N && ctrl) {
                            event.accepted = true;
                            if (list.currentIndex < list.count - 1)
                                list.currentIndex++;
                        } else if ([Qt.Key_Return, Qt.Key_Enter].includes(event.key)) {
                            event.accepted = true;
                            launcher.launchSelected();
                        } else if (event.key == Qt.Key_C && ctrl) {
                            event.accepted = true;
                            launcher.isOpen = false
                        }
                    }
                }
            }
        }
    } // End of mainWrapper
}
