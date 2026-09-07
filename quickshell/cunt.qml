pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import Quickshell.Wayland

Scope {
    id: root

    // Adjust corner radius size here
    property int cornerRadius: 12
    property int bwidth: 4

    Variants {
        model: Quickshell.screens

        Scope {
            id: screenRoot
            required property var modelData

            // Left Border Strip
            PanelWindow {
                screen: screenRoot.modelData
                anchors { top: true; bottom: true; left: true }
                implicitWidth: root.bwidth
                exclusiveZone: root.bwidth
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "qs-border-left"
                color: Colors.surface
            }

            // Right Border Strip
            PanelWindow {
                screen: screenRoot.modelData
                anchors { top: true; bottom: true; right: true }
                implicitWidth: root.bwidth
                exclusiveZone: root.bwidth
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "qs-border-right"
                color: Colors.surface
            }

            // Bottom Border Strip
            PanelWindow {
                screen: screenRoot.modelData
                anchors { right: true; bottom: true; left: true }
                implicitHeight: root.bwidth
                exclusiveZone: root.bwidth
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "qs-border-bottom"
                color: Colors.surface
            }

            // Top-Left Inner Concave Corner
            PanelWindow {
                screen: screenRoot.modelData
                anchors { top: true; left: true }
                implicitWidth: root.cornerRadius
                implicitHeight: root.cornerRadius
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "qs-corner-tl"
                color: "transparent"

                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.fillStyle = Colors.surface;

                        // Fill top-left vertex and curve inward
                        ctx.beginPath();
                        ctx.moveTo(0, 0);
                        ctx.lineTo(0, height);
                        ctx.arcTo(0, 0, width, 0, root.cornerRadius);
                        ctx.closePath();
                        ctx.fill();
                    }
                }
            }

            // Top-Right Inner Concave Corner
            PanelWindow {
                screen: screenRoot.modelData
                anchors { top: true; right: true }
                implicitWidth: root.cornerRadius
                implicitHeight: root.cornerRadius
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "qs-corner-tr"
                color: "transparent"

                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.fillStyle = Colors.surface;

                        // Fill top-right vertex and curve inward
                        ctx.beginPath();
                        ctx.moveTo(width, 0);
                        ctx.lineTo(width, height);
                        ctx.arcTo(width, 0, 0, 0, root.cornerRadius);
                        ctx.closePath();
                        ctx.fill();
                    }
                }
            }

            // Bottom-Left Inner Concave Corner
            PanelWindow {
                screen: screenRoot.modelData
                anchors { bottom: true; left: true }
                implicitWidth: root.cornerRadius
                implicitHeight: root.cornerRadius
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "qs-corner-bl"
                color: "transparent"

                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.fillStyle = Colors.surface;

                        // Fill bottom-left vertex and curve inward
                        ctx.beginPath();
                        ctx.moveTo(0, height);
                        ctx.lineTo(0, 0);
                        ctx.arcTo(0, height, width, height, root.cornerRadius);
                        ctx.closePath();
                        ctx.fill();
                    }
                }
            }

            // Bottom-Right Inner Concave Corner
            PanelWindow {
                screen: screenRoot.modelData
                anchors { bottom: true; right: true }
                implicitWidth: root.cornerRadius
                implicitHeight: root.cornerRadius
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "qs-corner-br"
                color: "transparent"

                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.fillStyle = Colors.surface;

                        // Fill bottom-right vertex and curve inward
                        ctx.beginPath();
                        ctx.moveTo(width, height);
                        ctx.lineTo(width, 0);
                        ctx.arcTo(width, height, 0, height, root.cornerRadius);
                        ctx.closePath();
                        ctx.fill();
                    }
                }
            }
        }
    }
}
