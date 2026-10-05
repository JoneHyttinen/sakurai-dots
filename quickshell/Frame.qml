import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland

Scope {
    id: root
    required property var modelData

    // Invisible, click-through strips that reserve space along an edge
    component EdgeZone: PanelWindow {
        screen: root.modelData
        color: "transparent"
        mask: Region {}
        WlrLayershell.namespace: "qs-frame-zone"
    }

    EdgeZone {
        anchors { left: true; top: true; bottom: true }
        implicitWidth: Theme.frame.side
        exclusiveZone: Theme.frame.side
    }
    EdgeZone {
        anchors { right: true; top: true; bottom: true }
        implicitWidth: Theme.frame.side
        exclusiveZone: Theme.frame.side
    }
    EdgeZone {
        anchors { left: true; right: true; bottom: true }
        implicitHeight: Theme.frame.side
        exclusiveZone: Theme.frame.side
    }

    // The visible frame
    PanelWindow {
        screen: root.modelData
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region {}  // clicks pass straight through
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "qs-frame"

        Shape {
            id: shape
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: Theme.colors.surface
                strokeColor: "transparent"
                fillRule: ShapePath.OddEvenFill  // inner rectangle becomes a hole

                PathRectangle {
                    x: 0
                    y: 0
                    width: shape.width
                    height: shape.height
                }
                PathRectangle {
                    x: Theme.frame.side
                    y: Theme.frame.top
                    width: shape.width - Theme.frame.side * 2
                    height: shape.height - Theme.frame.top - Theme.frame.side
                    radius: Theme.frame.radius
                }
            }
        }
    }
}
