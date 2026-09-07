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
    // focus: true
    color: "transparent" //Colors.module//Qt.rgba(0, 0, 0, 0.8)
    width: 560
    height: 360
    anchors {
        top: true
        right: true
        left: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
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

    Canvas {
        id: bgPanel

        // 1. Lock the explicit size of your panel layout
        width: 560
        height: 360

        // 2. Center it horizontally and anchor it to the top of the monitor window
        anchors.top: parent.top
        anchors.topMargin: 40
        anchors.horizontalCenter: parent.horizontalCenter

        // Custom properties for styling
        property color panelColor: Colors.surface
        property int outwardRadius: 24

        // 3. Force it to explicitly listen for layout updates so it redraws cleanly
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPanelColorChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();

            var w = width;
            var h = height;
            var r = outwardRadius;

            ctx.fillStyle = panelColor;
            ctx.beginPath();

            // Draw custom outline path containing inverse bottom curves
            ctx.moveTo(0, 0);                  // Top-left
            ctx.lineTo(w, 0);                  // Top-right
            ctx.lineTo(w, h - r);              // Down right edge
            ctx.quadraticCurveTo(w, h, w - r, h); // Outward curve bottom-right
            ctx.lineTo(r, h);                  // Across bottom edge
            ctx.quadraticCurveTo(0, h, 0, h - r); // Outward curve bottom-left
            ctx.lineTo(0, 0);                  // Back to start

            ctx.closePath();
            ctx.fill();
        }
    }

    // Rectangle {
    //     id: bgPanel
    //     width: 560//launcher.width
    //     height: 360//launcher.height
    //     anchors.top: parent.top
    //     anchors.topMargin: 0
    //     anchors.horizontalCenter: parent.horizontalCenter
    //     color: Colors.surface
    //     topLeftRadius: 0
    //     topRightRadius: 0
    //     bottomLeftRadius: 24
    //     bottomRightRadius: 24
    // }

    ColumnLayout {
        // anchors.fill: bgPanel
        spacing: 8
        anchors.margins: 16
        width: bgPanel.width - 32
        height: bgPanel.height - 32
        // anchors.centerIn: bgPanel
        anchors.top: bgPanel.top
        anchors.horizontalCenter: bgPanel.horizontalCenter

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
                opacity: 1//0.45
                color: Colors.module_hover//input.palette.highlight
            }

            delegate: Item {
                id: entry
                required property var modelData
                required property int index
                width: ListView.view.width
                height: 36

                MouseArea {
                    anchors.fill: parent
                    onClicked: list.currentIndex = entry.index
                    onDoubleClicked: launcher.launchSelected()
                }

                Row {
                    anchors.fill: parent
                    anchors.margins: 8
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
                        font.pointSize: 13
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            // Enter also works while ListView has focus
            Keys.onReturnPressed: launcher.launchSelected()
        }
        RowLayout {
            // IconImage {
            //     Layout.leftMargin: 10
            //     source: Quickshell.iconPath("nix-snowflake", true)
            //     Layout.preferredWidth: 25
            //     Layout.preferredHeight: 25
            // }

            TextField {
                id: input
                Layout.fillWidth: true
                placeholderText: ""
                font.pixelSize: 18
                color: Colors.surfacefg//Colors.surfacefg
                focus: true
                padding: 15

                onTextChanged: {
                    launcher.query = text;
                    // reset selection to first item of the filtered list
                    list.currentIndex = filtered.values.length > 0 ? 0 : -1;
                }

                background: Rectangle {
                    border.width: 0
                    color: Colors.module//"transparent"
                    radius: 16
                }

                // Quit
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
}
